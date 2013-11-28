package main

type Subscriber interface {
	Receive([]byte)
	String() string
}
