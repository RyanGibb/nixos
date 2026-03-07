;;; org.el --- Org mode configuration -*- lexical-binding: t; -*-

(use-package org
  :defer t
  :custom
  (org-directory "~/vault/")
  (org-agenda-files (list (concat org-directory "todo.org")
                          (concat org-directory "recurring.org")
                          (concat org-directory "habits.org")))
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
  :hook (org-mode . evil-org-mode))

(use-package evil-org-agenda
  :after org-agenda
  :config
  (evil-org-agenda-set-keys))

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
