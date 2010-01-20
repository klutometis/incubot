;;; Copyright (C) 2008, Peter Danenberg
(module
 incubot
 (analyse
  log-variate-integer
  interesting-tokens
  make-incubot
  incubot-connect!
  thread-start/timeout!
  maximum-length)
 (import scheme chicken)
 (use
  sqlite3
  posix
  irc
  ports
  foof-loop
  records
  format
  extras
  debug
  (srfi 1 13 14 18 27 95))
 (require-library regex)
 (import regex irregex)
 (include "analysis.scm")
 (include "dispatch.scm")
 (include "log.scm")
 (include "bot.scm"))
