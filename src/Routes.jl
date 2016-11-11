module Routes

using DataFrames, HttpCommon, HttpServer, JSON
using Database, Identification
export root, identify


function root(req::Request, res::Response)
    s = open(read, "index.html")
    res.headers["Content-Type"] = "text/html"
    res.data = s
    res.status = 200
end


function identify(req::Request, res::Response, vectors::Dict{Int64,Tuple{String,SparseVector{Int64,Int64}}},
                  ngram_idx::Dict{String,Int64})

    text = String(req.data)
    if length(text) == 0
        res.data = "Please give some text to identify!"
        return
    end

    # println("\nIdentifying language")
    results = identify_language(text, vectors, ngram_idx, 1, 5)
    sort!(results, cols=:similarity, rev=true)

    # println("\nThe 10 most similar articles:")
    articles = Array{Dict{String,Any}}(10)
    for i=1:10
        # println("\t$(i). $(LANGUAGES[results[i,:language]]), similarity = $(results[i,:similarity])")
        articles[i] = Dict{String,Any}()
        articles[i]["language"] = LANGUAGES[results[i,:language]]
        articles[i]["similarity"] = results[i,:similarity]
    end

    averages = aggregate(results, :language, mean)
    sort!(averages, cols=:similarity_mean, rev=true)
    # println("\nThe 10 most similar languages by average article similarity:")
    languages = Array{Dict{String,Any}}(10)
    for i=1:10
        lang = LANGUAGES[averages[i,:language]]
        # println("\t$(i). $(lang), similarity = $(averages[i,:similarity_mean])")
        languages[i] = Dict{String,Any}()
        languages[i]["language"] = lang
        languages[i]["similarity"] = averages[i,:similarity_mean]
    end

    res.data = JSON.json(Dict{AbstractString,Any}("articles" => articles, "languages" => languages))
    res.status = 200
end

end # module
