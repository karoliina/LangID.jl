# LangID.jl

A language identification system written in Julia.

This is my course project for the [Natural Language Processing
course](http://www.cs.mun.ca/~harold/Courses/CS4750/) at MUN. Identifies the language of the given text
by comparing its N-gram frequencies to those stored in a database created from Wikipedia articles in 30
different languages. Uses cosine similarity as the similarity metric.

Requires Julia 0.5, together with the `ArgParse`, `HttpServer`, `ProgressMeter`, `Formatting` and
`SQLite` packages (install with `Pkg.add("PackageName")`).

## Usage

`julia LangID.jl` will create the N-gram database on the first run. Requires an internet connection,
since the program will query articles from the Wikipedia API. The resulting database is ~100 MB in size. Takes
about 30 minutes.

Once the database is created, it is saved under `ngrams.sqlite` by default. (A different filename can be given
as a parameter to the program.) The command line version can then be run with `julia LangID.jl`.

For a web UI, you'll need to install `vue`, `vue-resource` and `chart.js` with `npm` (in the `src` directory)
and then run `browserify app.js > bundle.js` in the `static` directory. After this, the server can be started
with `julia LangID.jl --serve`. It serves the UI on `localhost:8000`.

This could be extended to visualize the similarities between the different languages contained in the database
-- some sort of clustering would be an interesting experiment.
