(require-extension
 syntax-case
 sqlite3
 (srfi 1 11 13 27))
(module
 incubot
 (analyse
  log-variate-integer)
 (include "analysis.scm"))
