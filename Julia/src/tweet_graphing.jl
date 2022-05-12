using DataFrames
using DataFramesMeta
using Graphs
using SparseArrays
using MetaGraphs
using GraphPlot
using Colors



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
based on the field true_id which represents replies and quote tweets 

# Arguments
- `twit_data::DataFrame`: Twitter data

# Returns
-  `SimpleDiGraph`: Directed bipartite network from user to tweet based on replies and quotes
"""
function generate_reply_quote_graph(twit_df::DataFrame)::SimpleDiGraph
    df_short = dropmissing(filter(:true_type => !in(["retweeted", "NULL", "c(\"quoted\", \"replied_to\")"]), select(twit_df, :created_at, :tweet_id, :author_id, :true_type, :true_id, :text, :reply_count, :like_count, :retweet_count, :quote_count)))
    df_extra = dropmissing(filter(:true_type => ==("c(\"quoted\", \"replied_to\")"), select(twit_df, :created_at, :tweet_id, :author_id, :true_type, :true_id, :text, :reply_count, :like_count, :retweet_count, :quote_count)))
    df_extra.true_type = collect.(filter.(x -> length(x) > 4, split.(df_extra.true_type, "\"")))
    df_extra.true_id = collect(filter.(x -> length(x) > 4, split.(df_extra.true_id, "\"")))
    df_part1 = deepcopy(df_extra)
    splice!.(df_part1.true_type, 2)
    splice!.(df_part1.true_id, 2)
    df_part2 = deepcopy(df_extra)
    splice!.(df_part2.true_type, 1)
    splice!.(df_part2.true_id, 1)
    df_joined = vcat(df_part1, df_part2)
    df_joined.true_type = String.(only.(df_joined.true_type))
    df_joined.true_id = String.(only.(df_joined.true_id))
    df_short = vcat(df_short, df_joined)

    total_nodes = unique(string.(vcat(df_short[!, :author_id], df_short[!, :tweet_id], df_short[!, :true_id])))
    
    m = Matrix(df_short)
    am = spzeros(Bool, length(total_nodes), length(total_nodes))
    
    for i = 1:size(df_short, 1)
        index1 = findfirst(==(string(m[i,3])), total_nodes)
        am[index1, findfirst(==(string(m[i,5])), total_nodes)] = true
    end

    g = SimpleDiGraph(am)

    return g
end


"""
Takes a DataFrame of Twitter data and a bipartite network from users to tweets based on replies 
and quotes and adds vertex and edge properties

# Arguments
- `twit_data::DataFrame`: Twitter data
- `g::SimpleDiGraph`: Directed bipartite network from user to tweet based on replies and quotes

# Returns
-  `MetaDiGraph`: Directed bipartite network from user to tweet based on replies and quotes with meta info
"""
function add_meta_reply_quote_graph(twit_df::DataFrame, g::SimpleDiGraph)::MetaDiGraph
    df_short = dropmissing(filter(:true_type => !in(["retweeted", "NULL", "c(\"quoted\", \"replied_to\")"]), select(twit_df, :created_at, :tweet_id, :author_id, :true_type, :true_id, :text, :reply_count, :like_count, :retweet_count, :quote_count)))
    df_extra = dropmissing(filter(:true_type => ==("c(\"quoted\", \"replied_to\")"), select(twit_df, :created_at, :tweet_id, :author_id, :true_type, :true_id, :text, :reply_count, :like_count, :retweet_count, :quote_count)))
    df_extra.true_type = collect.(filter.(x -> length(x) > 4, split.(df_extra.true_type, "\"")))
    df_extra.true_id = collect(filter.(x -> length(x) > 4, split.(df_extra.true_id, "\"")))
    df_part1 = deepcopy(df_extra)
    splice!.(df_part1.true_type, 2)
    splice!.(df_part1.true_id, 2)
    df_part2 = deepcopy(df_extra)
    splice!.(df_part2.true_type, 1)
    splice!.(df_part2.true_id, 1)
    df_joined = vcat(df_part1, df_part2)
    df_joined.true_type = String.(only.(df_joined.true_type))
    df_joined.true_id = String.(only.(df_joined.true_id))
    df_short = vcat(df_short, df_joined)

    total_nodes = unique(string.(vcat(df_short[!, :author_id], df_short[!, :tweet_id], df_short[!, :true_id])))

    mg = MetaDiGraph(g)

    for i = 1:length(total_nodes)
        set_prop!(mg, i, :id, total_nodes[i])
    end
    
    set_indexing_prop!(mg, :id)
    
    for i = 1:length(unique(df_short[!, :author_id]))
        set_prop!(mg, i, :type, "accountId")
    end
    
    for i = length(unique(df_short[!, :author_id]))+1:length(total_nodes)
        set_prop!(mg, i, :type, "tweetId")
        j = findfirst(==(total_nodes[i]), df_short.tweet_id)
        if (!isnothing(j))
            set_prop!(mg, i, :replies, df_short.reply_count[j])
            set_prop!(mg, i, :likes, df_short.like_count[j])
            set_prop!(mg, i, :retweets, df_short.retweet_count[j])
            set_prop!(mg, i, :quotes, df_short.quote_count[j])
            set_prop!(mg, i, :text, df_short.text[j])
        end
    end
    
    for i = 1:size(df_short, 1)
        str = mg[string(df_short[i,3]), :id]
        dst = mg[string(df_short[i,5]), :id]
        if haskey(props(mg, str, dst), :datetimes)
            set_prop!(mg, str, dst, :datetimes, push!(get_prop(mg, str, dst, :datetimes), df_short[i,1]))
        else
            set_prop!(mg, str, dst, :datetimes, [df_short[i,1]])
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
- `sd::Date`: Start date
- `ed::Date`: End date

# Returns
-  `MetaGraph`: Sliced directed bipartite network from user to tweet based on retweets and quotes with meta info
"""
function take_slice(mg::MetaDiGraph,sd::Date, ed::Date)::MetaDiGraph
    function slice_filter(g, e, sd, ed)
        dates = Date.(ZonedDateTime.(get_prop(g, e, :datetimes)))
        for date in dates
            if date >= sd && date <= ed
                return true
            end
        end
        return false
    end

    edges = filter_edges(mg, (g, e) -> slice_filter(g, e, sd, ed))
    slice_mg = mg[edges]   
    return slice_mg
end


"""
Takes a MetaGraph bipartite network and plots a metric function on slices of the network

# Arguments
- `mg::MetaDiGraph`: Directed MetaGraph using edges with datetime property
- `met::Function`: Function to apply to network
- `per::DatePeriod`: Time span for each slice
- `sd::Date`: Date to start slicing
- `ed::Date`: Date to stop slicing
- `cum::Bool`: Use cumulative slicing default = yes

"""
function plot_graph_metric(mg, met, per, sd, ed, cum = true)
    dates = sd:per:ed
    values = []
    last_date = sd
    for date in dates
        if cum
            sliced_mg = take_slice(mg, sd, date)
        else
            sliced_mg = take_slice(mg, last_date, date)
            last_date = date
        end
        try
            append!(values, met(sliced_mg))
        catch
            println("ERROR: Metric function failed on slice")
            append!(values, NaN)
        end
    end

    df_data = DataFrame(date = dates, n = values)

    plot = data(df_data) *
    visual(Lines) *
    mapping(:date => "Date", :n => Symbol(met))

    return draw(plot)        
end


"""
Takes a DataFrame of Twitter data and returns a bipartite network of tweet authors to to users who 
retweeted or quoted their tweets based on the field author_id and sourcetweet_author_id which 
represents replies and quote tweets 

# Arguments
- `twit_data::DataFrame`: Twitter data

# Returns
-  `SimpleDiGraph`: Directed bipartite network from user to original tweet autthor based on replies and quotes
"""
function generate_author_retweet_source_graph(twit_df::DataFrame)#::SimpleDiGraph
    df_short = dropmissing(filter(:sourcetweet_type => in(["retweeted", "c(\"quoted\", \"replied_to\")","quoted"]), select(twit_df, :author_id, :sourcetweet_author_id, :sourcetweet_type, :reply_count, :like_count, :retweet_count, :quote_count)))
    users = df_short[:,:author_id]
    og_authors = parse.(Int64, df_short[:, :sourcetweet_author_id])
    
    EdgeListFromIterators(c1, c2) = [Graphs.SimpleEdge(c1[i] => c2[i]) for i in 1:length(c1)]

    AssignUniqueNode(iter) = Dict([iter[i] => i  for i in 1:length(iter)])

    users_dict = AssignUniqueNode(string.("u",unique(users)))
    og_authors_dict = AssignUniqueNode(string.("a",unique(og_authors)))

    users_length = length(users_dict)
    og_authors_dict = Dict([key => (og_authors_dict[key]+users_length) for key in keys(og_authors_dict)])

    mg = MetaGraph(length(og_authors_dict)+users_length)
    set_indexing_prop!(mg, :id)
    for (k, v) in users_dict
        set_prop!(mg, v, :id, k)
    end

    for (k, v) in og_authors_dict
        set_prop!(mg, v, :id, k)
    end
    
    
    users_indeces = [users_dict[string.("u",key)] for key in users]
    og_authors_indeces = [og_authors_dict[string.("a",key)] for key in og_authors]

    e = EdgeListFromIterators(users_indeces, og_authors_indeces)
    for ei in e
        add_edge!(mg, ei)
    end
    return mg, users_length
end

function generate_small_user_author_plot(g::AbstractGraph, mindeg=4)
    go5 = g[[i for i in 1: length(degree(g)) if degree(g)[i]>=mindeg]]
    go2 = go5[[i for i in 1: length(degree(go5)) if degree(go5)[i]>=1]]

    nodesize = degree(g)[[i for i in 1: length(degree(g)) if degree(g)[i]>=mindeg]]
    nodesize = nodesize[[i for i in 1: length(degree(go5)) if degree(go5)[i]>=1]]

    nodelabels = [get_prop(go2, i, :id) for i in vertices(go2)]
    auc=[]
    for lbl in nodelabels
        if string(lbl[1]) == "a"
            push!(auc, colorant"orange")
        else
            push!(auc, colorant"blue")
        end
    end
    
    return gplot(go2, nodesize=nodesize, nodelabel=nodelabels, nodefillc=auc)
end

function generate_most_connected_user_author_plot(g::AbstractGraph, topnodes=20)
    sort_func(v)=-degree(g, v)

    topn = sort(vertices(g), by=sort_func)[1:topnodes]

 
    gtn = g[topn]
    nodesize = [degree(g,v) for v in vertices(g)][[n for n in topn]]

    nodelabels = [get_prop(gtn, i, :id) for i in vertices(gtn)]
    auc=[]
    for lbl in nodelabels
        if string(lbl[1]) == "a"
            push!(auc, colorant"orange")
        else
            push!(auc, colorant"blue")
        end
    end
    
    return gplot(gtn, nodesize=nodesize, nodelabel=nodelabels, nodefillc=auc)
end

function generate_unipartite_projection(g::AbstractGraph, userL)
    m = adjacency_matrix(g)
    true_m = m[userL+1:length(m[:,1]), 1:userL]
    author_mg = MetaGraph(true_m*true_m')
    set_indexing_prop!(author_mg, :id)

    for i in vertices(author_mg)
        id = get_prop(g, i+userL, :id)
        set_prop!(author_mg, i, :id, id)
    end
    return author_mg
end