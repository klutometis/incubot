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
(let ((db (sqlite3:open "log.db")))
  (let ((insert-saw
         (sqlite3:prepare
          db
          "INSERT INTO saws (saw) VALUES(?);"))
        (insert-token
         (sqlite3:prepare
          db
          "INSERT INTO tokens (token) VALUES(?);"))
        (insert-token-saw
         (sqlite3:prepare
          db
          "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);"))
        (select-token
         (sqlite3:prepare
          db
          "SELECT token_id FROM tokens WHERE token = ? LIMIT 1;"))
        (select-saw
         (sqlite3:prepare
          db
          "SELECT saw_id FROM saws WHERE saw = ? LIMIT 1;"))
        (count-token-saws
         (sqlite3:prepare
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
             (sqlite3:with-transaction
              db
              (lambda ()
                (let ((saw-id
                       (condition-case
                        (begin
                          (sqlite3:exec insert-saw saw)
                          (sqlite3:last-insert-rowid db))
                        ((exn sqlite3)
                         (sqlite3:first-result select-saw saw)))))
                  (for-each
                   (lambda (token)
                     (let ((token-id
                            (condition-case
                             (begin
                               (sqlite3:exec insert-token token)
                               (sqlite3:last-insert-rowid db))
                             ((exn sqlite3)
                              (sqlite3:first-result select-token token)))))
                       (if (zero?
                            (sqlite3:first-result count-token-saws
                                                  saw-id
                                                  token-id))
                           (sqlite3:exec insert-token-saw saw-id token-id))))
                   tokens))))))))))
