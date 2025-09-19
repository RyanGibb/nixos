;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Ryan Gibb"
      user-mail-address "ryan@freumh.org")

(load! "appearance.el")
(load! "mu4e.el")
(load! "ledger.el")
(load! "org.el")

;; (setq which-key-idle-delay 0.1)

;; https://github.com/doomemacs/doomemacs/issues/8101
;; (map! :m "TAB" #'evil-jump-forward)
;; (after! evil-org
;;         (setq evil-want-C-i-jump nil)
;; )

;; https://github.com/doomemacs/doomemacs/issues/3151
(map! :map evil-ex-completion-map
      "C-f" #'evil-command-window
      :map evil-ex-search-keymap
      "C-f" #'evil-command-window)
(setq evil-collection-setup-minibuffer t)

(global-set-key (kbd "<mouse-8>") #'evil-jump-backward)
(global-set-key (kbd "<mouse-9>") #'evil-jump-forward)

;; https://evil.readthedocs.io/en/latest/faq.html#underscore-is-not-a-word-character
(add-hook 'c-mode-common-hook #'(lambda () (modify-syntax-entry ?_ "w")))
(add-hook 'rust-mode-hook #'(lambda () (modify-syntax-entry ?_ "w")))
(add-hook 'emacs-lisp-mode-hook #'(lambda () (modify-syntax-entry ?- "w")))
(add-hook 'conf-toml-mode-hook #'(lambda () (modify-syntax-entry ?_ "w")))

(after! lsp-mode
  ;; https://github.com/emacs-lsp/lsp-mode/issues/713#issuecomment-985653873
  (advice-add 'lsp--get-ignored-regexes-for-workspace-root
              :around (lambda (fn workspace-root)
                        (let* ((ignored-things (funcall fn workspace-root))
                               (ignored-files-regex-list (car ignored-things))
                               (ignored-directories-regex-list (cadr ignored-things))
                               (cmd (format "cd '%s'; git clean --dry-run -Xd | cut -d' ' -f3" workspace-root))
                               (gitignored-things (split-string (shell-command-to-string cmd) "\n" t))
                               (gitignored-files (seq-remove (lambda (line) (string-match "[/\\\\]\\'" line)) gitignored-things))
                               (gitignored-directories (seq-filter (lambda (line) (string-match "[/\\\\]\\'" line)) gitignored-things))
                               (gitignored-files-regex-list
                                (mapcar (lambda (file) (concat "[/\\\\]" (regexp-quote file) "\\'"))
                                        gitignored-files))
                               (gitignored-directories-regex-list
                                (mapcar (lambda (directory)
                                          (concat "[/\\\\]"
                                                  (regexp-quote (replace-regexp-in-string "[/\\\\]\\'" "" directory))
                                                  "\\'"))
                                        gitignored-directories)))
                          (list
                           (append ignored-files-regex-list gitignored-files-regex-list)
                           (append ignored-directories-regex-list gitignored-directories-regex-list))))))

(setq! +latex-viewers '(pdf-tools evince))

;; auto build LaTeX on save
(add-hook 'LaTeX-mode-hook
          (lambda ()
            (add-hook 'after-save-hook
                      (lambda ()
                        (TeX-command TeX-command-default 'TeX-master-file -1))
                      nil t)))

(defun my/pdf-resize-window-to-width ()
  "Resize the current window to match the width of the PDF in `pdf-view-mode`."
  (interactive)
  (when (eq major-mode 'pdf-view-mode)
    (let* ((pdf-px-width (car (pdf-view-image-size))) ; PDF width in pixels
           (char-width   (frame-char-width))          ; One character width in pixels
           ;; Convert PDF pixel width to 'columns' in Emacs
           (desired-cols (round (/ (float pdf-px-width) (float char-width))))
           (current-cols (window-width))
           ;; The difference between desired and current
           (delta (- desired-cols current-cols)))
      ;; Resize the window horizontally by DELTA columns
      (window-resize (selected-window) delta t))))

(defun =caledonia ()
  "Start calendar client."
  (interactive)
  (require 'caledonia)
  (require 'caledonia-evil)
  (if (modulep! :ui workspaces)
      (+workspace-switch "*caledonia*" t))
  (caledonia-list))

(setq! caledonia-executable "/home/ryan/.opam/default/bin/caled")

;; They're real to me https://github.com/doomemacs/doomemacs/issues/2891
(add-hook 'messages-buffer-mode-hook #'doom-mark-buffer-as-real-h)
(add-hook 'org-agenda-mode-hook #'doom-mark-buffer-as-real-h)
(add-hook 'caledonia-mode-hook #'doom-mark-buffer-as-real-h)
(add-hook 'eww-mode-hook #'doom-mark-buffer-as-real-h)

(map! :leader
      :desc "Async cmd in the project root" "S" #'projectile-run-async-shell-command-in-root)
