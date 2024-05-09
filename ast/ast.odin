package ast

import "../token"

Node :: struct {}

Statement :: union #no_nil {
	LetStatement,
	ReturnStatement,
	ExpressionStatement,
}

// Maybe tagged union instead??
Expression :: struct {}

Program :: struct {
	statements: [dynamic]Statement,
}

LetStatement :: struct {
	token: token.Token,
	name:  Identifier,
	value: Expression,
}

ReturnStatement :: struct {}

ExpressionStatement :: struct {}

Identifier :: struct {
	token: token.Token, // the token.Ident token
	value: string,
}

statement_token_literal :: proc(statement: Statement) -> string {
	switch v in statement {
	case LetStatement:
		return "let"
	case ReturnStatement:
		return "return"
	case ExpressionStatement:
		return ""
	}

	// TODO(Thomas): Should be unreachable, how can we make sure this never happens?
	return ""
}
