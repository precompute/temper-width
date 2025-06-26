;;; temper-width.el --- Reduce width of visible content. -*- lexical-binding: t; -*-

;; Copyright (C) 2025 precompute

;; Author: precompute <git@precompute.net>
;; URL: https://github.com/precompute/legit
;; Created: June 14, 2025
;; Modified: June 26, 2025
;; Version: 0.5.0
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

;; This package reduces the width of displayed content.
;; It is similar to olivetti-mode and perfect-margin-mode, but lighter.
;; It runs as a global mode, but can be enabled/disabled on a per-file basis.

;; If the total-width of a window is larger than `temper-width-width’, its margins are modified
;; to make body-width≈temper-width-width.

;; The function `temper-width’ is added to `window-size-change-functions’.

;; Set `temper-width-enable-on-prog-derived’ to `t’ to temper all windows derived from
;; `prog-mode.’

;; To temper all buffers with a certain major-mode, add it to `temper-width-allowed-modes’.

;; To force-enable temper-width for a certain buffer, set the variable
;; `temper-width-force-enable’ to `t’.  Similarly, to force disable, set
;; `temper-width-force-disable’ to `t’.

;;; Code:
;;;; Variables
;;;;; Customizable
(defcustom temper-width-width 100
  "The width to which the content of a window should be set to."
  :type 'integer :group 'temper-width :local t)

(defcustom temper-width-enable-on-prog-derived nil
  "Whether `temper-width’ should be enabled on `prog-mode’ derived major-modes."
  :type 'bool :group 'temper-width)

(defcustom temper-width-allowed-modes nil
  "List of modes `temper-width’ should be enabled for.
Usage: (add-to-list 'temper-width-allowed-modes 'my-mode) "
  :type 'sexp :group 'temper-width)

;;;;; Internal
(defvar-local temper-width-enabled nil
  "Non-nil when `temper-width’ is enabled in the current buffer.")

;;;;; Other
(defvar-local temper-width-force-enable nil
  "When non-nil, `temper-width’ is force-enabled in this buffer.")
(defvar-local temper-width-force-disable nil
  "When non-nil, `temper-width’ is force-disabled in this buffer.")

;;;; Functions
(defun temper-width--window (window)
  "Temper the width of the content of the window WINDOW."
  (with-selected-window window
    (if (or (memq major-mode temper-width-allowed-modes)
            (when temper-width-enable-on-prog-derived (derived-mode-p 'prog-mode))
            temper-width-force-enable)
        (let* ((totalwidth (window-total-width))
               (userwidth temper-width-width)
               (bodywidth (window-body-width))
               (margin (/ (abs (- totalwidth userwidth)) 2)))
          (if (> (abs (- totalwidth userwidth)) 2)
              (if (> totalwidth userwidth)
                  (progn (setq temper-width-enabled t)
                         (set-window-margins window margin margin))
                (setq temper-width-enabled nil)
                (set-window-margins window 0 0))
            (when (< bodywidth totalwidth)
              (setq temper-width-enabled t)
              (set-window-margins window margin margin))))
      (when temper-width-force-disable
        (temper-width--disable window)))))

(defun temper-width--disable (window)
  "Disable `temper-width’ in WINDOW."
  (with-selected-window window
    (when temper-width-enabled
      (setq temper-width-enabled nil)
      (set-window-margins window 0 0))))

(defun temper-width (frame)
  "Invoke `temper-width--window’ for widows on FRAME."
  (with-selected-frame frame (walk-windows #'temper-width--window)))

(defun temper-width-global-mode--enable ()
  "Enable `temper-width-global-mode’ globally."
  (add-hook 'window-size-change-functions #'temper-width))

(defun temper-width-global-mode--disable ()
  "Disable `temper-width-global-mode’ globally."
  (remove-hook 'window-size-change-functions #'temper-width)
  (walk-windows #'temper-width--disable nil t))

;;;; Mode
(define-minor-mode temper-width-global-mode
  "Temper-Width tempers content to a readable width."
  :init-value nil
  :lighter "tmpr"
  :global t
  (if temper-width-global-mode
      (temper-width-global-mode--enable)
    (temper-width-global-mode--disable)))

;;; Provide:
(provide 'temper-width)

;;; temper-width.el ends here
