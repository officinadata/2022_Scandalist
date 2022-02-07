using DataFrames
using DataFramesMeta
using Graphs
using SparseArrays
using MetaGraphs


"""
Takes a DataFrame of Twitter data and returns a network of mentions between users 

# Arguments
- `twit_data::DataFrame`: Twitter data

# Returns
-  `SimpleDiGraph`: Directed network from user to user based on mentions
"""
function generate_mentions_graph(twit_df::DataFrame)::SimpleDiGraph
    df_with_mentions = dropmissing(filter(:mentions => !=([]), select(add_mentions(twit_df), :user_username, :mentions)))
    total_nodes = unique(vcat(df_with_mentions[!, :user_username], reduce(vcat, df_with_mentions[!, :mentions])))
    m = Matrix(df_with_mentions)

    am = spzeros(Bool, length(total_nodes), length(total_nodes))

    for i = 1:size(df_with_mentions, 1)
        index1 = findfirst(==(m[i,1]), total_nodes)
        for j = 1:size(m[i,2],1)
            am[index1, findfirst(==(m[i,2][j]), total_nodes)] = true
        end
    end

    g = SimpleDiGraph(am)
    
    return g
end


"""
Takes a DataFrame of Twitter data and returns a bipartite network of users to tweets
based on the field sourcetweet_id which represents retweets and quote tweets 

# Arguments
- `twit_data::DataFrame`: Twitter data

# Returns
-  `SimpleDiGraph`: Directed bipartite network from user to tweet based on retweets and quotes
"""
function generate_retweet_quote_graph(twit_df::DataFrame)::SimpleDiGraph
    df_short = dropmissing(select(twit_df, :created_at, :tweet_id, :author_id, :sourcetweet_id))
    total_nodes = unique(string.(vcat(df_short[!, :author_id], df_short[!, :tweet_id], df_short[!, :sourcetweet_id])))
    filter!(x -> x != "NA", total_nodes)
    
    m = Matrix(df_short)
    am = spzeros(Bool, length(total_nodes), length(total_nodes))

    for i = 1:size(df_short, 1)
        if m[i,4] != "NA"
            index1 = findfirst(==(string(m[i,3])), total_nodes)
            am[index1, findfirst(==(string(m[i,4])), total_nodes)] = true
        end
    end

    g = SimpleDiGraph(am)

    return g
end


"""
Takes a DataFrame of Twitter data and a bipartite network from users to tweets based on retweets 
and quotes and adds vertex and edge properties

# Arguments
- `twit_data::DataFrame`: Twitter data
- `g::SimpleDiGraph`: Directed bipartite network from user to tweet based on retweets and quotes

# Returns
-  `MetaGraph`: Directed bipartite network from user to tweet based on retweets and quotes with meta info
"""
function add_meta_retweet_quote_graph(twit_df::DataFrame, g::SimpleDiGraph)::MetaGraph
    df_short = dropmissing(select(twit_df, :created_at, :tweet_id, :author_id, :sourcetweet_id))

    mg = MetaGraph(g)

    for i = 1:length(total_nodes)
        set_prop!(mg, i, :id, total_nodes[i])
    end
    
    set_indexing_prop!(mg, :id)
    
    for i = 1:length(unique(df_short[!, :author_id]))
        set_prop!(mg, i, :type, "accountId")
    end
    
    for i = length(unique(df_short[!, :author_id]))+1:length(total_nodes)
        set_prop!(mg, i, :type, "tweetId")
    end
    
    for i = 1:size(df_short, 1)
        if df_short[i,4] != "NA"
            str = mg[string(df_short[i,3]), :id]
            dst = mg[string(df_short[i,4]), :id]
            if haskey(props(mg, str, dst), :datetimes)
                set_prop!(mg, str, dst, :datetimes, push!(get_prop(mg, str, dst, :datetimes), ZonedDateTime(df_short[i,1])))
            else
                set_prop!(mg, str, dst, :datetimes, [ZonedDateTime(df_short[i,1])])
            end
        end
    end

    return mg
end


"""
Takes a MetaGraph bipartite network from users to tweets based on retweets 
and quotes with a :datetimes edge property and returns a new MetaGraph with 
data from chosen time slice

# Arguments
- `mg::MetaGraph`: Directed bipartite network from user to tweet based on retweets and quotes with :datetimes edge
property
- `d::Date`: Date for slicing
- `date_func::Function`: Optional date manipulation function slice with e.g week, month

# Returns
-  `MetaGraph`: Sliced directed bipartite network from user to tweet based on retweets and quotes with meta info
"""
function take_slice(mg::MetaGraph, d::Date, date_func::Function = dayofyear)::MetaGraph
    edges = filter_edges(mg, (g, e) -> (date_func(d) in date_func.(Date.(get_prop(g, e, :datetimes)))))
    slice_mg = mg[edges]   
    return slice_mg
end