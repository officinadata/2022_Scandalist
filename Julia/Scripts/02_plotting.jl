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
using GraphPlot


set_aog_theme!()


function _plot_stats(df, date_func, dir)
    save(dir * "/graph1.png", wrap_in_makie(generate_unique_users(df, date_func), ["Day of year", "N unique users", "Daily unique users"]), px_per_unit = 3)
    save(dir * "/graph2.png", graph2(df, date_func), px_per_unit = 3)
    save(dir * "/graph3.png", wrap_in_makie(generate_unique_user_rate(df, dayofyear), ["Day of year", "N unique users per min", "Daily unique user rate"], true), px_per_unit = 3)
    save(dir * "/graph4.png", graph4(df, date_func), px_per_unit = 3)
    save(dir * "/graph5.png", graph5(df, date_func), px_per_unit = 3)
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