;;; nlpplus-ts-mode-tests.el --- Tests for nlpplus-ts-mode -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with:
;;   emacs --batch -L . -l test/nlpplus-ts-mode-tests.el \
;;     -f ert-run-tests-batch-and-exit
;; The grammars must be installed (M-x nlpplus-ts-mode-install-grammars).

;;; Code:

(require 'ert)
(require 'nlpplus-ts-mode)

(defmacro nlpplus-ts-test--with-buffer (mode language text &rest body)
  "Insert TEXT into a buffer in MODE and run BODY, if LANGUAGE is installed."
  (declare (indent 3))
  `(progn
     (skip-unless (treesit-language-available-p ,language))
     (with-temp-buffer
       (insert ,text)
       (let ((treesit-font-lock-level 4))
         (funcall ,mode)
         (font-lock-ensure))
       ,@body)))

(defun nlpplus-ts-test--face (string &optional offset)
  "Return the face at STRING, plus OFFSET characters, in the current buffer."
  (goto-char (point-min))
  (search-forward string)
  (get-text-property (+ (match-beginning 0) (or offset 0)) 'face))

(ert-deftest nlpplus-ts-test-pass-faces ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-mode 'nlpplus
      "@NODES _ROOT\n@POST\n  S(\"x\") = num(N(\"$text\", 2));\n  single();\n  mine();\n@RULES\n_money [layer=(_noun)] <- \\$ _xNUM dollars @@\n"
    (should (eq (nlpplus-ts-test--face "@NODES") 'font-lock-preprocessor-face))
    (should (eq (nlpplus-ts-test--face "_ROOT") 'font-lock-constant-face))
    (should (eq (nlpplus-ts-test--face "S(") 'font-lock-builtin-face))
    (should (eq (nlpplus-ts-test--face "\"x\"") 'font-lock-string-face))
    (should (eq (nlpplus-ts-test--face "num(") 'font-lock-builtin-face))
    (should (eq (nlpplus-ts-test--face "mine(") 'font-lock-function-call-face))
    (should (eq (nlpplus-ts-test--face "_money") 'font-lock-type-face))
    (should (eq (nlpplus-ts-test--face "layer") 'font-lock-property-name-face))
    (should (eq (nlpplus-ts-test--face "\\$") 'font-lock-escape-face))
    (should (eq (nlpplus-ts-test--face "_xNUM") 'font-lock-constant-face))
    (should (eq (nlpplus-ts-test--face "dollars") 'font-lock-string-face))
    (should (eq (nlpplus-ts-test--face "<-") 'font-lock-operator-face))))

(ert-deftest nlpplus-ts-test-indent ()
  (let ((expected (concat "@CODE\n"
                          "while (L(\"i\") < 3) {\n"
                          "    if (L(\"i\") == 1)\n"
                          "        L(\"x\") = 1;\n"
                          "    else\n"
                          "        L(\"x\") = 2;\n"
                          "    L(\"i\")++;\n"
                          "}\n"
                          "@@CODE\n"
                          "@POST\n"
                          "    single();\n"
                          "@RULES\n"
                          "_person <-\n"
                          "    _title\n"
                          "    _xCAP\n"
                          "    @@\n")))
    (nlpplus-ts-test--with-buffer #'nlpplus-ts-mode 'nlpplus
        (replace-regexp-in-string "^ +" "" expected)
      (setq indent-tabs-mode nil)
      (indent-region (point-min) (point-max))
      (should (equal (buffer-string) expected)))))

(ert-deftest nlpplus-ts-test-imenu ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-mode 'nlpplus
      "@DECL\nsquare(L(\"n\")) {\n  return L(\"n\") * L(\"n\");\n}\n@@DECL\n"
    (let ((index (funcall imenu-create-index-function)))
      (should (assoc "square" (cdr (assoc "Function" index)))))))

(ert-deftest nlpplus-ts-test-dict-faces ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-dict-mode 'nlpplus_dict
      "american samoan nationality=1 country=\"american samoa\"\n"
    (should (eq (nlpplus-ts-test--face "samoan") 'font-lock-function-name-face))
    (should (eq (nlpplus-ts-test--face "nationality") 'font-lock-property-name-face))
    (should (eq (nlpplus-ts-test--face "\"american") 'font-lock-string-face))))

(ert-deftest nlpplus-ts-test-kbb-faces ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-kbb-mode 'nlpplus_kbb
      "degrees\n  bs: name=\"bachelor of science\", level=bachelor\n"
    (should (eq (nlpplus-ts-test--face "degrees") 'font-lock-function-name-face))
    (should (eq (nlpplus-ts-test--face "bs") 'font-lock-type-face))
    (should (eq (nlpplus-ts-test--face "level") 'font-lock-property-name-face))))

(ert-deftest nlpplus-ts-test-seq-faces ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-seq-mode 'nlpplus_seq
      "tokenize\tnil\t# tokens\npat\tsentences\n/nlp\told\n"
    (should (eq (nlpplus-ts-test--face "tokenize") 'font-lock-keyword-face))
    (should (eq (nlpplus-ts-test--face "nil") 'font-lock-constant-face))
    (should (eq (nlpplus-ts-test--face "sentences") 'font-lock-function-name-face))
    (should (eq (nlpplus-ts-test--face "/nlp" 1) 'font-lock-comment-face))))

(ert-deftest nlpplus-ts-test-tree-faces ()
  (nlpplus-ts-test--with-buffer #'nlpplus-ts-tree-mode 'nlpplus_tree
      "_ROOT [0,3,0,3,0,0,node,un]\n   dog [0,3,0,3,0,0,alpha]\n"
    (should (eq (nlpplus-ts-test--face "_ROOT") 'font-lock-type-face))
    (should (eq (nlpplus-ts-test--face "alpha") 'font-lock-builtin-face))))

(provide 'nlpplus-ts-mode-tests)

;;; nlpplus-ts-mode-tests.el ends here
