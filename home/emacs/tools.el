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

  ;; M-1 through M-9 to switch workspace by number, M-0 for 10th
  (dotimes (i 10)
    (global-set-key (kbd (format "M-%d" (mod (1+ i) 10)))
                    `(lambda () (interactive)
                       (let* ((names (cl-remove persp-nil-name persp-names-cache :count 1))
                              (dest (nth ,i names)))
                         (when dest
                           (my/workspace-switch dest)
                           (my/workspace-display))))))

  ;; M-, / M-. to cycle workspaces (overrides xref-go-back / evil-repeat-pop-next)
  (with-eval-after-load 'evil
    (dolist (map (list evil-normal-state-map evil-insert-state-map
                       evil-visual-state-map evil-motion-state-map))
      (define-key map (kbd "M-,")
                  (lambda () (interactive) (persp-prev) (my/workspace-display)))
      (define-key map (kbd "M-.")
                  (lambda () (interactive) (persp-next) (my/workspace-display)))))

  (defun my/workspace-switch (name)
    "Switch to workspace NAME, tracking the previous workspace."
    (let ((old-name (safe-persp-name (get-current-persp))))
      (unless (equal old-name name)
        (setq my/workspace--last old-name)
        (persp-frame-switch name))))

  ;; Abort active minibuffer when switching workspaces to prevent stale prompts
  (advice-add 'persp-frame-switch :around
              (lambda (orig-fn &rest args)
                (if (> (minibuffer-depth) 0)
                    (progn
                      (run-at-time 0 nil (lambda () (apply orig-fn args)))
                      (abort-recursive-edit))
                  (apply orig-fn args))))

  (defun my/open-in-workspace (name fn &optional dir)
    "Switch to workspace NAME and call FN.
If DIR is non-nil, set `default-directory' to DIR in both the calling
buffer and any new buffer created by FN."
    (my/workspace-switch name)
    (let ((default-directory (if dir (expand-file-name dir) default-directory)))
      (funcall fn)
      (when dir
        (setq default-directory (expand-file-name dir))
        (set-persp-parameter 'project-dir (expand-file-name dir)))))

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
                       (name (if-let ((host (file-remote-p dir 'host)))
                                 (format "%s:%s" host (file-remote-p dir 'localname))
                               dir)))
                  (if (persp-with-name-exists-p name)
                      (my/workspace-switch name)
                    (my/workspace-switch name)
                    (funcall orig-fn dir))
                  (set-persp-parameter 'project-dir dir))))

  ;; Make project.el use the workspace's project dir
  (advice-add 'project-current :around
              (lambda (orig-fn &rest args)
                (let ((persp-dir (persp-parameter 'project-dir)))
                  (if persp-dir
                      (let ((default-directory persp-dir))
                        (apply orig-fn args))
                    (apply orig-fn args)))))

  ;; Show scratch instead of a buffer from another workspace when last buffer is killed
  (defun my/persp-show-scratch-on-last-kill ()
    (let* ((persp (get-current-persp))
           (persp-bufs (when persp (persp-buffers persp)))
           (bufs (cl-remove (current-buffer) persp-bufs)))
      (when (and persp persp-bufs (null bufs))
        (let ((win (selected-window)))
          (run-at-time 0 nil
                       (lambda ()
                         (when (window-live-p win)
                           (set-window-buffer win (get-scratch-buffer-create)))))))))
  (add-hook 'kill-buffer-hook #'my/persp-show-scratch-on-last-kill)

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

  (defun my/workspace-short-name (name)
    "Return a short display name for workspace NAME."
    (let ((base (file-name-nondirectory (directory-file-name name))))
      (if (string-match "\\`\\([^:]+\\):" name)
          (format "%s@%s" base (match-string 1 name))
        base)))

  (defun my/workspace-move (n)
    "Move the current workspace to position N (1-indexed)."
    (interactive "nMove to position: ")
    (let* ((names (cl-remove persp-nil-name persp-names-cache :count 1))
           (current (safe-persp-name (get-current-persp)))
           (idx (1- n)))
      (when (or (< idx 0) (>= idx (length names)))
        (user-error "Position %d out of range (1-%d)" n (length names)))
      (setq names (cl-remove current names :test #'equal :count 1))
      (setq persp-names-cache
            (cons persp-nil-name
                  (append (cl-subseq names 0 idx)
                          (list current)
                          (cl-subseq names idx))))
      (my/workspace-display)))

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
                    (propertize (format " [%d] %s " i (my/workspace-short-name name))
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
  (magit-display-buffer-function #'my/magit-display-buffer-fullframe-status)
  ;; Disable magit's window config save/restore — set-window-configuration is a
  ;; legacy C function that doesn't handle side windows correctly, mangling
  ;; their parameters (e.g. no-delete-other-windows) and sizes on restore.
  ;; See https://github.com/magit/magit/issues/4871
  (magit-pre-display-buffer-hook nil)
  (magit-bury-buffer-function #'my/magit-bury-buffer)
  :config
  ;; magit-display-buffer-fullframe-status-v1 uses delete-other-windows which
  ;; interacts badly with side windows:
  ;; - display-buffer-same-window can put magit IN the side window
  ;; - delete-other-windows can destroy side windows whose
  ;;   no-delete-other-windows parameter was lost after set-window-configuration
  ;; This version saves the full window layout (including side windows) via
  ;; window-state-get, then goes fullframe. On quit, it restores everything.
  (defvar my/magit--saved-window-state nil)

  (defun my/magit-display-buffer-fullframe-status (buffer)
    (if (eq (buffer-local-value 'major-mode buffer) 'magit-status-mode)
        (let ((win (cl-find-if-not
                    (lambda (w) (window-parameter w 'window-side))
                    (window-list))))
          (setq my/magit--saved-window-state
                (window-state-get (frame-root-window)))
          (let ((target (or win (selected-window))))
            (window--display-buffer buffer target 'reuse)
            (set-window-dedicated-p target t)
            (dolist (w (window-list))
              (unless (eq w target)
                (delete-window w)))
            (set-window-dedicated-p target nil)
            target))
      (magit-display-buffer-traditional buffer)))

  (defun my/magit-bury-buffer (_window)
    (if my/magit--saved-window-state
        (progn
          (window-state-put my/magit--saved-window-state (frame-root-window) t)
          (setq my/magit--saved-window-state nil))
      (switch-to-prev-buffer)))

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
  :custom
  ;; Use display-buffer so display-buffer-alist rules are respected.
  (helpful-switch-buffer-function
   (lambda (buf) (select-window (display-buffer buf))))
  :config
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key] #'helpful-key)
  ;; Restore helpful's TAB binding but as [tab] so it doesn't shadow C-i.
  (define-key helpful-mode-map [?\t] nil)
  (define-key helpful-mode-map [tab] #'forward-button)
  ;; q kills the helpful buffer. If there's a previous helpful buffer in the
  ;; window, show it. Otherwise close the window.
  (evil-collection-define-key 'normal 'helpful-mode-map
    "q" (lambda () (interactive)
          (let* ((win (selected-window))
                 (buf (current-buffer))
                 (prev (cl-find-if
                        (lambda (e)
                          (and (not (eq (car e) buf))
                               (buffer-live-p (car e))
                               (with-current-buffer (car e)
                                 (derived-mode-p 'helpful-mode))))
                        (window-prev-buffers win))))
            (if prev
                (progn
                  (set-window-buffer win (car prev))
                  (kill-buffer buf))
              (kill-buffer-and-window)))))
  ;; Allow evil jump list to track helpful buffers (they have no file so
  ;; evil ignores them by default).
  (setq evil--jumps-buffer-targets
        (concat "\\*\\(new\\|scratch\\|helpful \\)"))
  ;; Record evil jump so C-o works between helpful pages.
  (advice-add 'helpful--update-and-switch-buffer :around
              (lambda (orig-fn &rest args)
                (let ((old-buf (current-buffer))
                      (old-pos (point)))
                  (apply orig-fn args)
                  (save-current-buffer
                    (set-buffer old-buf)
                    (save-excursion
                      (goto-char old-pos)
                      (evil--jumps-push))))))
  ;; Open source links in the main window, not a new split.
  ;; helpful--navigate calls find-file-other-window by default.
  (advice-add 'helpful--navigate :override
              (lambda (button)
                (let ((path (substring-no-properties (button-get button 'path)))
                      (pos (get-text-property button 'position
                                              (marker-buffer button))))
                  (find-file path)
                  (when pos (goto-char pos))))))

;;;; Popup windows

(dolist (rule '(("\\*\\(?:[Hh]elp\\|helpful\\|Apropos\\).*"
                 (display-buffer-reuse-mode-window display-buffer-pop-up-window)
                 (mode helpful-mode help-mode))
                ("\\*\\(?:[Cc]ompil\\(?:ation\\|e-Log\\)\\|Warnings\\|Messages\\)\\*"
                 (display-buffer-in-side-window)
                 (side . bottom) (slot . -1) (window-height . 0.3))))
  (add-to-list 'display-buffer-alist rule))

;;;; Eglot (LSP)

(defun my/eldoc-help-at-point ()
  "Show eldoc documentation buffer, auto-dismissing on cursor movement.
Second press focuses the documentation window instead."
  (interactive)
  (let* ((buf (get-buffer "*eldoc*"))
         (win (and buf (get-buffer-window buf))))
    (if win
        (select-window win)
      (let ((eldoc-idle-delay 0))
        (eldoc-print-current-symbol-info))
      (eldoc-doc-buffer t)
      (when-let* ((buf (get-buffer "*eldoc*"))
                  (win (get-buffer-window buf)))
        (let ((source-window (selected-window)))
          (let ((skip t))
            (letrec ((dismiss (lambda ()
                                (if skip
                                    (setq skip nil)
                                  (cond
                                   ((eq this-command #'my/eldoc-help-at-point) nil)
                                   ((not (eq (selected-window) source-window)) nil)
                                   (t (when-let* ((w (get-buffer-window buf)))
                                        (delete-window w))
                                      (remove-hook 'post-command-hook dismiss)))))))
              (add-hook 'post-command-hook dismiss))))))))

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

;;;; Calendar

(use-package caledonia
  :commands (caledonia-list caledonia-search caledonia-query
             caledonia-add-event caledonia-edit-event caledonia-delete-event
             caledonia-agenda))

(use-package caledonia-evil
  :after (caledonia evil))

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
    (kbd "C-S-v") #'vterm-yank
    (kbd "C-<escape>") (lambda () (interactive)
                         (when vterm--term
                           (vterm-send-key "<escape>"))))
  ;; vterm--self-insert-meta mishandles M-RET (sends C-M-m instead of ESC RET)
  (define-key vterm-mode-map (kbd "M-RET")
              (lambda () (interactive)
                (when vterm--term
                  (process-send-string vterm--process "\e\C-m"))))
  ;; Let M-<num> workspace and M-h/j/k/l window bindings through
  (dotimes (i 9)
    (define-key vterm-mode-map (kbd (format "M-%d" (1+ i))) nil))
  (dolist (key '("M-h" "M-j" "M-k" "M-l"))
    (define-key vterm-mode-map (kbd key) nil))
)

;;;; BibTeX

(use-package bibtex
  :custom
  (bibtex-text-indentation 17)
  (bibtex-field-indentation 2)
  (bibtex-contline-indentation 17)
  (bibtex-align-at-equal-sign nil)
  (bibtex-entry-format '(opts-or-alts required-fields)))

;;; tools.el ends here
