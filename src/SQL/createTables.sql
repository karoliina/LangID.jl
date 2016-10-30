CREATE TABLE IF NOT EXISTS articles (
    language text NOT NULL,
    id integer PRIMARY KEY,
    title text NOT NULL,
    length integer NOT NULL
)

CREATE TABLE IF NOT EXISTS ngrams (
    language text PRIMARY KEY,
    n integer NOT NULL,
    ngram text NOT NULL,
    count integer NOT NULL
);
