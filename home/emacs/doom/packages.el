;; -*- no-byte-compile: t; -*-

;; (package! evil-collection)
;; (package! gruvbox-theme)
;; (package! mu)
(package! caledonia
  :recipe (:host github
           :repo "RyanGibb/caledonia"
           :files ("emacs/*.el"))
  :pin "334956a2dce78c5a59b6c3a7c6d1b1e6cc37072b")
;; (package! caledonia
;;   :recipe (:local-repo "/home/ryan/projects/caledonia"
;;            :files ("emacs/*.el")))
