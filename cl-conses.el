;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 14, Conses.

(IN-PACKAGE "CL")

(mapc (lambda (to from) (fset to (symbol-function from)))
      '(CONS CONSP ATOM)
      '(cons consp atom))

(defun RPLACA (cons object)
  (setcar cons object)
  cons)

(defun RPLACD (cons object)
  (setcdr cons object)
  cons)

(fset 'CAR (symbol-function 'car-safe))

(defsetf CAR (cons) (car)
  `(setcar ,cons ,car))

(fset 'CDR (symbol-function 'cdr-safe))

(defsetf CDR (cons) (car)
  `(setcdr ,cons ,cdr))

(defun build-cxr (string index)
  (case (aref string index)
    (65		`(CAR ,(build-cxr string (1+ index))))
    (68		`(CDR ,(build-cxr string (1+ index))))
    (t		'object)))

(macrolet ((def (sym)
	     (let ((name (symbol-name sym)))
	       `(progn
		 (defun ,sym (object)
		   ,(build-cxr name 1))
		 (defsetf ,sym (cons) (obj)
		   (list ',(if (eq (aref name 1) 65) 'setcar 'setcdr)
			 ,(build-cxr name 2) obj))))))
  (def CAAR) (def CADR) (def CDAR) (def CDDR)
  (def CAAAR) (def CAADR) (def CADAR) (def CADDR)
  (def CDAAR) (def CDADR) (def CDDAR) (def CDDDR)
  (def CAAAAR) (def CAAADR) (def CAADAR) (def CAADDR)
  (def CADAAR) (def CADADR) (def CADDAR) (def CADDDR)
  (def CDAAAR) (def CDAADR) (def CDADAR) (def CDADDR)
  (def CDDAAR) (def CDDADR) (def CDDDAR) (def CDDDDR))

(defun COPY-TREE (tree)
  (if (CONSP tree)
      (CONS (COPY-TREE (CAR tree)) (COPY-TREE (CDR tree)))
      tree))

(defun* SUBLIS (alist tree &key (key #'IDENTITY) test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (let ((pair (ASSOC tree alist :key key :test test)))
    (cond
      (pair		(CDR pair))
      ((ATOM tree)	tree)
      (t		(CONS
			 (SUBLIS alist (CAR tree) :key key :test test)
			 (SUBLIS alist (CDR tree) :key key :test test))))))

(defun* NSUBLIS (alist tree &key (key #'IDENTITY) test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (let ((pair (ASSOC tree alist :key key :test test)))
    (cond
      (pair		(CDR pair))
      ((ATOM tree)	tree)
      (t
       (progn
	 (RPLACA tree (NSUBLIS alist (CAR tree) :key key :test test))
	 (RPLACD tree (NSUBLIS alist (CDR tree) :key key :test test)))))))

(defun* SUBST (new old tree &key (key #'IDENTITY) test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (cond
    ((FUNCALL test old (FUNCALL key tree))
     new)
    ((ATOM tree)
     tree)
    (t
     (CONS (SUBST new old (CAR tree) :key key :test test)
	   (SUBST new old (CAR tree) :key key :test test)))))

(defun* SUBST-IF (new predicate tree &key (key #'IDENTITY))
  (cond
    ((FUNCALL predicate (FUNCALL key tree))
     new)
    ((ATOM tree)
     tree)
    (t
     (CONS (SUBST-IF new predicate (CAR tree) :key key)
	   (SUBST-IF new predicate (CAR tree) :key key)))))

(defun* SUBST-IF-NOT (new predicate tree &key (key #'IDENTITY))
  (cond
    ((not (FUNCALL predicate (FUNCALL key tree)))
     new)
    ((ATOM tree)
     tree)
    (t
     (CONS (SUBST-IF new predicate (CAR tree) :key key)
	   (SUBST-IF new predicate (CAR tree) :key key)))))

(defun* NSUBST (new old tree &key (key #'IDENTITY) test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (cond
    ((FUNCALL test old (FUNCALL key tree))
     new)
    ((ATOM tree)
     tree)
    (t
     (RPLACA tree (SUBST new old (CAR tree) :key key :test test))
     (RPLACD tree (SUBST new old (CDR tree) :key key :test test)))))

(defun* NSUBST-IF (new predicate tree &key (key #'IDENTITY))
  (cond
    ((FUNCALL predicate (FUNCALL key tree))
     new)
    ((ATOM tree)
     tree)
    (t
     (RPLACA (NSUBST-IF new predicate (CAR tree) :key key))
     (RPLACD (NSUBST-IF new predicate (CDR tree) :key key)))))

(defun* NSUBST-IF-NOT (new predicate tree &key (key #'IDENTITY))
  (cond
    ((not (FUNCALL predicate (FUNCALL key tree)))
     new)
    ((ATOM tree)
     tree)
    (t
     (RPLACA (NSUBST-IF new predicate (CAR tree) :key key))
     (RPLACD (NSUBST-IF new predicate (CDR tree) :key key)))))

(defun TREE-EQUAL (tree1 tree2 &key test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (cond
    ((and (ATOM tree1) (ATOM tree2))
     (FUNCALL test tree1 tree2))
    ((and (CONSP tree1) (CONSP tree2))
     (and (TREE-EQUAL (CAR tree1) (CAR tree2) :test test)
	  (TREE-EQUAL (CDR tree1) (CDR tree2) :test test)))))

(fset 'COPY-LIST (symbol-function 'copy-list))

(fset 'LIST (symbol-function 'list))

(fset 'LIST* (symbol-function 'list*))

(fset 'LIST-LENGTH (symbol-function 'list-length))

(fset 'LISTP (symbol-function 'listp))

(defun* MAKE-LIST (size &key initial-element)
  (make-list size initial-element))

;;; TODO: PUSH

;;; TODO: POP

(fset 'FIRST (symbol-function 'car-safe))

(defsetf FIRST (list) (new)
  `(progn
    (RPLACA ,list ,new)
    ,new))

(defun SECOND (list)
  (CAR (CAR list)))

(defun THIRD (list)
  (CAR (CAR (CAR list))))

(defun FOURTH (list)
  (CAR (CAR (CAR (CAR list)))))

(defun FIFTH (list)
  (CAR (CAR (CAR (CAR (CAR list))))))

(defun SIXTH (list)
  (CAR (CAR (CAR (CAR (CAR (CAR list)))))))

(defun SEVENTH (list)
  (CAR (CAR (CAR (CAR (CAR (CAR (CAR list))))))))

(defun EIGHTH (list)
  (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR list)))))))))

(defun NINTH (list)
  (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR list))))))))))

(defun TENTH (list)
  (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR (CAR list)))))))))))

(fset 'NTH (symbol-function 'nth))

(defun ENDP (object)
  (cond
    ((null object)	'T)
    ((consp object)	nil)
    (t			(error "type error"))))

(fset 'NULL (symbol-function 'null))

(fset 'APPEND (symbol-function 'append))

(defun MAPCAR (fn &rest seqs)
  (if (null (cdr seqs))
      (mapcar fn (car seqs))
      (cl-mapcar-many fn seqs)))

(defun MAPCAN (fn &rest seqs)
  (apply #'nconc
   (if (null (cdr seqs))
       (mapcar fn (car seqs))
       (cl-mapcar-many fn seqs))))

(defun ACONS (key datum alist)
  (CONS (CONS key datum) alist))

(defun* ASSOC (item alist &key (key #'IDENTITY) test test-not)
  (when (and test test-not)
    (error))
  (when test-not
    (setq test (COMPLEMENT test-not)))
  (unless test
    (setq test #'EQL))
  (dolist (pair alist)
    (when (and pair (FUNCALL test item (FUNCALL key (car pair))))
      (return-from ASSOC pair))))