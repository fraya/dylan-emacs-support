;;; dime-browse.el --- Dylan interaction mode -*- lexical-binding: t -*-

;; Package-Requires: ((emacs "25.1"))
;; URL: https://opendylan.org/
;; Author: Rui Patrocínio <rui.patrocinio@netvisao.pt>
;; Author: Hannes Mehnert <hannes@opendylan.org>
;; SPDX-License-Identifier: GPL-2.0-or-later

;;; Commentary:

;; Dylan class browser for Dime.

;;; Code:

;; Originally adapted from `slime-xref-browser.el'.

(require 'tree-widget)

(require 'dime)

(defun dime-browse--expand-subclass-node (widget)
  (or (widget-get widget :args)
      (let ((name (widget-get widget :tag)))
	(loop for kid in (dime-eval `(swank:dylan-subclasses ,name))
	      collect `(tree-widget :tag ,kid
				    :expander dime-browse--expand-subclass-node
				    :has-children t)))))

(defun dime-browse--expand-superclass-node (widget)
  (or (widget-get widget :args)
      (let ((name (widget-get widget :tag)))
	(loop for kid in (dime-eval `(swank:dylan-superclasses ,name))
	      collect `(tree-widget :tag ,kid
				    :expander dime-browse--expand-superclass-node
				    :has-children t)))))

(defun dime-browse-subclasses (name)
  "Read the name of a class and show its subclasses."
  (interactive (list (dime-read-symbol-name "Class Name: ")))
  (dime-browse--call-with-setup
   "*Dime class browser*" (dime-current-project) dylan-buffer-module "Class Browser"
   (lambda ()
     (widget-create 'tree-widget :tag name
                    :expander 'dime-browse--expand-subclass-node
                    :has-echildren t))))

(defun dime-browse-superclasses (name)
  "Read the name of a class and show its superclasses."
  (interactive (list (dime-read-symbol-name "Class Name: ")))
  (dime-browse--call-with-setup
   "*Dime class browser*" (dime-current-project) dylan-buffer-module "Class Browser"
   (lambda ()
     (widget-create 'tree-widget :tag name
                    :expander 'dime-browse--expand-superclass-node
                    :has-echildren t))))

(defvar dime-browse-map nil
  "Keymap for tree widget browsers")

(unless dime-browse-map
  (setq dime-browse-map (make-sparse-keymap))
  (set-keymap-parent dime-browse-map widget-keymap)
  (define-key dime-browse-map "q" 'bury-buffer))

(defun dime-browse--call-with-setup (buffer project module title fn)
  (switch-to-buffer buffer)
  (kill-all-local-variables)
  (setq dime-buffer-project project)
  (setq dylan-buffer-module module)
  (let ((inhibit-read-only t)) (erase-buffer))
  (widget-insert title "\n\n")
  (save-excursion
    (funcall fn))
  (lisp-mode-variables t)
  (dime-mode t)
  (use-local-map dime-browse-map)
  (widget-setup))

(provide 'dime-browse)

;;; dime-browse.el ends here
