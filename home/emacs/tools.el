;;; tools.el --- Development tools -*- lexical-binding: t; -*-

;;;; Workspaces

(use-package persp-mode
  :custom
  (persp-auto-resume-time -1)
  (persp-nil-hidden t)
  (persp-set-last-persp-for-new-frames t)
  (persp-switch-to-added-buffer nil)
  (persp-autokill-buffer-on-remove 'kill-weak)
  :config
  ;; Track last workspace for switching back
  (defvar my/workspace--last nil)

  ;; M-1 through M-9 to switch workspace by number
  (dotimes (i 9)
    (global-set-key (kbd (format "M-%d" (1+ i)))
                    `(lambda () (interactive)
                       (let* ((names (cl-remove persp-nil-name persp-names-cache :count 1))
                              (dest (nth ,i names)))
                         (when dest
                           (my/workspace-switch dest))))))

  (defun my/workspace-switch (name)
    "Switch to workspace NAME, tracking the previous workspace."
    (let ((old-name (safe-persp-name (get-current-persp))))
      (unless (equal old-name name)
        (setq my/workspace--last old-name)
        (persp-frame-switch name))))

  (defun my/open-in-workspace (name fn)
    "Switch to workspace NAME and call FN."
    (my/workspace-switch name)
    (funcall fn))

  (defun my/workspace-switch-last ()
    "Switch to the last workspace."
    (interactive)
    (if (and my/workspace--last
             (persp-get-by-name my/workspace--last))
        (my/workspace-switch my/workspace--last)
      (user-error "No previous workspace")))

  ;; Create/switch workspace when switching projects
  (advice-add 'project-switch-project :around
              (lambda (orig-fn &optional dir)
                (let* ((dir (or dir (project-prompt-project-dir)))
                       (name (file-name-nondirectory (directory-file-name dir))))
                  (my/workspace-switch name)
                  (funcall orig-fn dir))))

  (defun my/kill-current-workspace ()
    "Kill the current workspace."
    (interactive)
    (let* ((names (cl-remove persp-nil-name persp-names-cache :count 1))
           (current (safe-persp-name (get-current-persp))))
      (if (cdr names)
          (persp-kill current)
        (user-error "Can't delete last workspace"))))

  (defvar my/persp-restore-flag
    (expand-file-name "persp-restore" user-emacs-directory))

  (defun my/persp-init-once ()
    "Initialize persp-mode. In daemon mode, called after first frame."
    (remove-hook 'server-after-make-frame-hook #'my/persp-init-once)
    (persp-mode 1)
    (when (file-exists-p my/persp-restore-flag)
      (delete-file my/persp-restore-flag)
      (persp-load-state-from-file)))

  ;; In daemon mode, defer persp-mode until a frame exists
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'my/persp-init-once)
    (my/persp-init-once))

  (defun my/restart-and-restore ()
    "Save the current session and restart Emacs."
    (interactive)
    (persp-save-state-to-file)
    (write-region "" nil my/persp-restore-flag)
    (restart-emacs))

  (defun my/workspace-display ()
    "Display a list of workspaces in the echo area."
    (interactive)
    (let* ((names (cl-remove persp-nil-name persp-names-cache :count 1))
           (current (safe-persp-name (get-current-persp)))
           (message-log-max nil))
      (message "%s"
               (mapconcat
                (lambda (name)
                  (let ((i (1+ (cl-position name names :test #'equal))))
                    (propertize (format " [%d] %s " i name)
                                'face (if (equal name current)
                                          'highlight
                                        'default))))
                names " ")))))

;;;; Code folding

(use-package hideshow
  :hook (prog-mode . hs-minor-mode))

;;;; Git gutter

(use-package diff-hl
  :custom
  (diff-hl-show-staged-changes nil)
  :config
  (global-diff-hl-mode)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

;;;; Direnv

(use-package envrc
  :hook (after-init . envrc-global-mode)
  :config
  ;; Move envrc from after-change-major-mode-hook (runs after mode hooks)
  ;; to change-major-mode-after-body-hook (runs before mode hooks), so
  ;; eglot-ensure on mode hooks sees the direnv environment.
  (add-hook 'envrc-global-mode-hook
            (lambda ()
              (let ((fn #'envrc-global-mode-enable-in-buffer))
                (if (not envrc-global-mode)
                    (remove-hook 'change-major-mode-after-body-hook fn)
                  (remove-hook 'after-change-major-mode-hook fn)
                  (add-hook 'change-major-mode-after-body-hook fn 100))))))

;;;; Spell checking

(use-package flyspell
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))

;;;; Magit

(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  :config
  (defun my/magit-commit-update ()
    "Create a commit with the message \"update\"."
    (interactive)
    (magit-commit-create '("-m" "update")))
  (transient-append-suffix 'magit-commit "c"
    '("u" "Update" my/magit-commit-update)))

;;;; PDF

(use-package pdf-tools
  :demand t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :hook (pdf-view-mode . (lambda () (display-line-numbers-mode -1)))
  :custom
  (pdf-view-display-size 'fit-page)
  :config
  (pdf-tools-install-noverify)

  (defun my/pdf-view-fit-window-to-width ()
    "Resize the current window to match the width of the PDF."
    (interactive)
    (when (eq major-mode 'pdf-view-mode)
      (let* ((page-size (pdf-info-pagesize (pdf-view-current-page)))
             (page-aspect (/ (float (car page-size)) (cdr page-size)))
             (win-height-px (* (window-body-height) (frame-char-height)))
             (ideal-width-px (* win-height-px page-aspect))
             (desired-cols (round (/ ideal-width-px (float (frame-char-width)))))
             (delta (- desired-cols (window-width))))
        (ignore-errors (window-resize (selected-window) delta t)))))

  (defvar-local my/pdf-initial-fit-done nil)
  (add-hook 'pdf-view-after-change-page-hook
            (lambda ()
              (unless my/pdf-initial-fit-done
                (setq my/pdf-initial-fit-done t)
                (my/pdf-view-fit-window-to-width)
                (pdf-view-redisplay)))))

;;;; Help

(use-package helpful
  :config
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key] #'helpful-key))

;;;; Eglot (LSP)

(add-to-list 'display-buffer-alist
             '("\\*eldoc\\*"
               (display-buffer-in-side-window)
               (side . bottom) (slot . 1)
               (window-height . shrink-window-if-larger-than-buffer)))

(defun my/eldoc-help-at-point ()
  "Show eldoc documentation buffer, auto-dismissing on cursor movement.
Second press focuses the documentation window instead."
  (interactive)
  (let* ((buf (get-buffer "*eldoc*"))
         (win (and buf (get-buffer-window buf))))
    (if win
        (select-window win)
      (eldoc-doc-buffer t)
      (when-let* ((buf (get-buffer "*eldoc*"))
                  (win (get-buffer-window buf)))
        (let ((source-window (selected-window)))
          (letrec ((dismiss (lambda ()
                              (cond
                               ((eq this-command #'my/eldoc-help-at-point) nil)
                               ((not (eq (selected-window) source-window)) nil)
                               (t (when-let* ((w (get-buffer-window buf)))
                                    (quit-window nil w))
                                  (remove-hook 'post-command-hook dismiss))))))
            (run-with-timer 0 nil
                            (lambda ()
                              (add-hook 'post-command-hook dismiss)))))))))

(use-package eglot
  :hook ((neocaml-mode neocaml-interface-mode nix-mode) . eglot-ensure)
  :config
  (evil-collection-define-key 'normal 'eglot-mode-map
    "K" #'my/eldoc-help-at-point)
  ;; Make eglot non-exclusive so other capfs (yasnippet, cape) can contribute
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  ;; Only needed for modes eglot doesn't have a default server for
  (add-to-list 'eglot-server-programs
               '((neocaml-mode neocaml-interface-mode) . ("ocamllsp")))
  (add-to-list 'eglot-server-programs
               '(nix-mode . ("nixd"))))

;;;; RSS

(use-package elfeed
  :commands elfeed
  :config
  (defun my/elfeed-quit ()
    "Quit elfeed and kill the workspace."
    (interactive)
    (elfeed-db-save)
    (kill-buffer)
    (when (persp-with-name-exists-p "elfeed")
      (my/kill-current-workspace)))
  (evil-define-key 'normal elfeed-search-mode-map
    "q" #'my/elfeed-quit))

(use-package elfeed-org
  :after elfeed
  :config
  (setq rmh-elfeed-org-files (list (expand-file-name "elfeed.org" org-directory)))
  (elfeed-org))

;;;; Debugger

(use-package dape
  :commands dape
  :config
  (let ((cfg (alist-get 'ocamlearlybird dape-configs)))
    (when cfg
      (plist-put cfg 'modes '(neocaml-mode neocaml-interface-mode)))))

;;;; Terminal

(use-package vterm
  :commands vterm
  :config
  ;; Hide evil's cursor in insert mode so only vterm's terminal cursor shows
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local evil-normal-state-cursor 'box)
              (setq-local evil-insert-state-cursor '(nil))))
  (evil-collection-define-key 'insert 'vterm-mode-map
    (kbd "C-c") #'vterm--self-insert
    (kbd "C-S-v") #'vterm-yank)
  ;; vterm--self-insert-meta mishandles M-RET (sends C-M-m instead of ESC RET)
  (define-key vterm-mode-map (kbd "M-RET")
              (lambda () (interactive)
                (when vterm--term
                  (process-send-string vterm--process "\e\C-m")))))

;;;; Claude Code

(defun my/mcp-user-buffers ()
  "Get visible non-claude-code buffers, ordered by most recently accessed."
  (cl-remove-if (lambda (buf)
                  (or (string-match-p "\\*claude-code" (buffer-name buf))
                      (minibufferp buf)
                      (not (get-buffer-window buf))))
                (buffer-list)))

(defun my/mcp-list-buffers ()
  "List all visible user buffers with index, file path, and cursor position."
  (let ((bufs (my/mcp-user-buffers))
        (i 0))
    (if bufs
        (mapconcat (lambda (buf)
                     (with-current-buffer buf
                       (prog1 (format "[%d] %s (line %d/%d)"
                                      i
                                      (or buffer-file-name (buffer-name))
                                      (line-number-at-pos)
                                      (count-lines (point-min) (point-max)))
                         (cl-incf i))))
                   bufs "\n")
      "No user buffers found")))

(defun my/mcp-read-buffer (&optional index)
  "Read the contents of a visible buffer in Emacs.
INDEX selects which buffer (0 = most recent, default)."
  (let* ((bufs (my/mcp-user-buffers))
         (buf (nth (or index 0) bufs)))
    (if buf
        (with-current-buffer buf
          (let ((file (or buffer-file-name (buffer-name)))
                (content (buffer-substring-no-properties (point-min) (point-max)))
                (line (line-number-at-pos))
                (total-lines (count-lines (point-min) (point-max))))
            (format "File: %s\nCursor at line: %d\nTotal lines: %d\n\n%s"
                    file line total-lines content)))
      "No user buffer found")))

(defun my/mcp-edit-buffer (old-text new-text &optional index)
  "Replace OLD-TEXT with NEW-TEXT in a visible buffer.
INDEX selects which buffer (0 = most recent, default)."
  (let* ((bufs (my/mcp-user-buffers))
         (buf (nth (or index 0) bufs)))
    (if buf
        (with-current-buffer buf
          (let ((file (or buffer-file-name (buffer-name))))
            (save-excursion
              (goto-char (point-min))
              (if (search-forward old-text nil t)
                  (progn
                    (replace-match new-text t t)
                    (format "Replaced text in %s" file))
                (format "Text not found in %s" file)))))
      "No user buffer found")))

(use-package claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :custom
  (claude-code-ide-terminal-backend 'vterm)
  :config
  (claude-code-ide-emacs-tools-setup)

  (claude-code-ide-make-tool
   :function #'my/mcp-list-buffers
   :name "list-buffers"
   :description "List all visible user buffers (excluding claude-code), ordered by most recently accessed. Returns index, file path, cursor line, and total lines for each. Use the index with read-current-buffer and edit-current-buffer."
   :args nil)

  (claude-code-ide-make-tool
   :function #'my/mcp-read-buffer
   :name "read-current-buffer"
   :description "Read the full contents of the currently active buffer in Emacs. Returns the file path, cursor position, total lines, and buffer contents."
   :args '((:name "index"
                  :type integer
                  :description "Buffer index from list-buffers (0 = most recent, default)"
                  :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-edit-buffer
   :name "edit-current-buffer"
   :description "Edit the currently active buffer by replacing old text with new text. Use read-current-buffer first to see the contents."
   :args '((:name "old_text"
                  :type string
                  :description "The exact text to find and replace")
           (:name "new_text"
                  :type string
                  :description "The replacement text")
           (:name "index"
                  :type integer
                  :description "Buffer index from list-buffers (0 = most recent, default)"
                  :optional t))))

;;; tools.el ends here
