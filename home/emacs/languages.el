;;; languages.el --- Language-specific configuration -*- lexical-binding: t; -*-

;;;; OCaml

(use-package neocaml
  :mode (("\\.ml\\'" . neocaml-mode)
         ("\\.mli\\'" . neocaml-interface-mode))
  :config
  (require 'neocaml-repl)
  (add-hook 'neocaml-base-mode-hook #'neocaml-repl-minor-mode))

(with-eval-after-load 'org-src
  (setf (alist-get "ocaml" org-src-lang-modes nil nil #'equal) 'neocaml))

;;;; Nix

(use-package nix-mode
  :mode "\\.nix\\'")

;;;; Ledger

(use-package ledger-mode
  :mode "\\.ledger\\'"
  :custom
  (ledger-post-amount-alignment-column 52)
  (ledger-default-date-format ledger-iso-date-format)
  (ledger-post-account-alignment-column 4)
  (ledger-reconcile-default-commodity "£")
  :hook (ledger-mode . (lambda () (setq-local tab-always-indent 'complete)))
  :config
  (evil-define-key 'normal ledger-reconcile-mode-map
    (kbd "q") #'ledger-reconcile-quit)

  (my/local-leader-def
    :keymaps 'ledger-mode-map
    ""  '(:ignore t :which-key "ledger")
    "a" '(ledger-add-transaction :which-key "add transaction")
    "e" '(ledger-post-edit-amount :which-key "edit amount")
    "t" '(ledger-toggle-current :which-key "toggle")
    "d" '(ledger-delete-current-transaction :which-key "delete transaction")
    "r" '(ledger-report :which-key "report")
    "R" '(ledger-reconcile :which-key "reconcile")
    "s" '(ledger-sort-region :which-key "sort region")
    "S" '(ledger-schedule-upcoming :which-key "schedule")
    "c" '(ledger-mode-clean-buffer :which-key "clean buffer")
    "g s" '(ledger-display-ledger-stats :which-key "stats")
    "g b" '(ledger-display-balance-at-point :which-key "balance at point"))

  (my/local-leader-def
    :keymaps 'ledger-report-mode-map
    ""  '(:ignore t :which-key "report")
    "r" '(ledger-report :which-key "report")))

;;;; Slipshow

(use-package slipshow-mode
  :mode "\\.slp\\'"
  :config
  ;; slipshow puts {...} on nearly every line, markdown's worst case
  (defun my/slipshow-trim-font-lock ()
    (setq-local markdown-mode-font-lock-keywords
                (seq-remove (lambda (e)
                              (eq (car-safe e) 'markdown-match-inline-attributes))
                            markdown-mode-font-lock-keywords)))
  (add-hook 'slipshow-mode-hook #'my/slipshow-trim-font-lock)

  (my/local-leader-def
    :keymaps 'slipshow-mode-map
    ""  '(:ignore t :which-key "slipshow")
    "]" '(slipshow-preview-go-next :which-key "next")
    "[" '(slipshow-preview-go-previous :which-key "previous")
    "r" '(slipshow-resend-conf :which-key "resend config")))

;;;; LaTeX

(require 'tex-site)

(use-package tex
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-start-server nil)
  (preview-auto-cache-preamble nil)
  :config
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
  (setq-default TeX-command-default "LaTeX")
  (defun my/latex-compile ()
    "Save and compile the LaTeX document."
    (interactive)
    (TeX-save-document (TeX-master-file))
    (TeX-command TeX-command-default 'TeX-master-file -1))

  (defun my/tex-view-refit (&rest _)
    "After TeX-view, resize any visible pdf-view window to fit the PDF width."
    (dolist (win (window-list))
      (with-current-buffer (window-buffer win)
        (when (derived-mode-p 'pdf-view-mode)
          (with-selected-window win
            (my/pdf-view-fit-window-to-width)
            (pdf-view-redisplay))))))
  (advice-add 'TeX-view :after #'my/tex-view-refit)

  (my/local-leader-def
    :keymaps '(LaTeX-mode-map latex-mode-map)
    ""  '(:ignore t :which-key "latex")
    "v" '(TeX-view :which-key "view")
    "c" '(my/latex-compile :which-key "compile")
    "a" '(TeX-command-run-all :which-key "run all")
    "m" '(TeX-command-master :which-key "run a command")
    "p" '(preview-at-point :which-key "preview")
    "P" '(preview-clearout-at-point :which-key "clear preview")
    "f" '(TeX-fold-paragraph :which-key "fold paragraph")
    "F" '(TeX-fold-clearout-paragraph :which-key "unfold paragraph")))

;;;; Lean 4

(use-package nael
  :defer t
  :init
  (add-hook 'nael-mode-hook #'abbrev-mode)
  :config
  (require 'nael-eglot)
  (add-hook 'nael-mode-hook #'eglot-ensure)
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (when (derived-mode-p 'nael-mode)
                (nael-eglot-configure-when-managed))))

  (my/local-leader-def
    :keymaps 'nael-mode-map
    ""  '(:ignore t :which-key "lean")
    "a" '(nael-abbrev-help :which-key "abbrev help")))

;;;; Rocq / Coq (Proof General)

(use-package coq
  :mode ("\\.v\\'" . coq-mode)
  :custom
  (proof-splash-enable nil)
  (proof-three-window-mode-policy 'hybrid)
  :config
  (add-hook 'coq-mode-hook (lambda () (setq-local tab-width proof-indent)))

  (my/local-leader-def
    :keymaps 'coq-mode-map
    ""  '(:ignore t :which-key "rocq")
    "]" '(proof-assert-next-command-interactive :which-key "next")
    "[" '(proof-undo-last-successful-command :which-key "undo")
    "." '(proof-goto-point :which-key "goto point")
    "l" '(:ignore t :which-key "layout")
    "lc" '(pg-response-clear-displays :which-key "clear displays")
    "ll" '(proof-layout-windows :which-key "relayout")
    "lp" '(proof-prf :which-key "show proof")
    "p" '(:ignore t :which-key "proof")
    "pi" '(proof-interrupt-process :which-key "interrupt")
    "pp" '(proof-process-buffer :which-key "process buffer")
    "pq" '(proof-shell-exit :which-key "quit prover")
    "pr" '(proof-retract-buffer :which-key "retract buffer")
    "a" '(:ignore t :which-key "about/print/check")
    "aa" '(coq-Print :which-key "print")
    "aA" '(coq-Print-with-all :which-key "print (all)")
    "ab" '(coq-About :which-key "about")
    "aB" '(coq-About-with-all :which-key "about (all)")
    "ac" '(coq-Check :which-key "check")
    "aC" '(coq-Check-show-all :which-key "check (all)")
    "af" '(proof-find-theorems :which-key "find theorems")
    "g" '(:ignore t :which-key "goto")
    "ge" '(proof-goto-command-end :which-key "command end")
    "gl" '(proof-goto-end-of-locked :which-key "end of locked")
    "gs" '(proof-goto-command-start :which-key "command start")
    "i" '(:ignore t :which-key "insert")
    "ic" '(coq-insert-command :which-key "command")
    "ie" '(coq-end-Section :which-key "end section")
    "iI" '(coq-insert-intros :which-key "intros")
    "ir" '(coq-insert-requires :which-key "requires")
    "is" '(coq-insert-section-or-module :which-key "section/module")
    "it" '(coq-insert-tactic :which-key "tactic")
    "iT" '(coq-insert-tactical :which-key "tactical")))

(use-package company-coq
  :after coq
  :hook (coq-mode . company-coq-mode)
  :custom
  (company-coq-disabled-features '(hello company company-defaults spinner))
  :config
  (add-hook 'coq-mode-hook
            (lambda ()
              (dolist (b '(company-coq-master-backend company-coq-math-symbols-backend))
                (add-to-list 'completion-at-point-functions (cape-company-to-capf b)))))
  (advice-add 'company-coq--proof-goto-point-advice :override
              (lambda (&rest _)
                (when (bound-and-true-p company-candidates)
                  (company-abort))))
  (add-hook 'company-coq-mode-hook
            (lambda ()
              (setq-local outline-regexp
                          "^[ \t]*\\(Module\\|Section\\|Chapter\\|Class\\|Instance\\|Lemma\\|Theorem\\|Definition\\|Record\\|Inductive\\|Fixpoint\\|Proof\\|Qed\\|Defined\\|Admitted\\|Abort\\|End\\)\\b")
              (setq-local outline-level (lambda () (1+ (current-indentation))))
              (setq-local outline-heading-end-regexp "\n")
              (outline-minor-mode 1)
              (when (bound-and-true-p hs-minor-mode) (hs-minor-mode -1))
              (my/coq-fold-all-proofs)))

  (defun my/coq-fold-all-proofs ()
    "Fold every Lemma statement and Proof block in the buffer."
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*\\(Proof\\|Lemma\\)\\b" nil t)
        (beginning-of-line)
        (outline-hide-subtree)
        (forward-line 1))))

  (define-key coq-mode-map (kbd "M-.") nil)
  (define-key coq-mode-map (kbd "M-,") nil)
  (advice-add 'company-coq-jump-to-definition :before
              (lambda (&rest _) (evil-set-jump)))

  (evil-define-key 'normal coq-mode-map
    "gd" #'company-coq-jump-to-definition
    "gr" #'company-coq-grep-symbol
    "K"  #'company-coq-doc))

;;;; Tree-sitter

(setq treesit-font-lock-level 4)

;;; languages.el ends here
