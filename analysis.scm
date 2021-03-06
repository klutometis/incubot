;;; Copyright (C) 2008, Peter Danenberg
(define-syntax debug
  (syntax-rules ()
    ((_ x ...)
     (print `((x ,x) ...)))))

(define pi (* (atan 1) 4))

(define min-length 3)

(define char-set:special
  (char-set #\- #\[ #\] #\| #\\ #\` #\^ #\{ #\}))

(define char-set:nick
  (char-set-union char-set:letter+digit
                  char-set:special))

(define (filter-token token)
  (> (string-length token) min-length))

(define (interesting-tokens saw stop-words)
  (lset-difference
   string=?
   (delete-duplicates
    (map string-downcase
         (filter filter-token
                 (string-tokenize saw char-set:letter+digit))))
   stop-words))

(define (analyse saw . stop-words)
  (let ((db (open-database "log.db"))
        (tokens (interesting-tokens saw)))
    (if (null? interesting-tokens)
        'bored
        (let ((id-count
               (prepare
                db
                "SELECT token_id, token_count FROM tokens WHERE token = ? LIMIT 1;"))
              (saw-ids
               (prepare
                db
                "SELECT saw_id FROM token_saws WHERE token_id = ?;")))
          (let* ((token-counts
                  (zip
                   tokens
                   (map
                    (lambda (token)
                      (condition-case
                       (first-row id-count token)
                       ((exn sqlite3) #f)))
                    tokens)))
                 (filtered-tokens (filter cadr token-counts))
                 (sorted-tokens (sort filtered-tokens > cadadr))
                 (interesting-token
                  (if (null? filtered-tokens)
                      #f
                      (list-ref filtered-tokens
                                (log-variate-integer
                                 (length sorted-tokens))))))
            (if interesting-token
                (let* ((token-id (caadr interesting-token))
                       (saw-ids (map-row values saw-ids token-id)))
                  (if (null? saw-ids)
                      'sawless
                      saw-ids))
                'incomprehending))))))

;;; Random integer in [0 .. n - 1] with a logarithmic bias.
(define (log-variate-integer n)
  (inexact->exact (floor (log (+ (* (random-real) (- (exp n) 1)) 1)))))
