(setq savehist-file "~/.emacs.d/savehist")
(savehist-mode 1)
(setq savehist-additional-variables
      '(command-history
        search-ring
        regexp-search-ring
        kill-ring))
(setq history-length 10000)
(setq savehist-save-minibuffer-history t)

(desktop-save-mode 0)
(setq desktop-dirname "~/.emacs.d/desktop/")
(setq desktop-save t)
(add-hook 'emacs-startup-hook 'desktop-read)

(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))

