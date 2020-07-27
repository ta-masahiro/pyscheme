(define-macro (lambda args . bodys)
  ; 
  (let ((res (:partition (get-python-function (lambda (x) (and (pair? x) (eq? (car x) 'define)))) bodys)))
    (if (null? (car res))
      `(_lambda ,args ,@bodys)
      ; 
      (let ((defs 
              (map 
                (lambda(x) (if (pair? (car x)) `(,(caar x) (lambda ,(cdar x) ,@(cdr x))) `,x))
                (map-cdr (car res)))
            ))

        `(_lambda ,args (letrec ,defs ,@(cdr res)))))))
