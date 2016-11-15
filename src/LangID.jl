module LangID

using ArgParse, HttpCommon, HttpServer, JSON, SQLite
using Database, DataFrames, Identification, Routes

const VECTORS_FILENAME = "vectors.jls"
const NGRAM_IDX_FILENAME = "ngram_idx.jls"


function parse_commandline()
    s = ArgParseSettings()::ArgParseSettings

    @add_arg_table s begin
        "database_filename"
            help = "database filename"
            default = "ngrams.sqlite"
        "--port"
            help = "port"
            arg_type = Int
            default = 8000
        "--serve"
            help = "start the web server"
            action = :store_true
    end

    return parse_args(s)
end


function app(req::Request, vectors::Dict{Int64,Tuple{String,SparseVector{Int64,Int64}}},
                ngram_idx::Dict{String,Int64})
    println("Requested $(req.resource)")
    res = Response()
    if req.resource == "/"
        s = open(read, "static/index.html")
        res.headers["Content-Type"] = "text/html"
        res.data = s
        res.status = 200
    elseif ismatch(r"^.*\.(css|js)", req.resource)
        s = open(read, "static"*req.resource)
        res.data = s
        res.status = 200
        if ismatch(r"^.*\.js", req.resource)
            res.headers["Content-Type"] = "application/javascript"
        elseif ismatch(r"^.*\.css", req.resource)
            res.headers["Content-Type"] = "text/css"
        end
    elseif req.resource == "/identify"
        identify(req, res, vectors, ngram_idx)
    else
        res.data = "Not found"
        res.status = 404
    end
    res.headers["Access-Control-Allow-Origin"] = "*"
    res.headers["Access-Control-Allow-Credentials"] = "true"
    res.headers["Access-Control-Allow-Methods"] = "GET,HEAD,OPTIONS,POST,PUT"
    res.headers["Access-Control-Allow-Headers"] = "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers"
    return res
end


function textUI(vectors::Dict{Int64,Tuple{String,SparseVector{Int64,Int64}}},
                ngram_idx::Dict{String,Int64})
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
            averages = aggregate(results, :language, mean)
            sort!(averages, cols=:similarity_mean, rev=true)

            println("\nThe 10 most similar languages by average article similarity:\n")
            println("\t    Language", repeat(" ", 11), "Similarity")
            println("\t", repeat("-", 33))
            for i=1:10
                num = @sprintf "%2d" i
                lang = @sprintf "%-18s" LANGUAGES[averages[i,:language]]
                sim = @sprintf "%5.2f" averages[i, :similarity_mean]
                println("\t$(num). $(lang) $(sim)")
            end

            println("\nThe 10 most similar articles:\n")
            println("\t    Language", repeat(" ", 11), "Similarity")
            println("\t", repeat("-", 33))
            for i=1:10
                num = @sprintf "%2d" i
                lang = @sprintf "%-18s" LANGUAGES[results[i,:language]]
                sim = @sprintf "%5.2f" results[i, :similarity]
                println("\t$(num). $(lang) $(sim)")
            end
        end
        println()
    end
    println("Bye!")
end


function main()
    args = parse_commandline()

    if !isfile(args["database_filename"])
        println("Creating N-gram database, this will take a while...")
        db = initialize_database!(args["database_filename"], 50, 1, 5)
    else
        db = SQLite.DB(args["database_filename"])
    end

    if !isfile(VECTORS_FILENAME) || !isfile(NGRAM_IDX_FILENAME)
        println("Constructing N-gram count vectors, this will take a while...")
        const vectors, ngram_idx = get_ngram_count_vectors(db)
        open(f -> serialize(f, vectors), VECTORS_FILENAME, "w")
        open(f -> serialize(f, ngram_idx), NGRAM_IDX_FILENAME, "w")
        println("Done")
    else
        const vectors = open(deserialize, VECTORS_FILENAME, "r")
        const ngram_idx = open(deserialize, NGRAM_IDX_FILENAME, "r")
    end

    if args["serve"]
        server = Server((req, res) -> app(req, vectors, ngram_idx))
        run(server, args["port"])
    else
        textUI(vectors, ngram_idx)
    end
end

if !isinteractive()
    main()
end

end # module
