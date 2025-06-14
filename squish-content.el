;;; squish-content.el --- Reduce width of visible content. -*- lexical-binding: t; -*-

;; Copyright (C) 2025 precompute

;; Author: precompute <git@precompute.net>
;; URL: https://github.com/precompute/legit
;; Created: June 14, 2025
;; Modified: June 14, 2025
;; Version: 0.2.1
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
;; the margins using set-window-margin for that specific window.  It adds advice :after the
;; functions in `squish-content-enable-for’.  We use advice instead of change-major-mode-hook,
;; window-size-change-functions and others because advice runs once, while the others run far too
;; often, and can slow emacs down.  Since this is a cosmetic visual change, it makes sense to
;; only invoke it when the user does something to usefully change visual state.  AFAIK there is
;; no *-hook or *-functions that fills this niche in emacs as of [25-06-14].

;; NOTE: Adding advices can be somewhat unpredictable.  Try and stick to interactive, "top-level"
;; functions.

;;; Code:
;;;; Variables
(defcustom squish-content-width 100
  "The width to which the content of a window should be set to."
  :type 'integer
  :group 'squish-content)

(defcustom squish-content-advice-around-functions
  '( split-window split-window-sensibly
     balance-windows)
  "List of functions that are advised :around by `squish-content’.
If modified, disable and re-enable `squish-content-mode’ to see changes."
  :type 'sexp
  :group 'squish-content)

(defcustom squish-content-advice-after-functions
  '( windmove-left windmove-right windmove-up windmove-down
     find-file
     other-window toggle-frame-fullscreen
     delete-window delete-other-windows)
  "List of functions that are advised :after by `squish-content’.
If modified, disable and re-enable `squish-content-mode’ to see changes."
  :type 'sexp
  :group 'squish-content)

(defcustom squish-content-enable-on-prog-derived t
  "Whether `squish-content’ should be enabled on `prog-mode’ derived major-modes."
  :type 'bool
  :group 'squish-content)

(defcustom squish-content-enable-for
  '( org-mode text-mode dired-mode
     magit-mode Info-mode conf-colon-mode
     helpful-mode shortdoc-mode)
  "List of modes `squish-content’ should be enabled for.
If modified, disable and re-enable `squish-content-mode’ to see changes."
  :type 'sexp
  :group 'squish-content)

;;;; Functions
(defun squish-content--allowed? ()
  "Check whether the current major-mode is allowed for content squishing."
  (or (when squish-content-enable-on-prog-derived (derived-mode-p 'prog-mode))
      (memq major-mode squish-content-enable-for)))

(defun squish-content--squish (window)
  "Squish content of the buffer in WINDOW to `squish-content-width’."
  (when (squish-content--allowed?)
    (let* ((window (or window (selected-window)))
           (width (with-selected-window window (window-body-width)))
           (margin (when (<= squish-content-width width) (/ (- width squish-content-width) 2))))
      (when (and margin (> margin 0)) (set-window-margins window margin margin)))))

(defun squish-content--squish-all (&rest rest)
  "Calls `squish-content--squish’ over all windows in the current frame.
REST is ignored."
  (walk-windows #'squish-content--squish))

(defun squish-content--squish-all--around (f &rest args)
  "Same as `squish-content--squish-all’, but passes ARGS to function F."
  (squish-content--unsquish-all)
  (prog1 (apply f args) (squish-content--squish-all)))

(defun squish-content--unsquish (window)
  "Reset window margins for WINDOW."
  (set-window-margins window nil))

(defun squish-content--unsquish-all (&optional all)
  "Call `squish-content--squish’ for all windows in current frame.
When ALL is non-nil, unsquish all frames."
  (walk-windows #'squish-content--unsquish nil all))

(defun squish-content--add-around-advice (f)
  "Add advice `squish-content--squish-all’ around function F."
  (when (fboundp f) (advice-add f :around #'squish-content--squish-all--around)))

(defun squish-content--add-after-advice (f)
  "Add advice `squish-content--squish-all’ after function F."
  (when (fboundp f) (advice-add f :after #'squish-content--squish-all)))

(defun squish-content--remove-advice (f)
  "Remove advice `squish-content--squish-all’ from function F."
  (advice-remove f #'squish-content--squish-all))

(defun squish-content--remove-advice--around (f)
  "Remove advice `squish-content--squish-all--around’ from function F."
  (advice-remove f #'squish-content--squish-all--around))

(defun squish-content--enable ()
  "Add advice to `squish-content-enable-for’."
  (mapc #'squish-content--add-around-advice squish-content-advice-around-functions)
  (mapc #'squish-content--add-after-advice squish-content-advice-after-functions))

(defun squish-content--disable ()
  "Remove advice from `squish-content-enable-for’."
  (mapc #'squish-content--remove-advice--around squish-content-advice-around-functions)
  (mapc #'squish-content--remove-advice squish-content-advice-after-functions)
  (squish-content--unsquish-all t))

;;;; Mode
(define-minor-mode squish-content-mode
  "Squish-Content modifies the margins to satisfy `squish-content-width’."
  :init-value nil
  :lighter "squish"
  :global t
  (if squish-content-mode (squish-content--enable) (squish-content--disable)))

;;; Provide:
(provide 'squish-content)

;;; squish-content.el ends here
