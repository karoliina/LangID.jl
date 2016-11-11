module Identification

using SQLite
using Database, GetNgrams

export identify_language, get_ngram_count_vectors

# Functions for querying the SQLite N-gram database for the closest match between a given text and the N-gram
# counts contained in the database.

const SQL_DIR = "SQL"

"""
Computes the cosine similarity, or the cosine of the angle between the two vectors, of vectors a and b.
"""
function cosine(a::SparseVector{Int64,Int64}, b::SparseVector{Int64,Int64})
    # ensure the sparse vectors are of equal length
    if length(a) < length(b)
        a = sparsevec(a.nzind, a.nzval, b.n)
    elseif length(a) > length(b)
        b = sparsevec(b.nzind, b.nzval, a.n)
    end
    # compute the cosine similarity
    return dot(a, b)/(norm(a)*norm(b))
end

"""
Constructs (sparse) vectors containing N-gram counts. Each vector will represent one of the Wikipedia articles
in the database, and will contain all of the N-grams from every language as its elements, in the form

    (n_11, n_12, ..., n_1j, n_21, n_22, ..., n_2k, ..., n_Nl)

where n_1* are 1-gram counts, n_2* are 2-gram counts, and so on. The n-grams are sorted first by the ascending
value of N and then, within each N, lexicographically. If a certain article does not contain some N-gram, the
corresponding vector element will be zero.

Returns a dictionary mapping the article ID's to (language, vector) tuples, as well as a dictionary mapping
each of the N-grams to its index in the N-gram vectors.
"""
function get_ngram_count_vectors(db::SQLite.DB)
    # query the database for all distinct N-grams and construct the n-gram -> vector index dictionary
    res = SQLite.query(db, readstring(joinpath(SQL_DIR, "getAllNgrams.sql")))
    ngram_idx = Dict{String,Int64}()
    num_ngrams = size(res, 1)
    for i=1:num_ngrams
        ngram_idx[get(res[i,1])] = i
    end

    # construct the N-gram sparse vectors for each article in the database
    vectors = Dict{Int64,Tuple{String,SparseVector{Int64,Int64}}}()
    articles = SQLite.query(db, readstring(joinpath(SQL_DIR, "getNgramsByArticle.sql")))
    articles[:id] = convert(Array{Int64,1}, articles[:id])
    articles[:language] = convert(Array{String,1}, articles[:language])
    articles[:ngram] = convert(Array{String,1}, articles[:ngram])
    articles[:count] = convert(Array{Int64,1}, articles[:count])
    ids = unique(articles[:id])

    for id in ids
        articles_with_id = articles[articles[:id] .== id,:]
        vector = sparsevec([ngram_idx[x] for x in articles_with_id[:,:ngram]], articles_with_id[:,:count])
        vectors[id] = (articles_with_id[1,:language], vector)
    end

    return vectors, ngram_idx
end


"""
Given a sample text, attempts to identify it using the N-gram database.

Returns an array of tuples in the form (language, article ID, cosine similarity), sorted by descending cosine
similarity. Also returns the constructed N-gram count vectors, to avoid constructing them more than once per
program run.
"""
function identify_language(text::String, n_start::Int64, n_stop::Int64, db::SQLite.DB)
    println("Constructing N-gram count vectors, this will take a while...")
    vectors, ngram_idx = get_ngram_count_vectors(db)
    results = identify_language(text, vectors, ngrams, n_start, n_stop)
    return results, vectors
end


"""
Given a sample text and previously constructed N-gram count vectors, attempts to identify the language.

Returns a DataFrame containing the language, article ID and cosine similarity with the given text for each
article in the database.
"""
function identify_language(text::String, vectors::Dict{Int64,Tuple{String,SparseVector{Int64,Int64}}},
                           ngram_idx::Dict{String,Int64}, n_start::Int64, n_stop::Int64)

    # construct N-gram vector from the given text
    text_vector = get_ngram_vector(text, ngram_idx, n_start, n_stop)

    num_articles = length(vectors)
    results = DataFrame(language=Array{String}(num_articles),
                        id=Array{Int64}(num_articles),
                        similarity=Array{Float64}(num_articles))
    i = 1
    for (id, v) in vectors
        lang = v[1]
        vector = v[2]
        similarity = cosine(text_vector, vector)
        results[i,:language] = lang
        results[i,:id] = id
        results[i,:similarity] = similarity
        i += 1
    end

    results
end

end # module
