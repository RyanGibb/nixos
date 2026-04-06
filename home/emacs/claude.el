;;; claude.el --- Claude Code IDE and MCP tools -*- lexical-binding: t; -*-

;;;; Buffer tools

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

;;;; Git tools

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

;;;; mu4e tools

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

;;;; Caledonia tools

(defun my/mcp-caledonia--refresh ()
  "Refresh the Caledonia agenda buffer if it exists."
  (when-let* ((buf (get-buffer "*Caledonia Agenda*")))
    (with-current-buffer buf
      (when (eq major-mode 'caledonia-agenda-mode)
        (caledonia-refresh)))))

(defun my/mcp-caledonia-edit-event (id &optional summary start-date start-time
                                       end-date end-time timezone end-timezone
                                       location description alarms)
  "Edit calendar event ID, updating only the provided fields.
Refreshes the Caledonia agenda buffer afterwards."
  (require 'caledonia)
  (caledonia--ensure-server-running)
  (let* ((alarm-list (when alarms
                       (mapcar #'string-trim
                               (split-string alarms "," t "[ \t]+"))))
         (fields `(("id" . ,id)
                   ("summary" . ,summary)
                   ("start_date" . ,start-date)
                   ("start_time" . ,start-time)
                   ("end_date" . ,end-date)
                   ("end_time" . ,end-time)
                   ("timezone" . ,timezone)
                   ("end_timezone" . ,end-timezone)
                   ("location" . ,location)
                   ("description" . ,description)
                   ("alarms" . ,alarm-list)))
         (request-str (format "(EditEvent (%s))"
                              (caledonia--build-sexp-fields fields))))
    (caledonia--send-request request-str)
    (my/mcp-caledonia--refresh)
    (format "Event updated: %s" id)))

(defun my/mcp-caledonia-add-event (calendar summary start-date
                                    &optional start-time end-date end-time
                                    timezone end-timezone recurrence alarms
                                    location description)
  "Create a new calendar event.
CALENDAR is the calendar name, SUMMARY is the title, START-DATE is YYYY-MM-DD.
Refreshes the Caledonia agenda buffer afterwards."
  (require 'caledonia)
  (caledonia--ensure-server-running)
  (let* ((alarm-list (when alarms
                       (mapcar #'string-trim
                               (split-string alarms "," t "[ \t]+"))))
         (fields `(("calendar" . ,calendar)
                   ("summary" . ,summary)
                   ("start_date" . ,start-date)
                   ("start_time" . ,start-time)
                   ("end_date" . ,end-date)
                   ("end_time" . ,end-time)
                   ("timezone" . ,timezone)
                   ("end_timezone" . ,end-timezone)
                   ("recurrence" . ,recurrence)
                   ("alarms" . ,alarm-list)
                   ("location" . ,location)
                   ("description" . ,description)))
         (request-str (format "(CreateEvent (%s))"
                              (caledonia--build-sexp-fields fields))))
    (let* ((payload (caledonia--send-request request-str))
           (events (caledonia--get-events payload))
           (event (car events))
           (id (caledonia--get-key 'id event)))
      (my/mcp-caledonia--refresh)
      (format "Event created: %s [%s]" summary id))))

(defun my/mcp-caledonia-delete-event (id &optional occurrence-start)
  "Delete calendar event by ID.
If OCCURRENCE-START is provided (RFC 3339), delete only that occurrence
of a recurring event."
  (require 'caledonia)
  (caledonia--ensure-server-running)
  (let ((request-str
         (if occurrence-start
             (format "(DeleteEvent ((id %S)(occurrence_start %S)))" id occurrence-start)
           (format "(DeleteEvent ((id %S)))" id))))
    (caledonia--send-request request-str)
    (my/mcp-caledonia--refresh)
    (format "Event deleted: %s" id)))

(defun my/mcp-caledonia--format-event (event)
  "Format EVENT as a human-readable one-line string."
  (let* ((id (caledonia--get-key 'id event))
         (summary (or (caledonia--get-key 'summary event) "(no summary)"))
         (calendar (or (caledonia--get-key 'calendar event) ""))
         (start (caledonia--get-key 'start event))
         (end-val (caledonia--get-key 'end event))
         (is-date (caledonia--get-key 'is_date event))
         (location (caledonia--get-key 'location event))
         (recurring (caledonia--get-key 'recurring event))
         (start-str (if is-date
                        (caledonia--format-timestamp start "%Y-%m-%d")
                      (caledonia--format-timestamp start "%Y-%m-%d %H:%M")))
         (end-str (when end-val
                    (if is-date
                        (caledonia--format-timestamp end-val "%Y-%m-%d")
                      (caledonia--format-timestamp end-val "%H:%M"))))
         (time-str (if end-str
                       (format "%s-%s" start-str end-str)
                     start-str)))
    (format "%s  %s  %s [%s]%s%s"
            time-str
            (or summary "")
            calendar
            (or id "")
            (if location (format " @ %s" location) "")
            (if recurring " (recurring)" ""))))

(defun my/mcp-caledonia-list-events (&optional from to text)
  "List calendar events in a date range, optionally filtering by TEXT.
FROM defaults to \"today\", TO defaults to \"+3m\"."
  (require 'caledonia)
  (caledonia--ensure-server-running)
  (let* ((from (or from "today"))
         (to (or to "+3m"))
         (query (if text
                    `((text ,text) (from ,from) (to ,to))
                  `((from ,from) (to ,to))))
         (request-str (format "(Query %s)" (prin1-to-string query)))
         (payload (caledonia--send-request request-str))
         (events (caledonia--get-events payload)))
    (if (null events)
        "No events found"
      (mapconcat #'my/mcp-caledonia--format-event events "\n"))))

;;;; Claude Code IDE setup and tool registration

(use-package claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :custom
  (claude-code-ide-terminal-backend 'vterm)
  :config
  (claude-code-ide-emacs-tools-setup)

  ;; Pass direnv (envrc) environment through to vterm
  (defun my/claude-code-ide-inherit-envrc (orig-fun &rest args)
    "Advise terminal creation to inherit buffer-local process-environment.
This ensures direnv/envrc environment variables are passed to claude."
    (let* ((default-env (default-value 'process-environment))
           (extra-env (cl-set-difference process-environment default-env :test #'string=))
           (vterm-environment (append extra-env vterm-environment)))
      (apply orig-fun args)))
  (advice-add 'claude-code-ide--create-terminal-session :around #'my/claude-code-ide-inherit-envrc)

  ;; Buffer tools
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

  ;; Git tools
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

  ;; mu4e tools
  (claude-code-ide-make-tool
   :function #'my/mcp-mu4e-headers
   :name "mu4e-headers"
   :description "Search emails and list results. Returns numbered rows; use row numbers with mu4e-view and mu4e-reply."
   :args '((:name "query" :type string
            :description "mu search query (e.g. \"maildir:/ryan.gibb@cl.cam.ac.uk/Inbox\", \"flag:unread\", \"from:someone\"). IMPORTANT: Never use bare \"flag:unread\" — always exclude Gmail All Mail, e.g. \"flag:unread AND NOT flag:trashed AND NOT maildir:\\\"/ryangibb321@gmail.com/[Gmail]/All Mail\\\"\". For inbox use \"maildir:/ryan@freumh.org/Inbox OR maildir:/ryangibb321@gmail.com/Inbox OR maildir:/ryan.gibb@cl.cam.ac.uk/Inbox\".")
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
            :description "\"archive\", \"trash\", or explicit maildir path")))

  ;; Caledonia tools
  (claude-code-ide-make-tool
   :function #'my/mcp-caledonia-edit-event
   :name "caledonia-edit-event"
   :description "Edit a calendar event by ID. Only provided fields are updated. Read the Caledonia Event Details buffer to get the event ID from the filename. Refreshes the agenda afterwards."
   :args '((:name "id" :type string
            :description "Event UUID (from .ics filename)")
           (:name "summary" :type string
            :description "Event title/summary"
            :optional t)
           (:name "start_date" :type string
            :description "Start date (YYYY-MM-DD)"
            :optional t)
           (:name "start_time" :type string
            :description "Start time (HH:MM)"
            :optional t)
           (:name "end_date" :type string
            :description "End date (YYYY-MM-DD)"
            :optional t)
           (:name "end_time" :type string
            :description "End time (HH:MM)"
            :optional t)
           (:name "timezone" :type string
            :description "Timezone (e.g. Europe/London)"
            :optional t)
           (:name "end_timezone" :type string
            :description "End timezone if different from start (e.g. America/New_York)"
            :optional t)
           (:name "location" :type string
            :description "Event location"
            :optional t)
           (:name "description" :type string
            :description "Event description"
            :optional t)
           (:name "alarms" :type string
            :description "Comma-separated alarm triggers (e.g. '1w,3d,1d,16h,1h')"
            :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-caledonia-add-event
   :name "caledonia-add-event"
   :description "Create a new calendar event. Refreshes the agenda afterwards."
   :args '((:name "calendar" :type string
            :description "Calendar name (e.g. 'freumh')")
           (:name "summary" :type string
            :description "Event title/summary")
           (:name "start_date" :type string
            :description "Start date (YYYY-MM-DD)")
           (:name "start_time" :type string
            :description "Start time (HH:MM). Omit for all-day event"
            :optional t)
           (:name "end_date" :type string
            :description "End date (YYYY-MM-DD). Defaults to start_date"
            :optional t)
           (:name "end_time" :type string
            :description "End time (HH:MM). Required if start_time is set"
            :optional t)
           (:name "timezone" :type string
            :description "Timezone (e.g. Europe/London)"
            :optional t)
           (:name "end_timezone" :type string
            :description "End timezone if different from start (e.g. America/New_York)"
            :optional t)
           (:name "recurrence" :type string
            :description "RRULE recurrence string (e.g. FREQ=WEEKLY;BYDAY=MO)"
            :optional t)
           (:name "alarms" :type string
            :description "Comma-separated alarm triggers (e.g. '1w,3d,1d,16h,1h')"
            :optional t)
           (:name "location" :type string
            :description "Event location"
            :optional t)
           (:name "description" :type string
            :description "Event description"
            :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-caledonia-delete-event
   :name "caledonia-delete-event"
   :description "Delete a calendar event by ID. For recurring events, provide occurrence_start to delete a single occurrence."
   :args '((:name "id" :type string
            :description "Event UUID (from .ics filename)")
           (:name "occurrence_start" :type string
            :description "RFC 3339 timestamp to delete only this occurrence of a recurring event"
            :optional t)))

  (claude-code-ide-make-tool
   :function #'my/mcp-caledonia-list-events
   :name "caledonia-list-events"
   :description "List calendar events in a date range. Returns events with their IDs, times, summaries, and calendars. Optionally filter by text search."
   :args '((:name "from" :type string
            :description "Start date (YYYY-MM-DD, 'today', '+7d', etc.). Default: 'today'"
            :optional t)
           (:name "to" :type string
            :description "End date (YYYY-MM-DD, '+1m', etc.). Default: '+3m'"
            :optional t)
           (:name "text" :type string
            :description "Text to search for in event summaries"
            :optional t))))

;;; claude.el ends here
