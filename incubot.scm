;;; Copyright (C) 2008, Peter Danenberg
(require-extension
 syntax-case
 sqlite3
 posix
 regex
 irc
 ports
 foof-loop
 (srfi 1 9 11 12 13 18 26 27 95))
(module
 incubot
 (analyse
  log-variate-integer
  interesting-tokens
  make-incubot
  incubot-connect!
  thread-start/timeout!
  maximum-length)
 (include "analysis.scm")
 (include "dispatch.scm")
 (include "log.scm")
 (include "bot.scm"))
