(use srfi-1)

(define (append-map f . ls)
  (apply append (map-n f ls)))

(define (fail) #f)

(define (amb-proc . x)
  (define former-fail fail)
  (if (null? x)
    (fail)
    (call/cc (lambda (return) ; 分岐点
      (set! fail (lambda () ; 選ばなかった選択肢を保存
        (set! fail former-fail)
        (return (apply amb-proc (cdr x)))))
      (return ((car x))))))) ; 一つの選択肢を返す

(define-syntax amb
  (syntax-rules ()
    ((_) (amb-proc))
    ((_ value ...) (amb-proc (lambda () value) ...))))

(define problem '(
    (5 3 ? ? 7 ? ? ? ?)       
    (6 ? ? 1 9 5 ? ? ?)
    (? 9 8 ? ? ? ? 6 ?)
    (8 ? ? ? 6 ? ? ? 3)
    (4 ? ? 8 ? 3 ? ? 1)
    (7 ? ? ? 2 ? ? ? 6)
    (? 6 ? ? ? ? 2 8 ?)
    (? ? ? 4 1 9 ? ? 5)
    (? ? ? ? 8 ? ? 7 9)))

; リスト中の数字(1～9)が全て異なれば #t を返す
(define (unique x)
  (define check (make-vector 10 #t))
  (define (loop x)
    (if (null? x) #t
      (cond
        ((eq? (car x) '?)
          (loop (cdr x)))
        ((vector-ref check (car x))
          (vector-set! check (car x) #f)
          (loop (cdr x)))
        (else #f))))
  (loop x))

; (group n (1 2 3 ... )) => ((1 2 ... n) (n+1 n+2 ... 2n) ...)
(define (group count lis)
  (if (null? lis) '()
    (cons (take lis count)
          (group count (drop lis count)))))

 ; matrix が数独のルールを満たしていれば #t を返す 
(define (sudoku-check matrix)
  (and
 ; 行のチェック
       (every unique matrix)
 ; 列のチェック
       (every
         (lambda (x)
           (unique (map (lambda (row) (list-ref row x)) matrix)))
         (iota 9))
 ; 3x3 ブロックのチェック
       (every
         (lambda (three-rows)
           (every
             (lambda (x) (unique
                 (append-map
                   (lambda (row) (list-ref row x))
                   (map (lambda (row) (group 3 row)) three-rows))))
             (iota 3)))
         (group 3 matrix))))

 ; ?のマスを一つ置き換える
(define (replace-matrix proc subst matrix)
  (define replaced #f)
  (map
    (lambda (row)
      (map
        (lambda (cell)
          (cond
            ((and (not replaced) (proc cell)) (set! replaced #t) subst)
            (else cell)))
        row))
    matrix))

(define (solve problem)
  (let loop ((answer problem))
    (if (sudoku-check answer) ; 数字が重複していないかどうか
      (if
        ; ? が残っているかどうか 
        (any (lambda (row)
            (any (lambda (x) (eq? x '?)) row))
          answer)
        ; ? を (amb 1 2 ...) に置き換え、loopに戻る。
        (loop (replace-matrix (lambda (x) (eq? '? x)) (amb 1 2 3 4 5 6 7 8 9) answer))
        ; 答えを返す
        answer)
      ; 失敗
      (amb))))
 ; 問題を解いて表示する
(for-each
  (lambda (x) (display x) (newline))
  (solve problem))
