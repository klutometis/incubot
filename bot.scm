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

(define (exchange-saw db tokens)
  (let* ((select-token
          (sqlite3:prepare
           db
           "SELECT token_id, token_count FROM tokens WHERE token = ? LIMIT 1;"))
         (token-ids
          (map
           (lambda (token)
             (condition-case
              (sqlite3:first-row
               select-token
               token)
              ((exn sqlite3) #f)))
           tokens))
         (filtered-token-ids
          (filter values token-ids))
         (sorted-token-ids
          (sort filtered-token-ids > cadr)))
    (debug sorted-token-ids)
    (if (not (null? sorted-token-ids))
        (let* ((token-id
               (car
                (list-ref sorted-token-ids
                          (log-variate-integer
                           (length sorted-token-ids)))))
               (saw-ids
                (sqlite3:map-row
                 values
                 db
                 "SELECT saw_id FROM token_saws WHERE token_id = ?;"
                 token-id)))
          (debug token-id saw-ids)))))

(define (incubot-connect! incubot)
  (let ((connection (irc:connect (incubot-connection incubot)))
        (channel (incubot-channel incubot))
        (timeout (incubot-timeout incubot))
        (db (incubot-db incubot)))
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
                         (let ((interesting-tokens
                                (interesting-tokens
                                 body
                                 (list nick))))
                           (exchange-saw db interesting-tokens)
                           (irc:say
                            connection
                            (string-join
                             interesting-tokens)
                            destination)
                           (log-tokens
                            db
                            sender
                            interesting-tokens
                            body)))))))))
        (irc:join connection channel)
        (irc:add-message-handler!
         connection
         handle
         command: "PRIVMSG"
         body: nick)
        (thread-start!
         (let ((origin (format "PING :~A" nick)))
           (lambda ()
             (let iter ()
               (thread-sleep! 30)
               (irc:command connection origin) 
               (iter)))))
        (irc:run-message-loop
         connection
         debug: #t
         ping: #t)))))
