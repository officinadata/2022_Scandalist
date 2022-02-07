using Pkg

cd("Julia")
Pkg.activate(".")
Pkg.instantiate()

using Revise

include("../src/tweet_mining.jl")
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

Pepsi_data = "Data/pepsi.csv" |> read_tw_data

everyone_pepsi = @chain Pepsi_data begin
    @subset(week.(:date) .== 16)
    get_all_username()
end

set_aog_theme!()

sort(Pepsi_data,:quote_count, rev = true)
Pepsi_data

Pepsi_data = add_mentions(Pepsi_data)

# Wrangling functions

get_volume_by(Pepsi_data, week)

get_cumulative_volume_by(Pepsi_data, week)

get_interactions_by(Pepsi_data, dayofyear, mean)

get_interactions_by(Pepsi_data, dayofyear, sum)

add_mentions(Pepsi_data)

get_mentions_by(Pepsi_data, week, mean)

get_mentions_by(Pepsi_data, week, sum)

# Plotting functions

generate_volume_by_plot(Pepsi_data, dayofyear)

generate_cumulative_volume_by_plot(Pepsi_data, dayofyear)

generate_avg_mentions_by_plot(Pepsi_data, dayofyear)

generate_total_mentions_by_plot(Pepsi_data, dayofyear)

generate_avg_retweets_by_plot(Pepsi_data, dayofyear)

generate_total_retweets_by_plot(Pepsi_data, dayofyear)

generate_avg_quotes_by_plot(Pepsi_data, dayofyear)

generate_total_quotes_by_plot(Pepsi_data, dayofyear)


# ROUGH MENTIONS NETWORK TESTING

g = generate_mentions_graph(Pepsi_data)

savegraph("mention_graph.lgz", g)
g = loadgraph("mention_graph.lgz")

cen_df = DataFrame(user_name=total_nodes, centrality=eigenvector_centrality(g))
print(first(sort(cen_df, :centrality, rev=true), 20))

c = counter(filter(!=("NA"), Pepsi_data.sourcetweet_author_id))
c_df = DataFrame(source_id=collect(keys(c)), count=collect(values(c)))
print(first(sort(c_df, :count, rev=true), 20))

# ROUGH REPLY / QUOTES NETWORK TESTING

g = generate_retweet_quote_graph(Pepsi_data)

savegraph("reply_quote_graph.lgz", g)
g = loadgraph("reply_quote_graph.lgz")

mg = add_meta_retweet_quote_graph(Pepsi_data, g)

slice_mg = take_slice(mg, Date(2017,4,3), dayofyear)