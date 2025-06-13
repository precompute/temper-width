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
(defvar squish-content--split-function-backup nil
  "Backup for the original value of `split-window-preferred-function’.")

;;;; Hooks
;; change-major-mode-hook
;; window-size-change-functions
;; text-scale-mode-hook

;;;; Functions
(defun squish-content (&optional window)
  "Squish content of the buffer in WINDOW to `squish-content-width’."
  (let* ((window (or window (selected-window)))
         (width (with-selected-window window (window-body-width))))
    ((lambda (z) (set-window-margins window z z))
     (when (< squish-content-width width) (/ (- width squish-content-width) 2)))))

(defun squish-content--unsquish (window)
  "Reset window margins for WINDOW."
  (set-window-margins window nil))

(defun squish-content--unsquish-all (&optional all)
  "Call `squish-content’ for all windows in current frame.
When ALL is non-nil, unquish all frames."
  (walk-windows #'squish-content--unsquish nil all))

(defun squish-window-split-window (&rest args)
  "Calls `squish-content--unsquish-all’ and then `squish-content--split-function-backup’ with ARGS."
  (squish-content--unsquish-all)
  (funcall squish-content--split-function-backup args))

;;;; Mode
(define-minor-mode squish-content-mode
  "Squish-Content modifies the margins to satisfy `squish-content-width’."
  :init-value nil
  :lighter "squish"
  (if squish-content-mode
      (progn (setq squish-content--split-function-backup split-window-preferred-function)
             (setq split-window-preferred-function #'squish-window-split-window)
             ;; (add-hook 'window-size-change-functions #'squish-content t)
             )
    (setq split-window-preferred-function squish-content--split-function-backup)
    ;; (remove-hook 'window-size-change-functions #'squish-content t)
    (squish-content--unsquish-all t)))

;; [25-06-14 03:03:20] window-size-change-functions seems to call itself far too often, even when
;; scrolling!  That defeats the purpose of this package.  Maybe there’s list of functions that
;; are only invoked when the dimensions of a window are changed.
;;; Provide:
(provide 'squish-content)

;;; squish-content.el ends here
