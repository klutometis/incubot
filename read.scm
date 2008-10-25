(let iter ((value (read)))
  (if (eof-object? value)
      value
      (begin (pretty-print (eval value))
             (iter (read)))))
