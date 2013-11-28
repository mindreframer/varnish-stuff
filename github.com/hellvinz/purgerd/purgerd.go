package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"github.com/hellvinz/purgerd/client"
	"github.com/hellvinz/purgerd/utils"
	"io/ioutil"
	"log/syslog"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"
)

var logger *syslog.Writer

func init() {
	// log to syslog
	logger, _ = syslog.New(syslog.LOG_INFO, "")
}

func main() {
	// parse command line options
	incomingAddress := flag.String("i", "0.0.0.0:8111", "socket where purge messages are sent, '0.0.0.0:8111'")
	outgoingAddress := flag.String("o", "0.0.0.0:1118", "listening socket where purge message are sent to varnish reverse cli, 0.0.0.0:1118")
	version := flag.Bool("v", false, "display version")
	purgeOnStartUp := flag.Bool("p", false, "purge all the varnish cache on connection")
	secretFile := flag.String("s", "", "path of the file containing the varnish secret")
	flag.Parse()
	if *version {
		printVersion()
		os.Exit(0)
	}

	var secret string
	if *secretFile != "" {
		var err error
		secret, err = readSecretFile(*secretFile)
		if err != nil {
			logger.Crit(fmt.Sprintln(err))
			os.Exit(1)
		}
	}

	publisher := NewPublisher()

	go monitorSignals(publisher)

	go setupPurgeReceiver(incomingAddress, publisher)

	// we're ready to listen varnish cli connection
	setupPurgeSenderAndListen(outgoingAddress, *purgeOnStartUp, publisher, &secret)
}

//setupPurgeSenderAndListen start listening to the socket where varnish cli connects
//when a client connects it calls handleClient
func setupPurgeSenderAndListen(outgoingAddress *string, purgeOnStartup bool, publisher *Publisher, secret *string) {
	ln, err := net.Listen("tcp", *outgoingAddress)
	utils.CheckError(err, logger)
	for {
		conn, err := ln.Accept()
		if err != nil {
			// handle error
			continue
		}
		logger.Info(fmt.Sprintln("New client:", utils.ReverseName(conn)))

		// connect client to the pubsub purge
		go handleVarnishClient(conn, publisher, purgeOnStartup, secret)
	}
	return
}

//setupPurgeReceiver set up the tcp socket where ban messages come
//when a purge pattern is received it dispatches it to a Pub object
func setupPurgeReceiver(incomingAddress *string, publisher *Publisher) {
	receiver, err := net.Listen("tcp", *incomingAddress)
	utils.CheckError(err, logger)

	go func() {
		ping := []byte("ping")
		for {
			time.Sleep(5 * time.Second)
			publisher.Pub(ping)
		}
	}()
	for {
		conn, err := receiver.Accept()
		utils.CheckError(err, logger)
		go func(c net.Conn) {
			defer conn.Close()
			b, err := ioutil.ReadAll(conn)
			if err != nil {
				logger.Info(fmt.Sprintln("Client connection error:", err))
			} else {
				clean_purge := bytes.TrimSpace(b)
				logger.Info(fmt.Sprintln("<-", utils.ReverseName(conn), string(clean_purge)))
				publisher.Pub(clean_purge)
				conn.Write([]byte("OK\n"))
			}
		}(conn)
	}
	return
}

//handleVarnishClient is used to forward message received to the client
func handleVarnishClient(conn net.Conn, publisher *Publisher, purgeOnStartup bool, secret *string) {
	defer conn.Close()

	wait := make(chan bool)
	client := client.NewVarnishClient(&conn, wait)

	err := client.AuthenticateIfNeeded(secret)
	if err != nil {
		logger.Crit(fmt.Sprintln("Varnish authentication failed:", err))
		return
	}

	if purgeOnStartup {
		// flush the whole cache of the new client
		client.SendPurge([]byte(".*"))
	}

	// wait for purges
	publisher.Sub(client)
	<-wait

	// client has quit, clean up
	publisher.Unsub(client)
	logger.Info(fmt.Sprintln(utils.ReverseName(conn), "gone"))
}

//monitorSignals trap SIGUSR1 to print stats
func monitorSignals(p *Publisher) {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGUSR1)
	for {
		<-c
		clients := make([]string, 0)
		callback := func(client Subscriber) {
			clients = append(clients, client.String())
		}
		p.dowithsubscribers(callback)
		logger.Info(fmt.Sprintln("Purges sent:", p.Publishes, ". Connected Clients", clients))
	}
}

func readSecretFile(secretFile string) (secret string, err error) {
	file, err := os.Open(secretFile)
	if err != nil {
		return "", err
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		secret = scanner.Text()
	}
	return
}

//version
func printVersion() {
	fmt.Println("0.0.2")
}
