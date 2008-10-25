(define-record-type :incubot
  (make-incubot db connection channel timeout)
  incubot?
  (db incubot-db)
  (connection incubot-connection)
  (channel incubot-channel)
  (timeout incubot-timeout))

(define (message-body message)
  (let ((parameters (cadr (irc:message-parameters message))))
    (if (irc:extended-data? parameters)
        (irc:extended-data-content parameters)
        parameters)))

(define (sexp body)
  (let ((match (string-match (regexp "\\(.*\\)") body)))
    (if match
        (car match)
        match)))

(define (string->expression string)
  (with-input-from-string string (lambda () (read))))

(define (string->thunk string)
  (lambda () (eval (string->expression string))))

(define (expression->string expression)
  (condition-case
   (->string (eval expression))
   ((exn arity) "An arity exception occurred.")
   ((exn type) "A type  exception occurred.")
   ((exn arithmetic) "An arithmetic exception occurred.")
   ((exn i/o) "An i/o exception occurred.")
   ((exn i/o file) "A file-i/o exception occurred.")
   ((exn i/o net) "A net-i/o  exception occurred.")
   ((exn bounds) "A bounds exception occurred.")
   ((exn runtime) "A runtime exception occurred.")
   ((exn runtime limit) "A runtime-limit exception occurred.")
   ((exn match) "A match exception occurred.")
   ((exn syntax) "A syntax exception occurred.")
   ((exn breakpoint) "A breakpoint exception occurred.")
   ((exn) "An unknown exception occurred.")
   (var () (->string var))))

(define (incubot-connect! incubot)
  (let ((connection (irc:connect (incubot-connection incubot)))
        (channel (incubot-channel incubot))
        (timeout (incubot-timeout incubot)))
    (let ((nick (irc:connection-nick connection)))
      (let ((handle
             (lambda (message)
               (let ((receiver (irc:message-receiver message))
                     (sender (irc:message-sender message))
                     (body (message-body message)))
                 (let ((query? (string=? receiver nick))
                       (expression? (sexp body)))
                   (let ((destination (if query? sender channel)))
                     (if expression?
                         (thread-start/timeout!
                          timeout
                          (lambda ()
                            (irc:say
                             connection
                             (expression->string
                              (string->expression expression))
                             destination)))
                         (irc:say
                          connection
                          (string-join
                           (interesting-tokens (message-body message)
                                               (list nick)))
                          destination))))))))
        (irc:join connection channel)
        (irc:add-message-handler!
         connection
         handle
         command: "PRIVMSG"
         body: nick)
        (irc:run-message-loop
         connection
         debug: #t
         ping: #t)))))
