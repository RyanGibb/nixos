;;; completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;;; Minibuffer

(use-package vertico
  :config
  (vertico-mode)
  (require 'vertico-sort)
  (setq vertico-sort-function #'vertico-sort-history-length-alpha)
  (require 'vertico-repeat)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save))

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
        xref-show-xrefs-function #'consult-xref)
  (define-key minibuffer-local-map (kbd "C-s") #'consult-history))

;;;; In-buffer

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  :config
  (global-corfu-mode)
  (evil-define-key 'insert 'global
    (kbd "C-SPC") #'completion-at-point))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;;; Snippets

(use-package yasnippet
  :config
  (add-to-list 'yas-snippet-dirs
               (expand-file-name "snippets" user-emacs-directory))
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package yasnippet-capf
  :after (yasnippet cape)
  :config
  (add-hook 'yas-minor-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'yasnippet-capf 30 t))))

;;;; Shell history

(defun my/load-zsh-history ()
  "Load zsh history into `shell-command-history'."
  (let ((histfile (expand-file-name "~/.histfile")))
    (when (file-exists-p histfile)
      (with-temp-buffer
        (insert-file-contents histfile)
        (goto-char (point-min))
        (let (lines)
          (while (not (eobp))
            (let ((line (buffer-substring-no-properties
                         (line-beginning-position) (line-end-position))))
              (unless (string-empty-p line)
                (push line lines)))
            (forward-line 1))
          (setq shell-command-history
                (delete-dups lines)))))))

(add-hook 'emacs-startup-hook #'my/load-zsh-history)

;;;; Key discovery

(use-package which-key
  :config (which-key-mode))

;;; completion.el ends here
