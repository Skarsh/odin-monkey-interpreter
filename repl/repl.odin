package repl

import "core:fmt"
import "core:os"

import "../lexer"
import "../token"

PROMPT := ">> "

start :: proc() {
	buf: [1024]byte

	// TODO(Thomas): Support multi-line input
	for {
		n, err := os.read(os.stdin, buf[:])
		if err < 0 {
			if err == os.ERROR_HANDLE_EOF {
				return
			}
			fmt.eprintfln("Error reading input %v", err)
		}

		lex := lexer.new(string(buf[:n]))

		for tok := lexer.next_token(&lex);
		    tok.type != token.TokenType.Eof;
		    tok = lexer.next_token(&lex) {

			fmt.printfln("%v", tok)
		}

	}
}
