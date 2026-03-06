;;; tools.el --- Development tools -*- lexical-binding: t; -*-

;;;; Workspaces

(use-package perspective
  :custom
  (persp-mode-prefix-key (kbd "C-c w"))
  (persp-sort 'oldest)
  :config
  (persp-mode)
  ;; M-1 through M-9 to switch workspace by number
  (dotimes (i 9)
    (global-set-key (kbd (format "M-%d" (1+ i)))
                    `(lambda () (interactive)
                       (persp-switch-by-number ,(1+ i)))))

  (defun my/open-in-workspace (name fn)
    "Switch to workspace NAME and call FN."
    (persp-switch name)
    (funcall fn))

  ;; Create/switch workspace when switching projects
  (advice-add 'project-switch-project :around
              (lambda (orig-fn &optional dir)
                (let* ((dir (or dir (project-prompt-project-dir)))
                       (name (file-name-nondirectory (directory-file-name dir))))
                  (persp-switch name)
                  (funcall orig-fn dir))))

  (defun my/kill-current-workspace ()
    "Kill the current workspace."
    (interactive)
    (if (cdr (persp-names))
        (persp-kill (persp-current-name))
      (user-error "Can't delete last workspace")))

  (defun my/restart-and-restore ()
    "Save the current session and restart Emacs."
    (interactive)
    (persp-save-state-to-file)
    (setq persp-auto-resume-time 1)
    (restart-emacs))

  (defun my/workspace-display ()
    "Display a list of workspaces in the echo area."
    (interactive)
    (let* ((names (persp-names))
           (current (persp-current-name))
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
  :config
  (defun my/magit-commit-update ()
    "Create a commit with the message \"update\"."
    (interactive)
    (magit-commit-create '("-m" "update")))
  (transient-append-suffix 'magit-commit "c"
    '("u" "Update" my/magit-commit-update)))

;;;; PDF

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)

  (defun my/pdf-view-fit-window-to-width ()
    "Resize the current window to match the width of the PDF."
    (interactive)
    (when (eq major-mode 'pdf-view-mode)
      (let* ((pdf-px-width (car (pdf-view-image-size)))
             (char-width (frame-char-width))
             (desired-cols (round (/ (float pdf-px-width) (float char-width))))
             (delta (- desired-cols (window-width))))
        (window-resize (selected-window) delta t))))

  (add-hook 'pdf-view-after-change-page-hook #'my/pdf-view-fit-window-to-width))

;;;; Help

(use-package helpful
  :config
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key] #'helpful-key))

;;;; Xref

(setq xref-show-definitions-function #'consult-xref
      xref-show-xrefs-function #'consult-xref)

;;;; Eglot (LSP)

(use-package eglot
  :hook ((neocaml-mode neocaml-interface-mode nix-mode) . eglot-ensure)
  :config
  ;; Only needed for modes eglot doesn't have a default server for
  (add-to-list 'eglot-server-programs
               '((neocaml-mode neocaml-interface-mode) . ("ocamllsp")))
  (add-to-list 'eglot-server-programs
               '(nix-mode . ("nixd"))))

;;;; RSS

(use-package elfeed
  :commands elfeed)

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

;;; tools.el ends here
