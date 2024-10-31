(add-to-list 'load-path "~/.emacs.d/config")

(load "vim")
(load "appearance")
(load "save")
(load "email")

;; (setq interprogram-cut-function nil)
;; (setq interprogram-paste-function nil)

(require 'helm)
(helm-mode 1)

(require 'ledger-mode)
(setq ledger-post-amount-alignment-column 52)
(setq ledger-default-date-format ledger-iso-date-format)
(setq ledger-post-account-alignment-column 4)
(setq ledger-reconcile-default-commodity '£)

(setq-default truncate-lines t)
