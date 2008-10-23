(define-syntax debug
  (syntax-rules ()
    ((_ x ...)
     (print `((x ,x) ...)))))

(define pi (* (atan 1) 4))

(define min-length 3)

(define (process-token token)
  (string-downcase (string-filter char-set:letter token)))

(define (filter-token token)
  (> (string-length token) min-length))

(define (interesting-tokens saw)
  (map process-token
       (filter filter-token
               (string-tokenize saw char-set:letter))))

(define (analyse saw)
  (let ((db (sqlite3:open "log.db"))
        (tokens (interesting-tokens saw)))
    (let ((count (sqlite3:prepare
                  db
                  "SELECT token_count FROM tokens WHERE token = ? LIMIT 1;")))
      (sqlite3:with-transaction
       db
       (lambda ()
         (zip tokens
              (map (lambda (token) (sqlite3:first-result count token))
                   tokens)))))))

;;; Stirling; see: http://en.wikipedia.org/wiki/Incomplete_beta_function
(define (beta-approximation x y)
  (* (sqrt (* 2 pi))
     (/
;;;       (* (expt x (- x 0.5)) (expt y (- y 0.5)))
      (expt x (- x 0.5))
      (expt (+ x y) (+ x y -0.5)))))

(define (cumulative-log-distribution k p)
  (debug k p)
  (+ 1 (/ (beta-approximation (+ k 1) 0)
          (log (- 1 p)))))

(define (log-probability-mass k p)
  (* (/ -1 (log (- 1 p)))
     (/ (expt p k) k)))

(define (exponential-variate l p)
  (/ (- (log p)) l))

(define (log-concave-variate a mode)
  (let ((f (lambda (u) (exp (- (* a u))))))
    (let ((c (f mode))
          (u (* 2 (random-real)))
          (v (random-real)))
      (let-values (((x t)
                    (if (<= u 1)
                        (values u v)
                        (values
                         (- 1 (log (- u 1)))
                         (* v (- u 1))))))
        (let ((transform (lambda (x) (+ mode (/ x c)))))
          (let iter ((x (transform x)))
            (debug x)
            (if (<= t (* (/ 1 c) (f x)))
                x
                (iter (transform x)))))))))
