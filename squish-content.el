;;; squish-content.el --- Reduce width of visible content. -*- lexical-binding: t; -*-

;; Copyright (C) 2025 precompute

;; Author: precompute <git@precompute.net>
;; URL: https://github.com/precompute/legit
;; Created: June 14, 2025
;; Modified: June 14, 2025
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package reduces the width of the displayed content in a buffer.
;; It is similar to olivetti-mode and perfect-margin-mode, but lighter and lacks features.

;; It calculates the width of a windows, and if it is larger than squish-content-width, adjusts
;; the margins using set-window-margin for that specific window.
;; It associates itself with hooks that fire when a window is introduced, or when its dimensions
;; are changed.

;;; Code:
;;;; Variables
(defcustom squish-content-width 100
  "The width to which the content of a window should be set to."
  :type 'integer
  :group 'squish-content)

;;;; Internal
(defvar squish-content--split-function #'split-window-sensibly
  "The original value of `split-window-preferred-function’.")

;;;; Hooks
;; change-major-mode-hook
;; window-size-change-functions
;; text-scale-mode-hook

;; after-change-major-mode-hook
;;;; Functions
(defun squish-content--allowed-mode ()
  "Check if the current major-mode is allowed for content squishing."
  (or (derived-mode-p 'prog-mode)
      (memq major-mode '( org-mode text-mode dired-mode
                          magit-mode Info-mode conf-colon-mode
                          helpful-mode shortdoc-mode lexic))))

(defun squish-content--squish (&optional window)
  "Squish content of the buffer in WINDOW to `squish-content-width’."
  (when (squish-content--allowed-mode)
    (let* ((window (or window (selected-window)))
           (width (with-selected-window window (window-body-width))))
      ((lambda (z) (set-window-margins window z z))
       (when (< squish-content-width width) (/ (- width squish-content-width) 2))))))

(defun squish-content--squish-all (&optional window)
  "Calls `squish-content--squish’ over all windows in the current frame.
Optional WINDOW for abnormal hook compatibility."
  (message "Squishing all!")
  (set-window-parameter nil 'split-window 'squish-window-split-window)
  (walk-windows #'squish-content--squish))

(defun squish-content--unsquish (window)
  "Reset window margins for WINDOW."
  (set-window-margins window nil))

(defun squish-content--unsquish-all (&optional all)
  "Call `squish-content--squish’ for all windows in current frame.
When ALL is non-nil, unquish all frames."
  (message "Un-squishing all!")
  (set-window-parameter nil 'split-window nil)
  (walk-windows #'squish-content--unsquish nil all))

(defun squish-window-split-window (&optional window size side pixelwise)
  "Calls `squish-content--unsquish-all’ and then `split-window’ with WINDOW, SIZE, SIDE, PIXELWISE.
I don’t know why this needs to be given to the split-window parameter.  Copied from olivetti."
  (squish-content--unsquish-all)
  (split-window window size side pixelwise))

(defun squish-window-split-window-sensibly (&optional window)
  "Calls `squish-content--unsquish-all’ and then `split-window-sensibly’ with WINDOW."
  (squish-content--unsquish-all)
  (split-window-sensibly window)
  (squish-content--squish-all))

;;;; Mode
(define-minor-mode squish-content-mode
  "Squish-Content modifies the margins to satisfy `squish-content-width’."
  :init-value nil
  :lighter "squish"
  :global t
  (if squish-content-mode
      (progn (setq split-window-preferred-function #'squish-window-split-window-sensibly)
             ;; (add-hook 'window-size-change-functions #'squish-content--squish-all)
             ;; (add-hook 'after-change-major-mode-hook #'squish-content--squish-all)
             ;; (add-hook 'window-selection-change-functions #'squish-content--squish-all)
             )
    ;; (setq split-window-preferred-function squish-content--split-function)
    (setq split-window-preferred-function #'split-window-sensibly)
    ;; (remove-hook 'window-size-change-functions #'squish-content--squish-all)
    ;; (remove-hook 'after-change-major-mode-hook #'squish-content--squish-all)
    ;; (remove-hook 'window-selection-change-functions #'squish-content--squish-all)
    (squish-content--unsquish-all t)))

;; [25-06-14 03:03:20] window-size-change-functions are called even during scrolling!  That
;; defeats the purpose of this package.  Maybe there’s list of functions that are only invoked
;; when the dimensions of a window are changed, and not during redisplay.

;; [25-06-14 05:05:06] There might be another way to make it work.  Enabled in these modes: prog
;; org text dired magit Info conf-colon helpful shortdoc lexic Actions it needs to track:
;; Fullscreen, overall dimension change, split, buffer popup, selection change For prog, I could
;; use derived-mode-p, and the entire check could be in a (or) block

;; [25-06-14 15:11:35] Tried hooking to only window-selection-change-functions, but it seems to
;; flip the squishing on every selection.
;;; Provide:
(provide 'squish-content)

;;; squish-content.el ends here
