package lexer

import "core:fmt"
import "core:testing"

import "../token"

Lexer :: struct {
	input:         string,
	position:      int,
	read_position: int,
	ch:            byte,
}

new :: proc(input: string) -> Lexer {
	lexer := Lexer {
		input = input,
	}
	read_char(&lexer)
	return lexer
}

read_char :: proc(lexer: ^Lexer) {
	if lexer.read_position >= len(lexer.input) {
		lexer.ch = 0
	} else {
		lexer.ch = lexer.input[lexer.read_position]
	}
	lexer.position = lexer.read_position
	lexer.read_position += 1
}

next_token :: proc(lexer: ^Lexer) -> token.Token {
	char_str := curr_string(lexer^)
	tok := token.Token {
		type    = .Illegal,
		literal = char_str,
	}

	switch lexer.ch {
	case '=':
		tok.type = .Assign
	case ';':
		tok.type = .Semicolon
	case '(':
		tok.type = .Lparen
	case ')':
		tok.type = .Rparen
	case ',':
		tok.type = .Comma
	case '+':
		tok.type = .Plus
	case '{':
		tok.type = .Lbrace
	case '}':
		tok.type = .Rbrace
	case 0:
		tok.type = .Eof
		tok.literal = ""
	case:
	}

	read_char(lexer)
	return tok
}

curr_string :: proc(lexer: Lexer) -> string {
	if lexer.position >= len(lexer.input) {
		return "0"
	} else {
		return lexer.input[lexer.position:lexer.read_position]
	}
}


@(test)
test_next_token :: proc(t: ^testing.T) {
	input := `=+(){},;`

	tests := []struct {
		expected_type:    token.TokenType,
		expected_literal: string,
	} {
		{token.TokenType.Assign, "="},
		{token.TokenType.Plus, "+"},
		{token.TokenType.Lparen, "("},
		{token.TokenType.Rparen, ")"},
		{token.TokenType.Lbrace, "{"},
		{token.TokenType.Rbrace, "}"},
		{token.TokenType.Comma, ","},
		{token.TokenType.Semicolon, ";"},
		{token.TokenType.Eof, ""},
	}

	lexer := new(input)

	for tt, i in tests {
		tok := next_token(&lexer)
		buffer := [1024]byte{}
		if tok.type != tt.expected_type {
			testing.fail_now(
				t,
				fmt.bprintf(
					buffer[:],
					"test[%d] - tokentype wrong. expected = %s, got = %s",
					i,
					tt.expected_type,
					tok.type,
				),
			)
		}
	}


}
