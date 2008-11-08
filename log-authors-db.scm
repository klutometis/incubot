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
(let ((db (sqlite3:open "log.db")))
  (let ((insert-author
         (sqlite3:prepare
          db
          "INSERT INTO authors (author) VALUES(?);")))
    (loop
     ((for author (in-file "authors-uniq" read-line))
      (with tokens 0 (+ tokens 1)))
     (if (zero? (modulo tokens 1000))
         (print tokens))
     (sqlite3:exec insert-author author))))
