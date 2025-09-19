;;; org.el -*- lexical-binding: t; -*-

(setq org-directory "~/vault/")
(setq org-agenda-files `(,org-directory "~/projects/website/static/"))

(use-package! org-habit :after org)

(after! org
  (with-no-warnings
    (custom-declare-face '+org-todo-active  '((t (:inherit (bold font-lock-constant-face org-todo)))) "")
    (custom-declare-face '+org-todo-project '((t (:inherit (bold font-lock-doc-face org-todo)))) "")
    (custom-declare-face '+org-todo-onhold  '((t (:inherit (bold warning org-todo)))) ""))
  (setq org-todo-keywords
        '((sequence
           "TODO(t)"    ; A task that needs doing & is ready to do
           "PROJ(p)"    ; A project, which usually contains other tasks
           "LOOP(r)"    ; A recurring task
           "STRT(s)"    ; A task that is in progress
           "WAIT(w)"    ; Something external is holding up this task
           "HOLD(h)"    ; This task is paused/on hold because of me
           "IDEA(i)"    ; An unconfirmed and unapproved task or notion
           "|"
           "DONE(d)"    ; Task successfully completed
           "MOVE(m)"    ; Task rescheduled
           "KILL(k)"))  ; Task was cancelled, aborted, or is no longer applicable
        org-todo-keyword-faces
        '(("STRT" . +org-todo-active)
          ("WAIT" . +org-todo-onhold)
          ("HOLD" . +org-todo-onhold)
          ("PROJ" . +org-todo-project)
          ("MOVE" . org-done)
          ("KILL" . org-done)))
  (setq +org-capture-notes-file (concat org-directory "/refile.org"))
  (setq +org-capture-todo-file (concat org-directory "/todo.org"))
  (setq +org-capture-journal-file (concat org-directory "/journal.org"))
  (setq org-capture-templates
        `(("t" "Todo" entry
           (file +org-capture-todo-file)
           "* TODO %?\n%U\n%i" :prepend t)
          ("T" "Todo (link)" entry
           (file +org-capture-todo-file)
           "* TODO %?\n%a\n%U\n%i" :prepend t)
          ("r" "Refile" entry
           (file +org-capture-notes-file)
           "* %?\n%u\n%i" :prepend t)
          ("R" "Refile (link)" entry
           (file +org-capture-notes-file)
           "* %?\n%a\n%u\n%i" :prepend t)
          ("s" "Schedule" entry
           (file ,(concat org-directory "schedule.org"))
           "* %u %?\n%i" :prepend t))
        )
  (setq org-tag-alist '(("work" . ?w) ("systems" . ?s)))
  (map! :leader
        :desc "Org agenda" "A" #'org-agenda-list)

  (setq org-agenda-start-day nil)

  ;; https://stackoverflow.com/questions/10074016/org-mode-filter-on-tag-in-agenda-view
  (defun zin/org-agenda-skip-tag (tag &optional others)
    "Skip all entries that correspond to TAG.

If OTHERS is true, skip all entries that do not correspond to TAG."
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
          (current-headline (or (and (org-at-heading-p)
                                     (point))
                                (save-excursion (org-back-to-heading)))))
      (if others
          (if (not (member tag (org-get-tags current-headline)))
              next-headline
            nil)
        (if (member tag (org-get-tags current-headline))
            next-headline
          nil))))
  (setq org-agenda-custom-commands
        '(
          ("a" "Agenda"
           ((agenda ""
                    ((org-agenda-skip-function '(zin/org-agenda-skip-tag "habit" nil)))
                    )))
          ("n" "Agenda and all TODOs"
           ((agenda "")
            (alltodo "")))
          ("h" "Habits"
           ((agenda ""
                    ((org-agenda-span 'day)
                     (org-agenda-start-day nil)
                     (org-agenda-skip-function '(zin/org-agenda-skip-tag "habit" 't))))
            (tags-todo "habit"))
           ((org-agenda-compact-blocks nil)))
          ))
  (setq org-todo-repeat-to-state 'LOOP)

  (setq! citar-bibliography '("~/vault/references.bib"))

  (setq citar-library-paths '("~/library")
        citar-notes-paths '("~/vault")))

(defun convert-markdown-to-org-with-pandoc-and-delete ()
  "Convert the current Markdown file to an Org file using Pandoc and delete the original."
  (interactive)
  (when (and buffer-file-name
             (string-equal (file-name-extension buffer-file-name) "md"))
    (let* ((org-file (concat (file-name-sans-extension buffer-file-name) ".org"))
           (command (format "pandoc -f markdown -t org %s -o %s --wrap=preserve"
                            (shell-quote-argument buffer-file-name)
                            (shell-quote-argument org-file))))
      (save-buffer)
      (if (eq (call-process-shell-command command) 0)
          (progn
            (find-file org-file)
            (message "Converted %s to %s." buffer-file-name org-file))
        (message "Pandoc conversion failed!")))))

(map! :leader
      :desc "Convert Markdown to Org with Pandoc and delete"
      "f M" #'convert-markdown-to-org-with-pandoc-and-delete)

(defun weekfile ()
  "Open an Org file named YYYY-MM-DD.org for the Monday of the current week
in the ~/projects/website/static/ directory."
  (interactive)
  (let* ((current-time (current-time))
         ;; Day of week: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
         (dow (nth 6 (decode-time current-time)))
         ;; Offset to Monday (if today is Sunday (0), then go back 6 days)
         (offset (if (= dow 0) -6 (- 1 dow)))
         (monday-time (time-subtract current-time (days-to-time (- offset))))
         (formatted-date (format-time-string "%Y-%m-%d" monday-time))
         (filename (expand-file-name (concat formatted-date ".org")
                                     "~/projects/website/static/")))
    (find-file filename)))

(map! :leader
      :desc "weekfile" "W" #'weekfile)
