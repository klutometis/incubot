;;; Copyright (C) 2008, Peter Danenberg
(let iter ((value (read)))
  (if (eof-object? value)
      value
      (begin (print (eval value))
             (iter (read)))))
