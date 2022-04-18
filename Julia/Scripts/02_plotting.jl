using Pkg

cd("Julia")
Pkg.activate(".")
Pkg.instantiate()

using Revise

include("01_wrangling.jl")
include("../src/tweet_helpers.jl")
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


set_aog_theme!()


df = read_files("Data")
generate_unique_users(df[1], dayofyear) #Graph 1
generate_quote_volume(df[1], dayofyear) #Graph 2
generate_retweet_volume(df[1], dayofyear) #Graph 2
generate_reply_volume(df[1], dayofyear) #Graph 2
generate_unique_user_rate(df[1], dayofyear) #Graph 3
generate_quote_rate(df[1], dayofyear) #Graph 4
generate_retweet_rate(df[1], dayofyear) #Graph 4
generate_reply_rate(df[1], dayofyear) #Graph 4


function _plot_stats(df, date_func, dir)
    save(dir * "/volume.png", generate_volume_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/cumulative_volume.png", generate_cumulative_volume_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/avg_mentions.png", generate_avg_mentions_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/total_mentions.png", generate_total_mentions_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/avg_retweets.png", generate_avg_retweets_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/total_retweets.png", generate_total_retweets_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/avg_quotes.png", generate_avg_quotes_by_plot(df, date_func), px_per_unit = 3)
    save(dir * "/total_quotes.png", generate_total_quotes_by_plot(df, date_func), px_per_unit = 3)
end


function gen_stat_plots(date_func, out_dir)
    dfs = read_files("Data")
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
gen_net_plots(functions, Day(1), false, "Plots")
gen_stat_plots(dayofyear, "Plots")