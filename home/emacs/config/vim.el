; https://github.com/emacs-evil/evil-collection
(setq evil-want-integration t)
(setq evil-want-keybinding nil)

(require 'evil)
(evil-mode 1)

(define-key evil-normal-state-map (kbd "C-u") 'evil-scroll-up)
(define-key evil-visual-state-map (kbd "C-u") 'evil-scroll-up)
(global-set-key (kbd "C-x u") 'universal-argument)

(add-hook 'minibuffer-setup-hook 'evil-insert-state)

(setq evil-want-empty-ex-last-command nil)

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
(evil-leader/set-key
  "fb" 'helm-buffers-list)

(require 'evil-collection)
(evil-collection-init)

; (require 'vertico)
; (vertico-mode)
; 
; (require 'consult)
; (global-set-key (kbd "C-s") 'consult-line)
; (define-key minibuffer-local-map (kbd "C-r") 'consult-history)
; 
; (require 'orderless)
; (setq completion-styles '(orderless)
;       completion-category-defaults nil
;       completion-category-overrides '((file (styles partial-completion))))
; 
; (evil-leader/set-key
;   "ff" 'consult-find
;   "fg" 'consult-ripgrep)
; 
; (require 'posframe)
; 
; (require 'vertico-posframe)
; (setq vertico-posframe-poshandler 'posframe-poshandler-frame-center)
; (vertico-posframe-mode 1)
; 
; (setq consult-async-min-input 1)
; 
; (define-key minibuffer-local-map (kbd "C-w") 'backward-kill-word)

; esc quits
; https://stackoverflow.com/questions/8483182/evil-mode-best-practice
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)

(require 'evil-org)
(add-hook 'org-mode-hook 'evil-org-mode)
(evil-org-set-key-theme '(navigation insert textobjects additional calendar))
(require 'evil-org-agenda)
(evil-org-agenda-set-keys)
