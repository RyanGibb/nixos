;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;; All packages are installed via Nix, so use-package only configures them.
(setq use-package-always-ensure nil)

;;;; General settings

(setq user-full-name "Ryan Gibb"
      user-mail-address "ryan@freumh.org")

(setq-default indent-tabs-mode nil
              tab-width 4)
(setq create-lockfiles nil)
(setq auto-save-default t)
(let ((auto-save-dir (expand-file-name "auto-save/" user-emacs-directory)))
  (make-directory auto-save-dir t)
  (setq auto-save-file-name-transforms
        `((".*" ,auto-save-dir t))))
(setq make-backup-files nil)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

;; UTF-8 everywhere
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)

;; y/n instead of yes/no
(setq use-short-answers t)

;; Remember recent files
(recentf-mode 1)

;; Remember minibuffer history
(savehist-mode 1)

;; Remember cursor position in files
(save-place-mode 1)

;; Auto-revert files when changed on disk
(global-auto-revert-mode 1)

;; C-h after prefix shows searchable binding list via embark
(use-package embark
  :init
  (setq which-key-use-C-h-commands nil
        prefix-help-command #'embark-prefix-help-command))

;; project-switch-project goes straight to find-file
(setq project-switch-commands #'project-find-file)

;; Treat underscore as word character in programming modes
(add-hook 'prog-mode-hook
          (lambda () (modify-syntax-entry ?_ "w")))
(add-hook 'emacs-lisp-mode-hook
          (lambda () (modify-syntax-entry ?- "w")))

;;;; Load modules

(load (expand-file-name "appearance" user-emacs-directory))
(load (expand-file-name "evil" user-emacs-directory))
(load (expand-file-name "completion" user-emacs-directory))
(load (expand-file-name "tools" user-emacs-directory))
(load (expand-file-name "org" user-emacs-directory))
(load (expand-file-name "mu4e" user-emacs-directory))
(load (expand-file-name "languages" user-emacs-directory))

;;; init.el ends here
