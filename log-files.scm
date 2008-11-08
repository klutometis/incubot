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
(let ((token-file (open-output-file "tokens"))
      (saw-file (open-output-file "saws")))
  (loop
   ((for line (in-port (current-input-port) read-line)))
;;;    ((for line (in-file "04.01.01" read-line)))
   (let ((match (string-match pattern line)))
     (if match
         (let* ((saw (cadr match))
                (tokens (interesting-tokens saw)))
           (if (not (null? tokens))
               (begin
                 (display saw saw-file)
                 (newline saw-file)
                 (for-each
                  (lambda (token)
                    (display token token-file)
                    (newline token-file))
                  tokens)))))))
  (close-output-port token-file)
  (close-output-port saw-file))
