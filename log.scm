(define (insert/last-id db insert parameter)
  (sqlite3:exec insert parameter)
  (sqlite3:last-insert-rowid db))

(define (select-or-insert/id db select insert parameter)
  (condition-case
   (sqlite3:first-result select parameter)
   ((exn sqlite3)
    (insert/last-id db insert parameter))))

(define (log-tokens db author tokens saw)
  (debug author tokens saw)
  (let* ((count-saws
          (sqlite3:prepare
           db
           "SELECT count(*) FROM saws WHERE saw = ? LIMIT 1;"))
         (saws
          (condition-case
           (sqlite3:first-result count-saws saw)
           ((exn sqlite3) 0))))
    (debug saws)
    (if (zero? saws)
        (let* ((insert-saw
                (sqlite3:prepare
                 db
                 "INSERT INTO saws (saw) VALUES(?);"))
               (saw-id
                (insert/last-id db insert-saw saw)))
          (debug saw-id)
          (let* ((select-token
                  (sqlite3:prepare
                   db
                   "SELECT token_id FROM tokens WHERE token = ? LIMIT 1;"))
                 (insert-token
                  (sqlite3:prepare
                   db
                   "INSERT INTO tokens (token) VALUES(?);"))
                 (token-ids
                  (map (lambda (token)
                         (select-or-insert/id db select-token insert-token token))
                       tokens)))
            (debug token-ids)
            (let ((insert-token-saw
                   (sqlite3:prepare
                    db
                    "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);")))
              (for-each
               (lambda (token-id)
                 (sqlite3:exec insert-token-saw token-id saw-id))
               token-ids)
              (let ((insert-author
                     (sqlite3:prepare
                      db
                      "INSERT INTO authors (author) VALUES(?);")))
                (condition-case
                 (sqlite3:exec insert-author author)
                 ((exn sqlite3) 'author-exists)))))))))
