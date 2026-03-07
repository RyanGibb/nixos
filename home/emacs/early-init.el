;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;; Nix manages packages — disable installation but keep autoload activation
;; https://github.com/nix-community/emacs-overlay/issues/497
(setq package-archives nil)

;; Defer garbage collection during startup for faster load
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024)))) ; 16MB after startup

;; Disable UI elements before they render
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Prevent the glimpse of unstyled Emacs by disabling these early
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
