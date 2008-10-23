(require-extension
 syntax-case
 sqlite3
 (srfi 1 11 13 27))
(module
 incubot
 (analyse
  cumulative-log-distribution
  log-probability-mass
  log-concave-variate
  exponential-variate)
 (include "analysis.scm"))
