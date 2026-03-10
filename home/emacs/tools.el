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
                       (name (if-let ((host (file-remote-p dir 'host)))
                                 (format "%s:%s" host (file-remote-p dir 'localname))
                               dir)))
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

;;;; Calendar

(use-package caledonia
  :commands (caledonia-list caledonia-search caledonia-query))

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
    (kbd "C-S-v") #'vterm-yank)
  ;; vterm--self-insert-meta mishandles M-RET (sends C-M-m instead of ESC RET)
  (define-key vterm-mode-map (kbd "M-RET")
              (lambda () (interactive)
                (when vterm--term
                  (process-send-string vterm--process "\e\C-m"))))
  ;; Let M-<num> workspace bindings through in normal mode
  (dotimes (i 9)
    (define-key vterm-mode-map (kbd (format "M-%d" (1+ i))) nil)))

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

(defun my/mcp-git-repo-root (path)
  "Return the git repo root for PATH, or signal an error."
  (require 'magit)
  (let ((dir (if (file-directory-p path) path (file-name-directory path))))
    (or (magit-toplevel dir)
        (error "Not inside a Git repository: %s" path))))

(defun my/mcp-git--format-files (files)
  "Format a file list: one per line, or \"(none)\"."
  (if files
      (format "(%d) %s" (length files) (string-join files "\n  "))
    "(none)"))

(defun my/mcp-git-status (path)
  "Show git status for the repo containing PATH.
PATH is an absolute file or directory path."
  (let ((default-directory (my/mcp-git-repo-root path)))
    (format "Branch: %s\nStaged: %s\nUnstaged: %s\nUntracked: %s"
            (or (magit-get-current-branch) "(detached)")
            (my/mcp-git--format-files (magit-staged-files))
            (my/mcp-git--format-files (magit-unstaged-files))
            (my/mcp-git--format-files (magit-untracked-files)))))

(defun my/mcp-git-diff (file &optional staged)
  "Show diff with numbered hunks for FILE.
FILE is an absolute path. If STAGED is non-nil, show staged diff."
  (let* ((default-directory (my/mcp-git-repo-root file))
         (rel-file (file-relative-name file default-directory))
         (args (if staged
                   (list "diff" "--cached" "--" rel-file)
                 (list "diff" "--" rel-file)))
         (lines (apply #'magit-git-lines args))
         (hunk-num 0))
    (if (null lines)
        (format "No %s changes for %s" (if staged "staged" "unstaged") rel-file)
      (mapconcat (lambda (line)
                   (if (string-match "\\`@@" line)
                       (format "[%d] %s" (cl-incf hunk-num) line)
                     line))
                 lines "\n"))))

(defun my/mcp-git-stage (file &optional hunks)
  "Stage FILE or specific HUNKS of it.
FILE is an absolute path. HUNKS is a comma-separated list of hunk
numbers (e.g. \"1,3\"); omit to stage the whole file."
  (let* ((default-directory (my/mcp-git-repo-root file))
         (rel-file (file-relative-name file default-directory)))
    (if (not hunks)
        (progn
          (magit-stage-files (list rel-file))
          (format "Staged %s" rel-file))
      (require 'diff-hl)
      (let* ((hunk-nums (mapcar #'string-to-number (split-string hunks ",")))
             (diff-lines (magit-git-lines "diff" "--" rel-file))
             (hunk-line-map nil)
             (hunk-idx 0))
        (dolist (line diff-lines)
          (when (string-match "\\`@@ .* \\+\\([0-9]+\\)" line)
            (cl-incf hunk-idx)
            (push (cons hunk-idx (string-to-number (match-string 1 line)))
                  hunk-line-map)))
        (setq hunk-line-map (nreverse hunk-line-map))
        (let ((buf (find-file-noselect file))
              (staged-hunks nil))
          ;; Stage in reverse order so earlier hunk numbers stay valid
          (dolist (n (sort (copy-sequence hunk-nums) #'>))
            (let ((target-line (alist-get n hunk-line-map)))
              (if (not target-line)
                  (push (format "hunk %d not found" n) staged-hunks)
                (with-current-buffer buf
                  (save-excursion
                    (goto-char (point-min))
                    (forward-line (1- target-line))
                    (diff-hl-stage-current-hunk)))
                (push (format "hunk %d" n) staged-hunks))))
          (format "Staged %s: %s"
                  rel-file
                  (string-join (nreverse staged-hunks) ", ")))))))

(defun my/mcp-git-commit (path message &optional push amend)
  "Commit staged changes in the repo containing PATH with MESSAGE.
PATH is an absolute file or directory path. If PUSH is non-nil,
push to upstream after committing. If AMEND is non-nil, amend the
previous commit."
  (let ((default-directory (my/mcp-git-repo-root path)))
    (unless (or amend (magit-anything-staged-p))
      (error "Nothing staged to commit"))
    (if amend
        (magit-call-git "commit" "--amend" "-m" message)
      (magit-call-git "commit" "-m" message))
    (let ((hash (magit-rev-format "%h" "HEAD")))
      (when push
        (magit-push-current-to-upstream nil))
      (magit-refresh)
      (format "%s %s%s"
              (or hash "???")
              (car (split-string message "\n"))
              (if push " (pushed)" "")))))

;;;; mu4e MCP tools

(defvar my/mcp-mu4e--last-results nil
  "List of message plists from the last mu4e-headers search.")

(defun my/mcp-mu4e--get-result (index)
  "Get the message plist at 1-based INDEX from last search results."
  (unless my/mcp-mu4e--last-results
    (error "No search results — run mu4e-headers first"))
  (let ((msg (nth (1- index) my/mcp-mu4e--last-results)))
    (unless msg
      (error "Index %d out of range (1-%d)" index (length my/mcp-mu4e--last-results)))
    msg))

(defun my/mcp-mu4e--format-contact (contact)
  "Format a contact plist as \"Name <email>\" or just \"email\"."
  (let ((name (plist-get contact :name))
        (email (plist-get contact :email)))
    (if name (format "%s <%s>" name email) email)))

(defun my/mcp-mu4e--short-maildir (maildir)
  "Shorten maildir path for display."
  (if (string-match "\\`/[^/]+@\\([^/]+\\)\\(/.*\\)" maildir)
      (format "/%s%s" (match-string 1 maildir) (match-string 2 maildir))
    maildir))

(defun my/mcp-mu4e-headers (query &optional limit)
  "Search emails with QUERY and return numbered results.
LIMIT caps the number of results (default 20)."
  (require 'mu4e)
  (let* ((mu4e-search-results-limit (or limit 20))
         (done nil)
         (hook-fn (lambda () (setq done t))))
    (add-hook 'mu4e-headers-found-hook hook-fn 'append)
    (unwind-protect
        (cl-letf (((symbol-function 'pop-to-buffer)
                   (lambda (buf &rest _) (set-buffer buf)))
                  ((symbol-function 'switch-to-buffer)
                   (lambda (buf &rest _) (set-buffer buf))))
          (mu4e-search query)
          (let ((proc (get-buffer-process " *mu4e-server*")))
            (while (and (not done) proc (process-live-p proc))
              (accept-process-output proc 0.1))))
      (remove-hook 'mu4e-headers-found-hook hook-fn))
    (setq my/mcp-mu4e--last-results nil)
    (when-let* ((buf (get-buffer "*mu4e-headers*")))
      (with-current-buffer buf
        (mu4e-headers-for-each
         (lambda (msg)
           (push msg my/mcp-mu4e--last-results)))))
    (setq my/mcp-mu4e--last-results (nreverse my/mcp-mu4e--last-results))
    (if (null my/mcp-mu4e--last-results)
        "No results"
      (let ((i 0))
        (mapconcat
         (lambda (msg)
           (cl-incf i)
           (let* ((from (car (mu4e-message-field msg :from)))
                  (subject (mu4e-message-field msg :subject))
                  (date (mu4e-message-field msg :date))
                  (maildir (mu4e-message-field msg :maildir))
                  (flags (mu4e-message-field msg :flags)))
             (format "[%d] %s  %s  %s  %s%s"
                     i
                     (my/mcp-mu4e--short-maildir (or maildir ""))
                     (format-time-string "%b %d" date)
                     (if from (my/mcp-mu4e--format-contact from) "?")
                     (or subject "(no subject)")
                     (if (memq 'unread flags) "  *unread*" ""))))
         my/mcp-mu4e--last-results "\n")))))

(defun my/mcp-mu4e-view (index)
  "Read message at 1-based INDEX from last mu4e-headers search."
  (require 'mu4e)
  (let ((msg (my/mcp-mu4e--get-result index)))
    (mu4e-view-message-text msg)))

(defun my/mcp-mu4e-reply (index body)
  "Draft a reply to message at INDEX with BODY pre-filled.
Saves the draft to the drafts maildir for later review."
  (require 'mu4e)
  (let* ((msg (my/mcp-mu4e--get-result index))
         (msgid (mu4e-message-field msg :message-id))
         (subject (mu4e-message-field msg :subject))
         (headers-buf (get-buffer "*mu4e-headers*")))
    (unless headers-buf
      (error "No headers buffer — run mu4e-headers first"))
    (cl-letf (((symbol-function 'pop-to-buffer)
               (lambda (buf &rest _) (set-buffer buf)))
              ((symbol-function 'switch-to-buffer)
               (lambda (buf &rest _) (set-buffer buf))))
      (with-current-buffer headers-buf
        (mu4e-headers-goto-message-id msgid)
        (mu4e-compose-reply))
      ;; Find the compose buffer (most recent message-mode buffer)
      (let ((compose-buf (cl-find-if (lambda (buf)
                                       (with-current-buffer buf
                                         (derived-mode-p 'message-mode)))
                                     (buffer-list))))
        (unless compose-buf
          (error "Compose buffer not created"))
        (with-current-buffer compose-buf
          (message-goto-body)
          (insert body "\n\n")
          (save-buffer)
          (kill-buffer))
        (format "Draft saved: Re: %s" (or subject ""))))))

(defun my/mcp-mu4e--parse-indices (indices)
  "Parse INDICES string into list of message plists.
INDICES is comma-separated 1-based numbers or \"all\"."
  (if (equal indices "all")
      (or my/mcp-mu4e--last-results
          (error "No search results"))
    (mapcar (lambda (s)
              (my/mcp-mu4e--get-result (string-to-number (string-trim s))))
            (split-string indices ","))))

(defun my/mcp-mu4e-mark-read (indices)
  "Mark messages at INDICES as read.
INDICES is comma-separated row numbers or \"all\"."
  (require 'mu4e)
  (let ((msgs (my/mcp-mu4e--parse-indices indices)))
    (dolist (msg msgs)
      (mu4e--server-move (mu4e-message-field msg :docid) nil "+S-u-N"))
    (format "Marked %d message(s) as read" (length msgs))))

(defun my/mcp-mu4e-move (indices destination)
  "Move messages at INDICES to DESTINATION.
DESTINATION is \"archive\", \"trash\", or an explicit maildir path."
  (require 'mu4e)
  (let ((msgs (my/mcp-mu4e--parse-indices indices))
        (moved 0)
        (target nil))
    (dolist (msg msgs)
      (mu4e-context-determine msg)
      (setq target
            (pcase destination
              ("archive" (if (functionp mu4e-refile-folder)
                             (funcall mu4e-refile-folder msg)
                           mu4e-refile-folder))
              ("trash" (if (functionp mu4e-trash-folder)
                           (funcall mu4e-trash-folder msg)
                         mu4e-trash-folder))
              (_ destination)))
      (mu4e--server-move (mu4e-message-field msg :docid) target "+S-u-N")
      (cl-incf moved))
    (format "Moved %d message(s) to %s" moved target)))

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
                  :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-git-status
   :name "git-status"
   :description "Show git status for a repo. Returns branch, staged/unstaged/untracked files."
   :args '((:name "path"
                  :type string
                  :description "Absolute path to a file or directory in the repo")))

  (claude-code-ide-make-tool
   :function #'my/mcp-git-diff
   :name "git-diff"
   :description "Show diff with numbered hunks for a file. Use hunk numbers with git-stage."
   :args '((:name "file"
                  :type string
                  :description "Absolute path to the file")
           (:name "staged"
                  :type boolean
                  :description "Show staged changes instead of unstaged"
                  :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-git-stage
   :name "git-stage"
   :description "Stage a file or specific hunks. Use git-diff first to see numbered hunks."
   :args '((:name "file"
                  :type string
                  :description "Absolute path to the file to stage")
           (:name "hunks"
                  :type string
                  :description "Comma-separated hunk numbers to stage (omit to stage whole file)"
                  :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-git-commit
   :name "git-commit"
   :description "Commit staged changes. Use git-status to verify what's staged first."
   :args '((:name "path"
                  :type string
                  :description "Absolute path to a file or directory in the repo")
           (:name "message"
                  :type string
                  :description "Commit message")
           (:name "push"
                  :type boolean
                  :description "Push to upstream after committing"
                  :optional t)
           (:name "amend"
                  :type boolean
                  :description "Amend the previous commit instead of creating a new one"
                  :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-headers
   :name "mu4e-headers"
   :description "Search emails and list results. Returns numbered rows; use row numbers with mu4e-view and mu4e-reply."
   :args '((:name "query" :type string
            :description "mu search query (e.g. \"maildir:/ryan.gibb@cl.cam.ac.uk/Inbox\", \"flag:unread\", \"from:someone\")")
           (:name "limit" :type integer
            :description "Max results to return (default 20)"
            :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-view
   :name "mu4e-view"
   :description "Read a message by row number from the last mu4e-headers search."
   :args '((:name "index" :type integer
            :description "Row number from mu4e-headers results (1-based)")))

  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-reply
   :name "mu4e-reply"
   :description "Draft a reply to a message. Saves to drafts maildir for later review."
   :args '((:name "index" :type integer
            :description "Row number from mu4e-headers results (1-based)")
           (:name "body" :type string
            :description "Reply body text to pre-fill")))

  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-mark-read
   :name "mu4e-mark-read"
   :description "Mark messages as read by row number from the last mu4e-headers search."
   :args '((:name "indices" :type string
            :description "Row numbers to mark as read (comma-separated, e.g. \"1,2,3\") or \"all\"")))

  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-move
   :name "mu4e-move"
   :description "Move messages. Destination can be \"archive\", \"trash\" (resolved per account), or an explicit maildir path."
   :args '((:name "indices" :type string
            :description "Row numbers (comma-separated, e.g. \"1,2,3\") or \"all\"")
           (:name "destination" :type string
            :description "\"archive\", \"trash\", or explicit maildir path"))))

;;; tools.el ends here
