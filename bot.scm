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
                         (dispatch
                          (cut irc:say connection <> destination)
                          body
                          timeout)
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
;;;          debug: #t
;;;          ping: #t
         )))))
