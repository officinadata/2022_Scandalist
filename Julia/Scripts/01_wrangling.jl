using Pkg

using Revise

include("00_ingestion.jl")
include("../src/tweet_graphing.jl")

using Chain
using DataFrames
using DataFramesMeta
using Dates


function get_user_data()
    dfs = read_files("Data")
    out = []
    for df in dfs
        push!(out, _load_user_data(df))
    end
    return out
end


function _load_user_data(df)
    user_info = groupby(select(df, :user_username, :retweet_count, :like_count, :quote_count, :reply_count), :user_username)
    user_info = combine(user_info, nrow => :ntweets, :retweet_count => sum => :nretweets, :like_count => sum => :nlikes, :quote_count => sum => :nquotes, :reply_count => sum => :nreplies)
    return user_info
end
    
