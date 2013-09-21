package main

import (
    "net/http"
    "net/http/httputil"
    "strconv"
    "strings"
    "testing"
    "time"
)

// Should be kept in sync with validserver.go.
const granularity_in_seconds = 10
const target_server = "http://localhost:20752"
var client = http.Client{}

// As the target server is stateful (for clock documents), add a
// unique value to URLs on each test run.
var seed = strconv.FormatInt(time.Now().UTC().Unix(), 16)

func MakeReq(t *testing.T, url string) *http.Request {
    resp, err := http.NewRequest("GET", target_server + url + seed + "/", nil)
    if (err != nil) {
        t.Fatal("Error generating request.", err)
    }
    return resp
}

func DoReq(t *testing.T, req *http.Request, expected_code int) *http.Response {
    b, err := httputil.DumpRequestOut(req, true)
    if err != nil {t.Fatal("Error dumping out request.", err)}
    t.Log("    " + strings.TrimSpace(string(b)))
    
    resp, err := client.Do(req)
    if err != nil {t.Fatal("Error retrieving response.", err)}

    b, err = httputil.DumpResponse(resp, true)
    if err != nil {t.Fatal("Error dumping out response.", err)}
    t.Log("    " + strings.TrimSpace(string(b)))

    if resp.StatusCode != expected_code {
        t.Fatal("Expected status code", expected_code, "response code, but got", resp.StatusCode)
    }
    return resp
}

func GetBody(t *testing.T, resp *http.Response) string {
    buffer := make([]byte, 16384) // 16K should be enough for anyone!
    size, err := resp.Body.Read(buffer)
    defer resp.Body.Close()
    if err != nil {
        t.Fatal("Error extracting body.", err)
    }
    return strings.TrimSpace(string(buffer[0:size]))
}

func CompareBodies(t *testing.T, body1 string, body2 string, same bool, identical bool) {
    line1 := strings.Split(body1, "\n")[0]
    line2 := strings.Split(body2, "\n")[0]
    if same && (line1 != line2) {
        t.Fatal("First lines of requests are different, expected to be same.")    
    } else if !same && (line1 == line2) {
        t.Fatal("First line of request bodies are identical, expected differences.")
    }
    if identical && (body1 != body2) {
        t.Fatal("Request bodies are not the same, expected to be identical.")
    } else if !identical && (body1 == body2) {
        t.Fatal("Request bodies are identical, expected differences.")
    }
}

// Creates validation requests based on the response.
type Validator interface {
    Build(t *testing.T, r *http.Response) (*http.Request, *http.Request)
}

// Does something to make the document update.
type Updater interface {
    Update(t *testing.T, r *http.Request)
}

type ETagV struct {}
func (*ETagV) Build(t *testing.T, r *http.Response) (*http.Request, *http.Request) {
    modded := MakeReq(t, r.Request.URL.Path)
    same := MakeReq(t, r.Request.URL.Path)
    modded.Header.Add("If-None-Match", r.Header.Get("ETag"))
    same.Header.Add("If-Match", r.Header.Get("ETag"))
    return modded, same
}

type DateModV struct {}
func (*DateModV) Build(t *testing.T, r *http.Response) (*http.Request, *http.Request) {
    modded := MakeReq(t, r.Request.URL.Path)
    same := MakeReq(t, r.Request.URL.Path)
    modded.Header.Add("If-Modified-Since", r.Header.Get("Last-Modified"))
    same.Header.Add("If-Unmodified-Since", r.Header.Get("Last-Modified"))
    return modded, same
}

// Clock documents - we wait a second to ensure they will end up with
// different validators, and then do a PUT request to cause an update.
type ClockU struct {}
func (*ClockU) Update(t *testing.T, req *http.Request) {
    time.Sleep(time.Second)
    r := MakeReq(t, req.URL.Path)
    r.Method = "PUT"
    DoReq(t, r, 204)
}

// Periodic documents - we just wait until the document is "refreshed".
type PeriodicU struct {}
func (*PeriodicU) Update(t *testing.T, req *http.Request) {
    time.Sleep(time.Second * granularity_in_seconds)
}

// Common bit of code to test validators for updateable documents.
func DoValidationTest(t *testing.T, path string, v Validator, u Updater) {
    t.Parallel()
    
    t.Log("Getting original request.")
    req := MakeReq(t, path)
    resp := DoReq(t, req, 200)
    body := GetBody(t, resp)
    
    // Add the validator, and do the test again. It shouldn't have
    // changed.
    modded, same := v.Build(t, resp)
    t.Log("Checking original document hasn't been modified.")
    sresp := DoReq(t, same, 200)
    DoReq(t, modded, 304)
    sbody := GetBody(t, sresp)
    CompareBodies(t, body, sbody, true, true)
    
    // Update the document.
    if (u == nil) {return;}
    t.Log("Updating document.")
    u.Update(t, req)
    
    // Now if we try again, the responses should indicate modification.
    t.Log("Checking document is different.")
    mresp := DoReq(t, modded, 200)
    DoReq(t, same, 412)
    mbody := GetBody(t, mresp)
    CompareBodies(t, body, mbody, false, false)
}

/**
 * Tests.
 */

// Basic test of some functionality - handle missing documents and headers.
func TestBasicMissingDoc(t *testing.T) {
    t.Parallel()
    req := MakeReq(t, "/gosomewhere/notexpected/")
    DoReq(t, req, 410)
}

func TestGetHeaders(t *testing.T) {
    t.Parallel()
    req := MakeReq(t, "/static/headers/")
    resp := DoReq(t, req, 200)
    
    header := "User-Agent: Go http package"
    if !strings.Contains(GetBody(t, resp), header) {
        t.Fatal("Did not find expected User-Agent header.")
    }
}

// Test that we can get a simple static response.
func TestStaticDoc(t *testing.T) {
    t.Parallel()
    req := MakeReq(t, "/static/ourtestdoc/")
    resp1 := DoReq(t, req, 200)
    content1 := GetBody(t, resp1)
    
    // Get the document again - it should be identical.
    time.Sleep(time.Second)
    resp2 := DoReq(t, req, 200)
    content2 := GetBody(t, resp2)
    
    // First line should be the same - the date is static.
    // The generation line should differ though.
    CompareBodies(t, content1, content2, true, false)
}

/**
 * Test different document types and different validators.
 */
func TestStaticEtags(t *testing.T) {
    DoValidationTest(t, "/static/etag/functest/", &ETagV{}, nil)
}

func TestStaticModded(t *testing.T) {
    DoValidationTest(t, "/static/lastmod/functest/", &DateModV{}, nil)
}

func TestPeriodicEtags(t *testing.T) {
    DoValidationTest(t, "/periodic/etag/functest/", &ETagV{}, &PeriodicU{})
}

func TestPeriodicModded(t *testing.T) {
    DoValidationTest(t, "/periodic/lastmod/functest/", &DateModV{}, &PeriodicU{})
}

func TestClockEtags(t *testing.T) {
    DoValidationTest(t, "/clock/etag/functest/", &ETagV{}, &ClockU{})
}

func TestClockModded(t *testing.T) {
    DoValidationTest(t, "/clock/lastmod/functest/", &DateModV{}, &ClockU{})
}
