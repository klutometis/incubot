;;; Copyright (C) 2008, Peter Danenberg
(require-extension
 syntax-case
 foof-loop
 sqlite3
 (srfi 1 12 13))
(require 'regex)
(define-syntax debug
  (syntax-rules ()
    ((_ x ...)
     (print `((x ,x) ...)))))
(define pattern "[0-9]{2}:[0-9]{2}:[0-9]{2} <[^>]*> (.*)")
(define min-length 3)
(define (process-token token)
  (string-downcase (string-filter char-set:letter token)))
(define (filter-token token)
  (> (string-length token) min-length))
(define (interesting-tokens saw)
  (map process-token
       (filter filter-token
               (string-tokenize saw char-set:letter))))
(let ((db (open-database "log.db")))
  (let ((insert-saw
         (prepare
          db
          "INSERT INTO saws (saw) VALUES(?);"))
        (insert-token
         (prepare
          db
          "INSERT INTO tokens (token) VALUES(?);"))
        (insert-token-saw
         (prepare
          db
          "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);"))
        (select-token
         (prepare
          db
          "SELECT token_id FROM tokens WHERE token = ? LIMIT 1;"))
        (select-saw
         (prepare
          db
          "SELECT saw_id FROM saws WHERE saw = ? LIMIT 1;"))
        (count-token-saws
         (prepare
          db
          "SELECT count(*) FROM token_saws WHERE token_id = ? AND saw_id = ?;"))
        )
    (loop
     ((for line (in-port (current-input-port) read-line)))
;;;      ((for line (in-file "04.01.01" read-line)))
     (let ((match (string-match pattern line)))
       (if match
           (let* ((saw (cadr match))
                  (tokens (interesting-tokens saw)))
             (with-transaction
              db
              (lambda ()
                (let ((saw-id
                       (condition-case
                        (begin
                          (execute insert-saw saw)
                          (last-insert-rowid db))
                        ((exn sqlite3)
                         (first-result select-saw saw)))))
                  (for-each
                   (lambda (token)
                     (let ((token-id
                            (condition-case
                             (begin
                               (execute insert-token token)
                               (last-insert-rowid db))
                             ((exn sqlite3)
                              (first-result select-token token)))))
                       (if (zero?
                            (first-result count-token-saws
                                                  saw-id
                                                  token-id))
                           (execute insert-token-saw saw-id token-id))))
                   tokens))))))))))
