package lexer

import "core:fmt"
import "core:strings"
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

read_identifier :: proc(lexer: ^Lexer) -> string {
	position := lexer.position
	for is_letter(lexer.ch) {
		read_char(lexer)
	}
	return lexer.input[position:lexer.position]
}

is_letter :: proc(ch: byte) -> bool {
	return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z'
}

read_number :: proc(lexer: ^Lexer) -> string {
	position := lexer.position
	for is_digit(lexer.ch) {
		read_char(lexer)
	}
	return lexer.input[position:lexer.position]
}

is_digit :: proc(ch: byte) -> bool {
	return '0' <= ch && ch <= '9'
}

skip_whitespace :: proc(lexer: ^Lexer) {
	for lexer.ch == ' ' ||
	    lexer.ch == '\t' ||
	    lexer.ch == '\n' ||
	    lexer.ch == '\r' {
		read_char(lexer)
	}
}

peek_char :: proc(lexer: Lexer) -> byte {
	if lexer.read_position >= len(lexer.input) {
		return 0
	} else {
		return lexer.input[lexer.read_position]
	}
}

next_token :: proc(lexer: ^Lexer) -> token.Token {
	skip_whitespace(lexer)
	char_str := curr_string(lexer^)
	tok := token.Token {
		type    = .Illegal,
		literal = char_str,
	}

	switch lexer.ch {
	case '=':
		if peek_char(lexer^) == '=' {
			tok.type = .Eq
			tok.literal = lexer.input[lexer.position:lexer.read_position + 1]
			read_char(lexer)
		} else {
			tok.type = .Assign
		}
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
	case '-':
		tok.type = .Minus
	case '!':
		if peek_char(lexer^) == '=' {
			tok.type = .NotEq
			tok.literal = lexer.input[lexer.position:lexer.read_position + 1]
			read_char(lexer)
		} else {
			tok.type = .Bang
		}
	case '*':
		tok.type = .Asterisk
	case '/':
		tok.type = .Slash
	case '<':
		tok.type = .Less
	case '>':
		tok.type = .Greater
	case '{':
		tok.type = .Lbrace
	case '}':
		tok.type = .Rbrace
	case 0:
		tok.type = .Eof
		tok.literal = ""
	case:
		if is_letter(lexer.ch) {
			tok.literal = read_identifier(lexer)
			tok.type = token.lookup_ident(tok.literal)
			return tok
		} else if is_digit(lexer.ch) {
			tok.type = .Int
			tok.literal = read_number(lexer)
			return tok
		} else {
			tok.type = .Illegal
		}
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
	input := `let five = 5;
let ten = 10;

let add = fn(x, y) {
    x + y;
};

let result = add(five, ten);

!-/*5;
5 < 10 > 5;

if (5 < 10) {
    return true;
} else {
    return false;
}

10 == 10;
10 != 9;
`

	tests := []struct {
		expected_type:    token.TokenType,
		expected_literal: string,
	} {
		{.Let, "let"},
		{.Ident, "five"},
		{.Assign, "="},
		{.Int, "5"},
		{.Semicolon, ";"},
		{.Let, "let"},
		{.Ident, "ten"},
		{.Assign, "="},
		{.Int, "10"},
		{.Semicolon, ";"},
		{.Let, "let"},
		{.Ident, "add"},
		{.Assign, "="},
		{.Function, "fn"},
		{.Lparen, "("},
		{.Ident, "x"},
		{.Comma, ","},
		{.Ident, "y"},
		{.Rparen, ")"},
		{.Lbrace, "{"},
		{.Ident, "x"},
		{.Plus, "+"},
		{.Ident, "y"},
		{.Semicolon, ";"},
		{.Rbrace, "}"},
		{.Semicolon, ";"},
		{.Let, "let"},
		{.Ident, "result"},
		{.Assign, "="},
		{.Ident, "add"},
		{.Lparen, "("},
		{.Ident, "five"},
		{.Comma, ","},
		{.Ident, "ten"},
		{.Rparen, ")"},
		{.Semicolon, ";"},
		{.Bang, "!"},
		{.Minus, "-"},
		{.Slash, "/"},
		{.Asterisk, "*"},
		{.Int, "5"},
		{.Semicolon, ";"},
		{.Int, "5"},
		{.Less, "<"},
		{.Int, "10"},
		{.Greater, ">"},
		{.Int, "5"},
		{.Semicolon, ";"},
		{.If, "if"},
		{.Lparen, "("},
		{.Int, "5"},
		{.Less, "<"},
		{.Int, "10"},
		{.Rparen, ")"},
		{.Lbrace, "{"},
		{.Return, "return"},
		{.True, "true"},
		{.Semicolon, ";"},
		{.Rbrace, "}"},
		{.Else, "else"},
		{.Lbrace, "{"},
		{.Return, "return"},
		{.False, "false"},
		{.Semicolon, ";"},
		{.Rbrace, "}"},
		{.Int, "10"},
		{.Eq, "=="},
		{.Int, "10"},
		{.Semicolon, ";"},
		{.Int, "10"},
		{.NotEq, "!="},
		{.Int, "9"},
		{.Semicolon, ";"},
		{.Eof, ""},
	}

	lexer := new(input)

	for tt, i in tests {
		tok := next_token(&lexer)
		testing.expectf(
			t,
			tok.type == tt.expected_type,
			fmt.tprintf(
				"tests[%d] - tokentype wrong. expected: %s, got: %s",
				i,
				tt.expected_type,
				tok.type,
			),
		)

		testing.expectf(
			t,
			tok.literal == tt.expected_literal,
			fmt.tprintf(
				"tests[%d] - literal wrong. expected: %s, got: %s",
				i,
				tt.expected_literal,
				tok.literal,
			),
		)
	}
}
