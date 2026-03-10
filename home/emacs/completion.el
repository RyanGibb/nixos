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

(defvar my/zsh-history--offset 0
  "Byte offset into ~/.histfile up to which we have already read.")

(defvar my/zsh-history--mtime nil
  "Last known modification time of ~/.histfile.")

(defun my/load-zsh-history ()
  "Load new lines from zsh histfile into `shell-command-history'."
  (let* ((histfile (expand-file-name "~/.histfile"))
         (attrs (file-attributes histfile))
         (mtime (file-attribute-modification-time attrs))
         (size (file-attribute-size attrs)))
    (when (and size (not (equal mtime my/zsh-history--mtime)))
      (setq my/zsh-history--mtime mtime)
      (when (> size my/zsh-history--offset)
        (with-temp-buffer
          (insert-file-contents histfile nil my/zsh-history--offset size)
          (setq my/zsh-history--offset size)
          (goto-char (point-min))
          (while (not (eobp))
            (let ((line (buffer-substring-no-properties
                         (line-beginning-position) (line-end-position))))
              (unless (string-empty-p line)
                (push line shell-command-history)))
            (forward-line 1)))
        (delete-dups shell-command-history)))))

(add-hook 'emacs-startup-hook #'my/load-zsh-history)
(run-with-idle-timer 5 t #'my/load-zsh-history)

(defun my/append-to-zsh-history (command &rest _)
  "Append COMMAND to zsh histfile."
  (let ((histfile (expand-file-name "~/.histfile")))
    (write-region (concat command "\n") nil histfile 'append 'silent)))

;; Only advise async-shell-command, not shell-command, because
;; async-shell-command delegates to shell-command with " &" appended
;; and advising both would create duplicate entries.
(advice-add 'async-shell-command :before #'my/append-to-zsh-history)

;;;; Key discovery

(use-package which-key
  :config (which-key-mode))

;;; completion.el ends here
