;;; Copyright (C) 2008, Peter Danenberg
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
  (let ((match (string-match ".*\\(.*\\)" body)))
    (if match
        (car match)
        match)))

(define (sorted-token-ids db tokens)
  (let* ((select-token
          (prepare
           db
           "SELECT token_id, token_count FROM tokens WHERE token = ? LIMIT 1;"))
         (token-ids
          (map
           (lambda (token)
             (condition-case
              (first-row
               select-token
               token)
              ((exn sqlite3) #f)))
           tokens))
         (filtered-token-ids
          (filter values token-ids)))
    (sort filtered-token-ids > cadr)))

(define (saw-ids db sorted-token-ids)
  (let ((token-id
         (car
          (list-ref sorted-token-ids
                    (log-variate-integer
                     (length sorted-token-ids))))))
    (map-row
     values
     db
     "SELECT saw_id FROM token_saws WHERE token_id = ?;"
     token-id)))

;;; Can be expanded to delete every instance of nicks; but that limits
;;; our vocabulary by certain important words, videlicet "actor".
(define (delete-vocative db saw)
  (let ((tokens (string-tokenize saw)))
    (if (null? tokens)
        saw
        (let* ((nick (string-filter char-set:nick (car tokens)))
               (author-id
                (condition-case
                 (first-result
                  db
                  "SELECT author_id FROM authors WHERE author = ? LIMIT 1;"
                  nick)
                 ((exn sqlite3) #f))))
          (if author-id
              (string-join (cdr tokens))
              saw)))))

(define (exchange-saw db tokens)
  (if (null? tokens)
      #f
      (let ((sorted-token-ids (sorted-token-ids db tokens)))
        (if (null? sorted-token-ids)
            #f
            (let ((saw-ids (saw-ids db sorted-token-ids)))
              (if (null? saw-ids)
                  #f
                  (let* ((random-saw-id
                          (list-ref saw-ids (random-integer
                                             (length saw-ids))))
                         (saw
                          (first-result
                           db
                           "SELECT saw FROM saws WHERE saw_id = ? LIMIT 1;"
                           random-saw-id)))
                    (delete-vocative db saw))))))))

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
      ;; Since intercourse! doesn't return #f, log-saw should not be
      ;; invoked when handle is.
      #;
      (irc:add-message-handler!
       connection
       (cut log-saw! <> connection channel timeout db nick)
       command: "PRIVMSG")
      #;
      (start-ping! connection nick)
      (irc:run-message-loop
       connection
       debug: #t
       ping: #t))))
