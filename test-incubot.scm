(require-extension
 syntax-case
 sqlite3
 irc)
(require 'incubot)
(import incubot)
(let ((bot
       (make-incubot (sqlite3:open "log.db")
                     (irc:connection
                      server: "localhost"
                      nick: "incubot"
                      real-name: "Incubus Robot")
                     "#scheme")))
  (incubot-connect! bot))
