;;; languages.el --- Language-specific configuration -*- lexical-binding: t; -*-

;;;; OCaml

(use-package neocaml
  :mode (("\\.ml\\'" . neocaml-mode)
         ("\\.mli\\'" . neocaml-interface-mode))
  :config
  (require 'neocaml-repl)
  (add-hook 'neocaml-base-mode-hook #'neocaml-repl-minor-mode)
  (with-eval-after-load 'org-src
    (setf (alist-get "ocaml" org-src-lang-modes nil nil #'equal) 'neocaml)))

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

;;;; Tree-sitter

(setq treesit-font-lock-level 4)

;;; languages.el ends here
