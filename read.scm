(require-extension syntax-case)
(require 'incubot)
(import incubot)
(let iter ((value (read)))
  (if (eof-object? value)
      value
      (let ((value (->string (eval value))))
        (print (substring value 0 (min (string-length value)
                                       (+ maximum-length 1))))
        (iter (read)))))
