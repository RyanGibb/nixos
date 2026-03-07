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

;; Allow commands in minibuffer while in minibuffer
(setq enable-recursive-minibuffers t)

;; Remember recent files
(recentf-mode 1)

;; Remember minibuffer history
(savehist-mode 1)

;; Remember cursor position in files
(save-place-mode 1)

;; Auto-revert files when changed on disk
(global-auto-revert-mode 1)

;; Embark: C-; to act on candidate, SPC a from normal mode
;; In minibuffer (e.g. SPC / ripgrep):
;;   C-c C-e  export + enter wgrep (edit, then C-c C-e to apply, C-x s to save)
;;   C-c C-;  export to grep buffer (C-c C-p for wgrep, C-c C-k to discard)
;;   C-c C-l  collect candidates into buffer
;; C-h after prefix shows searchable binding list via embark
(use-package embark
  :init
  (setq which-key-use-C-h-commands nil
        prefix-help-command #'embark-prefix-help-command)
  :config
  (global-set-key (kbd "C-;") #'embark-act)
  (define-key minibuffer-local-map (kbd "C-;") #'embark-act)
  (define-key minibuffer-local-map (kbd "C-c C-;") #'embark-export)
  (define-key minibuffer-local-map (kbd "C-c C-l") #'embark-collect)
  (define-key minibuffer-local-map (kbd "C-c C-e") #'my/embark-export-write))

(use-package wgrep)

(defun my/embark-export-write ()
  "Export vertico results to a writable buffer (wgrep, wdired, or occur)."
  (interactive)
  (require 'embark)
  (require 'wgrep)
  (let* ((edit-command
          (pcase-let ((`(,type . ,candidates)
                       (run-hook-with-args-until-success 'embark-candidate-collectors)))
            (pcase type
              ('consult-grep #'wgrep-change-to-wgrep-mode)
              ('file #'wdired-change-to-wdired-mode)
              ('consult-location #'occur-edit-mode)
              (x (user-error "embark category %S doesn't support writable export" x)))))
         (embark-after-export-hook `(,@embark-after-export-hook ,edit-command)))
    (embark-export)))

;; Group grep results by file
(setq grep-use-headings t)

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
