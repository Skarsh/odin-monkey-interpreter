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

keywords := map[string]TokenType {
	"fn"  = .Function,
	"let" = .Let,
}

lookup_ident :: proc(ident: string) -> TokenType {
	tok, ok := keywords[ident]
	if ok {
		return tok
	}
	return .Ident
}
