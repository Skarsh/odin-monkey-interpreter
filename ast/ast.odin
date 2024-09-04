package ast

import "core:fmt"
import "core:strings"
import "core:testing"

import "../token"

Node :: union #no_nil {
	Statement,
	Expression,
}

Statement :: union #no_nil {
	LetStatement,
	ReturnStatement,
	ExpressionStatement,
}

Expression :: union {
	Identifier,
	IntegerLiteral,
	PrefixExpression,
	InfixExpression,
}

Program :: struct {
	statements: [dynamic]Statement,
}

destroy_program :: proc(program: ^Program) {
	delete(program.statements)
}

program_string :: proc(program: Program) -> string {
	builder := strings.builder_make(context.temp_allocator)
	for stmt in program.statements {
		strings.write_string(&builder, statement_string(stmt))
	}
	return strings.to_string(builder)
}

LetStatement :: struct {
	token: token.Token,
	name:  Identifier,
	value: Expression,
}

ReturnStatement :: struct {
	token:        token.Token,
	return_value: Expression,
}

ExpressionStatement :: struct {
	token:      token.Token,
	expression: Expression,
}

Identifier :: struct {
	token: token.Token, // the token.Ident token
	value: string,
}

PrefixExpression :: struct {}

InfixExpression :: struct {}

IntegerLiteral :: struct {
	token: token.Token,
	value: i64,
}

statement_token_literal :: proc(statement: Statement) -> string {
	switch stmt in statement {
	case LetStatement:
		return stmt.token.literal
	case ReturnStatement:
		return stmt.token.literal
	case ExpressionStatement:
		return stmt.token.literal
	case:
		unreachable()
	}
}

statement_string :: proc(statement: Statement) -> string {
	builder := strings.builder_make(context.temp_allocator)
	switch stmt in statement {
	case LetStatement:
		strings.write_string(&builder, fmt.tprintf("%s ", stmt.token.literal))
		strings.write_string(&builder, fmt.tprintf("%s", stmt.name.value))
		strings.write_string(&builder, " = ")
		if stmt.value != nil {
			strings.write_string(
				&builder,
				fmt.tprintf("%s", expression_string(stmt.value)),
			)
		}
		strings.write_string(&builder, ";")
		return strings.to_string(builder)
	case ReturnStatement:
		strings.write_string(&builder, fmt.tprintf("%s ", stmt.token.literal))
		if stmt.return_value != nil {
			strings.write_string(
				&builder,
				fmt.tprintf("%s ", expression_string(stmt.return_value)),
			)
		}
		strings.write_string(&builder, ";")
		return strings.to_string(builder)
	case ExpressionStatement:
		if stmt.expression != nil {
			strings.write_string(&builder, expression_string(stmt.expression))
			return strings.to_string(builder)
		}
		return strings.to_string(builder)
	case:
		unreachable()
	}
}

expression_string :: proc(expression: Expression) -> string {
	switch expr in expression {
	case Identifier:
		return identifier_string(expr)
	case IntegerLiteral:
		return integer_literal_string(expr)
	case PrefixExpression:
		return ""
	case InfixExpression:
		return ""
	case:
		unreachable()
	}
}

identifier_string :: proc(identifier: Identifier) -> string {
	return identifier.value
}

integer_literal_string :: proc(integer_literal: IntegerLiteral) -> string {
	return fmt.tprintf("%d", integer_literal.value)
}

@(test)
test_string :: proc(t: ^testing.T) {

	program := Program{}
	defer destroy_program(&program)
	append(
		&program.statements,
		LetStatement {
			token = token.Token{type = token.TokenType.Let, literal = "let"},
			name = Identifier {
				token = token.Token {
					type = token.TokenType.Ident,
					literal = "myVar",
				},
				value = "myVar",
			},
			value = Identifier {
				token = token.Token {
					type = token.TokenType.Ident,
					literal = "anotherVar",
				},
				value = "anotherVar",
			},
		},
	)

	expected_string := "let myVar = anotherVar;"
	actual_string := program_string(program)
	testing.expectf(
		t,
		strings.compare(actual_string, expected_string) == 0,
		fmt.tprintf("program_string() wrong. got: %s", actual_string),
	)
}
