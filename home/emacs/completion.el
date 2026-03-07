;;; completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;;; Minibuffer

(use-package vertico
  :config
  (vertico-mode)
  (require 'vertico-sort)
  (setq vertico-sort-function #'vertico-sort-history-length-alpha))

(use-package vertico-posframe
  :config (vertico-posframe-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :config (marginalia-mode))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-x p b" . consult-project-buffer)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-s l" . consult-line)
         ("M-s r" . consult-ripgrep))
  :init
  (setq xref-show-definitions-function #'consult-xref
        xref-show-xrefs-function #'consult-xref))

;;;; In-buffer

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  :config (global-corfu-mode))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;;; Snippets

(use-package yasnippet
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;;;; Key discovery

(use-package which-key
  :config (which-key-mode))

;;; completion.el ends here
