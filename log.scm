(define (insert/last-id db insert parameter)
  (sqlite3:exec insert parameter)
  (sqlite3:last-insert-rowid db))

(define (select-or-insert/id db select insert parameter)
  (condition-case
   (sqlite3:first-result select parameter)
   ((exn sqlite3)
    (insert/last-id db insert parameter))))

(define (log-tokens db author tokens saw)
  (let ((saw-id
         (select-or-insert/id
          db
          (sqlite3:prepare
           db
           "SELECT saw_id FROM saws WHERE saw = ? LIMIT 1;")
          (sqlite3:prepare
           db
           "INSERT INTO saws (saw) VALUES(?);")
          saw)))
    (let ((select-token-count
           (sqlite3:prepare
            db
            "SELECT token_count FROM tokens WHERE token_id = ? LIMIT 1;"))
          (select-token-id
           (sqlite3:prepare
            db
            "SELECT token_id FROM tokens WHERE token = ? LIMIT 1;"))
          (insert-token
           (sqlite3:prepare
            db
            "INSERT INTO tokens (token) VALUES(?);"))
          (insert-token-saw
           (sqlite3:prepare
            db
            "INSERT INTO token_saws (token_id, saw_id) VALUES(?, ?);"))
          (update-count
           (sqlite3:prepare
            db
            "UPDATE tokens SET token_count = ? WHERE token_id = ?;")))
      (let ((token-ids
             (map (lambda (token)
                    (select-or-insert/id db select-token-id insert-token token))
                  tokens)))
        (for-each
         (lambda (token-id)
           (condition-case
            (let ((count (sqlite3:first-result
                          select-token-count
                          token-id)))
              (sqlite3:exec update-count (+ count 1) token-id))
            ((exn sqlite3)
             (insert/last-id db insert-token token-id))))
         token-ids)
        (condition-case
         (sqlite3:exec
          db
          "INSERT INTO authors (author) VALUES(?);"
          author)
         ((exn sqlite3) 'author-exists))))))
