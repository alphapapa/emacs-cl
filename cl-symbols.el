;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 10, Symbols.

(IN-PACKAGE "EMACS-CL")

;;; Note that the Emacs Lisp symbol nil doubles as the Common Lisp
;;; symbol NIL.  This requires special attention in SYMBOL-NAME.

(fset 'SYMBOLP (symbol-function 'symbolp))

(defun KEYWORDP (sym)
  (and (SYMBOLP sym)
       (eq (SYMBOL-PACKAGE sym) *keyword-package*)))

(fset 'MAKE-SYMBOL (symbol-function 'make-symbol))

(defun COPY-SYMBOL (sym &optional copy-properties)
  (let ((new (make-symbol (symbol-name sym))))
    (when copy-properties
      (when (boundp sym)
	(setf (symbol-value new) (symbol-value sym)))
      (when (fboundp sym)
	(setf (symbol-function new) (symbol-function sym)))
      (setf (symbol-plist new) (copy-list (symbol-plist sym))))
    new))

(defun GENSYM (&optional x)
  (multiple-value-bind (prefix suffix)
      (cond
	((null x)	(values "G" (1- (incf *GENSYM-COUNTER*))))
	((STRINGP x)	(values x (1- (incf *GENSYM-COUNTER*))))
	((INTEGERP x)	(values "G" x))
	(t		(error "type error")))
    (MAKE-SYMBOL (FORMAT nil "~A~D" prefix suffix))))

(defvar *GENSYM-COUNTER* 1)

(defvar *gentemp-counter* 1)

(defun* GENTEMP (&optional (prefix "T") (package *PACKAGE*))
  (loop
   (MULTIPLE-VALUE-BIND (symbol found)
       (INTERN (FORMAT nil "~A~D" prefix *gentemp-counter*) package)
     (unless found
       (return-from GENTEMP (VALUES symbol)))
     (incf *gentemp-counter*))))

(fset 'SYMBOL-FUNCTION (symbol-function 'symbol-function))

(defsetf SYMBOL-FUNCTION (symbol) (fn)
  `(fset ,symbol ,fn))

(DEFSETF SYMBOL-FUNCTION (symbol) (fn)
  `(fset ,symbol ,fn))

(defun SYMBOL-NAME (symbol)
  (if symbol
      (symbol-name symbol)
      "NIL"))

(defvar *symbol-package-table* (make-hash-table :test 'eq :weakness t))

(defun SYMBOL-PACKAGE (sym)
  (gethash sym *symbol-package-table*))

(defsetf SYMBOL-PACKAGE (sym) (package)
  `(if (null ,package)
       (progn (remhash ,sym *symbol-package-table*) ,package)
       (setf (gethash ,sym *symbol-package-table*) ,package)))

(fset 'SYMBOL-PLIST (symbol-function 'symbol-plist))

(defsetf SYMBOL-PLIST (symbol) (plist)
  `(setplist ,symbol ,plist))

(fset 'SYMBOL-VALUE (symbol-function 'symbol-value))

(defsetf SYMBOL-VALUE (symbol) (val)
  `(set ,symbol ,val))

(defun GET (symbol property &optional default)
  (let ((val (member property (symbol-plist symbol))))
    (if val
	(car val)
	default)))

(defsetf GET (symbol property &optional default) (val)
  `(put ,symbol ,property ,val))

(defun REMPROP (symbol property)
  (setplist symbol (delete property (symbol-plist symbol))))

(fset 'BOUNDP (symbol-function 'boundp))

(fset 'MAKUNBOUND (symbol-function 'makunbound))

(fset 'SET (symbol-function 'set))
