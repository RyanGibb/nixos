;;; appearance.el -*- lexical-binding: t; -*-

(setq doom-font (font-spec :family "monospace" :size 15 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "sans-serif" :size 15))
(use-package! gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t))

(defun set-transparent-background (frame)
  (when (not (display-graphic-p frame))
    (set-face-attribute 'default frame :background "unspecified-bg")
    (set-face-attribute 'line-number frame :background "unspecified-bg")
    (set-face-attribute 'line-number-current-line frame :background "unspecified-bg"))
  (when (display-graphic-p frame)
    (set-frame-parameter frame 'alpha-background 80)
    (set-face-attribute 'default frame :background 'unspecified)
    (set-face-attribute 'line-number frame :background 'unspecified)
    (set-face-attribute 'line-number-current-line frame :background 'unspecified))
  )

(if (not (daemonp))
    ;; For a regular Emacs instance, set the background after the window is ready
    (add-hook 'window-setup-hook (lambda () (set-transparent-background nil)))
  ;; For Emacs running as a daemon, set it for each new frame
  (progn
    (add-hook 'after-make-frame-functions 'set-transparent-background)
    (mapc 'set-transparent-background (frame-list))))

(setq display-line-numbers-type 'relative)

(display-battery-mode 1)
