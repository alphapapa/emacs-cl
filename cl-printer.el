;;;; -*- emacs-lisp -*-
;;;
;;; Copyright (C) 2003 Lars Brinkhoff.
;;; This file implements operators in chapter 14, Conses.

(defmacro* PRINT-UNREADABLE-OBJECT ((object stream &key identity) &body body)
  `(progn
    (WRITE-STRING "#<" stream)
    (PRIN1 (TYPE-OF ,object) stream)
    (WRITE-STRING " " stream)
    ,@body
    ,@(when body
	`((WRITE-STRING " " stream)))
    ,@(when identity
        `((WRITE-STRING "identity" stream)))
    (WRITE-STRING ">" stream)))

(defun external-symbol-p (symbol)
  (eq (nth-value 1 (FIND-SYMBOL (SYMBOL-NAME symbol) (SYMBOL-PACKAGE symbol)))
      *:external*))

(defun write-char-to-*standard-output* (char)
  (WRITE-CHAR (CODE-CHAR char) *STANDARD-OUTPUT*))

;;; Ad-hoc unexensible.
(defun PRIN1 (object &optional stream-designator)
  (let* ((stream (resolve-output-stream-designator stream-designator))
	 (*STANDARD-OUTPUT* stream)
	 (standard-output #'write-char-to-*standard-output*))
    (cond
      ((or (integerp object)
	   (floatp object))
       (princ object))
      ((symbolp object)
       (cond
	 ((eq (nth-value 0 (FIND-SYMBOL (SYMBOL-NAME object) *PACKAGE*))
	      object)
	  (WRITE-STRING (SYMBOL-NAME object) stream))
	 ((null (SYMBOL-PACKAGE object))
	  (WRITE-STRING "#:" stream)
	  (WRITE-STRING (SYMBOL-NAME object) stream))
	 ((eq (SYMBOL-PACKAGE object) *keyword-package*)
	  (WRITE-STRING ":" stream)
	  (WRITE-STRING (SYMBOL-NAME object) stream))
	 (t
	  (WRITE-STRING (PACKAGE-NAME (SYMBOL-PACKAGE object)) stream)
	  (WRITE-STRING (if (external-symbol-p object) ":" "::") stream)
	  (WRITE-STRING (SYMBOL-NAME object) stream))))
      ((CHARACTERP object)
       (WRITE-STRING "#\\" stream)
       (WRITE-STRING (or (CHAR-NAME object) (string (CHAR-CODE object)))
		     stream))
      ((consp object)
       (WRITE-STRING "(" stream)
       (PRIN1 (car object) stream)
       (while (consp (cdr object))
	 (WRITE-STRING " " stream)
	 (setq object (cdr object))
	 (PRIN1 (car object) stream))
       (unless (null (cdr object))
	 (WRITE-STRING " . " stream)
	 (PRIN1 (cdr object) stream))
       (WRITE-STRING ")" stream))
      ((COMPILED-FUNCTION-P object)
       (PRINT-UNREADABLE-OBJECT (object stream :identity t)))
      ((INTERPRETED-FUNCTION-P object)
       (PRINT-UNREADABLE-OBJECT (object stream :identity t)))
      ((FUNCTIONP object)
       (PRINT-UNREADABLE-OBJECT (object stream :identity t)))
      ((cl::bignump object)
       (when (MINUSP object)
	 (WRITE-STRING "-" stream)
	 (setq object (cl:- object)))
       (WRITE-STRING "#x" stream)
       (let ((start t))
	 (dotimes (i (1- (length object)))
	   (let ((num (aref object (- (length object) i 1))))
	     (dotimes (j 7)
	       (let ((n (logand (ash num (* -4 (- 6 j))) 15)))
		 (unless (and (zerop n) start)
		   (setq start nil)
		   (WRITE-STRING (string (aref "0123456789ABCDEF" n))
				 stream))))))))
      ((cl::ratiop object)
       (PRIN1 (NUMERATOR object) stream)
       (WRITE-STRING "/" stream)
       (PRIN1 (DENOMINATOR object) stream))
      ((COMPLEXP object)
       (WRITE-STRING "#C(" stream)
       (PRIN1 (REALPART object) stream)
       (WRITE-STRING " " stream)
       (PRIN1 (IMAGPART object) stream)
       (WRITE-STRING ")" stream))
      ((BIT-VECTOR-P object)
       (WRITE-STRING "#*" stream)
       (dotimes (i (LENGTH object))
	 (PRIN1 (AREF object i) stream)))
      ((STRINGP object)
       (WRITE-STRING "\"" stream)
       (dotimes (i (LENGTH object))
	 (let ((char (CHAR-CODE (CHAR object i))))
	   (case char
	     (34	(WRITE-STRING "\\\"" stream))
	     (92	(WRITE-STRING "\\\\" stream))
	     (t		(WRITE-STRING (string char) stream)))))
       (WRITE-STRING "\"" stream))
      ((VECTORP object)
       (WRITE-STRING "#(" stream)
       (dotimes (i (LENGTH object))
	 (when (> i 0)
	   (WRITE-STRING " " stream))
	 (PRIN1 (AREF object i) stream))
       (WRITE-STRING ")" stream))
      ((PACKAGEP object)
       (PRINT-UNREADABLE-OBJECT (object stream)
         (WRITE-STRING (PACKAGE-NAME object) stream)))
      ((READTABLEP object)
       (PRINT-UNREADABLE-OBJECT (object stream :identity t)))
      ((STREAMP object)
       (PRINT-UNREADABLE-OBJECT (object stream :identity t)
         (cond
	   ((STREAM-filename object)
	    (WRITE-STRING object stream))
	   ((bufferp (STREAM-content object))
	    (WRITE-STRING (buffer-name (STREAM-content object)) stream))
	   ((STRINGP (STREAM-content object))
	    (WRITE-STRING (string 34) stream)
	    (WRITE-STRING (STREAM-content object) stream)
	    (WRITE-STRING (string 34) stream)))))
      (t
       (error))))
  object)

(defun PRINT (object &optional stream)
  (TERPRI stream)
  (PRIN1 object stream)
  (WRITE-CHAR (CODE-CHAR 32) stream)
  object)

(defun FORMAT (stream-designator format &rest args)
  (let ((stream (or (and (eq stream-designator t) *STANDARD-OUTPUT*)
		    stream-designator
		    (MAKE-STRING-OUTPUT-STREAM)))
	(i 0))
    (while (< i (LENGTH format))
      (let ((char (CHAR format i)))
	(if (eq (CHAR-CODE char) 126)
	    (case (CHAR-CODE (CHAR format (incf i)))
	      (37	(TERPRI))
	      (65	(PRIN1 (pop args) stream))
	      (68	(PRIN1 (pop args) stream)))
	    (WRITE-CHAR char stream)))
      (incf i))
    (if stream-designator
	nil
	(GET-OUTPUT-STREAM-STRING stream))))

