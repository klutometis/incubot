(require-extension
 srfi-27)
(require 'incubot)
(import incubot)
;; (analyse "i went to the market for certain appeal; came back weary")
(call-with-output-file
    "prob.dat"
  (lambda (port)
    (let write ((i 0))
      (if (< i 100000)
          (begin
            (display (log-variate-integer 10) port)
            (newline port)
            (write (+ i 1)))))))
