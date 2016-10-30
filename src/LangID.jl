module LangID

using SQLite, DataFrames
using Database, Identify

# TODO argparse: database filename
# TODO clean up UI, format results etc.

function main()
    database_filename = "ngrams.sqlite"
    vectors_filename = "vectors.jls"
    ngram_idx_filename = "ngram_idx.jls"

    if !isfile(database_filename)
        println("Creating N-gram database, this will take a while...")
        db = initialize_database!(database_filename, 50, 1, 5)
    else
        db = SQLite.DB(database_filename)
        if !isfile(vectors_filename) || !isfile(ngram_idx_filename)
            println("Constructing N-gram count vectors, this will take a while...")
            vectors, ngram_idx = get_ngram_count_vectors(db)
            open(f -> serialize(f, vectors), vectors_filename, "w")
            open(f -> serialize(f, ngram_idx), ngram_idx_filename, "w")
            println("Done")
        else
            vectors = open(deserialize, vectors_filename, "r")
            ngram_idx = open(deserialize, ngram_idx_filename, "r")
        end
        command = "i"
        while command != "q"
            println("Enter i to identify text, q to quit")
            command = chomp(readline())
            if command == "i"
                println("\nEnter some text, once done enter two empty lines")
                text = ""
                newline_count = 0
                while newline_count < 2
                    line = readline()
                    line == "\n" ? newline_count += 1 : newline_count = 0
                    text *= line
                end

                if length(text) == 0
                    continue
                end

                println("\nIdentifying language")
                results = identify_language(text, vectors, ngram_idx, 1, 5)
                sort!(results, cols=:similarity, rev=true)

                println("\nThe 10 most similar articles:")
                for i=1:10
                    println("\t$(i). $(LANGUAGES[results[i,:language]]), similarity = $(results[i,:similarity])")
                end

                averages = aggregate(results, :language, mean)
                sort!(averages, cols=:similarity_mean, rev=true)
                println("\nThe 10 most similar languages by average article similarity:")
                for i=1:10
                    lang = LANGUAGES[averages[i,:language]]
                    println("\t$(i). $(lang), similarity = $(averages[i,:similarity_mean])")
                end
            end
            println()
        end
        println("Bye!")
    end
end

if !isinteractive()
    main()
end

end # module
