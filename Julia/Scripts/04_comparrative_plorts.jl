using Pkg

cd("Julia")

Pkg.activate(".")
Pkg.instantiate()

using Revise

include("01_wrangling.jl")
include("../src/tweet_helpers_refac_dateticks.jl")
include("../src/tweet_graphing.jl")

using Chain
using CairoMakie
using Colors
using AlgebraOfGraphics
using DataFrames
using DataFramesMeta
using Dates

set_aog_theme!()

normalize(vec) = (vec .- minimum(vec)) / (maximum(vec) - minimum(vec))

function cumulative_sorting(df,column;for_comparison::Bool = false, scandal::String)
    nonprofit = ["ComicRelief","WWP1","WWP2","Oxfam","RedCrossAU","MIT1","MIT2","MIT3"]

    df = @chain df begin
        @subset(:true_type .!= "retweeted")
        groupby(:author_id)
        combine(column => sum => :tot)
        @orderby(-:tot)
        @subset(:tot .> 0)
        @transform(_,
        :cumulative = cumsum(:tot),
        :rownumber = rownumber.(eachrow(_)))
        @select :rownumber :cumulative
        @rtransform :type = scandal ∈ nonprofit ? "Non Profit" : "Profit"
        @rtransform :scandal = scandal
        rename(:rownumber => :x, :cumulative => :y)
    end

    if for_comparison
       
        df = @chain df begin
            @transform :y = normalize(:y)
            @transform :x = normalize(:x)
        end
        
    end

    return df
end

scandals = string.(read_names("Data"));
dfs = [unique(df,[:tweet_id,:author_id]) for df in read_files("Data")]

get_date(x) = Date(x)



function cumulative_comparison_plot(dfs, scandals, what;for_comparison=false)
    cumulatives = [
        cumulative_sorting(df, what;
            for_comparison=for_comparison, scandal)
        for (df, scandal) in zip(dfs, scandals)]
    cumulatives = vcat(cumulatives...)

    xtitle = for_comparison ? "Proportion" : "Number"

    cumulatives_plot = data(cumulatives) *
                       mapping(:x => xtitle * " of authors considered",
                               :y => "Cumulative " * string(what),
                               group=:scandal,
                               color=:type) *
                       visual(Lines)

    draw(cumulatives_plot)

    return (cumulatives_plot)
end


colors = cgrad(:thermal, 19, categorical=true)

resolution = (800, 600)
fig = Figure(; resolution);


draw!(fig[1,1],
    cumulative_comparison_plot(dfs,scandals,:retweet_count);
    axis=(yscale=log10,
          xscale=log10)
    #palettes=(color=colors,)
)

draw!(fig[1,2],
    cumulative_comparison_plot(dfs,scandals,:reply_count);
    axis=(yscale=log10,
          xscale=log10)
    #palettes=(color=colors,)
)
        

draw!(fig[2,1],
    cumulative_comparison_plot(dfs,scandals,:quote_count);
    axis=(yscale=log10,
          xscale=log10)
    #palettes=(color=colors,)
)

mkpath("PlotsDate/comparative_plots/")
save("PlotsDate/comparative_plots/comparative_cumulatives_raw_numbers.png", fig, px_per_unit = 3)

resolution = (800, 600)
fig = Figure(; resolution);


draw!(fig[1,1],
    cumulative_comparison_plot(dfs,scandals,:retweet_count;for_comparison = true);
    #palettes=(color=colors,)
)

draw!(fig[1,2],
    cumulative_comparison_plot(dfs,scandals,:reply_count;for_comparison = true);
    #palettes=(color=colors,)
)
        

draw!(fig[2,1],
    cumulative_comparison_plot(dfs,scandals,:quote_count;for_comparison = true);
    #palettes=(color=colors,)
)

fig

save("PlotsDate/comparative_plots/comparative_cumulatives_normalized.png", fig, px_per_unit = 3)