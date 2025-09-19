;;; mu4e.el -*- lexical-binding: t; -*-

;; https://github.com/doomemacs/doomemacs/issues/8210
(use-package mu4e
  :commands mu4e mu4e-compose-new
  )
(after! mu4e
  (setq mu4e-get-mail-command "mbsync -a")

  (setq sendmail-program "msmtp")
  (setq message-sendmail-f-is-evil t)
  (setq message-sendmail-extra-arguments '("--read-envelope-from"))
  (setq message-send-mail-function 'message-send-mail-with-sendmail)

  (let ((full-name "Ryan Gibb")
        (signature nil))
    (setq mu4e-contexts
          `(,
            (let ((mail-address "ryan@freumh.org")
                  (dir-name (concat "/ryan@freumh.org")))
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
                                            (:maildir "/ryan@freumh.org/Trash"   :key ?t)))
                 )))
            ,(let ((mail-address "ryangibb321@gmail.com")
                   (dir-name (concat "/ryangibb321@gmail.com")))
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
                                             (:maildir "/ryangibb321@gmail.com/[Gmail]/Bin"       :key ?t)))
                  )))
            ,(let ((mail-address "ryan.gibb@cl.cam.ac.uk")
                   (dir-name (concat "/ryan.gibb@cl.cam.ac.uk")))
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
                                          ,'((:maildir "/ryan.gibb@cl.cam.ac.uk/Inbox"     :key ?i)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Sent"      :key ?s)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Drafts"    :key ?d)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Archive"   :key ?a)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Spam"      :key ?x)
                                             (:maildir "/ryan.gibb@cl.cam.ac.uk/Trash"     :key ?t)))
                  )))
            ,(let ((mail-address "misc@freumh.org")
                   (dir-name (concat "/misc@freumh.org")))
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
                                             (:maildir "/misc@freumh.org/Trash"   :key ?t)))
                  )))

            )))

  (setq mu4e-context-policy 'pick-first)

                                        ; Fixing duplicate UID errors when using mbsync and mu4e
  (setq mu4e-change-filenames-when-moving t)

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
          (:name "Messages with images"
           :query "mime:image/*"
           :key ?p)))

  (setq mu4e-headers-fields
        '((:maildir . 40)
          (:human-date . 12)
          (:flags . 6)
          (:mailing-list . 10)
          (:from-or-to . 22)
          (:thread-subject . nil)))

  (setq mu4e-search-show-threads nil)

                                        ; (with-eval-after-load "mm-decode"
                                        ;   (add-to-list 'mm-discouraged-alternatives "text/html")
                                        ;   (add-to-list 'mm-discouraged-alternatives "text/richtext"))
  (setq shr-color-visible-luminance-min 80)

  (setq mail-user-agent 'mu4e-user-agent)
  (setq message-dont-reply-to-names 'mu4e-personal-or-alternative-address-p)

  (setq mu4e-search-include-related nil)

  (after! evil-collection
    (evil-collection-define-key 'normal 'mu4e-main-mode-map (kbd "i") 'mu4e-update-index)
    )

  ;; https://github.com/doomemacs/doomemacs/issues/8210
  ;; (setq mu4e-split-view nil)

  (require 'mu4e-icalendar)
  (gnus-icalendar-setup)

  (setq gnus-icalendar-org-capture-file "~/vault/cal.org")
  (setq gnus-icalendar-org-capture-headline '("Calendar"))
  (gnus-icalendar-org-setup)

  ;; https://github.com/doomemacs/doomemacs/issues/7847
  (map! :map mu4e-view-mode-map :ni "A" #'mu4e-view-mime-part-action)
  )
