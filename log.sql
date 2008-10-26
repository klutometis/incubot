DROP TABLE IF EXISTS tokens;
CREATE TABLE tokens(
       token_id INTEGER PRIMARY KEY AUTOINCREMENT,
       token TEXT UNIQUE DEFAULT NULL,
       token_count INTEGER
       );
DROP TABLE IF EXISTS saws;
CREATE TABLE saws(
       saw_id INTEGER PRIMARY KEY AUTOINCREMENT,
       saw TEXT UNIQUE DEFAULT NULL
       );
DROP TABLE IF EXISTS token_saws;
CREATE TABLE token_saws(
       token_id INTEGER KEY,
       saw_id INTEGER
       );
DROP TABLE IF EXISTS authors;
CREATE TABLE authors(
       author_id INTEGER PRIMARY KEY AUTOINCREMENT,
       author TEXT UNIQUE DEFAULT NULL
       );
