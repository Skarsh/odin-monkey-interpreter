package parser

import "core:fmt"
import "core:strings"
import "core:testing"

import "../ast"
import "../lexer"
import "../token"

Precedence :: enum {
	Lowest = 1,
	Equals, // == 
	LessGreater, // > or <
	Sum, // +
	Product, // *
	Prefix, // -X or !X
	Call, // myFunction(X)
}

prefix_parse_fn :: proc(parser: ^Parser) -> ast.Expression
infix_parse_fn :: proc(
	parser: ^Parser,
	expression: ast.Expression,
) -> ast.Expression

Parser :: struct {
	lexer:            lexer.Lexer,
	cur_token:        token.Token,
	peek_token:       token.Token,
	errors:           [dynamic]string,
	prefix_parse_fns: map[token.TokenType]prefix_parse_fn,
	infix_parse_fns:  map[token.TokenType]infix_parse_fn,
}

new :: proc(lexer: lexer.Lexer) -> Parser {
	parser := Parser {
		lexer = lexer,
	}

	parser.prefix_parse_fns = make(map[token.TokenType]prefix_parse_fn)
	register_prefix(&parser, token.TokenType.Ident, parse_identifier)

	// Read two tokens, so cur_token and peek_token are both set
	next_token(&parser)

	return parser
}

destroy_parser :: proc(parser: ^Parser) {
	delete(parser.errors)
	delete(parser.prefix_parse_fns)
}

register_prefix :: proc(
	parser: ^Parser,
	token_type: token.TokenType,
	fn: prefix_parse_fn,
) {
	parser.prefix_parse_fns[token_type] = fn
}

register_infix :: proc(
	parser: ^Parser,
	token_type: token.TokenType,
	fn: infix_parse_fn,
) {
	parser.infix_parse_fns[token_type] = fn
}

errors :: proc(parser: Parser) -> []string {
	return parser.errors[:]
}

peek_error :: proc(parser: ^Parser, token_type: token.TokenType) {
	buffer := [1024]byte{}
	msg := fmt.bprintf(
		buffer[:],
		"exptected next token to be %v, got %v instead",
		token_type,
		parser.peek_token.type,
	)
	// TODO(Thomas): Think about allocations here. Do we need to clone?
	append(&parser.errors, strings.clone(msg))
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
	case .Return:
		return parse_return_statement(parser)
	case:
		return parse_expression_statement(parser)
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

parse_return_statement :: proc(
	parser: ^Parser,
) -> (
	ast.ReturnStatement,
	bool,
) {
	statement := ast.ReturnStatement {
		token = parser.cur_token,
	}

	next_token(parser)

	// TODO: We're skipping the expressions until we 
	// encounter a semicolon
	for !cur_token_is(parser^, .Semicolon) {
		next_token(parser)
	}

	return statement, true
}

parse_expression_statement :: proc(
	parser: ^Parser,
) -> (
	ast.ExpressionStatement,
	bool,
) {
	stmt := ast.ExpressionStatement {
		token = parser.cur_token,
	}
	stmt.expression = parse_expression(parser, .Lowest)
	if stmt.expression == nil {
		return stmt, false
	}
	if peek_token_is(parser^, token.TokenType.Semicolon) {
		next_token(parser)
	}
	return stmt, true
}

parse_expression :: proc(
	parser: ^Parser,
	precedence: Precedence,
) -> ast.Expression {
	prefix := parser.prefix_parse_fns[parser.cur_token.type]
	if prefix == nil {
		return nil
	}
	left_exp := prefix(parser)
	return left_exp
}

parse_identifier :: proc(parser: ^Parser) -> ast.Expression {
	return ast.Identifier {
		token = parser.cur_token,
		value = parser.cur_token.literal,
	}
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
		peek_error(parser, token_type)
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
	defer destroy_parser(&parser)

	program := parse_program(&parser)
	defer ast.destroy_program(&program)
	check_parser_errors(t, parser)

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

	statement_token_literal := ast.statement_token_literal(statement)
	if statement_token_literal != "let" {
		testing.expectf(
			t,
			false,
			fmt.tprintf(
				"statement.token_literal not 'let'. got %s",
				statement_token_literal,
			),
		)
		return false
	}

	let_statement, ok := statement.(ast.LetStatement)
	if !ok {
		testing.expectf(
			t,
			false,
			fmt.tprintf("statement not ast.LetStatement, got %t", statement),
		)
		return false
	}

	if let_statement.name.value != name {
		testing.expectf(
			t,
			false,
			fmt.tprintf(
				"let_statement.name.value not '%s'. got %s",
				name,
				let_statement.name.value,
			),
		)
		return false
	}

	if let_statement.name.token.literal != name {
		testing.expectf(
			t,
			false,
			fmt.tprintf(
				"let_statement.name.token.literal not '%s'. got '%s'",
				name,
				let_statement.token.literal,
			),
		)
		return false
	}


	return true
}

check_parser_errors :: proc(t: ^testing.T, parser: Parser) {
	errors := errors(parser)
	if len(errors) == 0 {
		return
	}

	fmt.printfln("parser has %d errors", len(errors))
	for error_msg in errors {
		fmt.printfln("parser error: %s", error_msg)
	}
	testing.fail_now(t)
}

@(test)
test_return_statements :: proc(t: ^testing.T) {
	input := `
return 5;
return 10;
return 993322;
`
	lexer := lexer.new(input)
	parser := new(lexer)
	defer destroy_parser(&parser)

	program := parse_program(&parser)
	defer ast.destroy_program(&program)

	check_parser_errors(t, parser)

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

	for statement in program.statements {
		return_statement, ok := statement.(ast.ReturnStatement)
		if !ok {
			testing.expectf(
				t,
				false,
				fmt.tprintf(
					"statement not ast.ReturnStatement. got = %v",
					statement,
				),
			)
			continue
		}

		if return_statement.token.literal != "return" {
			testing.expectf(
				t,
				false,
				fmt.tprintf(
					"return_statement.token.literal not 'return', got %s",
					return_statement.token.literal,
				),
			)
		}
	}

}

@(test)
test_identifier_expression :: proc(t: ^testing.T) {
	input := "foobar;"

	l := lexer.new(input)
	p := new(l)
	defer destroy_parser(&p)
	program := parse_program(&p)
	defer ast.destroy_program(&program)
	check_parser_errors(t, p)

	if len(program.statements) != 1 {
		testing.fail_now(
			t,
			fmt.tprintf(
				"program has not enough statements. got: %v",
				len(program.statements),
			),
		)
	}

	stmt, stmt_ok := program.statements[0].(ast.ExpressionStatement)
	if !stmt_ok {
		testing.fail_now(
			t,
			fmt.tprintf(
				"exp not ast.ExpressionStatment. got: %t",
				program.statements[0],
			),
		)
	}

	ident, expr_ok := stmt.expression.(ast.Identifier)
	if !expr_ok {
		testing.fail_now(
			t,
			fmt.tprintf("exp not ast.Identifier. got: %t", stmt.expression),
		)
	}

	if ident.value != "foobar" {
		testing.fail_now(
			t,
			fmt.tprintf("ident.value not %s. got: %s", "foobar", ident.value),
		)
	}

	if ident.token.literal != "foobar" {
		testing.fail_now(
			t,
			fmt.tprintf(
				"ident.token.literal not %s. got: %s",
				"foobar",
				ident.token.literal,
			),
		)
	}
}
