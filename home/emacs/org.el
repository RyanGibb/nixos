;;; org.el --- Org mode configuration -*- lexical-binding: t; -*-

(use-package org
  :defer t
  :hook (org-mode . org-indent-mode)
  :custom
  (org-directory "~/vault/")
  (org-agenda-files (list (concat org-directory "todo.org")
                          (concat org-directory "recurring.org")
                          (concat org-directory "habits.org")))
  (org-agenda-window-setup 'current-window)
  (org-agenda-start-day nil)
  (org-todo-repeat-to-state "LOOP")
  (org-todo-keywords
   '((sequence
      "TODO(t)" "PROJ(p)" "LOOP(r)" "STRT(s)" "WAIT(w)" "HOLD(h)" "IDEA(i)"
      "|"
      "DONE(d)" "MOVE(m)" "KILL(k)")))
  (org-tag-alist '(("work" . ?w) ("systems" . ?s)))
  :config
  (require 'org-habit)

  (setq org-todo-keyword-faces
        '(("STRT" . (:inherit (bold font-lock-constant-face org-todo)))
          ("WAIT" . (:inherit (bold warning org-todo)))
          ("HOLD" . (:inherit (bold warning org-todo)))
          ("PROJ" . (:inherit (bold font-lock-doc-face org-todo)))
          ("MOVE" . org-done)
          ("KILL" . org-done)))
  (setq org-capture-templates
        `(("t" "Todo" entry
           (file ,(concat org-directory "todo.org"))
           "* TODO %?\n%U\n%i" :prepend t)
          ("T" "Todo (link)" entry
           (file ,(concat org-directory "todo.org"))
           "* TODO %?\n%a\n%U\n%i" :prepend t)
          ("r" "Refile" entry
           (file ,(concat org-directory "refile.org"))
           "* %?\n%u\n%i" :prepend t)
          ("R" "Refile (link)" entry
           (file ,(concat org-directory "refile.org"))
           "* %?\n%a\n%u\n%i" :prepend t)
          ("s" "Schedule" entry
           (file ,(concat org-directory "schedule.org"))
           "* %u %?\n%i" :prepend t)))

  ;; Custom agenda views
  (defun my/org-agenda-skip-tag (tag &optional others)
    "Skip entries with TAG. If OTHERS, skip entries without TAG."
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
          (current-headline (or (and (org-at-heading-p) (point))
                                (save-excursion (org-back-to-heading)))))
      (if others
          (if (not (member tag (org-get-tags current-headline)))
              next-headline nil)
        (if (member tag (org-get-tags current-headline))
            next-headline nil))))

  (setq org-agenda-custom-commands
        '(("a" "Agenda"
           ((agenda "" ((org-agenda-skip-function
                         '(my/org-agenda-skip-tag "habit" nil))))))
          ("n" "Agenda and all TODOs"
           ((agenda "")
            (alltodo "")))
          ("h" "Habits"
           ((agenda "" ((org-agenda-span 'day)
                        (org-agenda-start-day nil)
                        (org-agenda-skip-function
                         '(my/org-agenda-skip-tag "habit" t))))
            (tags-todo "habit"))
           ((org-agenda-compact-blocks nil))))))

(use-package evil-org
  :after org
  :hook (org-mode . evil-org-mode)
  :config
  (defun my/evil-org-override-return-bindings (&rest _)
    "Override evil-org return bindings with DWIM variants."
    (evil-define-key 'normal 'evil-org-mode
      (kbd "RET") #'my/org-dwim-at-point
      (kbd "<C-return>") #'my/org-insert-item-below
      (kbd "<C-S-return>") #'my/org-insert-item-above
      (kbd "<M-return>") #'my/org-insert-subheading-below
      (kbd "<M-S-return>") #'my/org-insert-subheading-above
      (kbd "<C-M-return>") #'my/org-insert-sub-todo-below
      (kbd "<C-M-S-return>") #'my/org-insert-sub-todo-above)
    (evil-define-key 'insert 'evil-org-mode
      (kbd "RET") #'my/org-return
      (kbd "<C-return>") #'my/org-insert-item-below
      (kbd "<C-S-return>") #'my/org-insert-item-above
      (kbd "<M-return>") #'my/org-insert-subheading-below
      (kbd "<M-S-return>") #'my/org-insert-subheading-above
      (kbd "<C-M-return>") #'my/org-insert-sub-todo-below
      (kbd "<C-M-S-return>") #'my/org-insert-sub-todo-above)
    (evil-define-key '(normal insert) 'evil-org-mode
      (kbd "S-<return>") #'my/org-shift-return))
  (advice-add 'evil-org-set-key-theme :after #'my/evil-org-override-return-bindings)
  (my/evil-org-override-return-bindings))

(use-package evil-org-agenda
  :after org-agenda
  :config
  (evil-org-agenda-set-keys))


;;;; Org DWIM return bindings

(defun my/org-get-todo-keywords-for (&optional keyword)
  "Return the list of todo keywords that KEYWORD belongs to."
  (when keyword
    (cl-loop for (type . keyword-spec)
             in (cl-remove-if-not #'listp org-todo-keywords)
             for keywords =
             (mapcar (lambda (x) (if (string-match "^\\([^(]+\\)(" x)
                                     (match-string 1 x)
                                   x))
                     keyword-spec)
             if (eq type 'sequence)
             if (member keyword keywords)
             return keywords)))

(defun my/org-table-previous-row ()
  "Go to the previous row (same column) in the current table."
  (interactive)
  (org-table-maybe-eval-formula)
  (org-table-maybe-recalculate-line)
  (if (and org-table-automatic-realign
           org-table-may-need-update)
      (org-table-align))
  (let ((col (org-table-current-column)))
    (beginning-of-line 0)
    (when (or (not (org-at-table-p)) (org-at-table-hline-p))
      (beginning-of-line))
    (org-table-goto-column col)
    (skip-chars-backward "^|\n\r")
    (when (org-looking-at-p " ")
      (forward-char))))

(defun my/org--insert-item (direction)
  "Insert a new heading, table cell or item in DIRECTION (above or below)."
  (let* ((context (org-element-lineage
                   (org-element-context)
                   '(table table-row headline inlinetask item plain-list)
                   t))
         ;; Eagerly resolve deferred properties before modifying the buffer
         (todo-keyword (org-element-property :todo-keyword context))
         (todo-type (org-element-property :todo-type context))
         (checkbox (org-element-property :checkbox context)))
    (pcase (org-element-type context)
      ((or `item `plain-list)
       (let ((orig-point (point)))
         (if (eq direction 'above)
             (org-beginning-of-item)
           (end-of-line))
         (let* ((ctx-item? (eq 'item (org-element-type context)))
                (ctx-cb (org-element-property :contents-begin context))
                (beginning-of-list? (and (not ctx-item?)
                                         (= ctx-cb orig-point)))
                (item-context (if beginning-of-list?
                                  (org-element-context)
                                context))
                (ictx-cb (org-element-property :contents-begin item-context))
                (empty? (and (eq direction 'below)
                             (or (not ictx-cb)
                                 (= ictx-cb
                                    (1+ (point))))))
                (pre-insert-point (point)))
           (when empty?
             (insert " "))
           (org-insert-item checkbox)
           (when empty?
             (delete-region pre-insert-point (1+ pre-insert-point))))))
      ((or `table `table-row)
       (pcase direction
         ('below (save-excursion (org-table-insert-row t))
                 (org-table-next-row))
         ('above (save-excursion (org-shiftmetadown))
                 (my/org-table-previous-row))))
      (_
       (let ((level (or (org-current-level) 1)))
         (pcase direction
           (`below
            (let (org-insert-heading-respect-content)
              (goto-char (line-end-position))
              (org-end-of-subtree)
              (insert "\n" (make-string level ?*) " ")))
           (`above
            (org-back-to-heading)
            (insert (make-string level ?*) " \n")
            (forward-line -1)
            (end-of-line)))
         (run-hooks 'org-insert-heading-hook)
         (when (and todo-keyword todo-type)
           (org-todo
            (cond ((eq todo-type 'done)
                   (car (my/org-get-todo-keywords-for todo-keyword)))
                  (todo-keyword)
                  ('todo)))))))

    (when (org-invisible-p)
      (org-show-hidden-entry))
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p)))
      (evil-insert 1))))

(defun my/org-dwim-at-point (&optional arg)
  "Do-what-I-mean at point.

If on a:
- checkbox list item or todo heading: toggle it.
- citation: follow it
- headline: cycle ARCHIVE subtrees, toggle latex/images; update stats.
- clock: update its time.
- footnote reference: jump to definition
- footnote definition: jump to first reference
- timestamp: open agenda view for the date
- table-row or TBLFM: recalculate formulas
- table-cell: clear it and go into insert mode
- babel-call: execute the source block
- statistics-cookie: update it
- src block: execute it
- latex fragment: toggle it
- link: follow it
- otherwise: refresh inline images in current tree."
  (interactive "P")
  (if (button-at (point))
      (call-interactively #'push-button)
    (let* ((context (org-element-context))
           (type (org-element-type context)))
      (while (and context (memq type '(verbatim code bold italic underline strike-through subscript superscript)))
        (setq context (org-element-property :parent context)
              type (org-element-type context)))
      (pcase type
        ((or `citation `citation-reference)
         (org-cite-follow context arg))

        (`headline
         (cond ((memq (bound-and-true-p org-goto-map)
                      (current-active-maps))
                (org-goto-ret))
               ((string= "ARCHIVE" (car-safe (org-get-tags)))
                (org-force-cycle-archived))
               ((or (org-element-property :todo-type context)
                    (org-element-property :scheduled context))
                (org-todo
                 (if (eq (org-element-property :todo-type context) 'done)
                     (or (car (my/org-get-todo-keywords-for (org-element-property :todo-keyword context)))
                         'todo)
                   'done))))
         (org-update-checkbox-count)
         (org-update-parent-todo-statistics))

        (`clock (org-clock-update-time-maybe))

        (`footnote-reference
         (org-footnote-goto-definition (org-element-property :label context)))

        (`footnote-definition
         (org-footnote-goto-previous-reference (org-element-property :label context)))

        ((or `planning `timestamp)
         (org-follow-timestamp-link))

        ((or `table `table-row)
         (if (org-at-TBLFM-p)
             (org-table-calc-current-TBLFM)
           (ignore-errors
             (save-excursion
               (goto-char (org-element-property :contents-begin context))
               (org-call-with-arg 'org-table-recalculate (or arg t))))))

        (`table-cell
         (org-table-blank-field)
         (org-table-recalculate arg)
         (when (and (string-empty-p (string-trim (org-table-get-field)))
                    (bound-and-true-p evil-local-mode))
           (evil-change-state 'insert)))

        (`babel-call
         (org-babel-lob-execute-maybe))

        (`statistics-cookie
         (save-excursion (org-update-statistics-cookies arg)))

        ((or `src-block `inline-src-block)
         (org-babel-execute-src-block arg))

        ((or `latex-fragment `latex-environment)
         (org-latex-preview arg))

        (`link
         (org-open-at-point arg))

        ((guard (org-element-property :checkbox (org-element-lineage context '(item) t)))
         (org-toggle-checkbox))

        (_
         (when (or (org-in-regexp org-ts-regexp-both nil t)
                   (org-in-regexp org-tsr-regexp-both nil  t)
                   (org-in-regexp org-link-any-re nil t))
           (call-interactively #'org-open-at-point)))))))

(defun my/org-return ()
  "Call `org-return' then indent (if `electric-indent-mode' is on)."
  (interactive)
  (org-return electric-indent-mode))

(defun my/org-shift-return (&optional arg)
  "Insert a literal newline, or dwim in tables.
Executes `org-table-copy-down' if in table."
  (interactive "p")
  (if (org-at-table-p)
      (org-table-copy-down arg)
    (when (and (bound-and-true-p evil-local-mode)
               (evil-normal-state-p))
      (goto-char (line-end-position)))
    (org-return nil arg)))

(defun my/org-insert-item-below (count)
  "Insert a new heading, table cell or item below the current one."
  (interactive "p")
  (dotimes (_ count) (my/org--insert-item 'below)))

(defun my/org-insert-item-above (count)
  "Insert a new heading, table cell or item above the current one."
  (interactive "p")
  (dotimes (_ count) (my/org--insert-item 'above)))

(defun my/org-insert-subheading-below (&optional todo)
  "Insert a subheading at the bottom of current heading's children.
With TODO non-nil, add a TODO keyword."
  (interactive)
  (org-back-to-heading)
  (let ((level (1+ (org-current-level))))
    (org-end-of-subtree)
    (insert "\n" (make-string level ?*) " ")
    (when todo (org-todo "TODO"))
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p)))
      (evil-insert 1))))

(defun my/org-insert-subheading-above (&optional todo)
  "Insert a subheading at the top of current heading's children.
With TODO non-nil, add a TODO keyword."
  (interactive)
  (org-back-to-heading)
  (let ((level (1+ (org-current-level))))
    (end-of-line)
    (insert "\n" (make-string level ?*) " ")
    (when todo (org-todo "TODO"))
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p)))
      (evil-insert 1))))

(defun my/org-insert-sub-todo-below ()
  "Insert a sub-TODO at the bottom of current heading's children."
  (interactive)
  (my/org-insert-subheading-below t))

(defun my/org-insert-sub-todo-above ()
  "Insert a sub-TODO at the top of current heading's children."
  (interactive)
  (my/org-insert-subheading-above t))


;;;; Org local leader bindings (SPC m)

(with-eval-after-load 'general
  (my/local-leader-def
    :keymaps 'org-mode-map
    ""    '(nil :which-key "org")
    "'"   '(org-edit-special :which-key "edit special")
    ","   '(org-switchb :which-key "switch org buffer")
    "."   '(consult-org-heading :which-key "goto heading")
    "/"   '(consult-org-agenda :which-key "goto agenda heading")
    "A"   '(org-archive-subtree-default :which-key "archive subtree")
    "e"   '(org-export-dispatch :which-key "export")
    "f"   '(org-footnote-action :which-key "footnote")
    "h"   '(org-toggle-heading :which-key "toggle heading")
    "i"   '(org-toggle-item :which-key "toggle item")
    "n"   '(org-store-link :which-key "store link")
    "o"   '(org-set-property :which-key "set property")
    "q"   '(org-set-tags-command :which-key "set tags")
    "t"   '(org-todo :which-key "todo state")
    "T"   '(org-todo-list :which-key "todo list")
    "x"   '(org-toggle-checkbox :which-key "toggle checkbox")

    ;; Clock
    "c"   '(:ignore t :which-key "clock")
    "c c" '(org-clock-cancel :which-key "cancel")
    "c g" '(org-clock-goto :which-key "goto")
    "c i" '(org-clock-in :which-key "clock in")
    "c I" '(org-clock-in-last :which-key "clock in last")
    "c o" '(org-clock-out :which-key "clock out")
    "c r" '(org-resolve-clocks :which-key "resolve")
    "c R" '(org-clock-report :which-key "report")

    ;; Date/deadline
    "d"   '(:ignore t :which-key "date/deadline")
    "d d" '(org-deadline :which-key "deadline")
    "d s" '(org-schedule :which-key "schedule")
    "d t" '(org-time-stamp :which-key "timestamp")
    "d T" '(org-time-stamp-inactive :which-key "inactive timestamp")

    ;; Links
    "l"   '(:ignore t :which-key "links")
    "l l" '(org-insert-link :which-key "insert link")
    "l L" '(org-insert-all-links :which-key "insert all links")
    "l s" '(org-store-link :which-key "store link")
    "l S" '(org-insert-last-stored-link :which-key "insert last link")
    "l t" '(org-toggle-link-display :which-key "toggle display")

    ;; Priority
    "p"   '(:ignore t :which-key "priority")
    "p d" '(org-priority-down :which-key "down")
    "p p" '(org-priority :which-key "set priority")
    "p u" '(org-priority-up :which-key "up")

    ;; Subtree
    "s"   '(:ignore t :which-key "subtree")
    "s a" '(org-toggle-archive-tag :which-key "toggle archive tag")
    "s b" '(org-tree-to-indirect-buffer :which-key "indirect buffer")
    "s d" '(org-cut-subtree :which-key "cut subtree")
    "s h" '(org-promote-subtree :which-key "promote")
    "s j" '(org-move-subtree-down :which-key "move down")
    "s k" '(org-move-subtree-up :which-key "move up")
    "s l" '(org-demote-subtree :which-key "demote")
    "s n" '(org-narrow-to-subtree :which-key "narrow")
    "s N" '(widen :which-key "widen")
    "s r" '(org-refile :which-key "refile")
    "s s" '(org-sparse-tree :which-key "sparse tree")
    "s S" '(org-sort :which-key "sort")))

;;;; Bibliography

(use-package citar
  :custom
  (citar-bibliography '("~/vault/references.bib"))
  (citar-library-paths '("~/library"))
  (citar-notes-paths '("~/vault"))
  (org-cite-global-bibliography '("~/vault/references.bib"))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar))

;;; org.el ends here
