(require-extension
 syntax-case
 sqlite3
 (srfi 1 11 12 13 27 95))
(module
 incubot
 (analyse
  log-variate-integer)
 (include "analysis.scm"))
