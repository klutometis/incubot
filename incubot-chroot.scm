;;; Copyright (C) 2008, Peter Danenberg
(use
 sqlite3
 irc
 posix)
(require 'incubot)
(import incubot)
(let ((root "/tmp/incubot"))
  (let ((bot
         (make-incubot (open-database "/tmp/incubot/log.db")
                       (irc:connection
                        server: "127.0.0.1"
                        nick: "incubot"
                        real-name: "Incubus Robot")
                       "#scheme"
                       2))
        (user (user-information "incubot")))
    (let ((user-id (third user))
          (group-id (fourth user)))
      (change-directory root)
      (set-root-directory! root)
      (set! (current-group-id) group-id)
      (set! (current-effective-group-id) group-id)
      (set! (current-user-id) user-id)
      (set! (current-effective-user-id) user-id)
      (incubot-connect! bot))))
