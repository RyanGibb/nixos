(require 'evil)
(evil-mode 1)

(define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
(define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
(global-set-key (kbd "C-x u") 'universal-argument)

(define-key evil-normal-state-map (kbd "C-i") 'evil-jump-forward)
(define-key evil-visual-state-map (kbd "C-i") 'evil-jump-forward)

(define-key evil-normal-state-map (kbd "C-o") 'evil-jump-backward)
(define-key evil-visual-state-map (kbd "C-o") 'evil-jump-backward)

(global-undo-tree-mode)
(evil-set-undo-system 'undo-tree)
(setq undo-tree-visualizer-diff t)
(setq undo-tree-auto-save-history t)
(setq undo-tree-history-directory-alist
  `(("." . ,(expand-file-name "undo-tree-history" user-emacs-directory))))

(require 'evil-leader)
(global-evil-leader-mode)
(evil-leader/set-leader "<SPC>")
(evil-leader/set-key
  "w" 'save-buffer)
(evil-leader/set-key
  "u" 'undo-tree-visualize)

;; (setq interprogram-cut-function nil)
;; (setq interprogram-paste-function nil)

(load-theme 'gruvbox-dark-medium t)
(set-frame-parameter nil 'alpha-background 70)
(add-to-list 'default-frame-alist '(alpha-background . 70))
;; (menu-bar-mode -1)
;; (tool-bar-mode -1)
;; (scroll-bar-mode -1)
(set-face-attribute 'default nil :height 110)

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(set-face-attribute 'line-number nil
                    :foreground "gray"
                    :background nil)
(set-face-attribute 'line-number-current-line nil
                    :foreground "orange"
                    :background nil)

(setq savehist-file "~/.emacs.d/savehist")

(savehist-mode 1)
(setq savehist-additional-variables
      '(command-history
        search-ring
        regexp-search-ring
        kill-ring))
(setq history-length 10000)
(setq savehist-save-minibuffer-history t)

(desktop-save-mode 1)
(setq desktop-dirname "~/.emacs.d/desktop/")
(setq desktop-save t)
(add-hook 'emacs-startup-hook 'desktop-read)

(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))
