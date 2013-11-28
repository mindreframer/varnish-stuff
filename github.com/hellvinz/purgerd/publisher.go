package main

import "sync/atomic"
import "sync"

type Publisher struct {
	subscribers            []Subscriber
	toberemovedsubscribers chan Subscriber
	tobeaddedsubscribers   chan Subscriber
	messages               chan []byte
	Publishes              int64
	m                      sync.Mutex
}

func NewPublisher() *Publisher {
	publisher := Publisher{}
	publisher.toberemovedsubscribers = make(chan Subscriber, 1)
	publisher.tobeaddedsubscribers = make(chan Subscriber, 10)
	publisher.messages = make(chan []byte, 50)
	publisher.Publishes = 0
	go publisher.monitorsubscriptions()
	go publisher.monitormessages()
	return &publisher
}

func (p *Publisher) Sub(c Subscriber) {
	p.tobeaddedsubscribers <- c
}

func (p *Publisher) Unsub(c Subscriber) {
	p.toberemovedsubscribers <- c
}

func (p *Publisher) Pub(message []byte) {
	p.messages <- message
}

func (p *Publisher) monitorsubscriptions() {
	var c Subscriber

	for {
		select {
		case c = <-p.toberemovedsubscribers:
			var i = 0
			var v Subscriber
			p.m.Lock()
			for i, v = range p.subscribers {
				if v == c {
					break
				}
			}
			p.subscribers = append(p.subscribers[:i], p.subscribers[i+1:]...)
			p.m.Unlock()
		case c = <-p.tobeaddedsubscribers:
			p.m.Lock()
			p.subscribers = append(p.subscribers, c)
			p.m.Unlock()
		}
	}
}

func (p *Publisher) monitormessages() {
	for {
		message := <-p.messages
		atomic.AddInt64(&p.Publishes, 1)
		p.m.Lock()
		for _, c := range p.subscribers {
			c.Receive(message)
		}
		p.m.Unlock()
	}
}

func (p *Publisher) dowithsubscribers(callback func(subscriber Subscriber)) {
	p.m.Lock()
	defer p.m.Unlock()
	for _, s := range p.subscribers {
		callback(s)
	}
}
