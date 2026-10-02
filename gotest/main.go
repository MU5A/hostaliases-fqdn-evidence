package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	for _, n := range os.Args[1:] {
		a, err := net.LookupHost(n)
		if err != nil {
			a = []string{"MISS"}
		}
		fmt.Printf("    query %-22q go-pure=%v\n", n, a)
	}
}
