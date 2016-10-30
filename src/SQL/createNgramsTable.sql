CREATE TABLE IF NOT EXISTS ngrams (
    language text NOT NULL,
    n integer NOT NULL,
    ngram text NOT NULL,
    count integer NOT NULL,
    id integer NOT NULL
);
