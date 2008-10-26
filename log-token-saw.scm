(require-extension
 syntax-case
 sqlite3
 (srfi 1 11 13))
(require 'incubot)
(import incubot)
(define-syntax debug
  (syntax-rules ()
    ((_ x ...)
     (print `((x ,x) ...)))))
(let ((db (sqlite3:open "log.db")))
  (let ((saws
         (sqlite3:prepare
          db
          "SELECT saw_id, saw FROM saws WHERE saw_id > 850000 LIMIT 250000;"))
        (insert-token-saw
         (sqlite3:prepare
          db
          "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);")))
    (sqlite3:for-each-row
     (lambda (saw-id saw)
       (let* ((tokens (interesting-tokens saw '()))
              (sql
               (format "SELECT token_id FROM tokens WHERE ~A;"
                       (string-join (make-list (length tokens) "token = ?")
                                    " OR ")))
              (statement (sqlite3:prepare db sql))
              (token-ids
               (condition-case
                (apply sqlite3:map-row values (cons statement tokens))
                ((exn sqlite3) #f)))
              (filtered-ids (filter values token-ids)))
         (if (zero? (modulo saw-id 100))
             (debug saw-id))
         (for-each
          (lambda (token-id)
            (sqlite3:exec insert-token-saw token-id saw-id))
          token-ids)))
     saws)))
