using Chain
using DataFrames
using DataFramesMeta
using Dates
using StatsBase


function get_mentions_by(twit_data::DataFrame, date_func::Function, manip_func::Function = mean)
    twit_data = add_mentions(twit_data)
    
    mentions_by = @chain twit_data begin
        @rtransform :temp = date_func(:date)
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


function wrap_in_makie(out_of_AoG, annotations, use_mad = false, fig = Figure(), use_log = false,)
    if use_log
        ax1 = Axis(fig[1,1],
            yscale = log10,
            xscale = log10,
            xlabel = annotations[1],
            ylabel = annotations[2],
            title = annotations[3],
        )
    else
        ax1 = Axis(fig[1,1],
            xlabel = annotations[1],
            ylabel = annotations[2],
            title = annotations[3],
        )
    end

    # dates = string.(out_of_AoG.data[1])
    days = length(out_of_AoG.data[1])
    # out_of_AoG.data.x = collect(1:days)
    ax1.xticks = (out_of_AoG.data[1][1:7:days], out_of_AoG.data[3][1:7:days])
    
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
    df = @chain df begin
        @subset(:true_type .!= "retweeted")
        groupby(:author_id)
        combine(column => sum => :tot)
        @orderby(-:tot)
        @transform(_,
        :cumulative = cumsum(:tot),
        :rownumber = rownumber.(eachrow(_))) .+ 1 # .+1 to make space for intercept
        @select :rownumber :cumulative
        rename(:rownumber => :x, :cumulative => :y)
    end
    #we add the intercept at 1,1 (that is 0,0 when logged)
    df = [DataFrame(x=1,y=1);df]
    return df
end
    

function get_column_summary(twit_data::DataFrame, column::Symbol, date_func::Function, manip_func::Function = sum)
    df = select(twit_data, :date, column)
    rename!(df, column => "data")
    df = @chain df begin
        @rtransform :d = date_func(:date)
        @by(:d, :y = manip_func(:data))
        @rtransform :x = dayofyear(:d)
        @select(:x, :y, :d)
    end

    return df
end


function plot_graph(data::DataFrame, annotations, add_mad::Bool = false, f = Figure(), use_log = false)
    aog = make_aog_graph(data)
    fig = wrap_in_makie(aog, annotations, add_mad, f, use_log)
    return fig
end
