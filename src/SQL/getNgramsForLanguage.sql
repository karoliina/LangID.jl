SELECT *
FROM ngrams
WHERE language=?
ORDER BY n ASC, ngram ASC;
