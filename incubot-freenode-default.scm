(require-extension
 syntax-case
 sqlite3
 irc)
(require 'incubot)
(import incubot)
(let ((bot
       (make-incubot (sqlite3:open "log.db")
                     (irc:connection
                      server: "irc.freenode.net"
                      nick: "incubot"
                      user: "incubot"
                      password: ""
                      real-name: "Incubus Robot")
                     "#scheme"
                     2)))
  (incubot-connect! bot))
