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
(let ((db (open-database "log.db")))
  (let ((insert-saw
         (prepare
          db
          "INSERT INTO saws (saw) VALUES(?);")))
    (loop
     ((for saw (in-file "saws-uniq" read-line))
      (with tokens 0 (+ tokens 1)))
     (if (zero? (modulo tokens 1000))
         (print tokens))
     (execute insert-saw saw))))
