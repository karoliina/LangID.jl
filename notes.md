* Wikipedia articles as training data, retrieved through the API from Julia
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

  * presentation: use an iJulia notebook?

TODO
  * design the UI
    * add more descriptive instructions and messages
    * format the output nicely
    * a web UI would be quite easy too, and much more impressive
      * use HttpServer to serve the data, and HTML/CSS/JS with Chart.js or plotly.js to create the UI (plotly.js
        seems better)
        * Vue.js and the vue-resource plugin (for HTTP requests) for the front end
  * cluster the languages using their prototype vectors and visualize
    * prototype vectors are created by adding the article vectors for each language
    * use some out-of-the-box algorithm from the Clustering package
      * for this, the vectors need to be collected into a matrix - this does not work for sparse matrices!
      * kmeans(X, k) where X is a matrix with the feature vectors as columns is very easy to use, and
        definitely fast enough for a 1000000x30 matrix
        * this does not use cosine similarity! may need to implement a custom version: https://www.quora.com/How-can-I-use-cosine-similarity-in-clustering-For-example-K-means-clustering
          * spherical k-means
    * how to visualize the ~1e6-dimensional cluster centroids and data points? project to 2D somehow?
