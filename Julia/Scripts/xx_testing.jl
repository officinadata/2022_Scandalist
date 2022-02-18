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

Redcross_data = "Data/RedCrossAU.csv" |> read_tw_data

mit_data = "Data/MIT2.csv" |> read_tw_data
mit_data.created_at = Date.(ZonedDateTime.(mit_data.created_at))
sort(mit_data, order(:created_at))

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

g = generate_reply_quote_graph(Redcross_data)

savegraph("reply_quote_graph.lgz", g)
g = loadgraph("reply_quote_graph.lgz")

mg = add_meta_reply_quote_graph(Redcross_data, g)

slice_mg = take_slice(mg, Date(2020,2,3), Date(2020,2,10))

function graph_metric(x)
    return mean(eigenvector_centrality(x))
end

plot_graph_metric(mg, graph_metric, Week(1), Date.(ZonedDateTime.(Redcross_data.created_at))[1], Date.(ZonedDateTime.(Redcross_data.created_at))[size(Redcross_data,1)])

#User plot 

user_info = groupby(select(Redcross_data, :user_username, :retweet_count, :like_count, :quote_count, :reply_count), :user_username)
user_info = combine(user_info, nrow => :ntweets, :retweet_count => sum => :nretweets, :like_count => sum => :nlikes, :quote_count => sum => :nquotes, :reply_count => sum => :nreplies)

user_info = sort(user_info, order(:nretweets, rev=false))

y = filter(x -> x > 100, user_info.nretweets)
x = collect(1:1:size(y,1))
users = data((; x, y)) *
visual(Lines) *
mapping(:x, :y)

draw(users)