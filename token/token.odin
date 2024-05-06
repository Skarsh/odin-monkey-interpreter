package token

import "core:fmt"
import "core:testing"

TokenType :: enum {
	Illegal,
	Eof,

	// Identifiers + literals
	Ident,
	Int,

	// Operators
	Assign,
	Plus,

	// Delimiters
	Comma,
	Semicolon,
	Lparen,
	Rparen,
	Lbrace,
	Rbrace,

	// Keywords
	Function,
	Let,
}

Token :: struct {
	type:    TokenType,
	literal: string,
}


@(test)
test_next_token :: proc(t: ^testing.T) {
	input := `=+(){},;`

	tests := []struct {
		expected_type:    TokenType,
		expected_literal: string,
	}{{TokenType.Assign, "="}, {TokenType.Plus, "+"}}

	fmt.println("tests: ", tests)

}
