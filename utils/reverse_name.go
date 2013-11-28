package utils

import "net"

var hostCache map[string]string

func init(){
    hostCache = map[string]string{}
}

//get reverse name
func ReverseName(conn net.Conn) (name string) {
    ip, _, _ := net.SplitHostPort(conn.RemoteAddr().String())
	name = hostCache[ip]
	if name == "" {
		names, err := net.LookupAddr(ip)
		if err == nil {
			name = names[0]
		} else {
			name = ip
		}
		hostCache[ip] = name
    }
	return name
}
