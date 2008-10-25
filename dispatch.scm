(define (thread-start/timeout! timeout thread)
  (let ((thread (thread-start! thread)))
    (let* ((flag (random-real))
           (join (thread-join! thread timeout flag)))
      (if (= join flag)
          (thread-terminate! thread)
          join))))

(define (make-timer time thunk)
  (make-thread (lambda () (thread-sleep! time) (thunk))))

(define (dispatch say string timeout)
  (let-values (((stdout stdin id stderr)
                (process* "./read")))
    (let ((thread
           (thread-start!
            (lambda ()
              (display string stdin)
              (close-output-port stdin)
              (let ((output
                     (loop ((for next-line (in-port stdout read-line))
                            (with line #!eof next-line))
                           => line))
                    (error (read-line stderr)))
                (close-input-port stdout)
                (close-input-port stderr)
                (cond ((not (eof-object? error)) (say error))
                      ((not (eof-object? output)) (say output)))))))
          (timer
           (make-timer
            timeout
            (lambda ()
              (condition-case
               (let-values (((termination
                              normality
                              status)
                             (process-wait id #t)))
                 (if (zero? termination)
                     (begin
                       (process-signal id signal/term)
                       (say "Evaluation timed out."))))
               ((exn process) values))))))
      (thread-start! timer)
      (thread-join! timer))))
