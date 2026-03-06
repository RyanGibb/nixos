;;; languages.el --- Language-specific configuration -*- lexical-binding: t; -*-

;;;; OCaml

(use-package neocaml
  :mode (("\\.ml\\'" . neocaml-mode)
         ("\\.mli\\'" . neocaml-interface-mode))
  :config
  (require 'neocaml-repl)
  (add-hook 'neocaml-base-mode-hook #'neocaml-repl-minor-mode))

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
    "g s" '(ledger-display-ledger-stats :which-key "stats")
    "g b" '(ledger-display-balance-at-point :which-key "balance at point"))

  (my/local-leader-def
    :keymaps 'ledger-report-mode-map
    ""  '(:ignore t :which-key "report")
    "r" '(ledger-report :which-key "report")))

;;;; Tree-sitter

(setq treesit-font-lock-level 4)

;;; languages.el ends here
