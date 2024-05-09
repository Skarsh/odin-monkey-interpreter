package parser

import "core:fmt"
import "core:testing"

import "../ast"
import "../lexer"
import "../token"

Parser :: struct {
	lexer:      lexer.Lexer,
	cur_token:  token.Token,
	peek_token: token.Token,
}

new :: proc(lexer: lexer.Lexer) -> Parser {
	parser := Parser {
		lexer = lexer,
	}

	// Read two tokens, so cur_token and peek_token are both set
	next_token(&parser)

	return parser
}


next_token :: proc(parser: ^Parser) {
	parser.cur_token = parser.peek_token
	parser.peek_token = lexer.next_token(&parser.lexer)
}

parse_program :: proc(parser: ^Parser) -> ast.Program {
	program := ast.Program{}

	for parser.cur_token.type != .Eof {
		statement, ok := parse_statement(parser)
		if ok {
			append(&program.statements, statement)
		}
		next_token(parser)
	}

	return program
}

parse_statement :: proc(parser: ^Parser) -> (ast.Statement, bool) {
	#partial switch parser.cur_token.type {
	case .Let:
		return parse_let_statement(parser)
	case:
		return ast.Statement{}, false
	}
}

parse_let_statement :: proc(parser: ^Parser) -> (ast.LetStatement, bool) {
	statement := ast.LetStatement {
		token = parser.cur_token,
	}

	if !expect_peek(parser, .Ident) {
		return ast.LetStatement{}, false
	}

	statement.name = ast.Identifier {
		token = parser.cur_token,
		value = parser.cur_token.literal,
	}

	if !expect_peek(parser, .Assign) {
		return ast.LetStatement{}, false
	}

	// TODO: We're skipping the expressions until we 
	// encounter a semicolon
	for !cur_token_is(parser^, .Semicolon) {
		next_token(parser)
	}

	return statement, true
}

cur_token_is :: proc(parser: Parser, token_type: token.TokenType) -> bool {
	return parser.cur_token.type == token_type
}

peek_token_is :: proc(parser: Parser, token_type: token.TokenType) -> bool {
	return parser.peek_token.type == token_type
}

expect_peek :: proc(parser: ^Parser, token_type: token.TokenType) -> bool {
	if peek_token_is(parser^, token_type) {
		next_token(parser)
		return true
	} else {
		return false
	}
}

@(test)
test_let_statements :: proc(t: ^testing.T) {
	input := `
let x = 5;
let y = 10;
let foobar = 838383;
`
	lex := lexer.new(input)
	parser := new(lex)

	program := parse_program(&parser)

	// TODO(Thomas): Go example from the book, what should we do here?
	//if program == nil {
	//    t.Fatalf("ParseProgram() returned nil")
	//}

	buffer := [1024]byte{}

	if len(program.statements) != 3 {
		testing.fail_now(
			t,
			fmt.bprintf(
				buffer[:],
				"program.statements does not contain 3 statements. got = %d",
				len(program.statements),
			),
		)
	}

	tests := []struct {
		expected_identifier: string,
	}{{"x"}, {"y"}, {"foobar"}}

	for tt, i in tests {
		statement := program.statements[i]
		if !test_let_statement(t, statement, tt.expected_identifier) {
			return
		}
	}
}

test_let_statement :: proc(
	t: ^testing.T,
	statement: ast.Statement,
	name: string,
) -> bool {

	buffer := [1024]byte{}

	statement_token_literal := ast.statement_token_literal(statement)
	if statement_token_literal != "let" {
		testing.fail_now(
			t,
			fmt.bprintf(
				buffer[:],
				"statement.token_literal not 'let. got = %s",
				statement_token_literal,
			),
		)
		return false
	}

	let_statement, ok := statement.(ast.LetStatement)
	if !ok {
		testing.fail_now(
			t,
			fmt.bprintf(
				buffer[:],
				"statement not ast.LetStatement, got %t",
				statement,
			),
		)
		return false
	}

	if let_statement.name.value != name {
		testing.fail_now(
			t,
			fmt.bprintf(
				buffer[:],
				"let_statment.name.value not '%s'. got = %s",
				name,
				let_statement.name.value,
			),
		)
		return false
	}

	if let_statement.name.token.literal != name {
		testing.fail_now(
			t,
			fmt.bprintf(
				buffer[:],
				"let_statement.name.token.literal not '%s'. got = '%s'",
				name,
				let_statement.name.token.literal,
			),
		)
		return false
	}


	return true
}