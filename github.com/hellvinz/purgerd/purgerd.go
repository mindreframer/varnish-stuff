package main

import (
	"flag"
	"fmt"
	zmq "github.com/alecthomas/gozmq"
	"io/ioutil"
	"log/syslog"
	"net"
	"os"
	"syscall"
	"time"
)

var context *zmq.Context
var logger *syslog.Writer

func main() {
	// parse command line options
	incomingAddress := flag.String("i", "0.0.0.0:8111", "0MQ REP socket address where purge message are sent, '0.0.0.0:8111'")
	outgoingAddress := flag.String("o", "0.0.0.0:1118", "listening socket where purge message are sent to varnish reverse cli, 0.0.0.0:1118")
	version := flag.Bool("v", false, "display version")
	purgeOnStartUp := flag.Bool("p", false, "purge all the varnish cache on connection")
	flag.Parse()
	if *version {
		printVersion()
		os.Exit(0)
	}

	// log to syslog
	logger, _ = syslog.New(syslog.LOG_INFO, "")

	// setup zmq
	context, _ = zmq.NewContext()
	defer context.Close()

	// the zmq REP socket where to send purge requests
	go setupPurgeReceiver(incomingAddress)

	// we're ready to listen varnish cli connection
	setupPurgeSenderAndListen(outgoingAddress, *purgeOnStartUp)
}

//setupPurgeSenderAndListen start listening to the socket where varnish cli connects
//when a client connects it is calling the handleConnection handler
func setupPurgeSenderAndListen(outgoingAddress *string, purgeOnStartup bool) {
	ln, err := net.Listen("tcp", *outgoingAddress)
	checkError(err)
	for {
		conn, err := ln.Accept()
		if err != nil {
			// handle error
			continue
		}
		logger.Info(fmt.Sprintln("New client: ", conn.RemoteAddr()))
		if purgeOnStartup {
			// flush the whole cache of the new client
			sendPurge(conn, ".*")
		}
		// connect client to the pubsub purge
		go connectClientToPusher(conn)
	}
	return
}

//setupPurgeReceiver set up the tcp socket where ban messages come
//when a purge pattern is received it dispatches it to a PUB socket
func setupPurgeReceiver(incomingAddress *string) {
	receiver, err := net.Listen("tcp", *incomingAddress)
	checkError(err)

	pusher, _ := context.NewSocket(zmq.PUB)
	defer pusher.Close()
	pusher.Bind("inproc://pusher")
	go func() {
		for {
			time.Sleep(5 * time.Second)
			pusher.Send([]byte("ping"), 0)
		}
	}()
	for {
		conn, err := receiver.Accept()
		checkError(err)
		go func(c net.Conn) {
			b, err := ioutil.ReadAll(conn)
			if err != nil {
				conn.Close()
			}
			logger.Info(fmt.Sprintln("i've received to purge from client:", string(b)))
			pusher.Send(b, 0)
		}(conn)
	}
	return
}

//connectClientToPusher is used to forward message received from the internal PUB socket to the client
func connectClientToPusher(conn net.Conn) {
	puller, _ := context.NewSocket(zmq.SUB)
	puller.SetSockOptString(zmq.SUBSCRIBE, "")
	defer puller.Close()
	defer conn.Close()
	puller.Connect("inproc://pusher")
	for {
		b, _ := puller.Recv(0)
		var err error
		if string(b) == "ping" {
			err = sendString(conn, string(b))
		} else {
			err = sendPurge(conn, string(b))
		}
		if err == syscall.EPIPE {
			logger.Info(fmt.Sprintln("client gone", conn.RemoteAddr()))
			break
		} else {
			logger.Debug(fmt.Sprintln("Client got", conn.RemoteAddr(), string(b)))
		}
	}
}

//sendPurge send a purge message to a client
//it appends a ban.url to the pattern passed
func sendPurge(conn net.Conn, pattern string) (err error) {
	err = sendString(conn, "ban.url "+pattern)
	return
}

//sendString is sending a raw string to a client
func sendString(conn net.Conn, message string) (err error) {
	n, err := conn.Write([]byte(message + "\n"))
	if n == 0 {
		logger.Debug(fmt.Sprintln("failed to send message", conn.RemoteAddr()))
		err = syscall.EPIPE
	}
	return
}

//checkError basic error handling
func checkError(err error) {
	if err != nil {
		logger.Crit(fmt.Sprintln("Fatal error", err.Error()))
		os.Exit(1)
	}
}

//version
func printVersion() {
	fmt.Println("0.0.1")
}
