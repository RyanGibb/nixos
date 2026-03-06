;;; appearance.el --- UI configuration -*- lexical-binding: t; -*-

(set-face-attribute 'default nil :family "monospace" :height 120 :weight 'medium)
(set-face-attribute 'variable-pitch nil :family "sans-serif" :height 120)

(use-package gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(display-battery-mode 1)
(blink-cursor-mode -1)

;; Transparent background
(defun my/set-transparent-background (frame)
  "Set transparent background for FRAME, handling both GUI and terminal."
  (if (display-graphic-p frame)
      (progn
        (set-frame-parameter frame 'alpha-background 80)
        (set-face-attribute 'default frame :background 'unspecified)
        (set-face-attribute 'line-number frame :background 'unspecified)
        (set-face-attribute 'line-number-current-line frame :background 'unspecified))
    (set-face-attribute 'default frame :background "unspecified-bg")
    (set-face-attribute 'line-number frame :background "unspecified-bg")
    (set-face-attribute 'line-number-current-line frame :background "unspecified-bg")))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/set-transparent-background)
  (add-hook 'window-setup-hook
            (lambda () (my/set-transparent-background (selected-frame)))))

;; Modeline
(use-package nerd-icons)
(use-package doom-modeline
  :config (doom-modeline-mode 1))

;;; appearance.el ends here
