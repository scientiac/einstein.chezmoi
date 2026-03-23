;;; package --- congif.el
;;; Commentary:
;;; This is my doom Emacs configuration.
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;;; Code:

(setq user-full-name "Spandan Guragain"
      user-mail-address "spandan@scientiac.space")

;; N Λ N O Font Settings
;; 'RobotoMono Nerd Font' is the standard name for the ttf-roboto-mono-nerd package
(setq doom-font (font-spec :family "RobotoMono Nerd Font Propo" :size 14 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "Inter" :size 15))

;; This ensures that symbols (icons) use the Nerd Font set specifically
(setq doom-symbol-font (font-spec :family "Symbols Nerd Font Mono" :size 12))

;; Optional: Makes the line spacing a bit taller to match the N Λ N O aesthetic
(setq-default line-spacing 0.12)

;; Use NANO Theme
(setq doom-theme 'doom-nano-dark)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/Org/")

;; Use NANO Modline
(use-package! doom-nano-modeline
  :config
  (doom-nano-modeline-mode 1)
  (global-hide-mode-line-mode 1))

;; Clean Dashboard
(setq fancy-splash-image (concat doom-private-dir "themes/doom-emacs-white.svg"))

;;; config.el ends here
