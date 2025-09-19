;;; ledger.el -*- lexical-binding: t; -*-

(after! ledger-mode
  (setq ledger-post-amount-alignment-column 52)
  (setq ledger-default-date-format ledger-iso-date-format)
  (setq ledger-post-account-alignment-column 4)
  (setq ledger-reconcile-default-commodity "£")
  (map! :map ledger-reconcile-mode-map
        :n "q" #'ledger-reconcile-quit)
  )
(setq tab-always-indent 'complete)
