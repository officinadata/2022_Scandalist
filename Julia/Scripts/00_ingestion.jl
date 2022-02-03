using Pkg

cd("Julia")
Pkg.activate(".")
Pkg.instantiate()

using Revise

include("../src/tweet_mining.jl")
include("01_wrangling.jl")
include("02_plotting.jl")

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

pepsi_with_mentions = dropmissing(filter(:mentions => !=([]), select(add_mentions(Pepsi_data), :user_username, :mentions)))
total_nodes = unique(vcat(pepsi_with_mentions[!, :user_username], reduce(vcat, pepsi_with_mentions[!, :mentions])))
m = Matrix(pepsi_with_mentions)

am = spzeros(Bool, length(total_nodes), length(total_nodes))

for i = 1:size(pepsi_with_mentions, 1)
    index1 = findfirst(==(m[i,1]), total_nodes)
    for j = 1:size(m[i,2],1)
        am[index1, findfirst(==(m[i,2][j]), total_nodes)] = true
    end
end

g = SimpleDiGraph(am)
savegraph("mention_graph.lgz", g)
g = loadgraph("mention_graph.lgz")

cen_df = DataFrame(user_name=total_nodes, centrality=eigenvector_centrality(g))
print(first(sort(cen_df, :centrality, rev=true), 20))

c = counter(filter(!=("NA"), Pepsi_data.sourcetweet_author_id))
c_df = DataFrame(source_id=collect(keys(c)), count=collect(values(c)))
print(first(sort(c_df, :count, rev=true), 20))

# ROUGH REPLY / QUOTES NETWORK TESTING

pepsi_short = dropmissing(select(Pepsi_data, :created_at, :tweet_id, :author_id, :sourcetweet_id))
total_nodes = unique(string.(vcat(pepsi_short[!, :author_id], pepsi_short[!, :tweet_id], pepsi_short[!, :sourcetweet_id])))
filter!(x -> x != "NA", total_nodes)
m = Matrix(pepsi_short)

am = spzeros(Bool, length(total_nodes), length(total_nodes))

for i = 1:size(pepsi_short, 1)
    if m[i,4] != "NA"
        index1 = findfirst(==(string(m[i,3])), total_nodes)
        am[index1, findfirst(==(string(m[i,4])), total_nodes)] = true
    end
end

g = SimpleDiGraph(am)
mg = MetaGraph(g)

for i = 1:length(total_nodes)
    set_prop!(mg, i, :id, total_nodes[i])
end

set_indexing_prop!(mg, :id)

for i = 1:length(unique(pepsi_short[!, :author_id]))
    set_prop!(mg, i, :type, "accountId")
end

for i = length(unique(pepsi_short[!, :author_id]))+1:length(total_nodes)
    set_prop!(mg, i, :type, "tweetId")
end

for i = 1:size(pepsi_short, 1)
    if pepsi_short[i,4] != "NA"
        str = mg[string(pepsi_short[i,3]), :id]
        dst = mg[string(pepsi_short[i,4]), :id]
        if haskey(props(mg, str, dst), :datetimes)
            #println(str, " ", dst)
            set_prop!(mg, str, dst, :datetimes, push!(get_prop(mg, str, dst, :datetimes), ZonedDateTime(pepsi_short[i,1])))
        else
            set_prop!(mg, str, dst, :datetimes, [ZonedDateTime(pepsi_short[i,1])])
        end
        #println(get_prop(mg, str, dst, :datetimes))
        #println(str, " ", dst)
    end
end

savegraph("reply_quote_graph.lgz", g)
g = loadgraph("reply_quote_graph.lgz")
