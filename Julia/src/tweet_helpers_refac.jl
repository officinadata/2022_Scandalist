using Chain
using DataFrames
using DataFramesMeta
using Dates
using StatsBase


function get_mentions_by(twit_data::DataFrame, date_func::Function, manip_func::Function = mean)
    twit_data = add_mentions(twit_data)
    
    mentions_by = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nmentions = manip_func(:n_mentions))
    end

    rename!(mentions_by, :temp => Symbol(date_func))

    return mentions_by
end


function add_mentions(twit_data::DataFrame)
    twit_data.mentions = get_mentions.(lowercase.(twit_data.text))
    twit_data.n_mentions = length.(twit_data.mentions)
    
    return twit_data
end


function make_aog_graph(df::DataFrame)
    aog = data(df) *
        visual(Lines) *
        mapping(Symbol(names(df)[1]), Symbol(names(df)[2]))

    return aog
end


function wrap_in_makie(out_of_AoG, annotations, use_mad = false, fig = Figure())
    ax1 = Axis(fig[1,1],
        xlabel = annotations[1],
        ylabel = annotations[2],
        title = annotations[3]
        )

    draw!(ax1, out_of_AoG)

    if use_mad
        mean_data = mean(out_of_AoG.data[2])
        mad_data = mad(out_of_AoG.data[2])
        
        hlines!(ax1, mean_data)
        hspan!(ax1, mean_data-mad_data , mean_data+mad_data, color = (:blue, 0.2))
    end
    
    return fig
end


function cumulative_sorting(df,column)
    @chain df begin
        @subset(:true_type .!= "retweeted")
        groupby(:author_id)
        combine(column => sum => :tot)
        @orderby(-:tot)
        @transform(_,
        :cumulative = cumsum(:tot),
        :rownumber = rownumber.(eachrow(_)))
    end
    return df
end
    

function get_column_summary(twit_data::DataFrame, column::Symbol, date_func::Function, manip_func::Function = sum)
    df = select(twit_data, :date, column)
    rename!(df, column => "data")
    df = @chain df begin
        @transform(:x = date_func.(:date))
        @by(:x, :y = manip_func(:data))
    end

    return df
end


function plot_graph(data::DataFrame, annotations, add_mad::Bool = false, f = Figure())
    aog = make_aog_graph(data)
    fig = wrap_in_makie(aog, annotations, add_mad, f)
    return fig
end
