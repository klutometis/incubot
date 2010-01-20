;;; Copyright (C) 2008, Peter Danenberg
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
(let ((db (open-database "log.db")))
  (let ((saws
         (prepare
          db
          "SELECT saw_id, saw FROM saws WHERE saw_id > 850000 LIMIT 250000;"))
        (insert-token-saw
         (prepare
          db
          "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);")))
    (for-each-row
     (lambda (saw-id saw)
       (let* ((tokens (interesting-tokens saw '()))
              (sql
               (format "SELECT token_id FROM tokens WHERE ~A;"
                       (string-join (make-list (length tokens) "token = ?")
                                    " OR ")))
              (statement (prepare db sql))
              (token-ids
               (condition-case
                (apply map-row values (cons statement tokens))
                ((exn sqlite3) #f)))
              (filtered-ids (filter values token-ids)))
         (if (zero? (modulo saw-id 100))
             (debug saw-id))
         (for-each
          (lambda (token-id)
            (execute insert-token-saw token-id saw-id))
          token-ids)))
     saws)))
