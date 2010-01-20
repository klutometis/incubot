;;; Copyright (C) 2008, Peter Danenberg
(import scheme chicken)
(use data-structures)
(let iter ((value (read)))
  (if (eof-object? value)
      value
      (let ((value (->string (eval value))))
        (print (substring value 0 (min (string-length value)
                                       (+ 256 1))))
        (iter (read)))))
