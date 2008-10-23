(require-extension
 srfi-27)
(require 'incubot)
(import incubot)
;; (analyse "i went to the market for certain appeal; came back weary")
(call-with-output-file
    "prob.dat"
  (lambda (port)
    (let write ((i 0))
      (if (< i 1000)
          (begin
;;;             (display (exponential-variate 1 (random-real)) port)
            (display (log (+ (* (random-real) (- (exp 4) 1)) 1)) port)
            (newline port)
            (write (+ i 1)))))))
;; (log-concave-variate 1 0)
