;;; Copyright (C) 2008, Peter Danenberg
(use
 sqlite3
 irc)
(require 'incubot)
(import incubot)
(let ((bot
       (make-incubot (open-database "log.db")
                     (irc:connection
                      server: "localhost"
                      nick: "incubot"
                      real-name: "Incubus Robot")
                     "#scheme"
                     2)))
  (incubot-connect! bot))
