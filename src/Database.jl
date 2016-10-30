module Database

using SQLite, ProgressMeter
using GetNgrams

export initialize_database!, LANGUAGES, SQL_DIR

"""
Functions for constructing and querying the N-gram SQLite database.
"""

# the languages included in the system. these are the top 30 languages in descending order of the number of
# articles.
const LANGUAGES = Dict{String,String}(
 "en"  =>  "English",
 "sv"  =>  "Swedish",
 "ceb" =>  "Cebuano",
 "de"  =>  "German",
 "nl"  =>  "Dutch",
 "fr"  =>  "French",
 "ru"  =>  "Russian",
 "it"  =>  "Italian",
 "es"  =>  "Spanish",
 "war" =>  "Winaray",
 "pl"  =>  "Polish",
 "vi"  =>  "Vietnamese",
 "ja"  =>  "Japanese",
 "pt"  =>  "Portuguese",
 "zh"  =>  "Chinese",
 "uk"  =>  "Ukrainian",
 "ca"  =>  "Catalan",
 "fa"  =>  "Persian",
 "no"  =>  "Norwegian (Bokmål)",
 "ar"  =>  "Arabic",
 "sh"  =>  "Serbo-Croatian",
 "fi"  =>  "Finnish",
 "hu"  =>  "Hungarian",
 "id"  =>  "Indonesian",
 "ro"  =>  "Romanian"
)

# directory containing the SQL files
const SQL_DIR = "SQL"

# the maximum number of variables in a SQLite query
const MAX_QUERY_LENGTH = 500


"""
Creates the SQLite database tables for storing article metadata and N-grams, and saves the database under the
given filename.
"""
function initialize_database!(filename::String, num_articles::Int64, n_start::Int64, n_stop::Int64)
    tic();

    db = SQLite.DB(filename)

    for sql_file in ["createArticlesTable.sql", "createNgramsTable.sql"]
        create_table_sql = readstring(joinpath(SQL_DIR, sql_file))
        SQLite.execute!(SQLite.Stmt(db, create_table_sql))
    end

    l = 1
    for (lang_id, lang_name) in LANGUAGES
        println("$(l)/$(length(LANGUAGES)): $(lang_name)")
        articles = query_articles!(lang_id, num_articles, db)
        create_and_store_ngrams!(lang_id, articles, n_start, n_stop, db)
        l += 1
    end

    t = toq();
    seconds = Dates.Second(round(t))
    println("Database initialization took $(Dates.CompoundPeriod(seconds))")

    return db
end


"""
Queries Wikipedia for the given number of articles in the given language, writing the metadata (article ID,
title and text length in bytes) into the Article table in the database.
Returns an array of the article texts.
"""
function query_articles!(language::String, num_articles::Int64, db::SQLite.DB)
    article_data = get_random_articles(language, num_articles)

    insert_article_sql = readstring("$(SQL_DIR)/insertArticle.sql")
    stmt = SQLite.Stmt(db, insert_article_sql)

    i = 1
    for (id, title, text) in article_data
        SQLite.bind!(stmt, 1, language)
        SQLite.bind!(stmt, 2, id)
        SQLite.bind!(stmt, 3, title)
        SQLite.bind!(stmt, 4, length(text))
        SQLite.execute!(stmt)
        i += 1
    end

    return article_data
end


"""
TODO docblock
"""
function construct_ngram_insert_query(num_ngrams::Int64)
    # println("query has $(num_ngrams*5) variables")
    insert_ngram_sql = readstring("$(SQL_DIR)/insertNgram.sql")
    b_range = search(insert_ngram_sql, r"\([?, ]+\)")
    values_block = insert_ngram_sql[b_range]
    sql = insert_ngram_sql[1:b_range.start-1]
    for i=1:num_ngrams-1
        sql *= values_block*","
    end
    sql *= values_block*";"
    return sql
end


"""
TODO docblock
"""
function create_and_store_ngrams!(language::String, articles::Array{Tuple{Int64,String,String}},
                                  n_start::Int64, n_stop::Int64, db::SQLite.DB)
    println("\tCreating N-grams...")
    ngrams, num_ngrams = find_all_article_ngram_counts(articles, n_start, n_stop)

    s = @sprintf "%-35s" "Inserting N-grams into database..."
    p = Progress(length(articles)*length(n_start:n_stop), 0.05, "\t"*s, 40)
    for n=n_start:n_stop
        for id in keys(ngrams[n])
            num_sql_variables = length(ngrams[n][id])*5
            if num_sql_variables > MAX_QUERY_LENGTH
                max_ngrams_per_query = div(MAX_QUERY_LENGTH, 5)
                num_max_length_queries, ngrams_in_remainder_query = divrem(length(ngrams[n][id]),
                                                                           max_ngrams_per_query)
                sql1 = construct_ngram_insert_query(max_ngrams_per_query)

                stmt = SQLite.Stmt(db, sql1)
                for q=0:num_max_length_queries-1
                    i = 0
                    start_idx = q*max_ngrams_per_query+1
                    stop_idx = (q+1)*max_ngrams_per_query
                    for (ngram, ngram_count) in ngrams[n][id][start_idx:stop_idx]
                        SQLite.bind!(stmt, i+1, language)
                        SQLite.bind!(stmt, i+2, n)
                        SQLite.bind!(stmt, i+3, ngram)
                        SQLite.bind!(stmt, i+4, ngram_count)
                        SQLite.bind!(stmt, i+5, id)
                        i += 5
                    end
                    SQLite.execute!(stmt)
                end

                if ngrams_in_remainder_query > 0
                    sql2 = construct_ngram_insert_query(ngrams_in_remainder_query)
                    stmt = SQLite.Stmt(db, sql2)
                    i = 0
                    # println("remainder:
                    #         $(length(ngrams[n][id][max_ngrams_per_query*num_max_length_queries+1:end])*5)
                    #         variables")

                    for (ngram, ngram_count) in ngrams[n][id][max_ngrams_per_query*num_max_length_queries+1:end]
                        SQLite.bind!(stmt, i+1, language)
                        SQLite.bind!(stmt, i+2, n)
                        SQLite.bind!(stmt, i+3, ngram)
                        SQLite.bind!(stmt, i+4, ngram_count)
                        SQLite.bind!(stmt, i+5, id)
                        i += 5
                    end
                    SQLite.execute!(stmt)
                end
            else
                sql = construct_ngram_insert_query(length(ngrams[n][id]))
                stmt = SQLite.Stmt(db, sql)
                i = 0
                for (ngram, ngram_count) in ngrams[n][id]
                    SQLite.bind!(stmt, i+1, language)
                    SQLite.bind!(stmt, i+2, n)
                    SQLite.bind!(stmt, i+3, ngram)
                    SQLite.bind!(stmt, i+4, ngram_count)
                    SQLite.bind!(stmt, i+5, id)
                    i += 5
                end
                SQLite.execute!(stmt)
            end
            next!(p)
        end
    end
end

end # module
