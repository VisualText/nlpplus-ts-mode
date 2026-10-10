# nlpplus-ts-mode

[![CI](https://github.com/VisualText/nlpplus-ts-mode/actions/workflows/ci.yml/badge.svg)](https://github.com/VisualText/nlpplus-ts-mode/actions/workflows/ci.yml)

Emacs major modes for [NLP++](https://visualtext.org) and the files an NLP++ analyzer is made of.
They use tree-sitter and need Emacs 29.1 or later.

| Mode | Files |
|---|---|
| `nlpplus-ts-mode` | Pass files: `*.nlp`, `*.pat` |
| `nlpplus-ts-dict-mode` | Dictionaries: `kb/user/*.dict` |
| `nlpplus-ts-kbb-mode` | Knowledge bases: `*.kbb` |
| `nlpplus-ts-seq-mode` | Pass sequences: `analyzer.seq` |
| `nlpplus-ts-tree-mode` | Parse trees: `*_log/*.tree` |

All five modes highlight their files. `nlpplus-ts-mode` also provides indentation, imenu, and
navigation by function and rule (`beginning-of-defun`, `end-of-defun`). It also registers the
[NLP++ language server](https://www.npmjs.com/package/nlpplus-language-server) with Eglot.

## Installing

1. Install the package:

   ```elisp
   (use-package nlpplus-ts-mode
     :vc (:url "https://github.com/VisualText/nlpplus-ts-mode"))
   ```

2. Install the grammars from
   [tree-sitter-nlpplus](https://github.com/VisualText/tree-sitter-nlpplus) by running
   `M-x nlpplus-ts-mode-install-grammars`. This needs a C compiler.

   If your Emacs's tree-sitter library is older than 0.25 (ABI 14), the command builds the
   grammars from their `abi-14` branch. The official Windows build of Emacs 30 has that older
   library.

3. For the language server, install it with `npm i -g nlpplus-language-server`. Then run
   `M-x eglot` in a pass file.

## Customizing

`nlpplus-ts-mode-indent-offset` (default 4) sets the indentation step in pass files.

To change how much is colored, set `treesit-font-lock-level`. Level 4 also colors function calls,
operators and punctuation.

## License

MIT
