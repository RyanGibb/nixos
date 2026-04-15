;;; mu4e.el --- Email configuration -*- lexical-binding: t; -*-

(use-package mu4e
  :commands (mu4e mu4e-compose-new)
  :config
  (setq mu4e-get-mail-command "mbsync -a")
  (setq sendmail-program "msmtp")
  (setq message-sendmail-f-is-evil t)
  (setq message-sendmail-extra-arguments '("--read-envelope-from"))
  (setq message-send-mail-function 'message-send-mail-with-sendmail)
  (setq mail-user-agent 'mu4e-user-agent)
  (setq message-dont-reply-to-names 'mu4e-personal-or-alternative-address-p)
  (setq mu4e-change-filenames-when-moving t)
  (setq mu4e-search-show-threads nil)
  (setq mu4e-search-include-related nil)
  (setq mu4e-context-policy 'pick-first)
  (setq shr-use-colors nil)
  ;; Prefer text/plain over text/html
  (setq mm-discouraged-alternatives '("text/html"))

  (defun my/mu4e-toggle-html ()
    "Toggle between text/plain and text/html in the current message."
    (interactive)
    (if (member "text/html" mm-discouraged-alternatives)
        (setq mm-discouraged-alternatives nil)
      (setq mm-discouraged-alternatives '("text/html")))
    (mu4e-view-refresh)
    (message "Preferring %s" (if mm-discouraged-alternatives "plain text" "HTML")))

  (let ((full-name "Ryan Gibb")
        (signature nil))
    (setq mu4e-contexts
          `(,(let ((mail-address "ryan@freumh.org")
                   (dir-name "/ryan@freumh.org"))
               (make-mu4e-context
                :name (concat "1 " mail-address)
                :match-func
                `(lambda (msg)
                   (when msg
                     (string-match-p
                      ,(concat "^" dir-name)
                      (mu4e-message-field msg :maildir))))
                :vars
                `((user-mail-address    . ,mail-address)
                  (user-full-name       . ,full-name)
                  (mu4e-sent-folder     . ,(concat dir-name "/Sent"))
                  (mu4e-drafts-folder   . ,(concat dir-name "/Drafts"))
                  (mu4e-trash-folder    . ,(concat dir-name "/Trash"))
                  (mu4e-refile-folder   . ,(concat dir-name "/Archive"))
                  (mu4e-compose-signature . ,signature)
                  (mu4e-maildir-shortcuts .
                                          ,'((:maildir "/ryan@freumh.org/Inbox"   :key ?i)
                                             (:maildir "/ryan@freumh.org/Sent"    :key ?s)
                                             (:maildir "/ryan@freumh.org/Drafts"  :key ?d)
                                             (:maildir "/ryan@freumh.org/Archive" :key ?a)
                                             (:maildir "/ryan@freumh.org/Trash"   :key ?t))))))
            ,(let ((mail-address "ryangibb321@gmail.com")
                   (dir-name "/ryangibb321@gmail.com"))
               (make-mu4e-context
                :name (concat "2 " mail-address)
                :match-func
                `(lambda (msg)
                   (when msg
                     (string-match-p
                      ,(concat "^" dir-name)
                      (mu4e-message-field msg :maildir))))
                :vars
                `((user-mail-address    . ,mail-address)
                  (user-full-name       . ,full-name)
                  (mu4e-sent-folder     . ,(concat dir-name "/[Gmail]/Sent Mail"))
                  (mu4e-drafts-folder   . ,(concat dir-name "/[Gmail]/Drafts"))
                  (mu4e-trash-folder    . ,(concat dir-name "/[Gmail]/Bin"))
                  (mu4e-refile-folder   . ,(concat dir-name "/[Gmail]/All Mail"))
                  (mu4e-compose-signature . ,signature)
                  (mu4e-maildir-shortcuts .
                                          ,'((:maildir "/ryangibb321@gmail.com/Inbox"             :key ?i)
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/Sent Mail" :key ?s)
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/Drafts"    :key ?d)
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/All Mail"  :key ?a)
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/Spam"      :key ?x)
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/Bin"       :key ?t))))))
            ,(let ((mail-address "ryan.gibb@cl.cam.ac.uk")
                   (dir-name "/ryan.gibb@cl.cam.ac.uk"))
               (make-mu4e-context
                :name (concat "3 " mail-address)
                :match-func
                `(lambda (msg)
                   (when msg
                     (string-match-p
                      ,(concat "^" dir-name)
                      (mu4e-message-field msg :maildir))))
                :vars
                `((user-mail-address    . ,mail-address)
                  (user-full-name       . ,full-name)
                  (mu4e-sent-folder     . ,(concat dir-name "/Sent"))
                  (mu4e-drafts-folder   . ,(concat dir-name "/Drafts"))
                  (mu4e-trash-folder    . ,(concat dir-name "/Trash"))
                  (mu4e-refile-folder   . ,(concat dir-name "/Archive"))
                  (mu4e-compose-signature . ,signature)
                  (mu4e-maildir-shortcuts .
                                          ,'((:maildir "/ryan.gibb@cl.cam.ac.uk/Inbox"   :key ?i)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Sent"    :key ?s)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Drafts"  :key ?d)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Archive" :key ?a)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Spam"    :key ?x)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Trash"   :key ?t))))))
            ,(let ((mail-address "misc@freumh.org")
                   (dir-name "/misc@freumh.org"))
               (make-mu4e-context
                :name (concat "4 " mail-address)
                :match-func
                `(lambda (msg)
                   (when msg
                     (string-match-p
                      ,(concat "^" dir-name)
                      (mu4e-message-field msg :maildir))))
                :vars
                `((user-mail-address    . ,mail-address)
                  (user-full-name       . ,full-name)
                  (mu4e-sent-folder     . ,(concat dir-name "/Sent"))
                  (mu4e-drafts-folder   . ,(concat dir-name "/Drafts"))
                  (mu4e-trash-folder    . ,(concat dir-name "/Trash"))
                  (mu4e-refile-folder   . ,(concat dir-name "/Archive"))
                  (mu4e-compose-signature . ,signature)
                  (mu4e-maildir-shortcuts .
                                          ,'((:maildir "/misc@freumh.org/Inbox"   :key ?i)
                                             (:maildir "/misc@freumh.org/Sent"    :key ?s)
                                             (:maildir "/misc@freumh.org/Drafts"  :key ?d)
                                             (:maildir "/misc@freumh.org/Archive" :key ?a)
                                             (:maildir "/misc@freumh.org/Trash"   :key ?t)))))))))

  (setq mu4e-personal-addresses
        '("ryan@freumh.org"
          "ryangibb321@gmail.com"
          "ryan.gibb@cl.cam.ac.uk"
          "rtg24@cam.ac.uk"
          "misc@freumh.org"))

  (setq mu4e-bookmarks
        '((:name "Unified Inbox"
           :query "maildir:/ryan@freumh.org/Inbox OR maildir:/ryangibb321@gmail.com/Inbox OR maildir:/ryan.gibb@cl.cam.ac.uk/Inbox"
           :favorite t
           :key ?i)
          (:name "Unread messages"
           :query "flag:unread AND NOT flag:trashed AND NOT maildir:\"/ryangibb321@gmail.com/[Gmail]/All Mail\""
           :key ?u)
          (:name "Today's messages"
           :query "date:today..now"
           :key ?t)
          (:name "Last 7 days"
           :query "date:7d..now"
           :hide-unread t
           :key ?w)
))

  (setq mu4e-headers-fields
        '((:maildir . 40)
          (:human-date . 12)
          (:flags . 6)
          (:mailing-list . 10)
          (:from-or-to . 22)
          (:thread-subject . nil)))

  ;; Calendar integration
  (require 'mu4e-icalendar)
  (gnus-icalendar-setup)
  (setq gnus-icalendar-org-capture-file "~/vault/cal.org")
  (setq gnus-icalendar-org-capture-headline '("Calendar"))
  (gnus-icalendar-org-setup)

  ;; Keep current email centered in headers view
  (defun my/mu4e-headers-recenter (&rest _)
    "Recenter the current line in the headers window."
    (when-let* ((buf (mu4e-get-headers-buffer))
                (win (get-buffer-window buf)))
      (with-selected-window win
        (recenter))))
  (advice-add 'mu4e-headers-next :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-headers-prev :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-headers-next-unread :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-headers-prev-unread :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-view-headers-next :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-view-headers-prev :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-view-headers-next-unread :after #'my/mu4e-headers-recenter)
  (advice-add 'mu4e-view-headers-prev-unread :after #'my/mu4e-headers-recenter)

  (setq mu4e-completing-read-function #'completing-read-default)
  (setq mu4e-confirm-quit nil)

  ;; Close mu4e workspace when main buffer is killed
  (add-hook 'mu4e-main-mode-hook
            (lambda ()
              (add-hook 'kill-buffer-hook
                        (lambda ()
                          (when (persp-with-name-exists-p "~/mail/")
                            (my/kill-current-workspace)))
                        nil t)))

  ;; 'i' to update index in main view
  (with-eval-after-load 'evil-collection
    (evil-collection-define-key 'normal 'mu4e-main-mode-map
      (kbd "i") 'mu4e-update-index))

  ;; 'A' for mime part action, 'h' to toggle HTML in message view
  (evil-define-key '(normal insert) mu4e-view-mode-map
    (kbd "A") #'mu4e-view-mime-part-action
    (kbd "h") #'my/mu4e-toggle-html)

  ;; Local leader bindings for compose mode
  (with-eval-after-load 'general
    (my/local-leader-def
      :keymaps 'mu4e-compose-mode-map
      ""  '(nil :which-key "compose")
      "s" '(message-send-and-exit :which-key "send")
      "d" '(message-kill-buffer :which-key "discard")
      "S" '(message-dont-send :which-key "save draft")
      "a" '(mail-add-attachment :which-key "attach"))))

;;; mu4e.el ends here
