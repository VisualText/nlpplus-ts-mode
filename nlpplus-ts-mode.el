;;; nlpplus-ts-mode.el --- Tree-sitter support for NLP++ -*- lexical-binding: t; -*-

;; Copyright (C) 2026 David de Hilster

;; Author: David de Hilster <dehilster@gmail.com>
;; Maintainer: David de Hilster <dehilster@gmail.com>
;; URL: https://github.com/VisualText/nlpplus-ts-mode
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: languages

;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Major modes for NLP++, a programming language for natural language
;; processing (https://visualtext.org), and for the files an NLP++
;; analyzer is made of:
;;
;;   `nlpplus-ts-mode'       pass files (*.nlp, *.pat)
;;   `nlpplus-ts-dict-mode'  dictionaries (kb/user/*.dict)
;;   `nlpplus-ts-kbb-mode'   knowledge bases (*.kbb)
;;   `nlpplus-ts-seq-mode'   pass sequences (analyzer.seq)
;;   `nlpplus-ts-tree-mode'  parse trees (*_log/*.tree)
;;
;; They use the tree-sitter grammars from
;; https://github.com/VisualText/tree-sitter-nlpplus.  Install them with
;; M-x nlpplus-ts-mode-install-grammars (this needs a C compiler).
;;
;; `nlpplus-ts-mode' registers the NLP++ language server with Eglot.
;; Install it with: npm i -g nlpplus-language-server

;;; Code:

(require 'treesit)
(eval-when-compile (require 'rx))

(defgroup nlpplus-ts nil
  "Tree-sitter support for NLP++."
  :group 'languages
  :prefix "nlpplus-ts-mode-")

(defcustom nlpplus-ts-mode-indent-offset 4
  "Number of columns for each indentation step in NLP++ pass files."
  :type 'integer
  :safe #'integerp)

;;; Grammars

(defconst nlpplus-ts-mode--repository
  "https://github.com/VisualText/tree-sitter-nlpplus"
  "Repository of the NLP++ tree-sitter grammars.")

(defconst nlpplus-ts-mode--grammars
  '((nlpplus . "src")
    (nlpplus_dict . "dict/src")
    (nlpplus_kbb . "kbb/src")
    (nlpplus_seq . "seq/src")
    (nlpplus_tree . "tree/src"))
  "Each NLP++ grammar and its source directory in the repository.")

(defun nlpplus-ts-mode--revision ()
  "Return the grammar revision this Emacs can load.
The abi-14 branch holds the parsers generated for tree-sitter libraries
that cannot load ABI 15."
  (if (< (treesit-library-abi-version) 15) "abi-14" "main"))

;;;###autoload
(defun nlpplus-ts-mode-install-grammars ()
  "Install or update the tree-sitter grammars for NLP++ and its file formats."
  (interactive)
  (let ((revision (nlpplus-ts-mode--revision)))
    (dolist (grammar nlpplus-ts-mode--grammars)
      (let ((treesit-language-source-alist
             (cons (list (car grammar) nlpplus-ts-mode--repository
                         revision (cdr grammar))
                   treesit-language-source-alist)))
        (treesit-install-language-grammar (car grammar))))))

;;; Pass files

(defconst nlpplus-ts-mode--builtins
  '("LJ" "abs" "addarg" "addattr" "addcnode" "addconcept" "addconval" "addnode"
    "addnumval" "addstmt" "addstrs" "addstrval" "addsval" "addword"
    "arraylength" "attrchange" "attrexists" "attrname" "attrtype" "attrvals"
    "attrwithval" "batchstart" "cap" "cbuf" "ceiling" "closefile" "conceptname"
    "conceptpath" "conval" "cout" "coutreset" "dballocstmt" "dbbindcol"
    "dbclose" "dbexec" "dbexecstmt" "dbfetch" "dbfreestmt" "dbopen" "deaccent"
    "debug" "dictfindword" "dictfirst" "dictgetword" "dictnext" "down"
    "eltnode" "excise" "exitpass" "exittopopup" "factorial" "fail" "fileout"
    "findana" "findattr" "findattrs" "findconcept" "findhierconcept" "findnode"
    "findphrase" "findroot" "findvals" "findwordpath" "firstnode" "floor" "flt"
    "fltval" "fncallstart" "fprintgvar" "fprintnvar" "fprintvar" "fprintxvar"
    "gdump" "getconcept" "getconval" "getnumval" "getpopupdata" "getstrval"
    "getsval" "ginc" "gp" "group" "gtolower" "guniq" "hitconf" "inc"
    "inheritval" "inputrange" "inputrangetofile" "interactive" "kbdumptree"
    "lasteltnode" "lastnode" "length" "lengthr" "levenshtein" "lextagger"
    "listadd" "listnode" "lj" "log" "logten" "lookup" "lowercase" "makeconcept"
    "makeparentconcept" "makephrase" "makestmt" "merge" "merger" "mkdir" "mod"
    "movecleft" "movecright" "movesem" "ndump" "next" "nextattr" "nextval"
    "ninc" "nodeconcept" "nodeowner" "noop" "num" "numrange" "numval"
    "openfile" "pathconcept" "percentstr" "permuten" "phraselength" "phraseraw"
    "phrasetext" "pncopyvars" "pndeletechilds" "pndown" "pninsert" "pnmakevar"
    "pnname" "pnnext" "pnprev" "pnrename" "pnreplaceval" "pnroot"
    "pnsingletdown" "pnup" "pnvar" "pnvarnames" "pow" "pranchor" "prchild"
    "preaction" "prev" "print" "printr" "printvar" "prlit" "prrange" "prtree"
    "prunephrases" "prxtree" "randomint" "regexp" "regexpi" "renameattr"
    "renamechild" "renameconcept" "renamenode" "replaceval" "resolveurl"
    "returnstmt" "rfaaction" "rfaactions" "rfaarg" "rfaargtolist" "rfacode"
    "rfaelement" "rfaelt" "rfaexpr" "rfalist" "rfalitelt" "rfalittoaction"
    "rfalittopair" "rfaname" "rfanodes" "rfanonlit" "rfanonlitelt" "rfanum"
    "rfaop" "rfapair" "rfapairs" "rfapostunary" "rfapres" "rfarange"
    "rfarecurse" "rfarecurses" "rfaregion" "rfaregions" "rfarule" "rfarulelts"
    "rfarulemark" "rfarules" "rfarulesfile" "rfaselect" "rfastr" "rfasugg"
    "rfaunary" "rfavar" "rfbarg" "rfbdecl" "rfbdecls" "rightjustifynum"
    "rmattr" "rmattrs" "rmattrval" "rmchild" "rmchildren" "rmconcept"
    "rmcphrase" "rmnode" "rmphrase" "rmval" "rmvals" "rmword" "round" "sdump"
    "setbase" "setlookahead" "setunsealed" "single" "singler" "singlex"
    "singlezap" "sortchilds" "sortconsbyattr" "sorthier" "sortphrase"
    "sortvals" "spellcandidates" "spellcorrect" "spellword" "splice" "split"
    "sqlstr" "sqrt" "startout" "stem" "stopout" "str" "strchar" "strchr"
    "strchrcount" "strclean" "strcontains" "strcontainsnocase" "strendswith"
    "strequal" "strequalnocase" "strescape" "strgreaterthan" "strisalpha"
    "strisdigit" "strislower" "strisupper" "strlength" "strlessthan"
    "strnotequal" "strnotequalnocase" "strpiece" "strrchr" "strspellcandidate"
    "strspellcompare" "strstartswith" "strsubst" "strtolower" "strtotitle"
    "strtoupper" "strtrim" "strunescape" "strval" "strwrap" "succeed" "suffix"
    "system" "take" "today" "topdir" "truncate" "unknown" "unpackdirs" "up"
    "uppercase" "urlbase" "urltofile" "var" "vareq" "varfn" "varfnarray"
    "varinlist" "varne" "varstrs" "varz" "whilestmt" "wnhypnymstoconcept"
    "wninit" "wnsensestoconcept" "wordindex" "wordpath" "writekb" "xaddlen"
    "xaddnvar" "xdump" "xinc" "xmlstr" "xrename")
  "Functions built into the NLP++ engine.")

(defconst nlpplus-ts-mode--builtin-regexp
  (concat "\\`" (regexp-opt nlpplus-ts-mode--builtins) "\\'")
  "Regexp matching exactly one NLP++ builtin function name.")

(defconst nlpplus-ts-mode--constant-regexp
  (rx bos "_" (or (seq "x" (+ upper)) "ROOT") eos)
  "Regexp matching node names that stand for classes of text.")

(defvar nlpplus-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?/ ". 14" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\\ "\\" table)
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?' "." table)
    (dolist (c '(?+ ?- ?= ?< ?> ?! ?& ?| ?% ?@))
      (modify-syntax-entry c "." table))
    table)
  "Syntax table for `nlpplus-ts-mode'.")

(defvar nlpplus-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'nlpplus
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'nlpplus
   :feature 'keyword
   '((section_start) @font-lock-preprocessor-face
     (section_end) @font-lock-preprocessor-face
     ["if" "else" "while" "return"] @font-lock-keyword-face)

   :language 'nlpplus
   :feature 'definition
   '((function_definition name: (identifier) @font-lock-function-name-face)
     (recurse_section name: (identifier) @font-lock-function-name-face)
     (recurse_section end_name: (identifier) @font-lock-function-name-face))

   :language 'nlpplus
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'nlpplus
   :feature 'escape-sequence
   :override t
   '((escape_sequence) @font-lock-escape-face
     (escape_char) @font-lock-escape-face)

   :language 'nlpplus
   :feature 'constant
   `(((node_name) @font-lock-constant-face
      (:match ,nlpplus-ts-mode--constant-regexp @font-lock-constant-face)))

   :language 'nlpplus
   :feature 'type
   '((node_name) @font-lock-type-face)

   ;; Literal words, numbers and symbols that a rule matches in the text
   :language 'nlpplus
   :feature 'string
   '((rule_element name: (identifier) @font-lock-string-face)
     (rule_element name: (symbol) @font-lock-string-face)
     (modifier_list (identifier) @font-lock-string-face)
     (modifier_list (symbol) @font-lock-string-face))

   :language 'nlpplus
   :feature 'property
   '((modifier name: (identifier) @font-lock-property-name-face)
     (modifier value: (identifier) @font-lock-constant-face)
     (modifiers "*" @font-lock-property-name-face))

   :language 'nlpplus
   :feature 'builtin
   `((variable_scope) @font-lock-builtin-face
     ((call_expression function: (identifier) @font-lock-builtin-face)
      (:match ,nlpplus-ts-mode--builtin-regexp @font-lock-builtin-face)))

   :language 'nlpplus
   :feature 'function
   '((call_expression function: (identifier) @font-lock-function-call-face)
     (call_expression scope: (identifier) @font-lock-type-face))

   :language 'nlpplus
   :feature 'number
   '([(number) (float)] @font-lock-number-face)

   :language 'nlpplus
   :feature 'operator
   '(["<-" "=" "+" "-" "*" "/" "%" "%%" "<<" "&&" "||" "!" "==" "!=" "<="
      ">=" "++" "--"] @font-lock-operator-face
      (binary_expression operator: ["<" ">"] @font-lock-operator-face)
      (reference) @font-lock-operator-face
      "@@" @font-lock-preprocessor-face)

   :language 'nlpplus
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)

   :language 'nlpplus
   :feature 'delimiter
   '(["," ";" "::"] @font-lock-delimiter-face))
  "Tree-sitter font-lock settings for `nlpplus-ts-mode'.")

(defvar nlpplus-ts-mode--indent-rules
  `((nlpplus
     ((node-is ,(rx bos "}" eos)) parent-bol 0)
     ((node-is ,(rx bos "else" eos)) parent-bol 0)
     ((parent-is ,(rx bos "block" eos)) parent-bol nlpplus-ts-mode-indent-offset)
     ((parent-is ,(rx bos (or "if_statement" "while_statement") eos))
      parent-bol nlpplus-ts-mode-indent-offset)
     ;; A rule starts at the margin with its suggested node; its elements
     ;; and the closing @@ go under it.
     ((match nil ,(rx bos "rule" eos) ,(rx bos "suggested" eos)) column-0 0)
     ((parent-is ,(rx bos "rule" eos)) parent-bol nlpplus-ts-mode-indent-offset)
     ((parent-is ,(rx bos "modifier_list" eos))
      parent-bol nlpplus-ts-mode-indent-offset)
     ;; The actions of a rule, under @PRE, @CHECK or @POST
     ((parent-is ,(rx bos (or "pre_section" "check_section" "post_section") eos))
      column-0 nlpplus-ts-mode-indent-offset)
     ((parent-is ,(rx bos (or "argument_list" "parameter_list") eos))
      parent-bol nlpplus-ts-mode-indent-offset)
     (no-node column-0 0)
     (catch-all column-0 0)))
  "Tree-sitter indentation rules for `nlpplus-ts-mode'.")

(defun nlpplus-ts-mode--defun-name (node)
  "Return the name of the function or rule NODE, or nil."
  (pcase (treesit-node-type node)
    ("function_definition"
     (treesit-node-text (treesit-node-child-by-field-name node "name") t))
    ("rule"
     (treesit-node-text (treesit-node-child-by-field-name
                         (treesit-node-child-by-field-name node "suggested")
                         "name")
                        t))
    ("recurse_section"
     (treesit-node-text (treesit-node-child-by-field-name node "name") t))))

;;;###autoload
(define-derived-mode nlpplus-ts-mode prog-mode "NLP++"
  "Major mode for NLP++ pass files, using tree-sitter."
  :group 'nlpplus-ts
  :syntax-table nlpplus-ts-mode--syntax-table
  (when (treesit-ready-p 'nlpplus)
    (treesit-parser-create 'nlpplus)

    (setq-local comment-start "# ")
    (setq-local comment-end "")
    (setq-local comment-start-skip "\\(?:#+\\|/\\*+\\)[ \t]*")

    (setq-local treesit-font-lock-settings nlpplus-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (keyword string type)
                  (builtin constant escape-sequence number property)
                  (bracket delimiter function operator)))

    (setq-local treesit-simple-indent-rules nlpplus-ts-mode--indent-rules)

    (setq-local treesit-defun-type-regexp
                (rx bos (or "function_definition" "rule" "recurse_section") eos))
    (setq-local treesit-defun-name-function #'nlpplus-ts-mode--defun-name)
    (setq-local treesit-simple-imenu-settings
                '(("Function" "\\`function_definition\\'" nil nil)
                  ("Recurse" "\\`recurse_section\\'" nil nil)
                  ("Rule" "\\`rule\\'" nil nil)))

    (treesit-major-mode-setup)))

;;; Data formats

(defun nlpplus-ts-mode--setup-data (language settings features comment)
  "Set up a data-format mode for LANGUAGE.
SETTINGS and FEATURES are its font-lock settings and feature list.
COMMENT is its line comment start, or nil."
  (when (treesit-ready-p language)
    (treesit-parser-create language)
    (when comment
      (setq-local comment-start comment)
      (setq-local comment-end ""))
    (setq-local treesit-font-lock-settings settings)
    (setq-local treesit-font-lock-feature-list features)
    (treesit-major-mode-setup)))

(defvar nlpplus-ts-mode--data-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\" "\"" table)
    table)
  "Syntax table for the NLP++ data-format modes.")

(defvar nlpplus-ts-mode--dict-font-lock-settings
  (treesit-font-lock-rules
   :language 'nlpplus_dict
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'nlpplus_dict
   :feature 'definition
   '((headword (word) @font-lock-function-name-face))

   :language 'nlpplus_dict
   :feature 'property
   '((attribute name: (word) @font-lock-property-name-face)
     "=" @font-lock-operator-face)

   :language 'nlpplus_dict
   :feature 'string
   '((string) @font-lock-string-face
     (value) @font-lock-constant-face
     (item) @font-lock-constant-face))
  "Tree-sitter font-lock settings for `nlpplus-ts-dict-mode'.")

;;;###autoload
(define-derived-mode nlpplus-ts-dict-mode prog-mode "NLP++ Dict"
  "Major mode for NLP++ dictionaries, using tree-sitter."
  :group 'nlpplus-ts
  :syntax-table nlpplus-ts-mode--data-syntax-table
  (nlpplus-ts-mode--setup-data
   'nlpplus_dict nlpplus-ts-mode--dict-font-lock-settings
   '((comment definition) (property string)) "# "))

(defvar nlpplus-ts-mode--kbb-font-lock-settings
  (treesit-font-lock-rules
   :language 'nlpplus_kbb
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'nlpplus_kbb
   :feature 'definition
   '((entry concept: (concept) @font-lock-function-name-face)
     (nested_entry concept: (concept) @font-lock-type-face))

   :language 'nlpplus_kbb
   :feature 'property
   '((attribute name: (_) @font-lock-property-name-face)
     [":" "="] @font-lock-operator-face)

   :language 'nlpplus_kbb
   :feature 'string
   '((attribute value: (string) @font-lock-string-face)
     (list (string) @font-lock-string-face)
     (value) @font-lock-constant-face
     (item) @font-lock-constant-face))
  "Tree-sitter font-lock settings for `nlpplus-ts-kbb-mode'.")

;;;###autoload
(define-derived-mode nlpplus-ts-kbb-mode prog-mode "NLP++ KBB"
  "Major mode for NLP++ knowledge bases, using tree-sitter.
Indentation is the concept hierarchy, two spaces a level."
  :group 'nlpplus-ts
  :syntax-table nlpplus-ts-mode--data-syntax-table
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (nlpplus-ts-mode--setup-data
   'nlpplus_kbb nlpplus-ts-mode--kbb-font-lock-settings
   '((comment definition) (property string)) "# "))

(defvar nlpplus-ts-mode--seq-font-lock-settings
  (treesit-font-lock-rules
   :language 'nlpplus_seq
   :feature 'comment
   '((comment) @font-lock-comment-face
     ;; An inactive pass reads as switched off.
     (pass inactive: (inactive) @font-lock-comment-face
           type: (pass_type) @font-lock-comment-face))

   :language 'nlpplus_seq
   :feature 'keyword
   '((pass_type) @font-lock-keyword-face
     (nil) @font-lock-constant-face)

   :language 'nlpplus_seq
   :feature 'definition
   '((pass file: (name) @font-lock-function-name-face)
     (number) @font-lock-number-face))
  "Tree-sitter font-lock settings for `nlpplus-ts-seq-mode'.")

;;;###autoload
(define-derived-mode nlpplus-ts-seq-mode prog-mode "NLP++ Seq"
  "Major mode for NLP++ pass sequences (analyzer.seq), using tree-sitter."
  :group 'nlpplus-ts
  :syntax-table nlpplus-ts-mode--data-syntax-table
  (nlpplus-ts-mode--setup-data
   'nlpplus_seq nlpplus-ts-mode--seq-font-lock-settings
   '((comment definition) (keyword)) "# "))

(defvar nlpplus-ts-mode--tree-font-lock-settings
  (treesit-font-lock-rules
   :language 'nlpplus_tree
   :feature 'definition
   '((separator) @font-lock-comment-face
     (pass_header) @font-lock-doc-face
     (tree_header) @font-lock-doc-face
     ((name) @font-lock-type-face (:match "\\`_" @font-lock-type-face)))

   :language 'nlpplus_tree
   :feature 'keyword
   '((type) @font-lock-builtin-face
     (flag) @font-lock-keyword-face)

   :language 'nlpplus_tree
   :feature 'property
   '((variable name: (string) @font-lock-property-name-face)
     (variable value: (string) @font-lock-string-face)
     (number) @font-lock-number-face))
  "Tree-sitter font-lock settings for `nlpplus-ts-tree-mode'.")

;;;###autoload
(define-derived-mode nlpplus-ts-tree-mode prog-mode "NLP++ Tree"
  "Major mode for NLP++ parse trees, using tree-sitter."
  :group 'nlpplus-ts
  (setq-local buffer-read-only t)
  (nlpplus-ts-mode--setup-data
   'nlpplus_tree nlpplus-ts-mode--tree-font-lock-settings
   '((definition) (keyword property)) nil))

;;; Files and the language server

;;;###autoload
(when (treesit-available-p)
  (add-to-list 'auto-mode-alist '("\\.\\(?:nlp\\|pat\\)\\'" . nlpplus-ts-mode))
  (add-to-list 'auto-mode-alist '("/kb/user/[^/]*\\.dict\\'" . nlpplus-ts-dict-mode))
  (add-to-list 'auto-mode-alist '("\\.kbb\\'" . nlpplus-ts-kbb-mode))
  (add-to-list 'auto-mode-alist '("/analyzer\\.seq\\'" . nlpplus-ts-seq-mode))
  (add-to-list 'auto-mode-alist '("_log/[^/]*\\.tree\\'" . nlpplus-ts-tree-mode)))

;;;###autoload
(with-eval-after-load 'eglot
  (defvar eglot-server-programs)
  (add-to-list 'eglot-server-programs
               '(nlpplus-ts-mode "nlpplus-language-server" "--stdio")))

(provide 'nlpplus-ts-mode)

;;; nlpplus-ts-mode.el ends here
