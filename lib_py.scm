; mlib.scm : micro Scheme 用ライブラリ
;
;            Copyright (C) 2009 Makoto Hiroi
;            Copyright (C) 2016 Masahiro Taniguro
;
(_define LIB_VER "1708022149:R7RSfunctions/traditional MACRO/let-optionals*  ")
;(display "\tBasic Liblary  : ")
;(display LIB_VER)
;(display "\n")
;
;   condにバグ(?)あり 修正
;   (let () body ...)に対応 
;   beginを構文にしたのでマクロ記述をコメントアウト
;   ローカルdefineをletrecに変換するようlambdaを修正
;   infinite?、finite?、nan?
;   2因数のlist=、check-arg、get-python-function
;   fold、fold-right等に対応、list=に対応
;   primitive化したmap函数の因数が通常のclosueでも対応できるようにした
;   #\...対応に伴い、#\space等の定義を削除(new_read:11162155以降)
;   map関連をprimitive化
;   map-car,map-cdrを使う()
;   receiveを複数body対応にした
;   list?をproper-list?と同じ定義になるよう変更
;   :appendｗprimitiveに変更
;   new-lineを再度整理した(確定版)
;   多変数appnendを追加; それに伴い基礎関数で用いる
;       appendを:appendとして再定義した
;   define, define-macro, lamdaをマクロに変更した
;       ※vm/compilerは11021438以上が必要
;   newlineを整理
;   call-with-XXX-fileでcloseが抜けていたのを修正
;   いくつかの文字定数を定義,writeの暫定対応
;   いらない関数の整理
;   meanをマクロで追加
;   let-optionals*,let1,acond2,aifに対応
;   gensymに仮対応した
;   cond節の=>に対応した
;   vectorのR7RS部に対応
;   valuesに暫定対応した
;

;(_define caar (_lambda (x) (car (car x))))     ; ->primitive
;(_define cdar (_lambda (x) (cdr (car x))))     ; ->primitive
;(_define cadar (_lambda (x) (car (cdar x))))   ; ->primitive
;(_define list (_lambda args args))             ; ->primitive
; (_define :append  ; 2変数version;後で多変数を定義
;  (_lambda (xs ys)
;    (if (null? xs)
;      ys
;      (cons (car xs) (:append (cdr xs) ys)))))
(_define :append :append-1)  ; primitive 版は約30倍速い

; quasiquote
; (_define transfer
;   (_lambda (ls)
;     (if (pair? ls)
;         (if (pair? (car ls))
;             (if (eq? (caar ls) 'unquote)
;                 (list 'cons (cadar ls) (transfer (cdr ls)))
;               (if (eq? (caar ls) 'unquote-splicing)
;                   (list ':append (cadar ls) (transfer (cdr ls)))
;                 (list 'cons (transfer (car ls)) (transfer (cdr ls)))))
;           (list 'cons (list 'quote (car ls)) (transfer (cdr ls))))
;       (list 'quote ls))))

; (_define-macro quasiquote (_lambda (x) (transfer x)))

(%python-import "macro_sub")

(_define-macro quasiquote (_lambda (x) (translator x 0)))

; lambda暫定定義
; letrecの定義後再定義(lambda中のdefineをletrecに変換)
(_define-macro lambda
  (_lambda (args . body)
    `(_lambda ,args ,@body)))

(_define-macro ^
  (_lambda (args . body)
    `(_lambda ,args ,@body)))

; define
(_define-macro define
  (_lambda (name-arg . body)
    (if (pair? name-arg)
      `(_define ,(car name-arg) (lambda ,(cdr name-arg) ,@body))
      `(_define ,name-arg ,@body))))  ; エラーチェック要
                                      ; name-argはsymbol、bodyは1個

; define-macro
(_define-macro define-macro
  (_lambda (name-arg . body)
    (if (pair? name-arg)
      `(_define-macro ,(car name-arg) (lambda ,(cdr name-arg) ,@body))
      `(_define-macro ,name-arg ,@body))))  ; エラーチェック要
                                            ; name-argはsymbol、bodyは1個
; call/cc
(_define-macro call/cc
  (_lambda (proc) `(_call/cc ,proc)))
(_define-macro call-with-current-continuation
  (_lambda (proc) `(_call/cc ,proc)))

; 表示関連
; (define write display)  ; 暫定対応  => primitiveにした
(define newline
  (lambda x
    (if (null? x) (display "\n")
      (display "\n" (car x)))))

(define (print . args)
        (for-each (lambda (x) (display x) (display " ")) args)
        (newline))

; 述語
; (define null? (lambda (x) (eq? x '())))
; (define not (lambda (x) (if (eq? x #f) #t #f)))
; (define newline (lambda () (display "\n")))
; 数
(define remainder %)
(define modulo %)
;(define zero? (lambda (x) (= x 0)))
;(define p+ (lambda (x . y) (if (null? y) x (fold-right + x y))))
;(define p- (lambda (x . y) (if (null? y) (neg x) (- x (fold-right + 0 y)))))
;(define p* (lambda (x . y) (if (null? y) x (fold-right * x y))))
;(define p/ (lambda (x . y) (if (null? y) (/ 1 x) (/ x (fold-right * 1 y)))))
;(define (p= x . y) (if (null? y) #t (fold-right = x y)))
;(define (p<= x . y) (if (null? y) #t (fold-right <= x y)))
; (define positive? (lambda (x) (< 0 x)))
; (define negative? (lambda (x) (> 0 x)))
; (define even? (lambda (x) (zero? (% x 2))))
; (define odd? (lambda (x) (= 1 (% x 2))))

; (define max
;   (lambda (x . xs)
;     (fold-left (lambda (a b) (if (< a b) b a)) x xs)))
; (define min
;   (lambda (x . xs)
;     (fold-left (lambda (a b) (if (> a b) b a)) x xs)))

(define gcdi
  (lambda (a b)
    (if (zero? b)
	     a
       (gcdi b (mod a b)))))

;(define gcd
;  (lambda xs
;    (if (null? xs)
;	      0
;       (fold-left (lambda (a b) (gcdi a b)) (car xs) (cdr xs)))))

(define lcmi (lambda (a b) (/ (* a b) (gcdi a b))))
(define lcm
  (lambda xs
    (if (null? xs)
	     1
       (fold-left (lambda (a b) (lcmi a b)) (car xs) (cdr xs)))))
; cxxr
;(define caar (lambda (x) (car (car x))))
;(define cadr (lambda (x) (car (cdr x))))
;(define cdar (lambda (x) (cdr (car x))))
;(define cddr (lambda (x) (cdr (cdr x))))
(define caaar (lambda (x) (car (caar x))))
(define caadr (lambda (x) (car (cadr x))))
;(define cadar (lambda (x) (car (cdar x))))
;(define caddr (lambda (x) (car (cddr x))))
(define cdaar (lambda (x) (cdr (caar x))))
(define cdadr (lambda (x) (cdr (cadr x))))
(define cddar (lambda (x) (cdr (cdar x))))
(define cdddr (lambda (x) (cdr (cddr x))))
(define caaaar (lambda (x) (car (caaar x))))
(define caaadr (lambda (x) (car (caadr x))))
(define caadar (lambda (x) (car (cadar x))))
(define caaddr (lambda (x) (car (caddr x))))
(define cadaar (lambda (x) (car (cdaar x))))
(define cadadr (lambda (x) (car (cdadr x))))
(define caddar (lambda (x) (car (cddar x))))
;(define cadddr (lambda (x) (car (cdddr x))))   ; -> primitive
(define cdaaar (lambda (x) (cdr (caaar x))))
(define cddddr (lambda (x) (cdr (cdddr x))))
;(define caddddr (lambda (x) (car (cddddr x)))) ; -> primitive
(define cdddddr (lambda (x) (cdr (cddddr x))))
(define cadddddr (lambda (x) (car (cdddddr x))))

;;; リスト操作関数

;(define list (lambda args args))
(define list? (lambda x (if (pair? x) #t (null? x))))   ; srfi-1ではproper-list?と同じ
                                                        ; 後で再定義する
(define list-set! (lambda (lis num val) (set-car! (list-tail lis num) val)))


; リストの探索
;(define memq
;  (lambda (x ls)
;    (if (null? ls)
;        #f
;        (if (eq? x (car ls))
;            ls
;          (memq x (cdr ls))))))
;
;(define memv
;  (lambda (x ls)
;    (if (null? ls)
;        #f
;        (if (eqv? x (car ls))
;            ls
;          (memv x (cdr ls))))))

(define memq :memq) ; primitive
(define memv :memv) ; primitive
;(define member :member) ; primitive
(define (member x ls . f)
  (if (null? f) (:member x ls) 
                (::member x ls (get-python-function (car f)))))

; 連想リストの探索
(define assq
  (lambda (x ls)
    (if (null? ls)
        #f
      (if (eq? x (car (car ls)))
          (car ls)
        (assq x (cdr ls))))))

;
(define assv
  (lambda (x ls)
    (if (null? ls)
        #f
      (if (eqv? x (car (car ls)))
          (car ls)
        (assv x (cdr ls))))))

;
(define assoc
  (lambda (x ls)
    (if (null? ls)
        #f
        (if (equal? x (car (car ls)))
            (car ls)
            (assoc x (cdr ls))))))
(define :assoc assoc)
;;; 高階関数

; マッピング
;
(define map-1
  (lambda (fn ls)
    (if (null? ls)
        '()
      (cons (fn (car ls)) (map-1 fn (cdr ls))))))

(define map-2
  (lambda (fn xs ys)
    (if (null? xs)
        '()
      (cons (fn (car xs) (car ys)) (map-2 fn (cdr xs) (cdr ys))))))

(define map
  (lambda (f . args)
    (if (memq '() args)
	'()
;     (cons (apply f (map-1 car args))
;	    (apply map f (map-1 cdr args))))))
      (cons (apply f (map-car args))        ; map-car = (map-1 car ls)
        (apply map f (map-cdr args))))))    ; map-cdr = (map-1 cdr ls)

; フィルター
;(define filter
;  (lambda (fn ls)
;    (if (null? ls)
;        '()
;      (if (fn (car ls))
;          (cons (car ls) (filter fn (cdr ls)))
;        (filter fn (cdr ls))))))
(define (filter fn ls)
  (:filter (get-python-function fn) ls))
(define (filter! fn ls)
  (:filter! (get-python-function fn) ls))

;(define remove
;  (lambda (pr ls)
;    (if (null? ls) ls
;      (if (pr (car ls) ) (remove pr (cdr ls))
;        (cons (car ls) (remove pr (cdr ls)))))))
(define (remove fn ls)
  (:remove (get-python-function fn) ls))
(define (remove! fn ls)
  (:remove! (get-python-function fn) ls))

; 畳み込み
(define fold-right
  (lambda (fn a ls)
    (if (null? ls)
        a
      (fn (car ls) (fold-right fn a (cdr ls))))))


(define fold-left
  (lambda (fn a ls)
    (if (null? ls) 
        a
      (fold-left fn (fn a (car ls)) (cdr ls)))))



(define fold
  (lambda (fn a ls)
    (if (null? ls) 
        a
      (fold fn (fn (car ls) a) (cdr ls)))))

;;; マクロ

; quasiquote
;(define transfer
;  (lambda (ls)
;    (if (pair? ls)
;        (if (pair? (car ls))
;            (if (eq? (caar ls) 'unquote)
;                (list 'cons (cadar ls) (transfer (cdr ls)))
;              (if (eq? (caar ls) 'unquote-splicing)
;                  (list 'append (cadar ls) (transfer (cdr ls)))
;                (list 'cons (transfer (car ls)) (transfer (cdr ls)))))
;          (list 'cons (list 'quote (car ls)) (transfer (cdr ls))))
;      (list 'quote ls))))
;
;(define-macro quasiquote (lambda (x) (transfer x)))

; let (named-let)
 (define-macro let
   (lambda (args . body)
     (if (or_ (pair? args) (null? args))    ; using binary or 
         `((lambda ,(map-car args) ,@body) ,@(map-1 cadr args))
       ; named-let
       `(letrec ((,args (lambda ,(map-car (car body)) ,@(cdr body))))
         (,args ,@(map-1 cadr (car body)))))))

;  (define-macro let
;    (lambda (args . body)
;      (cond 
;        ((pair? args) 
;          `((lambda ,(map-car args) ,@body) ,@(map-1 cadr args)))
;        ((null? args)
;          `((lambda () ,@body)))
;        ; named-let
;        (else
;          `(letrec ((,args (lambda ,(map-car (car body)) ,@(cdr body))))
;            (,args ,@(map-1 cadr (car body))))))))

; and
(define-macro and
  (lambda args
    (if (null? args)
        #t
      (if (null? (cdr args))
          (car args)
        `(if ,(car args) (and ,@(cdr args)) #f)))))

; or
;(define-macro or
;  (lambda args
;    (if (null? args)
;        #f
;      (if (null? (cdr args))
;          (car args)
;          `(let ((__val__ ,(car args)))
;            (if __val__ __val__ (or ,@(cdr args))))))))

; gensym
; 仮版:単にランダムな名前を作るだけで変数が衝突しない保障はない
(define gensym
  (lambda x
    (let ((randnumstr (number->string (random-integer 1000000))))
      (if (null? x) (string->symbol (string-append " !_" randnumstr))
        (string->symbol (string-append (car x) randnumstr))))))
(define-macro (or . args)
  (if (null? args)
    #f
    (if (null? (cdr args))
      (car args)
      (let ((val (gensym)))
        `(let ((,val ,(car args)))
           (if ,val ,val (or ,@(cdr args))))))))
; let*
(define-macro let*
  (lambda (args . body)
    (if (null? (cdr args))
        `(let (,(car args)) ,@body)
      `(let (,(car args)) (let* ,(cdr args) ,@body)))))

; letrec
(define-macro letrec
  (lambda (args . body)
    (let ((vars (map-car args))
          (vals (map-1 cadr args)))
      `(let ,(map-1 (lambda (x) `(,x '*undef*)) vars)
            ,@(map-2 (lambda (x y) `(set! ,x ,y)) vars vals)
            ,@body))))
(define letrec* letrec)
; begin ; beginはマクロでなく構文にした17'0720
; (define-macro begin
;   (lambda args
;     (if (null? args)
;         `((lambda () '*undef*))
;       `((lambda () ,@args)))))

;(define reverse
;  (lambda (ls)
;    (letrec ((iter (lambda (ls a)
;                     (if (null? ls)
;                         a
;                       (iter (cdr ls) (cons (car ls) a))))))
;      (iter ls '()))))
(define reverse :reverse)   ; primitive
; (define-macro reverse! (lambda (ls) `(set! ,ls (reverse ,ls))))   ; use primitive function
(define reverse! :reverse!)
; cond
(define-macro cond
  (lambda args
    (if (null? args)
        `'*undef*
      (if (eq? (caar args) 'else)
          `(begin ,@(cdar args))
        (if (null? (cdar args))
            `(let ((+value+ ,(caar args)))
              (if +value+ +value+ (cond ,@(cdr args))))

          (if (eq? (cadar args) '=>)          ; =>に対応
              `(let ((__test__ ,(caar args)))   ;
                (if __test__                   ;
                  (,(caddar args) __test__)    ;
                    (cond  ,@(cdr args))))       ;

            `(if ,(caar args)
               (begin ,@(cdar args))
               (cond ,@(cdr args)))))))))

(define-macro cond
  (lambda args (let ((value (gensym)))
    (if (null? args)
        `'*undef*
      (if (eq? (caar args) 'else)
          `(begin ,@(cdar args))
        (if (null? (cdar args))
            `(let ((,value ,(caar args)))
              (if ,value ,value (cond ,@(cdr args))))

          (if (eq? (cadar args) '=>)          ; =>に対応
              `(let ((,value ,(caar args)))   ;
                (if ,value                   ;
                  (,(caddar args) ,value)    ;
                    (cond  ,@(cdr args))))       ;

            `(if ,(caar args)
               (begin ,@(cdar args))
               (cond ,@(cdr args))))))))))
; case
(define-macro _case                         ; caseの元ver
  (lambda (key . args)                      ; keyに副作用がない場合いしか使えない
    (if (null? args)
        `'*undef*
      (if (eq? (caar args) 'else)
          `(begin ,@(cdar args))
        `(if (memv ,key ',(caar args))
             (begin ,@(cdar args))
           (_case ,key ,@(cdr args)))))))

(define-macro case
  (lambda (expr . args)
    (if (or (not (pair? expr)) (eq? (car expr) 'quote))   ; exprが即値であれば
      `(_case ,expr ,@args)                             ; そのまま展開するが
      (let ((key (gensym)))                             ; そうでない場合は副作用があるので
        `(let ((,key ,expr))                            ; 別変数keyに拘束したうえで
           (_case ,key ,@args))))))                     ; caseに展開する
; do
(define-macro do
  (lambda (var-form test-form . args)
    (let ((vars (map-car var-form))
          (vals (map-1 cadr var-form))
          (step (map-1 cddr var-form))
          (loop (gensym)))
      `(letrec ((,loop (lambda ,vars
                        (if ,(car test-form)
                            (begin ,@(cdr test-form))
                          (begin
                            ,@args
                            (,loop ,@(map-2 (lambda (x y)
                                             (if (null? x) y (car x)))
                                           step
                                           vars)))))))
        (,loop ,@vals)))))

;;; マクロを使った関数の定義

(define (list? x)   ; list  = null|no dotted list|no circular list
  (let lp ((x x) (lag x))
    (if (pair? x)
    (let ((x (cdr x)))
      (if (pair? x)
          (let ((x   (cdr x))
            (lag (cdr lag)))
        (and (not (eq? x lag)) (lp x lag)))
          (null? x)))
    (null? x))))

;;; APPEND is R4RS.
;(define (append . lists)
;  (if (pair? lists)
;      (let recur ((list1 (car lists)) (lists (cdr lists)))
;        (if (pair? lists)
;            (let ((tail (recur (car lists) (cdr lists))))
;              (fold-right cons tail list1)) ; Append LIST1 & TAIL.
;            list1))
;      '()))

(define append :append-n)   ; primitive
;(define (append . lists) (if (null? lists) '() (:append-n (car lists) (cdr lists))))

; reverse (named-let 版)
(define reversei
  (lambda (ls)
    (let loop ((ls ls) (a '()))
      (if (null? ls)
          a
          (loop (cdr ls) (cons (car ls) a))))))

(define reverse-do
  (lambda (xs)
    (do ((ls xs (cdr ls)) (result '()))
        ((null? ls) result)
      (set! result (cons (car ls) result)))))

;;; 継続のテスト

(define bar1 (lambda (cont) (display "call bar1\n")))
(define bar2 (lambda (cont) (display "call bar2\n") (cont #f)))
(define bar3 (lambda (cont) (display "call bar3\n")))
(define test (lambda (cont) (bar1 cont) (bar2 cont) (bar3 cont)))

;
(define find-do
  (lambda (fn ls)
    (call/cc
      (lambda (k)
        (do ((xs ls (cdr xs)))
            ((null? xs) #f)
          (if (fn (car xs)) (k (car xs))))))))

;
(define map-check (lambda (fn chk ls)
  (call/cc
    (lambda (k)
      (map (lambda (x) (if (chk x) (k '()) (fn x))) ls)))))

;
(define flatten (lambda (ls)
  (call/cc
    (lambda (cont)
      (letrec ((flatten-sub
                (lambda (ls)
                  (cond ((null? ls) '())
                        ((not (pair? ls)) (list ls))
                        ((null? (car ls)) (cont '()))
                        (else (append (flatten-sub (car ls))
                                      (flatten-sub (cdr ls))))))))
        (flatten-sub ls))))))

;
(define make-iter
 (lambda (proc . args)
  (letrec ((iter
            (lambda (return)
              (apply
                proc
                (lambda (x)             ; 高階関数に渡す関数の本体
                  (set! return          ; 脱出先継続の書き換え
                   (call/cc
                    (lambda (cont)
                      (set! iter cont)  ; 継続の書き換え
                      (return x)))))
                args)
                ; 終了後は継続 return で脱出
                (return #f))))
    (lambda ()
      (call/cc
        (lambda (cont) (iter cont)))))))

;
(define for-each-tree
 (lambda (fn ls)
  (let loop ((ls ls))
    (cond ((null? ls) '())
          ((pair? ls)
           (loop (car ls))
           (loop (cdr ls)))
          (else (fn ls))))))
;;;
;;; test関数
;;;
(define fib (lambda (n a b)
              (if (:=  n 1)a
                (fib (1- n) (:+ a b) a))))

(define tak (lambda (x y z)
              (if (:<= x y) z
                (tak (tak (1- x) y z)
                     (tak (1- y) z x)
                     (tak (1- z) x y)))))

(define tarai
  (lambda (x y z)
    (if (:<= x y)
        y
      (tarai (tarai (1- x) y z)
             (tarai (1- y) z x)
             (tarai (1- z) x y)))))

(define-macro delay
  (lambda (expr)
    `(make-promise (lambda () ,expr))))

(define make-promise
  (lambda (f)
    (let ((flag #f) (result #f))
      (lambda ()
        (if (not flag)
            (let ((x (f)))
              (if (not flag)
                  (begin (set! flag #t)
                         (set! result x)))))
        result))))

(define force
  (lambda (promise) (promise)))

(define tarai1
  (lambda (x y z)
    (if (:<= x y)
        y
      (let ((zz (force z)))
        (tarai1 (tarai1 (1- x) y (delay zz))
                (tarai1 (1- y) zz (delay x))
                (delay (tarai1 (1- zz) x (delay y))))))))

(define tarai2  (lambda (x y z)
  (if (:<= x y)
      y
    (let ((zz (z)))
      (tarai2 (tarai2 (1- x) y (lambda () zz))
              (tarai2 (1- y) zz (lambda () x))
              (lambda () (tarai2 (1- zz) x (lambda () y))))))))
;;
;; マクロ
;;
(define unquote
  (lambda (x) (error "," "unquote appeared outside quasiquote")))

(define unquote-splicing
  (lambda (x) (error ",@"  "unquote-splicing appeared outside quasiquote")))

; (define translator-sub
;   (lambda (sym ls n succ)
;     (list 'list
; 	  (list 'quote sym)
; 	  (translator ls (+ n succ)))))
; 
; (define translator-unquote
;   (lambda (ls n)
;     (list 'cons
; 	  (if (zero? n)
; 	      (cadar ls)
; 	    (translator-sub 'unquote (cadar ls) n -1))
; 	  (translator (cdr ls) n))))
; 
; (define translator-unquote-splicing
;   (lambda (ls n)
;     (if (zero? n)
; 	(list ':append (cadar ls) (translator (cdr ls) n))
;       (list 'cons
; 	    (translator-sub 'unquote-splicing (cadar ls) n -1)
; 	    (translator (cdr ls) n)))))
; 
; (define translator-quasiquote
;   (lambda (ls n)
;     (list 'cons
; 	  (translator-sub 'quasiquote (cadar ls) n 1)
; 	  (translator (cdr ls) n))))
; 
; (define translator-list
;   (lambda (ls n)
;     (if (eq? (caar ls) 'unquote)
; 	  (translator-unquote ls n)
;     (if (eq? (caar ls) 'unquote-splicing)
; 	  (translator-unquote-splicing ls n)
; 	(if (eq? (caar ls) 'quasiquote)
; 	  (translator-quasiquote ls n)
; 	  (list 'cons
; 	      (translator (car ls) n)
; 	      (translator (cdr ls) n)))))))
; 
; (define translator-atom
;   (lambda (ls n)
;     (if (eq? (car ls) 'unquote)
; 	  (if (zero? n)
; 	    (cadr ls)
; 	  (if (= n 1)
; 	      (if (eq? (car (cadr ls)) 'unquote-splicing)
; 		  (list 'cons (list 'quote 'unquote) (cadr (cadr ls)))
; 		(translator-sub 'unquote (cadr ls) n -1))
; 	    (translator-sub 'unquote (cadr ls) n -1)))
;     (if (eq? (car ls) 'unquote-splicing)
; 	  (if (zero? n)
; 	      (error ",@" "invalid unquote-splicing form")
; 	  (if (= n 1)
; 		(if (eq? (car (cadr ls)) 'unquote-splicing)
; 		    (list 'cons (list 'quote 'unquote-splicing) (cadr (cadr ls)))
; 		    (translator-sub 'unquote-splicing (cadr ls) n -1))
; 	    (translator-sub 'unquote-splicing (cadr ls) n -1)))
; 	(if (eq? (car ls) 'quasiquote)
; 	    (translator-sub 'quasiquote (cadr ls) n 1)
; 	  (list 'cons
; 		(list 'quote (car ls))
; 		(translator (cdr ls) n)))))))
; 
; (define translator
;   (lambda (ls n)
;     (if (pair? ls)
;         (if (pair? (car ls))
; 	    (translator-list ls n)
; 	  (translator-atom ls n))
;       (list 'quote ls))))

; (%python-import "macro_sub")

; (define-macro quasiquote (lambda (x) (translator x 0)))

; メモ化関数

(define memoize (lambda (func)
  (let ((table (make-hash-table 'equal?)))
    (lambda args
      (if (hash-table-exists? table args)
          (hash-table-get table args)
          (let ((value (apply func args)))
            (hash-table-put! table args value)
            value))))))

; (set! tak (memoize tak))
; (set! tarai (memoize tarai))

;(define cons* (lambda (first . rest)
;  (let recur ((x first) (rest rest))
;    (if (pair? rest)
;        (cons x (recur (car rest) (cdr rest)))
;        x))))
(define cons* :cons*)   ; ->primitive
(define list* cons*)
;

; データの追加
(define-macro push! (lambda (place x)
    `(set! ,place (cons ,x ,place))))

; データの取り出し
(define-macro pop!
  (lambda (place)
    (let ((x (gensym)))
      `(let ((,x (car ,place)))
         (set! ,place (cdr ,place))
         ,x))))

(define-macro when
    (lambda (test . body)
      `(if , test (begin . ,body))))

(define-macro unless (lambda (test . body)
  `(if (not ,test) (begin . ,body))))

(define-macro while
  (lambda (test . body)
    `(do ()
       ((not ,test))
       ,@body)))

(define-macro for_
  (lambda (vars . body)
    (let ((var (car vars)) (start (cadr vars)) (stop (caddr vars)) (limit (gensym)))
    `(do ((,var ,start (1+ ,var))
          (,limit ,stop))
       ((> ,var ,limit))
       ,@body))))

(define-macro for
  (lambda (vars . bodys)
    (let ((var (car vars)) (start (cadr vars)) (stop (caddr vars))(loop (gensym " loop!")))
      `(let ,loop ((,var ,start)) (if (> ,var ,stop) '*undef* (begin ,@bodys (,loop (1+ ,var))))))))

(define-macro dotimes
  (lambda (var_count . bodys)
    (let ((var (car var_count)) (count (cadr var_count)))
      `(let loop ((,var 0)) (if (>= ,var ,count) '*undef* (loop (1+ ,var) (begin ,@bodys)))))))

(define-macro 1+!
  (lambda (x) `(set! ,x (1+ ,x))))

(define-macro 1-!
  (lambda (x) `(set! ,x (1- ,x))))


(define null-list?
  (lambda (lis)
    (cond
      ((null? lis) #t)
      ((pair? lis) #f)
      (else (error "null-list?", "args must be pair or null")))))

;(define append! (lambda (lis1 lis2)
;  (begin (set-cdr! (last-pair lis1) lis2) lis1)))
(define append-1! :append-1!)
(define append! :append-n!)

; (define (values . things)
;   (call/cc
;     (lambda (cont) (apply cont things))))
;
;  (define receive
;      (lambda (params expr . body)
;         (call-with-values (lambda () expr) (lambda params . body))))
;
; http://stackoverflow.com/questions/16674214/how-to-implement-call-with-values-to-match-the-values-example-in-r5rs;
;
;(define call/cc #f)
;(define values #f)
;(define call-with-values #f)
;(let ((magic (cons 'multiple 'values)))
;  (define magic?
;    (lambda (x)
;      (and (pair? x) (eq? (car x) magic))))

 ; (set! call/cc
 ;   (let ((primitive-call/cc call/cc))
 ;     (lambda (p)
 ;       (primitive-call/cc
 ;         (lambda (k)
 ;           (p (lambda args
 ;                (k (apply values args)))))))))

;  (set! values
;    (lambda args
;      (if (and (not (null? args)) (null? (cdr args)))
;          (car args)
;          (cons magic args))))
;
;  (set! call-with-values
;    (lambda (producer consumer)
;      (let ((x (producer)))
;        (if (magic? x)
;            (apply consumer (cdr x))
;            (consumer x))))))

(define-macro receive (lambda (formals expression . bodys)  ; bodyを複数個対応に変更
              `(call-with-values (lambda () ,expression)
                                 (lambda ,formals ,@bodys))))

(define max+min
  (lambda x
    (values (max x) (min x))))

(define max&min max+min)

;;
; othe numeric
(define (floor/ x y) (values (floor-quotient x y) (floor-remainder x y)))
(define (truncate/ x y) (values (truncate-quotient x y) (truncate-remainder x y)))
(define (exact-integer-sqrt x) (let ((val (floorsqrt x))) (values val (- x (square val)))))
(define make-rectangular complex)
(define make-polar rect)
(define real-part real)
(define imag-part imag)
(define angle phase)
(define magnitude abs)

(define number? (lambda (x) (or (integer? x) (real? x) (complex? x) (rational? x))))
(define exact? (lambda (x) (or (integer? x) (rational? x))))
(define inexact? (lambda (x) (or (real? x) (complex? x))))
(define (exact-integer? x) (and (exact? x) (integer? x)))
(define inexact->exact
  (lambda (x)
    (cond
      ((exact? x) x)
      ((real? x) (Fraction x))
      ((complex? x) (error x "is complex number, dos'n comvert exact number"))
      (else (error x "isn't number!")))))
(define exact->inexact
  (lambda (x)
    (cond
      ((inexact? x) x)
      ((number? x) (float x))
      (else (error x "isn't number!")))))
(define exact inexact->exact)
(define inexact exact->inexact)

(define (finite? x) (not (or (nan? x) (infinite x))))
(define average (lambda (lis)
  (/ (sum lis) (length lis))))
(define-macro mean_
  (lambda x
    `(/ (+ ,@x) ,(length x))))

(define (mean . x) (/ (sum x) (length x)))

;(define boolean? (lambda (x) (or (= #t x) (= #f x))))

; for-each
(define (for-each-1 proc lis)
  (let loop ((lis lis))
    (if (null? lis)
      #t
      (begin
        (proc (car lis))
        (loop (cdr lis))))))

(define (for-each-2 proc ls1 ls2)
  (let loop ((ls1 ls1) (ls2 ls2))
   (if (null? ls1)
      #t
      (begin
        (proc (car ls1) (car ls2))
        (loop (cdr ls1) (cdr ls2))))))

(define (for-each proc . lists)
  (let loop ((lists lists))
    (if (memq '() lists)
      #t
      (begin
        (apply proc (map-car lists))
        (loop (map-cdr lists))))))

 (define (for-each proc . lists)
   (:for-each (get-python-function proc) lists))

 (define (pair-for-each proc . lists)
   (:pair-for-each (get-python-function proc) lists))

; char
(define char=? = )
(define char<? < )
(define char<=? <= )
(define char>? >)
(define char>=? >= )

(define (char-ci=? x y) (= (upper x) (upper y)))
(define (char-ci<? x y) (< (upper x) (upper y)))
(define (char-ci<=? x y) (<= (upper x) (upper y)))
(define (char-ci>? x y) (> (upper x) (upper y)))
(define (char-ci>=? x y) (>= (upper x) (upper y)) )
; string
(define string=? = )
(define string<? < )
(define string<=? <= )
(define string>? >)
(define string>=? >= )

(define (string-ci=? x y) (= (upper x) (upper y)))
(define (string-ci<? x y) (< (upper x) (upper y)))
(define (string-ci<=? x y) (<= (upper x) (upper y)))
(define (string-ci>? x y) (> (upper x) (upper y)))
(define (string-ci>=? x y) (>= (upper x) (upper y)) )

(define char-upcase upper)
(define char-downcase lower)
(define string-upcase upper)
(define string-downcase lower)

;(define-macro (string-set! str ref char)   ; primitive
;  `(set! ,str (string-set ,str ,ref ,char)))

;(define (string-map proc . str)
;  (let ((n (length str))(f (get-python-function proc)))
;    (cond
;      ((= 0 n) '())
;      ((= 1 n) (:string-map-1 f (car str)))
;      ((= 2 n) (:string-map-2 f (car str) (cadr str)))
;      (else    (:string-map-n f str)))))  
(define (string-map proc str . start&end)
  (let ((n (length str)) (f (get-python-function proc)))
        (cond 
          ((:= 0 n) (:string-map-1 f str))
          ((:= 1 n) (:string-map-1 f (substring str (car start&end))))
          ((:= 2 n) (:string-map-1 f (substring str (car start&end) (cadr start&end)))))))

;(define #\? "?")            ; char定数の定義(#\で始まるもの)をしていないので暫定対応
;(define #\space " ")
;(define #\tab   "\t")
;(define #\null "")
;(define #\newline "\n")

;vector
(define vector (lambda x (list->vector x)))
(define rnrs:vector-fill! vector-fill!)

(define (vector-map proc . vects)
  (let ((n (length vects))(f (get-python-function proc)))
    (cond
      ((= 0 n) '())
      ((= 1 n) (:vector-map-1 f (car vects)))
      ((= 2 n) (:vector-map-2 f (car vects) (cadr vects)))
      (else    (:vector-map-n f vects)))))  

(define (vector-for-each proc . vects)
  (:vector-for-each (get-python-function proc) vects))

( define string-for-each vector-for-each)

(define (vector-count proc . vects)
  (:vector-count (get-python-function proc) vects))

(define (vector-fold proc s . vects)
  (let ((n (length vects))(f (get-python-function proc)))
    (cond
      ((= 0 n) '())
      ((= 1 n) (:vector-fold-1 f s (car vects)))
      ((= 2 n) (:vector-fold-2 f s (car vects) (cadr vects)))
      (else    (:vector-fold-n f s vects)))))

(define (vector-fold-right proc s . vects)
  (:vector-fold-right (get-python-function proc) s vects))

(define (vector-unfold proc l . seeds)
  (:vector-unfold (get-python-function proc) l seeds))  

(define (vector-unfold-right proc l . seeds)
  (:vector-unfold-right (get-python-function proc) l seeds))  

; 入出力
(define close-output-file close-input-file)
(define close-input-port close-input-file)
(define close-output-port close-input-file)
(define close-port close-input-file)

(define call-with-input-file
  (lambda (file proc)
    (let ((port (open-input-file file))) (proc port) )))

(define call-with-output-file
  (lambda (file proc)
    (let ((port (open-output-file file))) (proc port) (close-output-file port))))
;;;
;;; 以下は必須ではない
;;; 仮置き
;;;
; gensym
; 仮版:単にランダムな名前を作るだけで変数が衝突しない保障はない
(define gensym
  (lambda x
    (let ((randnumstr (number->string (random-integer 1000000))))
      (if (null? x) (string->symbol (string-append " !_" randnumstr))
        (string->symbol (string-append (car x) randnumstr))))))

; let-optional*
; 参考 http://saito.hatenablog.jp/entry/20110310/1299765814
; define-syntaxで書いてあったのを伝統的マクロに書き換えた
(define (atom? x) (and (not (pair? x)) (not (null? x))))

(define-macro (let-optionals* args v-d-r . body)
  (cond
    ((null? v-d-r)
     `(begin ,@body))
    ((atom? v-d-r)
     `(let ((,v-d-r ,args)) ,@body))
    ((atom? (car v-d-r))
     `(let* ((__t ,args)
             (,(car v-d-r) (if (null? __t) #t (car __t))))
        (let-optionals* (if (null? __t) '() (cdr __t)) ,(cdr v-d-r) ,@body)))
    (else
      `(let* ((t__ ,args)
              (,(caar v-d-r) (if (null? t__) ,(cadar v-d-r) (car t__))))
         (let-optionals* (if (null? t__) '() (cdr t__)) ,(cdr v-d-r) ,@body)))))
; 
; let-values* / let-values
; 簡略版　でも十分動く
(define-macro (let*-values argexps . bodys)
  (cond
    ((null? argexps)
      `(begin ,@bodys))
    ((null? (cdr argexps))
      `(receive ,(caar argexps) ,(cadar argexps) ,@bodys))
    (else
      `(receive ,(caar argexps) ,(cadar argexps) (let*-values ,(cdr argexps) ,@bodys)))))

(define let-values let*-values)

(define-macro (define-values vars exp)
  (cond 
    ((or (null? vars) (null? (car vars)))
     `(call-with-values (lambda () ,exp)(lambda () '*undef*)))
    ((not (pair? vars))
     `(define ,vars (call-with-values (lambda () ,exp) list)))
    (else
      `(begin  
        (define ,(car vars) (call-with-values (lambda () ,exp) list)) 
        (define-values ,(cdr vars) (apply values (cdr ,(car vars)))) 
        (define ,(car vars) (car ,(car vars))))
      )))


; acond2
(define-macro acond2
 (lambda clauses
   (if (null? clauses)
       '()
       (let ((cl1 (car clauses))
             (val (gensym))
             (win (gensym)))
         `(receive (,val ,win) ,(car cl1)
                   (if (or ,val ,win)
                       (let  ((it ,val)) ,@(cdr cl1))
                       (acond2 ,@(cdr clauses))))))))
; let1
(define-macro let1
  (lambda (var expr . body)
    `(let ((,var ,expr)) ,@body)))

; (define-macro (let1 var-exp . body)
;   (let ((var (car var-exp)) (exp (cadr var-exp)))
;     `(let ((,var ,exp)) ,@body)))

; aif
(define-macro aif
  (lambda (sexp . body)
    `(let1 it ,sexp
       ;(if it . ,body))))
       (if it ,@body))))

; defmacro 古い形式のscheme用にcommon-lisp風マクロ
(define-macro defmacro
  (lambda (name params body)
    `(define-macro ,name (lambda ,params ,body))))
;;;
;;; mapをprimitive関数を使って再定義
;;;
(define map-1
  (lambda (fn ls)
    (:map-1 (get-python-function fn) ls)))

;          (letrec ((_map_1 (lambda (fn ls) 
;                             (if (null? ls)
;                               '()
;                               (cons (fn (car ls)) (_map_1 fn (cdr ls)))))))
;            (_map_1 fn ls)))))

(define map-2
  (lambda (fn xs ys)
    (:map-2 (get-python-function fn) xs ys)))

;          (letrec ((_map_2 (lambda (fn xs ys)
;                             (if (null? xs)
;                               '()
;                               (cons (fn (car xs) (car ys))
;                                     (_map_2 fn (cdr xs) (cdr ys)))))))
;            (_map_2 fn xs ys)))))

(define map-n
  (lambda (fn  args)
    (:map (get-python-function fn) args)))

;          (letrec ((_map_ (lambda (f args)
;                           (if (memq '() args)
; 	                        '()
;                             (cons (apply f (map-car args))
;                                            (_map_ f (map-cdr args)))))))
;            (_map_ f args)))))

;(define (map f . arg)
;  (let ((n (length arg)))
;    (cond
;      ((= 0 n) '())
;      ((= 1 n) (map-1 f (car arg)))
;      ((= 2 n) (map-2 f (car arg) (cadr arg)))
;      (else    (map-n f arg)))))  

(define (map fn . arg)
  (let ((n (length arg)) (f (get-python-function fn)))
    (cond
      ((= 0 n) '())
      ((= 1 n) (:map-1 f (car arg)))
      ((= 2 n) (:map-2 f (car arg) (cadr arg)))
      (else    (:map f arg)))))  

;(define fold-right-1
;  (lambda (fn a ls)
;    (aif (:get-primitive-body fn)
;         (:fold-right-1 it a ls)
;         (aif (:get-closure-body fn)
;              (:fold-right-1 it a ls)
;              (error fn "is not closue")))))
; ;        (letrec ((_fold_ (lambda (fn a ls)
; ;                        (if (null? ls)
; ;                            a
; ;                            (fn (car ls) (_fold_ fn a (cdr ls)))))))
; ;         (_fold_ fn a ls)))))
;
;(define fold-right-n
;  (lambda (fn a lists)
;    (:fold-right-n (get-python-function fn) a lists)))
;
;(define (fold-right fn a . lists)
;  (let ((n (length lists)) (f (get-python-function fn)))
;    (cond
;      ((= 0 n) '())
;      ((= 1 n) (fold-right-1 fn a (car lists)))
;      (else    (fold-right-n fn a lists)))))

(define (fold-right fn a . lists)
  (let ((n (length lists)) (f (get-python-function fn)))
    (cond
      ((= 0 n) '())
      ((= 1 n) (:fold-right-1 f a (car lists)))
      (else    (:fold-right-n f a lists)))))

;(define fold-1
;  (lambda (fn a ls)
;    (aif (:get-primitive-body fn)
;         (:fold-left-1 it a ls)
;         (aif (:get-closure-body fn)
;              (:fold-left-1 it a ls)
;              (error fn "is not closue")))))
;;         (fold fn a ls))))
;
;(define fold-n
;  (lambda (fn a lists)
;    (:fold-left-n (get-python-function fn) a lists)))
;
;(define (fold fn a . lists)
;  (let ((n (length lists)))
;    (cond
;      ((= 0 n) '())
;      ((= 1 n) (fold-1 fn a (car lists)))
;      (else    (fold-n fn a lists)))))

(define (fold fn a . lists)
  (let ((n (length lists)) (f (get-python-function fn)))
    (cond 
      ((= 0 n) '())
      ((= 1 n) (:fold-left-1 f a (car lists)) )
      (else    (:fold-left-n f a lists)))))

(define fold-left fold)
;
; 2引数のlist=                      ;;;;;;;;; 2因数のlist=は削除
; 多引数版はsrfi-1で対応する
;
;(define (list= fn l1 l2)
;  (aif (:get-primitive-body fn)
;       (:list= it l1 l2)
;       (aif (:get-closure-body fn)
;            (:list= it l1 l2)
;            (error fn "is not closue"))))

(define (list= pred . lists)
  (let ((f (get-python-function pred)) 
        (n (length lists)))
    (if (= n 2) 
      (:list=2 f (car lists) (cadr lists))
      (:list=n f lists))))

(define quit exit)


(define-macro check-arg
    (lambda (stx val caller)
      `(if (not(,stx ,val)) (error ',stx ,val ',caller) )))     ; !!must be change!!

;(define (get-python-function func)
;  (check-arg procedure? func get-python-function)
;  (aif (:get-primitive-body func) it
;       (aif (:get-closure-body func) it
;            f)))

(define :get-closue-body :get-closure-body)

; (define (make-primitive lambda_  . body)
;   (if (not (null? body)) (%python-ex (car body)))
;   (list "primitive" (%python-ev lambda_)))

(define (partition pred lis)
  (let ((p (:partition (get-python-function pred) lis)))
        (values (car p) (cdr p))))

(define (partition! pred lis)
  (let ((p (:partition! (get-python-function pred) lis)))
        (values (car p) (cdr p))))

(define (quick-sort f ls)
  (if (null? ls)
      ls
    (let ((p (car ls)))
      (receive (a b) (partition (lambda (x) (f x p)) (cdr ls))
        (append (quick-sort f a)
                (cons p (quick-sort f b)))))))

;;; valuesをprimitiveに変更
; (%python-import "values")
 (define values :values)
 (define call-with-values
     (lambda (producer consumer)
       (let ((x (producer)))
         (if (:values? x)
             (apply consumer (:values->list x))
             (consumer x)))))

;(define call-with-current-continuation call/cc)

; Top Leve以外のdefineをletrecに変換
; (lambda args body1 ... (define def_args1 def_bodys1) body2 ... (define def_args 2 def_body2) ...)を
; (lambda args body1 ... (letrec ((def_args1 def_bodys) (def_args2 def_body2)) body2 ...)に変換する
(define-macro (lambda args . bodys)
  ; 
  (let ((res    ;car部にはdefine節がcdr部にはそれ以外が入る 
          (:partition (get-python-function (lambda (x) 
                       (and (pair? x) (or (eq? (car x) 'define) 
                                          (eq? (car x) '_define)))))
                    bodys)))
    ;
    (if (null? (car res))       ; car resはdefine節、cdr resはbody節
      `(_lambda ,args ,@bodys)  ; define節がなければ何もせずに_lambdaに変換
      ; 
      (let ((defs   ; (define (def_name args) bodys)を
              (map  ; (define (lambda (args) bodys)に変換しておく
                (lambda(x) (if (pair? (car x)) `(,(caar x) (lambda ,(cdar x) ,@(cdr x))) `,x))
                (map-cdr (car res))) ; ←define 節の先頭の「define」を抜いたもの
            ))

        `(_lambda ,args (letrec ,defs ,@(cdr res)))))))

(define (scheme-report-environment n)
  (if (:= n 5) #t #f))

(define list-position list-index)

(define-macro define-struct
  (lambda (s . ff)
    (let ((s-s (symbol->string s)) (n (length ff)))
      (let* ((n+1 (+ n 1))
             (vv (make-vector n+1)))
        (let loop ((i 1) (ff ff))
          (if (<= i n)
            (let ((f (car ff)))
              (vector-set! vv i 
                (if (pair? f) (cadr f) '(if #f #f)))
              (loop (+ i 1) (cdr ff)))))
        (let ((ff (map (lambda (f) (if (pair? f) (car f) f))
                       ff)))
          `(begin
             (define ,(string->symbol 
                       (string-append "make-" s-s))
               (lambda fvfv
                 (let ((st (make-vector ,n+1)) (ff ',ff))
                   (vector-set! st 0 ',s)
                   ,@(let loop ((i 1) (r '()))
                       (if (>= i n+1) r
                           (loop (+ i 1)
                                 (cons `(vector-set! st ,i 
                                          ,(vector-ref vv i))
                                       r))))
                   (let loop ((fvfv fvfv))
                     (if (not (null? fvfv))
                         (begin
                           (vector-set! st 
                               (+ (list-position (car fvfv) ff)
                                  1)
                             (cadr fvfv))
                           (loop (cddr fvfv)))))
                   st)))
             ,@(let loop ((i 1) (procs '()))
                 (if (>= i n+1) procs
                     (loop (+ i 1)
                           (let ((f (symbol->string
                                     (list-ref ff (- i 1)))))
                             (cons
                              `(define ,(string->symbol 
                                         (string-append
                                          s-s "." f))
                                 (lambda (x) (vector-ref x ,i)))
                              (cons
                               `(define ,(string->symbol
                                          (string-append 
                                           "set!" s-s "." f))
                                  (lambda (x v) 
                                    (vector-set! x ,i v)))
                               procs))))))
             (define ,(string->symbol (string-append s-s "?"))
               (lambda (x)
                 (and (vector? x)
                      (eqv? (vector-ref x 0) ',s))))))))))
;;;
;;;
(define-macro (time expr)
  (let ((c (current-milliseconds)))
    (eval expr)
    (/ (- (current-milliseconds) c) 1000.0)))

;;; srfi-39 make-parameter parametarize
;;;
; (define (make-parameter init . o)
;   (let*  ((converter
;              (if (pair? o) (car o) (lambda (x) x)))
;            (value (converter init)))
;     (lambda args
;       (cond
;         ((null? args)
;          value)
;         ;((eq? (car args) <param-set!>)
;         ; (set! value (cadr args)))
;         ;((eq? (car args) <param-convert>)
;         ; converter)
;         ;(else
;         ;  (error "bad parameter syntax"))))))
;         (else
;           (set! value (converter (car args))))))))

(define make-parameter
  (lambda (init . conv)
    (let ((converter
            (if (null? conv) (lambda (x) x) (car conv))))
      (let ((global-cell
              (cons #f (converter init))))
        (letrec ((parameter
                   (lambda new-val
                     (let ((cell (dynamic-lookup parameter global-cell)))
                       (cond ((null? new-val)
                              (cdr cell))
                             ((null? (cdr new-val))
                              (set-cdr! cell (converter (car new-val))))
                             (else ; this case is needed for parameterize
                               (converter (car new-val))))))))
          (set-car! global-cell parameter)
          parameter)))))

; (define-syntax parameterize
;   (syntax-rules ()
;                 ((parameterize ((expr1 expr2) ...) body ...)
;                  (dynamic-bind (list expr1 ...)
;                                (list expr2 ...)
;                                (lambda () body ...)))))
(load "/usr/share/slib/dynwind.scm")
(define-macro parameterize
  (lambda (exprs . bodys)
                 `(dynamic-bind (list ,@(map-car exprs))
                               (list ,@(map cadr exprs))
                               (lambda () ,@bodys))))
(define dynamic-bind
  (lambda (parameters values body)
    (let* ((old-local
             (dynamic-env-local-get))
           (new-cells
             (map (lambda (parameter value)
                    (cons parameter (parameter value #f)))
                  parameters
                  values))
           (new-local
             (append new-cells old-local)))
      (dynamic-wind
        (lambda () (dynamic-env-local-set! new-local))
        body
        (lambda () (dynamic-env-local-set! old-local))))))

(define dynamic-lookup
  (lambda (parameter global-cell)
    (or (assq parameter (dynamic-env-local-get))
        global-cell)))

(define dynamic-env-local '())

(define dynamic-env-local-get
  (lambda () dynamic-env-local))

(define dynamic-env-local-set!
  (lambda (new-env) (set! dynamic-env-local new-env)))
; 

(define (every f . lists) (:every (get-python-function f) lists))
(define (any   f . lists) (:some  (get-python-function f) lists))
(define append! :append-n!)

(define (map! f . lists) (:map! (get-python-function f) lists))
(define (filter-map f . lists) (:filter-map (get-python-function f) lists))

(define (with-input-from-port port thunk)
  (thunk port))
(define (with-input-from-string str thunk)
  (thunk (open-input-file str)))

(define (with-output-from-port port thunk)
  (thunk port))
(define (with-output-from-string str thunk)
  (thunk (open-input-file str)))

;(define _read_macro_table (make-hash-table =))
;(define-macro (define-record-co)

;
;  with関係の入出力関数
;
(define (call-with-port port proc)
    (dynamic-wind (lambda() '())
                  (lambda()(proc port))
                  (lambda() (close-input-port port))))

(define (call-with-input-file path proc)
  (let ((port #f))
    (dynamic-wind (lambda() (set! port (open-input-file path)))
                  (lambda()(proc port))
                  (lambda() (close-input-port port)))))

(define (call-with-output-file path proc)
  (let ((port #f))
    (dynamic-wind (lambda() (set! port (open-output-file path)))
                  (lambda() (proc port))
                  (lambda() (close-output-port port)))))

(define (with-input-from-port port proc)
  (dynamic-wind (lambda () (:change-current-input-port port))
                (lambda () (proc))
                (lambda () (:change-current-input-port (standard-input-port)))))

(define (with-output-to-port port proc)
  (dynamic-wind (lambda () (:change-current-output-port port))
                (lambda () (proc))
                (lambda () (:change-current-output-port (standard-output-port)))))

(define (with-input-from-file path proc)
  (let ((port #f))
    (dynamic-wind (lambda () (set! port (open-input-file path))
                             (:change-current-input-port port))
                  (lambda () (proc))
                  (lambda () (close-input-port port) 
                             (:change-current-input-port (standard-input-port))))))

(define (with-output-to-file path proc)
  (let ((port #f))
    (dynamic-wind (lambda () (set! port (open-output-file path))
                             (:change-current-output-port port))
                  (lambda () (proc))
                  (lambda () (close-output-port port) 
                             (:change-current-output-port (standard-input-port))))))

(%python-import "string_IO")

(define (call-with-input-string str proc)
  (let ((port #f))
    (dynamic-wind (lambda () (set! port (open-input-string str)))
                  (lambda () (proc port))
                  (lambda () (close-input-port port)))))

(define (call-with-output-string str proc)
  (let ((port #f))
    (dynamic-wind (lambda () (set! port (open-output-string str)))
                  (lambda () (proc port))
                  (lambda () (get-output-string port)(close-output-port port)))))

(%python-import "edit_new")

(define (edit f) 
  (call-with-input-string 
    (list->string (vector->list (:edit f)))
    (lambda (f) (let ((s #t))
        (while (not (eof-object? s)) (set! s (read f)) (eval s))))))

(define :eval eval)
(define :load load)
(define for-all every)
(define exists any)
(define (aapend-map f . l) (apply append (map-n f l)))

(define (vector= f . vects)
  (:vector= (get-python-function f) vects))

(define (unspecified) '*undef*)
(define (sorted? ls . o)
  (if (null? o) (:sorted? ls)
                (:sorted? ls (get-python-function (car o)))))
(define (sort ls . o)
  (if (null? o) (:sort ls)
                (if (null? (cdr o))
                    (:sort ls (get-python-function (car o)))
                    (:sort ls (get-python-function (car o)) (get-python-function (cadr o))))))
(define sort! sort)
(define (vector-sort v . o)
  (if (null? o) (:sort-v v)
                (:sort-v v (get-python-function (car o)))))
(define (vector-sort! v . o)
  (if (null? o) (:sort-v! v)
                (:sort-v! v (get-python-function (car o)))))
