;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 5, Data and Control Flow.

(IN-PACKAGE "EMACS-CL")

(defvar *setf-definitions* (make-hash-table))

(defun APPLY (fn &rest args)
  (cond
    ((INTERPRETED-FUNCTION-P fn)
     (eval-lambda-form (append (list (aref fn 1))
			       (butlast args)
			       (car (last args)))
		       (aref fn 2)))
    ((FUNCTIONP fn)
     (apply #'apply fn args))
    (t
     (apply #'apply (FDEFINITION fn) args))))

(defmacro* DEFUN (name lambda-list &body body)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (SETF (FDEFINITION ,name) (function* (lambda ,lambda-list ,@body)))))

; (cl:defmacro DEFUN (name lambda-list &body body)
;   `(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
;      (SETF (FDEFINITION ,name)
;	     (FUNCTION (LAMBDA ,lambda-list
;	       (BLOCK ,name ,@body))))
;      ',name))

(defun FDEFINITION (name)
  (cond
    ((symbolp name)
     (symbol-function name))
    ((and (consp name) (eq (first name) 'SETF) (eq (cddr name) nil))
     (gethash (second name) *setf-definitions*))
    (t
     (error))))

(defsetf FDEFINITION (name) (fn)
  `(cond
    ((symbolp ,name)
     (setf (symbol-function ,name) ,fn))
    ((and (consp ,name) (eq (first ,name) 'SETF) (eq (cddr ,name) nil))
     (setf (gethash (second ,name) *setf-definitions*) ,fn))
    (t
     (error "type error"))))

;;; TODO: fboundp

;;; TODO: fmakunbound

;;; TODO: flet, labels, macrolet

(defun FUNCALL (fn &rest args)
  (cond
    ((INTERPRETED-FUNCTION-P fn)
     (eval-lambda-form (cons (aref fn 1) args) (aref fn 2)))
    ((FUNCTIONP fn)
     (apply fn args))
    (t
     (apply (FDEFINITION fn) args))))

;;; TODO: function

(defun FUNCTION-LAMBDA-EXPRESSION (fn)
  (cond
    ((INTERPRETED-FUNCTION-P fn)	(VALUES (aref fn 1) T nil))
    ((subrp fn)				(VALUES nil nil nil))
    ((compiled-function-p fn)		(VALUES nil nil nil))
    ((FUNCTIONP fn)			(VALUES nil T nil))
    (t					(error "type error"))))

(defun FUNCTIONP (object)
  (or (and (functionp object) (atom object) (not (symbolp object)))
      (INTERPRETED-FUNCTION-P object)))

(defun COMPILED-FUNCTION-P (object)
  (or (compiled-function-p object)
      (subrp object)))

;;; TODO: call-argument-limit

(defvar LAMBDA-LIST-KEYWORDS
        '(&allow-other-keys &aux &body &environment &key &optional
	  &rest &whole))

(defvar *constants* '(nil T PI))

(defmacro* DEFCONSTANT (name initial-value &optional documentation)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
    (defvar ,name ,initial-value)
    (pushnew ',name *constants*)
    ',name))

(defun expand-tagbody-forms (body start end)
  (do ((clauses nil)
       (clause (list (list start)))
       (forms body (cdr forms)))
      ((null forms)
       (setq clause (append clause (list (list 'go end))))
       (setq clauses (append clauses `(,clause)))
       clauses)
    (let ((form (first forms)))
      (cond
	((atom form)
	 (setq clause (append clause `((go ,form))))
	 (setq clauses (append clauses `(,clause)))
	 (setq clause `((,form))))
	(t
	 (setq clause (append clause `(,form))))))))

(defmacro* tagbody (&body body)
  (let ((pc (gensym))
	(start (gensym))
	(end (gensym))
	(throw-tag (gensym)))
    `(let ((,pc ',start))
      (macrolet ((go (tag)
		   (list 'throw
			 (list 'quote ',throw-tag)
			 (list 'quote tag))))
	(while (not (eq ,pc ',end))
	  (setq ,pc
		(catch ',throw-tag
		  (case ,pc
		    ,@(expand-tagbody-forms body start end))))))
      nil)))

(fset 'NOT (symbol-function 'not))

(DEFCONSTANT T 'T)

(fset 'EQ (symbol-function 'eq))

(defun EQL (x y)
  (or (eq x y)
      (cond
	((and (CHARACTERP x) (CHARACTERP y))
	 (eq (CHAR-CODE x) (CHAR-CODE y)))
	((and (cl::bignump x) (cl::bignump y))
	 (and (eq (length x) (length y))
	      (every #'eq x y)))
	((and (cl::ratiop x) (cl::ratiop y))
	 (and (EQL (numerator x) (numerator y))
	      (EQL (denominator x) (denominator y))))
	((and (COMPLEXP x) (COMPLEXP y))
	 (and (EQL (REALPART x) (REALPART y))
	      (EQL (IMAGPART x) (IMAGPART y))))
	(t
	 nil))))

(defun EQUAL (x y)
  (or (EQL x y)
      (cond
	((and (consp x) (consp y))
	 (and (EQUAL (car x) (car y))
	      (EQUAL (cdr x) (cdr y))))
	((and (STRINGP x) (STRINGP y))
	 (and (eq (LENGTH x) (LENGTH y))
	      (every #'eq x y)))
	((and (BIT-VECTOR-P x) (BIT-VECTOR-P y))
	 (and (eq (LENGTH x) (LENGTH y))
	      (every #'eq x y)))
	;; TODO: pathnames
	(t
	 nil))))

;;; TODO: EQUALP

(defun IDENTITY (object)
  object)

(defun COMPLEMENT (fn)
  (let ((env (augment-environment nil :variable '(fn))))
    (setf (lexical-value 'fn env) fn)
    (enclose '(LAMBDA (x) (NOT (FUNCALL fn x))) env)))

(cl:defmacro AND (&rest forms)
  (if (null forms)
      T
      `(IF ,(first forms) (AND ,@(rest forms)))))

(cl:defmacro COND (&rest clauses)
  (if (null clauses)
      nil
      (let ((clause (first clauses)))
	(case (length clause)
	  (0	`(COND ,@(rest clauses)))
	  (1	`(OR ,(first clause) (COND ,@(rest clauses))))
	  (t	`(IF ,(first clause) (PROGN ,@(rest clause))
				     (COND ,@(rest clauses))))))))

(defmacro IF (condition then &optional else)
  `(if ,condition ,then ,else))

(cl:defmacro OR (&rest forms)
  (if (null forms)
      nil
      (with-gensyms (x)
	`(LET ((,x ,(first forms)))
	   (IF ,x ,x (OR ,@(rest forms)))))))

(cl:defmacro WHEN (condition &body body)
  `(IF ,condition (PROGN ,@body)))

(cl:defmacro UNLESS (condition &body body)
  `(IF ,condition nil (PROGN ,@body)))

(cl:defmacro CASE (form &rest clauses)
  (let ((val (gensym))
	(seen-otherwise nil))
    `(LET ((,val ,form))
       (COND
	 ,@(mapcar (lambda (clause)
		     (when seen-otherwise
		       (error "syntax error"))
		     (setq seen-otherwise
			   (member (first clause) '(T OTHERWISE)))
		     (cond
		       (seen-otherwise
			`(T ,@(rest clause)))
		       ((atom (first clause))
			`((EQL ,val ,(first clause))
			  ,@(rest clause)))
		       (t
			`((MEMBER ,val (QUOTE ,(first clause)))
			  ,@(rest clause)))))
		   clauses)))))

(defmacro* MULTIPLE-VALUE-BIND (vars form &body body)
  (if (null vars)
      `(progn ,form ,@body)
      (let ((n -1))
	`(let ((,(first vars) ,form)
	       ,@(mapcar (lambda (var) `(,var (nth ,(incf n) mvals)))
			 (rest vars)))
	   ,@body))))

(cl:defmacro MULTIPLE-VALUE-BIND (vars form &body body)
  `(MULTIPLE-VALUE-CALL (LAMBDA ,vars ,@body) ,form))

;;; MULTIPLE-VALUE-CALL is a special operator.

(defmacro* MULTIPLE-VALUE-LIST (form)
  (let ((val (gensym)))
    `(let ((,val ,form))
       (if (zerop nvals)
	   nil
	   (cons ,val mvals)))))

(cl:defmacro MULTIPLE-VALUE-LIST (form)
  `(MULTIPLE-VALUE-CALL #'LIST ,form))

;;; MULTIPLE-VALUE-PROG1 is a special operator.

(defmacro* MULTIPLE-VALUE-SETQ (vars form)
  (if (null vars)
      form
      (let ((n -1))
	`(setq ,(first vars) ,form
	       ,@(mappend (lambda (var) `(,var (nth ,(incf n) mvals)))
			  (rest vars))))))

(cl:defmacro MULTIPLE-VALUE-SETQ (vars form)
  (let ((vals (gensym))
	(n -1))
    `(let ((,vals (MULTIPLE-VALUE-LIST ,form)))
       (SETQ ,@(mapcar (lambda (var) `(,var (nth ,(incf n) ,vals))) vars)))))

(defun VALUES (&rest vals)
  (VALUES-LIST vals))

(defun VALUES-LIST (list)
  (setq nvals (length list))
  (setq mvals (cdr-safe list))
  (car-safe list))

(defmacro* NTH-VALUE (n form)
  (if (eq n 0)
      `(VALUES ,form)
      `(progn
	,form
	(VALUES (nth ,(1- n) mvals)))))

(cl:defmacro NTH-VALUE (n form)
  `(MULTIPLE-VALUE-CALL (LAMBDA (&rest vals) (NTH ,n vals)) ,form))

(defun keyword (string)
  (NTH-VALUE 0 (INTERN string *keyword-package*)))

;;; TODO:
; (defmacro DEFINE-MODIFY-MACRO (name lambda-list fn &optional documentation)
;   `',name)

(defmacro* DEFSETF (access-fn &rest args)
  (case (length args)
    (0 (error "syntax error"))
    (1 (short-form-defsetf access-fn (first args)))
    (t (apply #'long-form-defsetf access-fn args))))

(defun short-form-defsetf (access-fn update-fn)
  `(DEFINE-SETF-EXPANDER ,access-fn (&rest args)
     (let ((var (gensym))
	   (temps (map-to-gensyms args)))
       (VALUES temps
	       args
	       (list var)
	       (append '(,update-fn) temps (list var))
	       (list* ',access-fn temps)))))

(defun* long-form-defsetf (access-fn lambda-list variables &body body)
  (let ((args (remove-if (lambda (x) (member x LAMBDA-LIST-KEYWORDS))
			 lambda-list)))
    `(DEFINE-SETF-EXPANDER ,access-fn ,lambda-list
       (let* ((var (gensym))
	     (temps (map-to-gensyms ',args))
	     (,(first variables) var))
	 (VALUES temps
		 (list ,@args)
		 (list var)
		 (apply (lambda ,lambda-list ,@body) temps)
		 (cons ',access-fn temps))))))

(defvar *setf-expanders* (make-hash-table))

(defmacro* DEFINE-SETF-EXPANDER (access-fn lambda-list &body body)
  (setq lambda-list (copy-list lambda-list))
  (remf lambda-list '&environment)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (setf (gethash ',access-fn *setf-expanders*)
           (lambda ,lambda-list ,@body))
     ',access-fn))

(cl:defmacro DEFINE-SETF-EXPANDER (access-fn lambda-list &body body)
  (setq lambda-list (copy-list lambda-list))
  (remf lambda-list '&environment)
  `(EVAL-WHEN (,(keyword "COMPILE-TOPLEVEL")
	       ,(keyword "LOAD-TOPLEVEL")
	       ,(keyword "EXECUTE"))
     (SETF (GETHASH ',access-fn *setf-expanders*)
           (LAMBDA ,lambda-list ,@body))
     (QUOTE ,access-fn)))

(defun GET-SETF-EXPANSION (place &optional env)
  (setq place (MACROEXPAND place))
  (cond
   ((consp place)
    (let ((fn (gethash (first place) *setf-expanders*)))
      (if fn
	  (apply fn (rest place))
	  (let ((temps (map-to-gensyms (rest place)))
		(var (gensym)))
	    (VALUES temps
		    (rest place)
		    (list var)
		    `(FUNCALL '(SETF ,(first place)) ,var ,@temps)
		    `(,(first place) ,@temps))))))
   ((symbolp place)
    (let ((var (gensym)))
      (VALUES nil nil (list var) `(SETQ ,place ,var) place)))
   (t
    (error))))

(defmacro* SETF (place value &environment env)
  (MULTIPLE-VALUE-BIND (temps values variables setter getter)
      (GET-SETF-EXPANSION place env)
    `(let* (,@(MAPCAR #'list temps values)
	    (,(first variables) ,value))
       ,setter)))

(cl:defmacro SETF (place value)
  (MULTIPLE-VALUE-BIND (temps values variables setter getter)
      (GET-SETF-EXPANSION place env)
    `(LET* (,@(MAPCAR #'list temps values)
	    (,(first variables) ,value))
       ,setter)))
