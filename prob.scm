;;; Copyright (C) 2008, Peter Danenberg
(require-extension
 srfi-27)
(require 'incubot)
(import incubot)
(call-with-output-file
    "prob.dat"
  (lambda (port)
    (let write ((i 0))
      (if (< i 100000)
          (begin
            (display (log-variate-integer 10) port)
            (newline port)
            (write (+ i 1)))))))
