(load-theme 'gruvbox-dark-medium t)

(defun set-transparent-background ()
  (when (not (display-graphic-p))
    (set-face-attribute 'default nil :background "unspecified-bg")
    (set-face-attribute 'line-number nil :background "unspecified-bg")
    (set-face-attribute 'line-number-current-line nil :background "unspecified-bg"))
  (when (display-graphic-p)
    (set-frame-parameter nil 'alpha-background 80)
    (add-to-list 'default-frame-alist '(alpha-background . 80))
    (set-face-attribute 'line-number nil :background nil)
    (set-face-attribute 'line-number-current-line nil :background nil))
  )

(add-hook 'window-setup-hook 'set-transparent-background)

; (menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(set-face-attribute 'default nil :height 110)

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)

(setq completion-show-help nil)
