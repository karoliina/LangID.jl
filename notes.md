* Wikipedia dumps as training data
  * use https://github.com/attardi/wikiextractor to convert .xml dumps into plain text
  * download and convert dumps one by one, storing the n-gram frequencies for each language into a SQLite
    database?
    * need to find out how many articles per language to use, and to compile a list of languages to use
      * https://meta.wikimedia.org/wiki/List_of_Wikipedias#All_Wikipedias_ordered_by_number_of_articles
  * alternatively use the API, through Julia, to get a random article in each of the languages N times
    * full documentation: https://en.wikipedia.org/w/api.php?action=help&modules=main
    * 1000 random pages in english: https://en.wikipedia.org/w/api.php?action=query&list=random&format=json&rnnamespace=0&rnlimit=1000
      * use article ID's to get the text
    * (almost) plain text for an article ID: https://en.wikipedia.org/w/api.php?format=jsonfm&action=query&pageids=17241468&prop=extracts&explaintext
      * need to strip out all non-alpha characters other than spaces, and replace newlines by spaces
      * this uses the TextExtracts extension: https://www.mediawiki.org/wiki/Extension:TextExtracts

  * top 30 languages in decreasing order of articles:
    * source: https://meta.wikimedia.org/wiki/List_of_Wikipedias#All_Wikipedias_ordered_by_number_of_articles
    * en, sv, ceb, de, nl, fr, ru, it, es, war, pl, vi, ja, pt, zh, uk, ca, fa, no, ar, sh, fi, hu, id, ro

  * database initialization takes about 2 hours (2 h, 9 min, 17 sec)
  * database contains ~1 million distinct N-grams

TODO
  * design the UI
    * how will the text be input? both STDIN and text file
    * need to store human-readable language names somewhere, for a nice output
      * separate languages table?
      * or make the LANGUAGES constant a dictionary that is accessible from main?
    * a web UI would be quite easy too, and much more impressive
      * Escher makes both the serving and UI's, including graphs, super easy: http://escher-jl.org/

  * try the nearest prototype method, or average the similarities over each language?

