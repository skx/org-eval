;;; org-eval.el --- Execute named org-mode blocks on load/save -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Steve Kemp

;; Author: Steve Kemp <steve@steve.fi>
;; Maintainer: Steve Kemp <steve@steve.fi>
;; Version: 0.3.6
;; Package-Requires: ((emacs "29.1") (org "9.0"))
;; Keywords: org, outlines
;; URL: https://github.com/skx/org-eval

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package can be used to ensure that named blocks are executed
;; when org-mode files are visited, or saved after edits.
;;
;; This is designed to allow you to update all tables, automatically,
;; or perform other similar utility actions.
;;
;; To use these facilities define blocks like so in your org-mode files:
;;
;; #+NAME: org-eval-load
;; #+BEGIN_SRC emacs-lisp :results output silent
;;   (message "I like cakes when documents load.")
;; #+END_SRC
;;
;; #+NAME: org-eval-save
;; #+BEGIN_SRC emacs-lisp :results output silent
;;   (message "I like a party, just before a save!")
;; #+END_SRC
;;
;; By default `org-mode' will prompt you to confirm that you want
;; execution to happen, we use `org-eval-prefix-list' to enable
;; whitelisting particular prefix-directories, which means there is
;; no need to answer `y` to the prompt.
;;
;; So as a second line of defense we require you to explicitly
;; name the blocks that you trust in your configuration, like so:
;;
;;   (use-package org-eval
;;     :after org
;;     :config
;;      (setq org-eval-prefix-list (list (expand-file-name "~/Private/"))
;;            org-eval-loadblock-name "skx-loadblock"
;;            org-eval-saveblock-name "skx-saveblock")
;;      (org-eval-global-mode 1))
;;
;; This means blocks named `skx-loadblock' will be executed when files
;; are loaded from beneath `~/Private', and on-save the block named skx-saveblock
;; will be executed.
;;
;; I hope that this means there is no realistic way for malicious files
;; to execute arbitrary code upon your system;  The files would have to
;; have the correct named blocks, and be saved within a trusted directory
;; before any possible malicious code could be executed.
;;
;;

(require 'org)
(require 'ob-core)

;; Avoid byte-compile warnings for org functions
(declare-function org-babel-execute-src-block "ob-core" (&optional arg info))
(declare-function org-babel-goto-named-src-block "ob-core" (name))
(declare-function org-babel-src-block-names "ob-core" (&optional lang))
(declare-function org-save-outline-visibility "org" (arg &rest body))


;;; Configuration

(defgroup org-eval nil
  "Automatic evaluation of code blocks within `org-mode` files."
  :group 'org)

(defcustom org-eval-prefix-list nil
  "Directories under which evaluation is allowed."
  :type '(repeat directory)
  :group 'org-eval)

(defcustom org-eval-loadblock-name
  nil
  "Name of the source block executed when an Org file is visited.

If nil, no block is executed on load."
  :type '(choice (const :tag "Disable" nil)
                 string)
  :group 'org-eval)

(defcustom org-eval-saveblock-name
  nil
  "Name of the source block executed before an Org file is saved.

If nil, no block is executed on save."
  :type '(choice (const :tag "Disable" nil)
                 string)
  :group 'org-eval)




;;; Code:

(defun org-eval-execute-named-block (name)
  "Execute the specified block if it exists, within the current file.

NAME is the name of the block which will be evaluated."
  (save-excursion
    (org-save-outline-visibility t
      (if (member name (org-babel-src-block-names))
          (if (org-eval-safe-file-p (buffer-file-name))
              (let ((org-confirm-babel-evaluate nil))
                (org-babel-goto-named-src-block name)
                (org-babel-execute-src-block))
            (message
             "%s not included in org-eval-prefix-list, refusing evaluation of %s"
             (buffer-file-name)
             name))))))

(defun org-eval-loadblock ()
  "Execute the block with name `org-eval-loadblock-name'."
  (if org-eval-loadblock-name
      (org-eval-execute-named-block org-eval-loadblock-name)))

(defun org-eval-saveblock ()
  "Execute the block with name `org-eval-saveblock-name'."
  (if org-eval-saveblock-name
      (org-eval-execute-named-block org-eval-saveblock-name)))

(defun org-eval-safe-file-p (file)
  "Return non-nil if FILE is in one of `org-eval-allowed-dirs`."
  (when (and file org-eval-prefix-list)
    (let ((truename (file-truename file)))
      (seq-some (lambda (dir)
                  (string-prefix-p (file-name-as-directory (file-truename dir))
                                   truename))
                org-eval-prefix-list))))

;; Make this a minor-mode

(defun org-eval--maybe-load ()
  "Run load block when appropriate."
  (when (derived-mode-p 'org-mode)
    (org-eval-loadblock)))

(defun org-eval--maybe-save ()
  "Run save block when appropriate."
  (when (derived-mode-p 'org-mode)
    (org-eval-saveblock)))

;;;###autoload
(define-minor-mode org-eval-mode
  "Minor mode to automatically evaluate named Org blocks on load and save.

When enabled, executes:

- The block named by `org-eval-loadblock-name' on file visit.
- The block named by `org-eval-saveblock-name' before save.

Evaluation only occurs for files beneath directories contained upon
the `org-eval-prefix-list'."
  :lighter " OrgEval"
  :group 'org-eval
  (if org-eval-mode
      (progn
        ;; Run load block immediately
        (org-eval--maybe-load)

        ;; Add buffer-local save hook
        (add-hook 'before-save-hook
                  #'org-eval--maybe-save
                  nil
                  t))
    ;; Disable mode
    (remove-hook 'before-save-hook
                 #'org-eval--maybe-save
                 t)))


;;
;; Putting this in a lambda gave me byte-compiler warnings
;;   org-eval.el:200:2: Warning: docstring has wrong usage of unescaped single quotes
;;   (use \=' or different quoting such as ...')
;;
;; Those warnings seem to come from the define-globalized-minor-mode.  Weird.
;;
(defun org-eval-mode--enable ()
  "Helper function to enable our globalized mode."
  (when (derived-mode-p 'org-mode)
    (org-eval-mode 1)))


;;;###autoload
(define-globalized-minor-mode org-eval-global-mode
  org-eval-mode
  org-eval-mode--enable)


(provide 'org-eval)
;;; org-eval.el ends here
