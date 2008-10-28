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
  (if (null? tokens)
      #f
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
        (if (null? sorted-token-ids)
            #f
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
              (if (null? saw-ids)
                  #f
                  (sqlite3:first-result
                   db
                   "SELECT saw FROM saws WHERE saw_id = ? LIMIT 1;"
                   (list-ref saw-ids (random-integer (length saw-ids))))))))))

(define (useful-parameters message channel nick)
  (let ((receiver (irc:message-receiver message))
        (sender (irc:message-sender message))
        (body (message-body message)))
    (let* ((query? (string=? receiver nick))
           (destination (if query? sender channel)))
      (values receiver sender body destination))))

(define (intercourse! message connection channel timeout db nick)
  (let-values (((receiver sender body destination)
                (useful-parameters message channel nick)))
    (if (sexp body)
        (dispatch
         (cut irc:say connection <> destination)
         body
         timeout)
        (let* ((tokens (interesting-tokens body (list nick)))
               (saw (exchange-saw db tokens)))
          (if saw (irc:say connection saw destination))))))

(define (log-saw! message connection channel timeout db nick)
  (let-values (((receiver sender body destination)
                (useful-parameters message channel nick)))
    (let ((interesting-tokens
           (interesting-tokens body '())))
      (log-tokens db sender interesting-tokens body))))

(define (start-ping! connection nick)
  (thread-start!
   (let ((origin (format "PING :~A" nick)))
     (lambda ()
       (let iter ()
         (thread-sleep! 30)
         (irc:command connection origin) 
         (iter))))))

(define (incubot-connect! incubot)
  (let ((connection (irc:connect (incubot-connection incubot)))
        (channel (incubot-channel incubot))
        (timeout (incubot-timeout incubot))
        (db (incubot-db incubot)))
    (let ((nick (irc:connection-nick connection)))
      (irc:join connection channel)
      (irc:add-message-handler!
       connection
       (cut intercourse! <> connection channel timeout db nick)
       command: "PRIVMSG"
       body: nick)
      ;; Since handle doesn't return #f, log-saw should not be
      ;; invoked when handle is.
      (irc:add-message-handler!
       connection
       (cut log-saw! <> connection channel timeout db nick)
       command: "PRIVMSG")
      (start-ping! connection nick)
      (irc:run-message-loop
       connection
       debug: #t
       ping: #t))))
