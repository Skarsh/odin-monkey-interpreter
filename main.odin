package main

import "core:fmt"
import "core:os"

import "repl"

main :: proc() {
	fmt.println("Hello! This is the Monkey programming language!")
	fmt.println("Feel free to type in commands")
	repl.start()
}
