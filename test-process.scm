(require-extension
 syntax-case
 posix
 foof-loop
 (srfi 1 11 18))
(define reader
  "(let iter ((value (read)))
     (if (eof-object? value)
       value
       (begin (print (eval value))
              (iter (read)))))")
(define (make-timer time thunk)
  (make-thread (lambda () (thread-sleep! time) (thunk))))
(let-values (((stdout stdin id stderr)
              (process* (format "csi -s test-stdin.scm" reader))
;;;               (process* "./test-stdin")
              ))
  (let ((thread
         (thread-start!
          (lambda ()
            (display "incubot: (require-extension posix) (sleep 3) 2 unbound" stdin)
            (close-output-port stdin)
            (let ((output
                   (loop ((for next-line (in-port stdout read-line))
                          (with line #!eof next-line))
                         => line))
                  (error (read-line stderr)))
              (close-input-port stdout)
              (close-input-port stderr)
              (print output)
              (print error)))))
        (timer
         (make-timer
          2
          (lambda ()
            (print
             (condition-case
              (let-values (((termination
                             normality
                             status)
                            (process-wait id #t)))
                (if (zero? termination)
                    (begin
                      (process-signal id signal/term)
                      (format "Process ~A terminated." id))
                    (format "Process ~A finished." id)))
              ((exn process)
               (format "Process ~A does not exist." id))))))))
    (thread-start! timer)
    (thread-join! timer)))
