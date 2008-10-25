(define (thread-start/timeout! timeout flag thread)
  (let ((thread (thread-start! thread)))
    (let ((join (thread-join! thread timeout flag)))
      (if (= join flag)
          (thread-terminate! thread))
      join)))

(define (make-timer time thunk)
  (make-thread (lambda () (thread-sleep! time) (thunk))))

(define (interesting? output)
  (not (eof-object? output)))

(define maximum-length 256)

(define (process-output output)
  (let ((length (string-length output)))
     (if (> length maximum-length)
         (string-append
          (string-take output maximum-length) "...")
         output)))

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
                (cond ((interesting? error)
                       (say (process-output error)))
                      ((interesting? output)
                       (say (process-output output))))))))
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
                       (say (format "Eval ~A timed out." id)))))
               ((exn process) values))))))
      (thread-start! timer)
      (thread-join! timer))))
