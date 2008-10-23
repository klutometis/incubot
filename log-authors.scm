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
(define pattern "[0-9]{2}:[0-9]{2}:[0-9]{2} <([^>]*)> .*")
(define min-length 3)
(define (process-token token)
  (string-downcase (string-filter char-set:letter token)))
(define (filter-token token)
  (> (string-length token) min-length))
(define (interesting-tokens saw)
  (map process-token
       (filter filter-token
               (string-tokenize saw char-set:letter))))
(let ((author-file (open-output-file "authors")))
  (loop
   ((for line (in-port (current-input-port) read-line)))
;;;    ((for line (in-file "04.01.01" read-line)))
   (let ((match (string-match pattern line)))
     (if match
         (let ((author (cadr match)))
           (display author author-file)
           (newline author-file)))))
  (close-output-port author-file))
