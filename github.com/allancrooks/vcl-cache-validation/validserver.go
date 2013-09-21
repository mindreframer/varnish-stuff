/**
 * This is a webserver which returns virtual documents which appear to
 * either be static, periodically updated (every X seconds), or that
 * can be programatically updated. It performs e-tag and date modified
 * validation.
 */

package main

import (
    "fmt"
    "net/http"
    "os"
    "sort"
    "strconv"
    "strings"
    "sync"
    "time"
)

const granularity_in_seconds = 10
const help_text = `
USAGE: You can go to any of the following URLs to get some content:
  /static/* -> A document which appears to never update.
  /periodic/* -> A document which updates every 10 seconds.
  /clock/* -> A document which can be updated manually.
  
To update a document on the /clock/ resource, just send a PUT request
(the content of which will be ignored), and it will be updated. The
server treats each path as a unique document, so adding any of the path
components mentioned below will be considered a different document.

Documents can also output validation headers if the following components
are present in the path:
  /datemod/ -> Outputs a Last-Modified header, and performs date resource validation.
               This will check If-Modified-Since and If-Unmodified-Since headers.
  /etag/ -> Outputs an Etag header, and performs E-Tag resource validation.
            This will check If-Match and If-None-Match headers.
            
If the following components are present in the path, you can get additional data.
  /headers/ -> Outputs the request headers in the response.

So to access a document which appears to update every 10 seconds, and
to output an Etag header, and include request headers:
  /periodic/etag/headers/hamster/slipper/
`

// We record old responses for the test suite.
type HistoricResponse struct {
    Code int
    Body string
}

var last_responses = make(map[string]HistoricResponse)

// This is where we store our clocked documents.
var dynamic_docs = make(map[string]time.Time)
var our_mutex = sync.Mutex{}

/**
 * This is a quickly put together bit of code "wot I wrote" which
 * emulates Python's StringIO (or Java's ByteWriter) such that we
 * can compose a response by writing to a buffer and then determine
 * the correct Content-Length header at the end.
 */
type ByteWriter struct {
    buf []byte
    pos int
}

func Buffy() *ByteWriter {
    res := new(ByteWriter)
    res.buf = make([]byte, 4096) // 4K should be enough for anyone!
    res.pos = 0
    return res
}

func (s *ByteWriter) Write(bs []byte) (n int, err error) {
    n = len(bs)
    copy(s.buf[s.pos:s.pos+n], bs)
    s.pos += n
    return
}

func (b *ByteWriter) AsString() string {
    return string(b.buf[0:b.pos]);
}

/**
 * Handler function for the server.
 */
func handle(w http.ResponseWriter, r *http.Request) {

    /**
     * This is the function where we write out a response, set the
     * right headers, set the content length etc. All the logic later
     * on in the code should call this function and return.
     */
    respond := func (code int, message string) {
        timestamp := time.Now().Format("[2006/01/02 15:04:05]")
        fmt.Println(timestamp, r.Method, r.URL, "->", code)
        
        /**
         * http.Error will set a Content-Type. Even for 304's. That's
         * fine. And then when writing out the response, it'll complain
         * that the header is there. Nice.
         * 
         * That's why I stopped using http.Error and instead just avoid
         * writing out those headers if there's no response content.
         * Make sure that any 304's returned will not pass a message!
         */
        if len(message) > 0 {
            w.Header().Set("Content-Length", strconv.Itoa(len(message)))
            w.Header().Set("Content-Type", "text/plain; charset=utf-8")
        }
        w.WriteHeader(code)
        fmt.Fprint(w, message)

        // Cache this response for test inspection.        
        our_mutex.Lock()
        defer our_mutex.Unlock()
        if r.Method == "GET" && len(r.URL.RawQuery) == 0 {
            last_responses[r.URL.Path] = HistoricResponse{code, message}
        }
    }
    
    // All URLs have to have forward slashes at the end!
    if !strings.HasSuffix(r.URL.Path, "/") {
        respond(410, "You must have a forward slash at the end of the path.")
        return
    }
    
    now := time.Now().UTC()
    
    // Here's where we update clock documents.
    if r.Method == "PUT" && strings.HasPrefix(r.URL.Path, "/clock/") {
        our_mutex.Lock()
        dynamic_docs[r.URL.Path] = now
        our_mutex.Unlock()
        respond(204, "")
        return
    }

    // Only GET allowed.
    if r.Method != "GET" {
        respond(405, "Only GET requests supported")
        return
    }
    
    // If there's a query string argument of lastresp=yes, we
    // "reproduce" the content without the original headers.
    if r.URL.Query().Get("lastresp") == "yes" {
        our_mutex.Lock()
        lastresp, has_it := last_responses[r.URL.Path]
        our_mutex.Unlock()
        
        if !has_it {
            respond(404, "No previous response available.")
            return
        }

        // Write out the previous body. We won't cache the response,
        // because there's a query string place.
        respond(lastresp.Code, lastresp.Body)
        return
    }
    
    // Print help text on the root resource.
    if r.URL.Path == "/" {
        respond(200, help_text)
        return
    }
    
    // Determine what things we want to do for our response.
    print_headers := strings.Index(r.URL.Path, "/headers/") != -1
    use_etags := strings.Index(r.URL.Path, "/etag/") != -1
    use_lastmod := strings.Index(r.URL.Path, "/lastmod/") != -1

    // This is the content.
    var then time.Time;
    if strings.HasPrefix(r.URL.Path, "/static/") {
        then = time.Date(2012, 12, 20, 20, 12, 12, 0, now.Location())
    } else if strings.HasPrefix(r.URL.Path, "/periodic/") {
        seconds := ((now.Second() / granularity_in_seconds) * granularity_in_seconds)
        then = time.Date(now.Year(), now.Month(), now.Day(), now.Hour(), now.Minute(), seconds, 0, now.Location())
    } else if strings.HasPrefix(r.URL.Path, "/clock/") {
        our_mutex.Lock()
        var has_time bool
        
        // Get the dynamic document.
        then, has_time = dynamic_docs[r.URL.Path]
        
        // But if one isn't there, create it now.
        if (!has_time) {then = now}
        dynamic_docs[r.URL.Path] = then
        our_mutex.Unlock()
    } else {
        respond(410, "No handler defined here.")
        return
    }
    
    now_header := now.Format(time.RFC1123Z)
    then_header := then.Format(time.RFC1123Z)

    // Custom headers for the response.
    headers := make(map[string]string)
        
    // E-Tag check, based on the method "validate_etags" in cptools.py
    // in CherryPy's module.
    if use_etags {
    
        // Generate the E-Tag.
        etag := then.Format("2006-01-02,15:04:05")
        etag_enc := "\"" + etag + "\""
        
        // Note: Not bothering with multiple headers at the moment.
        
        // Check If-Match header.
        etag_if_match := r.Header.Get("If-Match")
        if (len(etag_if_match) > 0) && 
            !(etag_enc == "\"*\"" || etag_enc == etag_if_match) {
            respond(412, "If-Match failed: ETag did not match")
            return
        }
        
        // Check If-None-Match header.
        etag_if_none_match := r.Header.Get("If-None-Match")
        if (len(etag_if_none_match) > 0) && (
            etag_enc == "\"*\"" || etag_enc == etag_if_none_match) {
            respond(304, "")
            return
        }
        
        headers["Etag"] = etag_enc
    }

    // Last modified check, based on the method "validate_since" in
    // cptools.py in CherryPy's module.
    if use_lastmod {
    
        // Check If-Unmodified-Since header.
        unmod_since := r.Header.Get("If-Unmodified-Since")
        if (len(unmod_since) > 0) && (unmod_since != then_header) {
            respond(412, "Document has been modified")
            return
        }

        // Check If-Modified-Since header.
        mod_since := r.Header.Get("If-Modified-Since")
        if (len(mod_since) > 0) && (mod_since == then_header) {
            respond(304, "")
            return
        }
        
        headers["Last-Modified"] = then_header
    }    

    /**
     * Response-writing time! We write in a buffer because we want to
     * determine and set the Content-Length, as Go's libraries won't do
     * it automatically.
     */    
    b := Buffy()
    
    fmt.Fprintln(b, "Content date:", then_header)
    fmt.Fprintln(b, "Generated:   ", now_header)

    // Add request headers to the response.
    if (print_headers) {
        fmt.Fprintln(b, "\nREQUEST HEADERS:")
        keys := make([]string, 0, len(r.Header))
        for k := range r.Header {
            keys = append(keys, k)
        }
        sort.Strings(keys)
        for _, key := range keys {
            fmt.Fprintf(b, "  %v: %v\n", key, r.Header[key][0])
        }
    }
    
    // Copy headers into the response.
    for key, val := range headers {
        w.Header().Set(key, val)
    }
    
    // Write out buffered content.
    content := b.AsString()
    respond(200, content) // Won't actually write out the response!
    return
}

func main() {
    if len(os.Args) != 2 {
        fmt.Fprintln(os.Stderr, "You must pass a single argument of the address to listen on.")
        fmt.Fprintln(os.Stderr, "  (e.g. \"localhost:4000\")")
        return
    }
    
    http.HandleFunc("/", handle)
    fmt.Println("Listening and serving on", os.Args[1])
    serve_err := http.ListenAndServe(os.Args[1], nil)
    if serve_err != nil {
        fmt.Fprintln(os.Stderr, "ERROR:", serve_err)
    }
}
