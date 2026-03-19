;;; evil.el --- Evil mode and leader keybindings -*- lexical-binding: t; -*-

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil) ; required for evil-collection
  (setq evil-want-C-u-scroll t)
  (setq evil-undo-system 'undo-tree)
  :config
  (evil-mode 1)
  ;; In GUI frames, distinguish C-i from TAB so evil-jump-forward works
  ;; even in buffers with button maps (e.g. helpful).
  (when (display-graphic-p)
    (define-key input-decode-map [?\C-i] [C-i])
    (define-key evil-normal-state-map [C-i] #'evil-jump-forward)))

(use-package evil-collection
  :after evil
  :init
  (setq evil-collection-setup-minibuffer t)
  (setq evil-collection-magit-use-z-for-folds t)
  :config
  (evil-collection-init)
  (evil-set-initial-state 'shell-command-mode 'normal))

;; ys<motion><char> to add, cs<old><new> to change, ds<char> to delete, S in visual
(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

;; gcc to comment line, gc<motion> to comment region
(use-package evil-nerd-commenter
  :after evil
  :config
  (evil-define-key '(normal visual) 'global
    "gc" 'evilnc-comment-operator))

;; C-a / C-x to increment/decrement numbers
(use-package evil-numbers
  :after evil
  :config
  (evil-define-key '(normal visual) 'global
    (kbd "C-a") 'evil-numbers/inc-at-pt
    (kbd "C-x") 'evil-numbers/dec-at-pt
    (kbd "g C-a") 'evil-numbers/inc-at-pt-incremental
    (kbd "g C-x") 'evil-numbers/dec-at-pt-incremental))

;; s/S for 2-char search (like vim-sneak)
(use-package evil-snipe
  :after evil
  :custom
  (evil-snipe-scope 'visible)
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

;; gs prefix for label-based motions: gs s (2-char), gs / (timer), gs SPC (all windows)
(use-package avy
  :custom
  (avy-all-windows nil)
  (avy-all-windows-alt t)
  (avy-background t)
  (avy-single-candidate-jump nil))

(use-package evil-easymotion
  :after (evil avy)
  :config
  (evilem-default-keybindings "gs")
  (define-key evilem-map "s" #'evil-avy-goto-char-2)
  (define-key evilem-map "/" #'evil-avy-goto-char-timer)
  (define-key evilem-map " " (lambda () (interactive)
                               (let ((current-prefix-arg t))
                                 (call-interactively #'evil-avy-goto-char-timer))))
  (define-key evilem-map "a" (evilem-create #'evil-forward-arg))
  (define-key evilem-map "A" (evilem-create #'evil-backward-arg)))

(use-package undo-tree
  :config
  (global-undo-tree-mode)
  (setq undo-tree-history-directory-alist
        `(("." . ,(expand-file-name "undo-tree-hist" user-emacs-directory)))))

;; Mouse back/forward buttons
(global-set-key (kbd "<mouse-8>") #'evil-jump-backward)
(global-set-key (kbd "<mouse-9>") #'evil-jump-forward)

;; Error navigation
(evil-define-key 'motion 'global
  "]e" #'flymake-goto-next-error
  "[e" #'flymake-goto-prev-error)

;;;; Leader keybindings (SPC)

(use-package general
  :after evil
  :config
  (general-create-definer my/leader-def
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (general-create-definer my/local-leader-def
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC m"
    :non-normal-prefix "M-SPC m")

  (my/leader-def
    ""    '(nil :which-key "leader")
    "SPC" '(project-find-file :which-key "find file in project")
    ":"   '(execute-extended-command :which-key "M-x")
    "."   '(find-file :which-key "find file")
    ","   '(consult-buffer :which-key "switch buffer")
    "/"   '(consult-ripgrep :which-key "search project")
    "`"   '(evil-switch-to-windows-last-buffer :which-key "last buffer")
    "RET" '(bookmark-jump :which-key "bookmark jump")
    "'"   '(vertico-repeat :which-key "resume last search")
    ";"   '(pp-eval-expression :which-key "eval expression")
    "a"   '(embark-act :which-key "actions")
    "u"   '(universal-argument :which-key "universal argument")
    "x"   '(scratch-buffer :which-key "scratch buffer")
    "X"   '(org-capture :which-key "org capture")
    "A"   '((lambda () (interactive) (my/open-in-workspace "~/vault/" #'org-agenda-list "~/vault")) :which-key "agenda list")

    ;; Buffers
    "b"   '(:ignore t :which-key "buffer")
    "b b" '(consult-buffer :which-key "switch buffer")
    "b d" '(kill-current-buffer :which-key "kill buffer")
    "b k" '(kill-current-buffer :which-key "kill buffer")
    "b K" '(my/kill-all-buffers :which-key "kill all buffers")
    "b l" '(evil-switch-to-windows-last-buffer :which-key "last buffer")
    "b n" '(next-buffer :which-key "next buffer")
    "b p" '(previous-buffer :which-key "prev buffer")
    "b r" '(revert-buffer :which-key "revert buffer")
    "b s" '(save-buffer :which-key "save buffer")
    "b S" '(evil-write-all :which-key "save all buffers")
    "b N" '(evil-buffer-new :which-key "new empty buffer")
    "b m" '(bookmark-set :which-key "set bookmark")
    "b M" '(bookmark-delete :which-key "delete bookmark")
    "b O" '(my/kill-other-buffers :which-key "kill other buffers")
    "b ]" '(next-buffer :which-key "next buffer")
    "b [" '(previous-buffer :which-key "prev buffer")

    ;; Files
    "f"   '(:ignore t :which-key "file")
    "f f" '(find-file :which-key "find file")
    "f r" '(consult-recent-file :which-key "recent files")
    "f s" '(save-buffer :which-key "save")
    "f S" '(write-file :which-key "save as")
    "f D" '(my/delete-this-file :which-key "delete this file")
    "f R" '(my/rename-this-file :which-key "rename/move this file")
    "f u" '(my/sudo-find-file :which-key "sudo find file")
    "f U" '(my/sudo-this-file :which-key "sudo this file")
    "f y" '(my/yank-file-path :which-key "yank file path")
    "f Y" '(my/yank-file-path-relative :which-key "yank relative path")

    ;; Git
    "g"   '(:ignore t :which-key "git")
    "g g" '(magit-status :which-key "magit status")
    "g G" '(magit-status-here :which-key "magit status here")
    "g B" '(magit-blame :which-key "magit blame")
    "g /" '(magit-dispatch :which-key "magit dispatch")
    "g l" '(magit-log-buffer-file :which-key "magit buffer log")
    "g ]" '(diff-hl-next-hunk :which-key "next hunk")
    "g [" '(diff-hl-previous-hunk :which-key "prev hunk")
    "g s" '(diff-hl-stage-current-hunk :which-key "stage hunk")
    "g r" '(diff-hl-revert-hunk :which-key "revert hunk")

    ;; Code
    "c"   '(:ignore t :which-key "code")
    "c a" '(eglot-code-actions :which-key "code actions")
    "c d" '(xref-find-definitions :which-key "jump to definition")
    "c D" '(xref-find-references :which-key "jump to references")
    "c f" '(eglot-format :which-key "format buffer/region")
    "c i" '(eglot-find-implementation :which-key "find implementations")
    "c k" '(eldoc-doc-buffer :which-key "documentation")
    "c r" '(eglot-rename :which-key "rename")
    "c t" '(eglot-find-typeDefinition :which-key "find type definition")
    "c w" '(delete-trailing-whitespace :which-key "delete trailing whitespace")
    "c x" '(flymake-show-buffer-diagnostics :which-key "list diagnostics")

    ;; Help (inherit all C-h bindings from help-map)
    "h"   '(:keymap help-map :which-key "help")

    ;; Insert
    "i"   '(:ignore t :which-key "insert")
    "i s" '(yas-insert-snippet :which-key "snippet")
    "i e" '(insert-char :which-key "unicode")
    "i r" '(evil-show-registers :which-key "from register")

    ;; Notes/Org
    "n"   '(:ignore t :which-key "notes")
    "n a" '(org-agenda :which-key "org agenda")
    "n c" '(org-capture :which-key "org capture")
    "n l" '(org-store-link :which-key "store link")

    ;; Open
    "o"   '(:ignore t :which-key "open")
    "o a" '((lambda () (interactive) (my/open-in-workspace "~/vault/" #'org-agenda "~/vault")) :which-key "org agenda")
    "o m" '((lambda () (interactive) (my/open-in-workspace "~/mail/" #'mu4e "~/mail")) :which-key "mu4e")
    "o f" '(make-frame :which-key "new frame")
    "o -" '(dired-jump :which-key "dired")
    "o e" '((lambda () (interactive) (my/open-in-workspace "elfeed" #'elfeed)) :which-key "elfeed")
    "o c" '((lambda () (interactive) (my/open-in-workspace "~/calendar/" #'caledonia-agenda "~/calendar")) :which-key "caledonia")
    "o l" '(claude-code-ide-menu :which-key "claude code")
    "o t" '(vterm :which-key "terminal")

    ;; Project (inherit project-prefix-map, override d)
    "p"   '(:keymap project-prefix-map :which-key "project")
    "p d" '(project-forget-project :which-key "remove known project")

    ;; Quit
    "q"   '(:ignore t :which-key "quit/session")
    "q q" '(save-buffers-kill-terminal :which-key "quit")
    "q Q" '(evil-quit-all-with-error-code :which-key "quit without saving")
    "q K" '(save-buffers-kill-emacs :which-key "kill emacs (and daemon)")
    "q f" '(delete-frame :which-key "delete frame")
    "q F" '(my/kill-all-buffers :which-key "clear current frame")
    "q s" '(persp-save-state-to-file :which-key "save session")
    "q l" '(persp-load-state-from-file :which-key "restore session")
    "q r" '(restart-emacs :which-key "restart emacs")
    "q R" '(my/restart-and-restore :which-key "restart and restore")

    ;; Search
    "s"   '(:ignore t :which-key "search")
    "s s" '(consult-line :which-key "search buffer")
    "s b" '(consult-line-multi :which-key "search all buffers")
    "s d" '((lambda () (interactive) (consult-ripgrep default-directory)) :which-key "search cwd")
    "s p" '(consult-ripgrep :which-key "search project")
    "s i" '(consult-imenu :which-key "jump to symbol")
    "s m" '(consult-bookmark :which-key "jump to bookmark")
    "s r" '(evil-show-marks :which-key "jump to mark")
    "s S" '((lambda () (interactive) (consult-line (thing-at-point 'symbol))) :which-key "search symbol at point")
    "s f" '(locate :which-key "locate file")
    "s j" '(evil-show-jumps :which-key "jump list")
    "s u" '(undo-tree-visualize :which-key "undo history")

    ;; Toggle
    "t"   '(:ignore t :which-key "toggle")
    "t l" '(display-line-numbers-mode :which-key "line numbers")
    "t r" '(read-only-mode :which-key "read-only")
    "t s" '(flyspell-mode :which-key "spell checker")
    "t w" '(visual-line-mode :which-key "word wrap")
    "t F" '(toggle-frame-fullscreen :which-key "fullscreen")

    ;; Windows (inherit all C-w bindings from evil-window-map)
    "w"   '(:keymap evil-window-map :which-key "window")
    "w d" '(kill-buffer-and-window :which-key "kill buffer & window")
    "w w" '(ace-window :which-key "ace window")

    ;; Workspaces
    "TAB"     '(:ignore t :which-key "workspace")
    "TAB TAB" '(my/workspace-display :which-key "display workspaces")
    "TAB ."   '(persp-frame-switch :which-key "switch workspace")
    "TAB `"   '(my/workspace-switch-last :which-key "last workspace")
    "TAB n"   '(persp-frame-switch :which-key "new workspace")
    "TAB N"   '(persp-frame-switch :which-key "new named workspace")
    "TAB d"   '(my/kill-current-workspace :which-key "kill workspace")
    "TAB m"   '(my/workspace-move :which-key "move workspace")
    "TAB r"   '(persp-rename :which-key "rename workspace")
    "TAB ]"   '(persp-next :which-key "next workspace")
    "TAB ["   '(persp-prev :which-key "prev workspace")

    "W"   '(weekfile :which-key "weekfile"))

  ;; Remove C- duplicates from evil-window-map so C-h (help) works under SPC w
  (dolist (key '("\C-h" "\C-j" "\C-k" "\C-l" "\C-s" "\C-v"
                 "\C-n" "\C-p" "\C-o" "\C-r" "\C-c" "\C-f"
                 "\C-b" "\C-t" "\C-x" "\C-_" "\C-]"))
    (define-key evil-window-map key nil))

  (defun my/kill-other-buffers ()
    "Kill all buffers except the current one."
    (interactive)
    (mapc #'kill-buffer (delq (current-buffer) (buffer-list))))

  (defun my/sudo-find-file (file)
    "Open FILE with sudo via TRAMP."
    (interactive "FFind file (sudo): ")
    (find-file (concat "/sudo::" (expand-file-name file))))

  (defun my/sudo-this-file ()
    "Re-open the current file with sudo via TRAMP."
    (interactive)
    (find-file (concat "/sudo::" (or buffer-file-name (error "Buffer is not visiting a file")))))

  (defun my/kill-all-buffers ()
    "Kill all buffers."
    (interactive)
    (mapc #'kill-buffer (buffer-list)))

  (defun my/yank-file-path ()
    "Copy the current buffer's file path to the kill ring."
    (interactive)
    (if-let ((path (or buffer-file-name default-directory)))
        (progn (kill-new path) (message "%s" path))
      (error "Buffer is not visiting a file")))

  (defun my/yank-file-path-relative ()
    "Copy the current buffer's file path relative to project root."
    (interactive)
    (if-let ((path (or buffer-file-name default-directory)))
        (let* ((root (or (when-let ((proj (project-current))) (project-root proj))
                         default-directory))
               (rel (file-relative-name path root)))
          (kill-new rel)
          (message "%s" rel))
      (error "Buffer is not visiting a file")))

  (defun my/delete-this-file ()
    "Delete the current file and kill its buffer."
    (interactive)
    (let ((file (or buffer-file-name (error "Buffer is not visiting a file"))))
      (when (y-or-n-p (format "Delete %s? " file))
        (delete-file file)
        (kill-buffer))))

  (defun my/rename-this-file (new-name)
    "Rename the current file to NEW-NAME."
    (interactive (list (read-file-name "Rename to: " nil nil nil
                                       (file-name-nondirectory buffer-file-name))))
    (let ((old (or buffer-file-name (error "Buffer is not visiting a file"))))
      (rename-file old new-name 1)
      (set-visited-file-name new-name t t)))

  (defun weekfile ()
    "Open an Org file named YYYY-MM-DD.org for the Monday of the current week."
    (interactive)
    (let* ((current-time (current-time))
           (dow (nth 6 (decode-time current-time)))
           (offset (if (= dow 0) -6 (- 1 dow)))
           (monday-time (time-subtract current-time (days-to-time (- offset))))
           (formatted-date (format-time-string "%Y-%m-%d" monday-time))
           (filename (expand-file-name (concat formatted-date ".org")
                                       "~/projects/website/static/")))
      (find-file filename))))

;;; evil.el ends here
