package token


TokenType :: enum {
	Illegal,
	Eof,

	// Identifiers + literals
	Ident,
	Int,

	// Operators
	Assign,
	Plus,
	Minus,
	Bang,
	Asterisk,
	Slash,
	Less,
	Greater,
	Eq,
	NotEq,

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
	True,
	False,
	If,
	Else,
	Return,
}

Token :: struct {
	type:    TokenType,
	literal: string,
}

keywords := map[string]TokenType {
	"fn"     = .Function,
	"let"    = .Let,
	"true"   = .True,
	"false"  = .False,
	"if"     = .If,
	"else"   = .Else,
	"return" = .Return,
}

lookup_ident :: proc(ident: string) -> TokenType {
	tok, ok := keywords[ident]
	if ok {
		return tok
	}
	return .Ident
}
