;;; temper-width.el --- Reduce width of visible content. -*- lexical-binding: t; -*-

;; Copyright (C) 2025 precompute

;; Author: precompute <git@precompute.net>
;; URL: https://github.com/precompute/legit
;; Created: June 14, 2025
;; Modified: August 15, 2025
;; Version: 0.8.0
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
;; It is similar to olivetti-mode and perfect-margin-mode, but lighter (to my eyes).
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
;; Helper functions `temper-width-force-enable-locally’ and `temper-width-force-disable-locally’
;; are provided.  Call them with a prefix argument to disable their effect.

;; To /only/ enable temper-width on specific buffers and nowhere else, enable
;; `temper-width-blind-global-mode', then call `temper-width-force-enable-locally' (or set
;; `temper-width-force-enable' to `t').

;; `temper-width-global-mode' and `temper-width-blind-global-mode' are mutually exclusive.

;;; Code:
;;;; Variables
;;;;; Customizable
(defcustom temper-width-width 100
  "The width to which the content of a window should be set to."
  :type 'integer :group 'temper-width :local t)

(defcustom temper-width-enable-on-prog-derived nil
  "Whether `temper-width’ should be enabled on `prog-mode’ derived major-modes."
  :type 'boolean :group 'temper-width)

(defcustom temper-width-allowed-modes nil
  "List of modes `temper-width’ should be enabled for.
Usage: (add-to-list 'temper-width-allowed-modes 'my-mode)"
  :type 'sexp :group 'temper-width)

;;;;; Internal
(defvar-local temper-width-enabled nil
  "Non-nil when `temper-width’ is enabled in the current buffer.")
(defvar-local temper-width-split-window-function nil
  "Backup for `split-window-preferred-function’.")

;;;;; Other
(defvar-local temper-width-force-enable nil
  "When non-nil, `temper-width’ is force-enabled in this buffer.")
(defvar-local temper-width-force-disable nil
  "When non-nil, `temper-width’ is force-disabled in this buffer.")

;;;; Functions
(defun temper-width--window (window &optional blind?)
  "Temper the width of the content of the window WINDOW.
When BLIND? is t, don't check allowed modes or prog-derived modes."
  (with-selected-window window
    (if (and temper-width-enabled temper-width-force-disable
             (not blind?))
        (temper-width--disable window)
      (when (if blind? temper-width-force-enable
              (and (or (memq major-mode temper-width-allowed-modes)
                       (when temper-width-enable-on-prog-derived
                         (derived-mode-p 'prog-mode))
                       temper-width-force-enable)
                   (not temper-width-force-disable)))
        (let* ((totalwidth (window-total-width))
               (userwidth temper-width-width)
               (bodywidth (window-body-width))
               (margin (/ (abs (- totalwidth userwidth)) 2)))
          (if (> (abs (- totalwidth userwidth)) 2)
              (if (> totalwidth userwidth)
                  (temper-width--enable window margin)
                (temper-width--disable window))
            (when (< bodywidth totalwidth)
              (temper-width--enable window margin))))))))

(defun temper-width--enable (window margin)
  "Enable `temper-width’ in WINDOW with MARGIN."
  (with-selected-window window
    (setq temper-width-enabled t)
    (set-window-parameter window 'split-window 'temper-width-split-window)
    (unless (bound-and-true-p temper-width-split-window-function)
      (setq temper-width-split-window-function split-window-preferred-function))
    (setq-local split-window-preferred-function #'temper-width-split-window-2)
    (set-window-margins window margin margin)))

(defun temper-width--disable (window)
  "Disable `temper-width’ in WINDOW."
  (with-selected-window window
    (setq temper-width-enabled nil)
    (when (eq (window-parameter window 'split-window) 'temper-width-split-window)
      (set-window-parameter window 'split-window nil))
    (set-window-margins window 0 0)))

(defun temper-width-split-window (&optional window size side pixelwise)
  "Reset WINDOW and call `split-window’ with WINDOW SIZE SIDE and PIXELWISE."
  (walk-windows #'temper-width--disable)
  (split-window window size side pixelwise))

(defun temper-width-split-window-2 (&optional window)
  "Reset WINDOW and call `temper-width-split-window-function’ with WINDOW."
  (walk-windows #'temper-width--disable)
  (funcall temper-width-split-window-function window))

(defun temper-width (frame)
  "Invoke `temper-width--window’ for widows on FRAME."
  (with-selected-frame frame (walk-windows #'temper-width--window)))

(defun temper-width-force-enable-locally (arg)
  "Force-enable temper-width in this buffer.
When ARG is non-nil, unset force-enable.
This function makes changes buffer-locally.
For permanent changes, use file/directory variables, or add a mode to
`temper-width-allowed-modes’."
  (interactive "P")
  (if (or temper-width-global-mode temper-width-blind-global-mode)
      (setq temper-width-force-enable (if arg nil t))
    (message "Please enable `temper-width-global-mode’ or `temper-width-blind-global-mode’ first.")))

(defun temper-width-force-disable-locally (arg)
  "Force-disable temper-width in this buffer.
When ARG is non-nil, unset force-disable.
This function makes changes buffer-locally.
For permanent changes, use file/directory variables, or add a mode to
`temper-width-allowed-modes’."
  (interactive "P")
  (if (or temper-width-global-mode temper-width-blind-global-mode)
      (setq temper-width-force-disable (if arg nil t))
    (message "Please enable `temper-width-global-mode’ or `temper-width-blind-global-mode’ first.")))

(defun temper-width-global-mode--enable ()
  "Enable `temper-width-global-mode’ globally."
  (add-hook 'window-size-change-functions #'temper-width))

(defun temper-width-global-mode--disable ()
  "Disable `temper-width-global-mode’ globally."
  (remove-hook 'window-size-change-functions #'temper-width)
  (setq split-window-preferred-function temper-width-split-window-function)
  (setq temper-width-split-window-function nil)
  (walk-windows #'temper-width--disable nil t))

(defun temper-width-blind (frame)
  "Invoke `temper-width--window’ for windows on FRAME, with BLIND set to true."
  (with-selected-frame frame
    (walk-windows (lambda (w) (temper-width--window w t)))))

(defun temper-width-blind-global-mode--enable ()
  "Enable `temper-width-blind-global-mode’ globally."
  (add-hook 'window-size-change-functions #'temper-width-blind))

(defun temper-width-blind-global-mode--disable ()
  "Disable `temper-width-blind-global-mode’ globally."
  (remove-hook 'window-size-change-functions #'temper-width-blind)
  (setq split-window-preferred-function temper-width-split-window-function)
  (setq temper-width-split-window-function nil)
  (walk-windows #'temper-width--disable nil t))

;;;; Mode
(define-minor-mode temper-width-blind-global-mode
  "Temper-Width-Blind tempers content in specific buffers to a readable width."
  :init-value nil
  :lighter " tmprbl"
  :global t
  (when temper-width-global-mode
    (temper-width-global-mode -1))
  (if temper-width-blind-global-mode
      (temper-width-blind-global-mode--enable)
    (temper-width-blind-global-mode--disable)))

(define-minor-mode temper-width-global-mode
  "Temper-Width tempers content to a readable width."
  :init-value nil
  :lighter " tmpr"
  :global t
  (when temper-width-blind-global-mode
    (temper-width-blind-global-mode -1))
  (if temper-width-global-mode
      (temper-width-global-mode--enable)
    (temper-width-global-mode--disable)))

;;; Provide:
(provide 'temper-width)

;;;; TODO
;;;; - Add something that fixes things when the size of the frame changes, especially when maximizing it.
;;;; - Alternative mode that allows adjusting margins to keep window as close to the center as possible.
;;; temper-width.el ends here
