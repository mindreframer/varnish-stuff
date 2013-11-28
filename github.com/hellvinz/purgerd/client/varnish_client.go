package client

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"github.com/hellvinz/purgerd/utils"
	"net"
	"syscall"
)

type VarnishClient struct {
	messagesChannel chan []byte
	conn            *net.Conn
	workInProgess   chan bool
	//exitFunc func(*Client)
}

func NewVarnishClient(conn *net.Conn, workInProgress chan bool) *VarnishClient {
	client := new(VarnishClient)
	client.messagesChannel = make(chan []byte, 10)
	client.conn = conn
	client.workInProgess = workInProgress
	go client.monitorMessages()
	return client
}

func (c *VarnishClient) Receive(message []byte) {
	c.messagesChannel <- message
}

func (c *VarnishClient) monitorMessages() {
	defer close(c.messagesChannel)
	for {
		message := <-c.messagesChannel
		err := c.sendMessage(message)
		if err == syscall.EPIPE {
			break
		}
	}
	c.exit()
}

func (c *VarnishClient) sendMessage(message []byte) (err error) {
	if string(message) == "ping" {
		err = c.sendString(message)
	} else {
		err = c.SendPurge(message)
	}
	return
}

func (c *VarnishClient) exit() {
	c.workInProgess <- false
}

//sendPurge send a purge message to a client
//it appends a ban.url to the pattern passed
func (c *VarnishClient) SendPurge(pattern []byte) (err error) {
	err = c.sendString(append([]byte("ban.url "), pattern...))
	return
}

//sendString is sending a raw string to a client
func (c *VarnishClient) sendString(message []byte) (err error) {
	n, err := (*c.conn).Write(append(message, []byte("\n")...))
	if n == 0 {
		err = syscall.EPIPE
	}
	return
}

func (c *VarnishClient) AuthenticateIfNeeded(secret *string) (err error) {
	// check if client need auth
	message := make([]byte, 512)
	(*c.conn).Read(message)
	cli := Cliparser(message)
	if cli.Status == 107 {
		if *secret == "" {
			err = errors.New("Client varnish asked for a secret, provide one with -s")
			return
		}
		challenge := cli.Body[:32]
		response := fmt.Sprintf("%s\n%s\n%s\n", challenge, *secret, challenge)
		hasher := sha256.New()
		hasher.Write([]byte(response))
		_, err = (*c.conn).Write([]byte(fmt.Sprintf("auth %s\n", hex.EncodeToString(hasher.Sum(nil)))))
	}
	return
}

func (c *VarnishClient) String() string {
	return utils.ReverseName(*c.conn)
}
