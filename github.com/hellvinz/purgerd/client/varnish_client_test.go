package client

import (
	"fmt"
	"net"
	"testing"
	"time"
)

func TestNewVarnishClient(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Listen failed: %v", err)
	}
	defer ln.Close()

	c, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		t.Fatalf("Dial failed: %v", err)
	}
	defer c.Close()

	//bye := func(tobedestroyed *Client){
	//    fmt.Println("bye guys")
	//}

	wait := make(chan bool, 1)
	client := NewVarnishClient(&c, wait)
	if client == nil {
		t.Fatalf("NewVarnishClient failed")
	}
}

func TestVarnishClientReceive(t *testing.T) {
	messageSent := make(chan bool, 1)
	messageReceived := make(chan []byte, 1)
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Listen failed: %v", err)
	}
	defer ln.Close()

	go func(ln net.Listener) {
		c, _ := ln.Accept()
		<-messageSent
		message := make([]byte, 12)
		_, err := c.Read(message)
		if err != nil {
			fmt.Println(err)
		} else {
			messageReceived <- message
		}
	}(ln)

	time.Sleep(1 * time.Second)
	c, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		t.Fatalf("Dial failed: %v", err)
	}
	defer c.Close()

	//bye := func(tobedestroyed *VarnishClient){
	//    fmt.Println("bye guys")
	//}

	wait := make(chan bool, 1)
	client := NewVarnishClient(&c, wait)
	if client == nil {
		t.Fatal("NewVarnishClient failed")
	}
	client.Receive([]byte("han"))
	messageSent <- true
	message := <-messageReceived
	if string(message) != "ban.url han\n" {
		t.Fatalf("VarnishClient.Receive failed expected \nban.url han\n got \n%s", message)
	}
}
