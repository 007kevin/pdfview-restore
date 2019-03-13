;;; pdf-view-restore.el --- Support for opening last known pdf position in pdfview mode -*- lexical-binding: t; -*-

;; Copyright (c) 2019 Kevin Kim <kevinkim1991@gmail.com>

;; Author: Kevin Kim <kevinkim1991@gmail.com>
;; URL: https://github.com/007kevin/pdf-view-restore
;; Keywords: files convenience
;; Version: 0.1
;; Package-Requires: ((pdf-tools "0.90") (emacs "24.4"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Support for saving and opening last known pdf position in pdfview mode.
;; Information  will be saved relative to the pdf being viewed so ensure
;; `pdf-view-restore-filename' is in the same directory as the viewing pdf.
;;
;; To enable, add the following:
;;   (pdf-view-restore-setup)

;;; Code:

(require 'pdf-view)

(defcustom pdf-view-restore-filename ".pdf-view-restore"
  "Filename to save the last known pdf position."
  :group 'pdf-view-restore
  :type 'string)

;;;###autoload
(defun pdf-view-restore-setup ()
  "Setup the necessary hooks to automatically save and restore pages
in pdf-view-mode. The before and after advice onto pdf-view-mode is there
to prevent saving upon creating the pdf-view-mode buffer."
  (let ((allow-save t))
    (advice-add 'pdf-view-mode :before (lambda() (setq allow-save nil)))
    (advice-add 'pdf-view-mode :after (lambda() (setq allow-save t)))
    (add-hook 'pdf-view-mode-hook 'pdf-view-restore)
    (add-hook 'pdf-view-after-change-page-hook
              (lambda() (if allow-save (pdf-view-restore-save))))))

(defun pdf-view-restore ()
  "Restore page."
  (when (eq major-mode 'pdf-view-mode)
    ;; This buffer is in pdf-view-mode
  (let ((page (pdf-view-restore-get-page)))
    (if page (pdf-view-goto-page page)))))

(defun pdf-view-restore-save ()
  "Save restore information."
  (when (eq major-mode 'pdf-view-mode)
    ;; This buffer is in pdf-view-mode
    (let ((page (pdf-view-current-page)))
      (pdf-view-restore-set-page page))))

(defun pdf-view-restore-get-page ()
  "Return restore page."
  (let* ((alist (pdf-view-restore-unserialize))
         (key (pdf-view-restore-key))
         (val (cadr (assoc key alist))))
    val))

(defun pdf-view-restore-set-page (page)
  "Save restore PAGE."
  (let* ((alist (pdf-view-restore-unserialize))
         (key (pdf-view-restore-key)))
    (pdf-view-restore-serialize (pdf-view-restore-alist-set key page alist))))

(defun pdf-view-restore-alist-set (key val alist)
  "Set property KEY to VAL in ALIST.  Return new alist."
  (let ((alist (delq (assoc key alist) alist)))
    (add-to-list 'alist `(,key ,val))))

(defun pdf-view-restore-key ()
  "Key for storing data is based on filename."
  (file-name-base buffer-file-name))

;;; Serialization
(defun pdf-view-restore-serialize (data)
  "Serialize DATA to `pdf-view-restore-filename'.
The saved data can be restored with `pdf-view-restore-unserialize'."
  (when (file-writable-p pdf-view-restore-filename)
    (with-temp-file pdf-view-restore-filename
      (insert (let (print-length) (prin1-to-string data))))))

(defun pdf-view-restore-unserialize ()
  "Read data serialized by `pdf-view-restore-serialize' from `pdf-view-restore-filename'."
  (with-demoted-errors
      "Error during file deserialization: %S"
    (when (file-exists-p pdf-view-restore-filename)
      (with-temp-buffer
        (insert-file-contents pdf-view-restore-filename)
        ;; this will blow up if the contents of the file aren't
        ;; lisp data structures
        (read (buffer-string))))))


(provide 'pdf-view-restore)
;;; pdf-view-restore.el ends here
