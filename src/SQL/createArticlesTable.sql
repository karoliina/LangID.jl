CREATE TABLE IF NOT EXISTS articles (
    language text NOT NULL,
    id integer NOT NULL,
    title text NOT NULL,
    length integer NOT NULL,
    PRIMARY KEY (language, id)
);
