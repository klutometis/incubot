(define-record-type :incubot
  (make-incubot db connection channel)
  incubot?
  (db incubot-db)
  (connection incubot-connection)
  (channel incubot-channel))

(define (message-body message)
  (let ((parameters (cadr (irc:message-parameters message))))
    (if (irc:extended-data? parameters)
        (irc:extended-data-content parameters)
        parameters)))

(define (incubot-connect! incubot)
  (let ((connection (irc:connect (incubot-connection incubot))))
    (let ((nick (irc:connection-nick connection))
          (channel (incubot-channel incubot)))
      (let ((handle
             (lambda (message)
               (let ((receiver (irc:message-receiver message))
                     (sender (irc:message-sender message)))
                 (let ((destination
                        (if (string=? receiver nick) sender channel)))
                   (irc:say connection (message-body message) destination))))))
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
