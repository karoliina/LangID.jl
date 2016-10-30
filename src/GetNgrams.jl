module GetNgrams

using ProgressMeter, Formatting, Requests
import Requests: get, options

export get_random_articles, get_article, find_all_article_ngram_counts, get_ngram_vector

"""
Functions for retrieving text from Wikipedia articles using the Wikipedia API, and for extracting N-grams from
their contents.
"""

const API_URL = FormatExpr("https://{:s}.wikipedia.org/w/api.php")
const LENGTH_THRESHOLD = 1000


"""
Queries the Wikipedia API for n distinct, random articles in the given language by first retrieving a set of
random article ID's and then filtering out the articles that don't pass the length or uniqueness criteria. The
length of the article text in characters needs to be at least LENGTH_THRESHOLD, and duplicate article ID's
within each language are not accepted.
Returns an array of (article ID, title, text) tuples.
Throws an exception if the query fails to return with a response status of 200 (OK).
"""
function get_random_articles(language::String, n::Int64)
    query_options = Dict{String,Any}(
        "action"       => "query",
        "generator"    => "random",
        "format"       => "json",
        "prop"         => "info",
        "grnnamespace" => 0,
        "grnlimit"     => n
    )
    url = format(API_URL, language)

    ids = Set{Int64}()
    results = Array{Tuple{Int64,String,String}}(n) # id, title, text

    # query n articles at a time, repeating the query if necessary
    i = 1
    s = @sprintf "%-35s" "Querying articles..."
    p = Progress(n, 0.5, "\t"*s, 40)
    while length(ids) < n
        response = get(url; query=query_options)
        if response.status != 200
            throw(ErrorException("Failed to query for random article ID's in $(lang_name)!
                                 Response status was $(response.status)"))
        end
        content = Requests.json(response)["query"]["pages"]
        for (k, v) in content
            length(ids) == n && break
            if !in(v["pageid"], ids)
                title, text = get_article(language, v["pageid"])
                if length(text) >= LENGTH_THRESHOLD
                    push!(ids, v["pageid"])
                    results[i] = (v["pageid"], title, text)
                    i += 1
                    next!(p)
                end
            end
        end
    end

    return results
end


"""
Queries the Wikipedia API for the title and plain text contents of the article with the given ID, in the given
language.
Throws an exception if the query fails to return with a response status of 200 (OK).
"""
function get_article(language::String, id::Int64)
    query_options = Dict{String,Any}(
        "action"      => "query",
        "format"      => "json",
        "prop"        => "extracts",
        "explaintext" => true,
        "pageids"     => id
    )
    url = format(API_URL, language)

    response = get(url; query=query_options)
    if response.status != 200
        throw(ErrorException("Failed to query for article $(id) in the language $(language)! Response status
                             was $(response.status)"))
    end

    content = Requests.json(response)["query"]["pages"][string(id)]
    return content["title"], content["extract"]
end


"""
Cleans up the given text string so that N-grams can be extracted from it. Removes all numbers, removes all
punctuation characters other than apostrophes, replaces dashes and control characters with spaces, and
converts the string to lowercase.
"""
function preprocess_text(text::String)
    processed = ""
    # convert to lowercase
    lower = lowercase(text)
    # remove numbers, punctuation etc. as described
    for ch in lower
        if iscntrl(ch) || ch == '-'
            processed *= " "
        elseif isalpha(ch) || isspace(ch) || ch == '\''
            processed *= string(ch)
        end
    end
    # replace multiple subsequent spaces with a single one
    processed = replace(strip(processed), r"[ ]{2,}", " ")
    return processed
end


"""
Extracts the N-grams and their occurrence counts from the given string. Returns an array containing
(N-gram, count) pairs.
The input string is assumed to be in lowercase (where applicable) and to contain no punctuation other than
apostrophes, no numbers, and no newline characters.
"""
function get_ngram_counts(text::String, n::Int64)
    # split the text to tokens, pad them with underscores representing word boundaries (if n > 1)
    if n > 1
        tokens = ["_"*x*"_" for x in split(text, " ")]
    else
        tokens = split(text, " ")
    end

    ngrams = Dict{String,Int64}()
    for w in tokens
        # find the valid character indices in this token
        idx = filter(i->isvalid(w, i), 1:endof(w))
        # iterate over the N-grams
        for i=1:length(idx)-n+1
            ng = w[idx[i]:idx[i+n-1]]
            if haskey(ngrams, ng)
                ngrams[ng] += 1
            else
                ngrams[ng] = 1
            end
        end
    end

    return collect(ngrams)
end


"""
Extracts the N-grams with their counts from each of the given (unprocessed) strings. The values of N from
n_start to n_stop, inclusive, will be used.
Returns a dictionary mapping the values of N to article ID's to their respective N-gram count arrays, as
well as the total number of N-grams in the articles.
"""
function find_all_article_ngram_counts(articles::Array{Tuple{Int64,String,String}}, n_start::Int64,
                                       n_stop::Int64)

    ngrams = Dict{Int64,Dict{Int64,Array{Pair{String,Int64}}}}()
    for n=n_start:n_stop
        ngrams[n] = Dict{Int64,Array{Pair{String,Int64}}}()
    end

    num_ngrams = 0
    for (id, title, text) in articles
        processed = preprocess_text(text)
        for n=n_start:n_stop
            ngrams[n][id] = get_ngram_counts(processed, n)
            num_ngrams += length(ngrams[n][id])
        end
    end

    return ngrams, num_ngrams
end


"""
Given an (unprocessed) query text and a dictionary mapping N-grams existing in the database to their indices
in the sparse N-gram vectors, processes the query text using preprocess_text and constructs the N-gram count
vector from it.
"""
function get_ngram_vector(text::String, ngram_idx::Dict{String,Int64}, n_start::Int64, n_stop::Int64)
    processed = preprocess_text(text)

    max_idx = maximum(values(ngram_idx))
    vector = Dict{Int64,Int64}()
    for n=n_start:n_stop
        ngrams = get_ngram_counts(processed, n)
        for (ng, count) in ngrams
            if !haskey(ngram_idx, ng)
                max_idx += 1
                vector[max_idx] = count
            else
                vector[ngram_idx[ng]] = count
            end
        end
    end
    return sparsevec(vector)
end

end # module
