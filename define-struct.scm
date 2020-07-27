;;; 
;;; slibのdefine-structをslibのrecordで定義する
;;;
;
; (define-struct point (x y z))
;  ->point?
; (define P1 (make-point 1 2 3))
;  ->P1
; (point? P1)
; ->#t
; (point-x P1)
; ->1
; (point-x-set! P1 23)
; ->*unef*
; (point-x P1)
; ->23
; 
(use record)

(define-macro (define-struct s ff)
    (let ((s-s (symbol->string s)) (ID (gensym " !RECORD!_")))
          `(begin
             ; first, create a record, useing make-record-type.
             (define ,ID (make-record-type ',s ',ff))
             ; create a constructor (make-'record name') useing record-constructor.
             (define ,(string->symbol 
                       (string-append "make-" s-s))
               (lambda x (apply (record-constructor ,ID) x)))
             ; Create accessors and modifires ,useing record-accessor and record-modifire.
             ,@(let loop ((f-f ff) (procs '()))
                 (if (null? f-f) procs
                     (loop (cdr f-f)
                           (let ((f (symbol->string
                                     (car f-f))))
                             (cons
                              `(define ,(string->symbol 
                                         (string-append
                                          s-s "-" f))
                                 (lambda (x) ((record-accessor ,ID ',(string->symbol f)) x)))
                              (cons
                               `(define ,(string->symbol
                                          (string-append 
                                           s-s "-" f "-set!"))
                                  (lambda (x v) 
                                    ((record-modifier ,ID ',(string->symbol f)) x v)))
                               procs))))))
             ; record-predicate
             (define ,(string->symbol (string-append s-s "?"))
               (lambda (x)
                 ((record-predicate ,ID) x)))
             )))
                      
