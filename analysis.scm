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

;;; Random integer in [0 .. n - 1] with a logarithmic bias.
(define (log-variate-integer n)
  (exact->inexact (floor (log (+ (* (random-real) (- (exp n) 1)) 1)))))
