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

(setq-default truncate-lines t)
