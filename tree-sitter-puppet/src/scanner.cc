#include <cwctype>
#include <iostream>
#include <string>
#include <tree_sitter/parser.h>

namespace {

using std::string;

enum TokenType {
  HEREDOC_HEADER,
  HEREDOC_TRIM_BORDER,
  HEREDOC_END,
  HEREDOC_END_TRIM,
};

struct Scanner {
  void skip(TSLexer *lexer) { lexer->advance(lexer, true); }

  void advance(TSLexer *lexer) { lexer->advance(lexer, false); }

  unsigned serialize(char *buffer) {
    if (heredoc_delimiter.length() + 2 >= TREE_SITTER_SERIALIZATION_BUFFER_SIZE)
      return 0;
    buffer[0] = started_heredoc;
    buffer[1] = heredoc_trim_indent;
    heredoc_delimiter.copy(&buffer[2], heredoc_delimiter.length());
    return heredoc_delimiter.length() + 2;
  }

  void deserialize(const char *buffer, unsigned length) {
    if (length == 0) {
      started_heredoc = false;
      heredoc_trim_indent = false;
      heredoc_delimiter.clear();
    } else {
      started_heredoc = buffer[0];
      heredoc_trim_indent = buffer[1];
      heredoc_delimiter.assign(&buffer[2], &buffer[length]);
    }
  }

  void skip_spaces(TSLexer *lexer) {
    for (;;) {
      if (lexer->lookahead == ' ') {
        skip(lexer);
      } else {
        return;
      }
    }
  }

  const int32_t TerminatingSymbols[6] = {')', '/', '\\', ':', '\n', '"'};

  bool scan(TSLexer *lexer, const bool *valid_symbols) {
    // Grab the heredoc termination string.
    // There are couple of symbols that are listed as illegal herdoc delims
    // in puppet sytanx. If we get any of these illegal characters,
    // mark the current character as the end of the token
    if (valid_symbols[HEREDOC_HEADER]) {
      for (;;) {
        if (lexer->lookahead == 0) {
          return false;
        }
        for (int i = 0; i < (sizeof(TerminatingSymbols) / (sizeof(int32_t)));
             i++) {
          if (lexer->lookahead == TerminatingSymbols[i]) {
            started_heredoc = true;
            lexer->result_symbol = HEREDOC_HEADER;
            std::cout << "DOC WORD: " << heredoc_delimiter << "\n";
            return true;
          }
        }
        heredoc_delimiter += lexer->lookahead;
        skip(lexer);
      }
    }
    if (valid_symbols[HEREDOC_TRIM_BORDER]) {
      // Look for the '   |' before the term word
      int count = 0;
      for (;;) {
        switch (lexer->lookahead) {
        case ' ':
          count++;
          advance(lexer);
        case '|':
          lexer->mark_end(lexer);
          advance(lexer);
          lexer->result_symbol = HEREDOC_TRIM_BORDER;
          return true;
        default:
          return false;
        }
        skip(lexer);
      }
    }

    // Check to see if the current line is a heredoc terminator
    if (valid_symbols[HEREDOC_END] || valid_symbols[HEREDOC_END_TRIM]) {
      if (!started_heredoc) {
        return false;
      }
      bool seen_dash = false;
      for (;;) {
        skip_spaces(lexer);
        switch (lexer->lookahead) {
        case 0:
          return false;
        case '-':
          if (seen_dash) {
            return false;
          }
          seen_dash = true;
          // If we find the - mark, it must be trim
          if (!valid_symbols[HEREDOC_END_TRIM] || valid_symbols[HEREDOC_END]) {
            return false;
          }
          heredoc_trim_indent = true;
          skip(lexer);
        default:
          // If we see a non space, non - dash character after the pipe, it has
          // to match the herdoc terminator exactly
          for (int i = 0; i < heredoc_delimiter.length(); i++) {
            std::cout << "COMPARING DOC WORD: " << heredoc_delimiter[i] << " "
                      << lexer->lookahead << "\n";
            if (heredoc_delimiter[i] != lexer->lookahead) {
              return false;
            }
            advance(lexer);
          }
          if (heredoc_trim_indent) {
            lexer->result_symbol = HEREDOC_END;
          } else {
            lexer->result_symbol = HEREDOC_END_TRIM;
          }
          return true;
        }
      }
      skip(lexer);
    }
  }
  string heredoc_delimiter;
  bool started_heredoc;
  bool heredoc_trim_indent;
};
} // namespace

extern "C" {

void *tree_sitter_puppet_external_scanner_create() { return new Scanner(); }

bool tree_sitter_puppet_external_scanner_scan(void *payload, TSLexer *lexer,
                                              const bool *valid_symbols) {
  Scanner *scanner = static_cast<Scanner *>(payload);
  return scanner->scan(lexer, valid_symbols);
}

unsigned tree_sitter_puppet_external_scanner_serialize(void *payload,
                                                       char *state) {
  Scanner *scanner = static_cast<Scanner *>(payload);
  return scanner->serialize(state);
}

void tree_sitter_puppet_external_scanner_deserialize(void *payload,
                                                     const char *state,
                                                     unsigned length) {
  Scanner *scanner = static_cast<Scanner *>(payload);
  scanner->deserialize(state, length);
}

void tree_sitter_puppet_external_scanner_destroy(void *payload) {
  Scanner *scanner = static_cast<Scanner *>(payload);
  delete scanner;
}
}
