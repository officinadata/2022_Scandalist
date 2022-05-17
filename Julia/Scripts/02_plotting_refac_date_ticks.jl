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
using AlgebraOfGraphics
using DataFrames
using DataFramesMeta
using Dates
using Graphs
using SparseArrays
using DataStructures
using MetaGraphs
using GraphPlot
using Compose
import Cairo
import Compose


set_aog_theme!()


function graph2(df, date_func)
    fig = Figure()

    g1 = plot_graph(get_column_summary(df, :quote_count, date_func, sum), 
        ["Day of year", "N quotes", "Daily quote volume"], true, fig[1,1])
    g2 = plot_graph(get_column_summary(df, :retweet_count, date_func, sum), 
        ["Day of year", "N retweets", "Daily retweet volume"], true, fig[1,2])
    g3 = plot_graph(get_column_summary(df, :reply_count, date_func, sum), 
        ["Day of year", "N replies", "Daily reply volume"], true, fig[2,1])
    
    return fig
end


function graph4(df, date_func)
    fig = Figure()

    g1 = plot_graph(@transform(get_column_summary(df, :quote_count, date_func, sum), :y = :y/1440), 
        ["Day of year", "Avg n quotes per min", "Daily quote rate"], true, fig[1,1])
    g2 = plot_graph(@transform(get_column_summary(df, :retweet_count, date_func, sum), :y = :y/1440), 
        ["Day of year", "Avg n retweets per min", "Daily retweet rate"], true, fig[1,2])
    g3 = plot_graph(@transform(get_column_summary(df, :reply_count, date_func, sum), :y = :y/1440), 
        ["Day of year", "Avg n replies per min", "Daily reply rate"], true, fig[2,1])
 
    return fig
end


function graph5(df, date_func)
    fig = Figure()

    g1 = plot_graph(cumulative_sorting(df, :quote_count), 
        ["Author", "Cumulative n quotes", "Cumulative quotes by author"], false, fig[1,1], true)
    g2 = plot_graph(cumulative_sorting(df, :retweet_count),
        ["Author", "Cumulative n retweets", "Cumulative retweets by author"], false, fig[1,2], true)
    g3 = plot_graph(cumulative_sorting(df, :reply_count),
        ["Author", "Cumulative n replies", "Cumulative replies by author"], false, fig[2,1], true)
    
    return fig
end


function _plot_stats(df, date_func, dir)
    save(dir * "/graph1.png", plot_graph(get_column_summary(df, :author_id, date_func, length ∘ unique), ["Day of year", "N unique users", "Daily unique users"], true), px_per_unit = 3)
    save(dir * "/graph2.png", graph2(df, date_func), px_per_unit = 3)
    save(dir * "/graph3.png", plot_graph(@transform(get_column_summary(df, :author_id, date_func, length ∘ unique), :y = :y/1440),  ["Day of year", "N unique users per min", "Daily unique user rate"], true), px_per_unit = 3)
    save(dir * "/graph4.png", graph4(df, date_func), px_per_unit = 3)
    save(dir * "/graph5.png", graph5(df, date_func), px_per_unit = 3)
end


function _plot_graphs(df, dir)
    g,userL = generate_author_retweet_source_graph(df)
    author_mg = generate_unipartite_projection(g, userL)
    Compose.draw(Compose.PNG(dir * "/graph6.png", 16cm, 16cm), generate_most_connected_user_author_plot(author_mg))
    Compose.draw(Compose.PNG(dir * "/graph7.png", 16cm, 16cm), generate_most_connected_user_author_plot(author_mg))
end


function gen_stat_plots(date_func, out_dir, dfs = read_files("Data"))
    scandals = read_names("Data")

    for s in scandals
        if !isdir(out_dir * "/" * s)
            mkdir(out_dir * "/" * s)
        end
    end

    for i = 1:length(dfs)
        _plot_stats(dfs[i], date_func, out_dir * "/" * scandals[i])
    end
end


function gen_graph_plots(out_dir)
    dfs = read_files("Data")
    scandals = read_names("Data")

    for s in scandals
        if !isdir(out_dir * "/" * s)
            mkdir(out_dir * "/" * s)
        end
    end

    for i = 1:length(dfs)
        _plot_graphs(dfs[i], out_dir * "/" * scandals[i])
    end
end


function _plot_net_met(df, met_funcs, per, cum, dir)
    g = generate_reply_quote_graph(df)
    mg = add_meta_reply_quote_graph(df, g)
    for met_func in met_funcs
        save(dir * "/" * string(Symbol(met_func)) * ".png", plot_graph_metric(mg, met_func, per, Date.(ZonedDateTime.(df.created_at))[1], Date.(ZonedDateTime.(df.created_at))[size(df,1)], cum), px_per_unit = 3)
    end
end


function gen_net_plots(met_funcs, per, cum, out_dir)
    dfs = read_files("Data")
    scandals = read_names("Data")

    for s in scandals
        if !isdir(out_dir * "/" * s)
            mkdir(out_dir * "/" * s)
        end
    end

    for i = 1:length(dfs)
        _plot_net_met(dfs[i], met_funcs, per, cum, out_dir * "/" * scandals[i])
    end
end


function graph_metric(x)
    return mean(degree(x))
end

functions = [graph_metric]
#gen_net_plots(functions, Day(1), false, "Plots2")


dfs = [unique(df,[:tweet_id,:author_id]) for df in read_files("Data")]

get_date(x) = Date(x)

gen_stat_plots(get_date, "PlotsDate", dfs)
#gen_graph_plots("Plots")
