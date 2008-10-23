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
(let ((db (sqlite3:open "log.db")))
  (let ((insert-token
         (sqlite3:prepare
          db
          "INSERT INTO tokens (token, token_count) VALUES(?, ?);")))
    (loop
     (
;;;       (for token (in-port (current-input-port) read-line))
      (for token (in-file "tokens-uniq" read-line))
      (with tokens 0 (+ tokens 1)))
     (if (zero? (modulo tokens 1000))
         (print tokens))
     (let ((match (string-match " *([0-9]+) (.*)" token)))
       (if match
           (let ((token-count (cadr match))
                 (token (caddr match)))
             (sqlite3:exec insert-token token token-count)))))))
