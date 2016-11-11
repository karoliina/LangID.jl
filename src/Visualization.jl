module Visualization

using Gadfly, DataFrames, Database

export best_languages_barplot!


function best_languages_barplot!(df::DataFrame)
    sort!(df, cols=:similarity_mean)
    plot(df, x=df[:,:similarity_mean], y=[LANGUAGES[x] for x in df[:,:language]],
         Geom.bar(orientation=:horizontal),
         Theme(bar_spacing=2px),
         Guide.xlabel("Similarity"),
         Guide.ylabel("Language"))
end



end # module
