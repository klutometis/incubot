(let iter ((value (read)))
  (if (eof-object? value)
      value
      (let ((value (->string (eval value))))
        (display (substring value 0 (min (string-length value) 257)))
        (newline)
        (iter (read)))))
