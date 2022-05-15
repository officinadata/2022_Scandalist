using Pkg

cd("2022/2022_Scandalist/Julia")
Pkg.activate(".")
Pkg.instantiate()

using Revise

include("01_wrangling.jl")
include("../src/tweet_helpers_refac.jl")
include("../src/tweet_graphing.jl")
include("../src/tweet_mining.jl")

using Arrow
using Chain
using CSV
using DataFrames
using DataFramesMeta
using Dates
using SparseArrays
using DataStructures

dfs = read_files("Data")
scandals = read_names("Data")

original_dfs = [@subset(df,:true_type .== "NULL") for df in dfs]

original_dfs = [unique(original_df,[:tweet_id,:user_username]) for original_df in original_dfs]

function compute_ratios(df)
    df = @chain df begin
        @subset(:like_count .> 0, :retweet_count .> 0)
        @transform(:ratio_reply_like = :reply_count .- :like_count, :ratio_quote_retweet = :quote_count .- :retweet_count)
    end
end

original_df_ratios = compute_ratios.(original_dfs)

for (df,filename) in zip(original_df_ratios, scandals)
    Arrow.write("CleanData/" * filename * ".arrow", df, ntasks = 12 )
end

## K most liked/replied/... tweets


function kmost_tweets(df::DataFrame,k::I,what) where I<:Integer
    result_df = @chain df begin
        @orderby(-1 .* $what)
        @select(:user_username,:text,:created_at,:user_url,:user_name,:user_location,:user_verified,
        :retweet_count,:like_count,:quote_count,:reply_count, :ratio_reply_like, :ratio_quote_retweet)
    end
    return result_df[1:k,:]
end

metrics = String.([:retweet_count,:like_count,:quote_count,:reply_count, :ratio_reply_like, :ratio_quote_retweet])

for (df,scandal) in zip(original_df_ratios, scandals)
    for metric in metrics
        mkpath("Tweets/k_top_tweets_by_metric/" * scandal)
        CSV.write( "Tweets/k_top_tweets_by_metric/" * scandal * "/top_200_" * metric * ".csv"  , kmost_tweets(df, 200, metric))
    end
end

## K most active users

function kmost_active_users(df::DataFrame,k::I) where I<:Integer

    if "c(\"quoted\", \"replied_to\")" ∈ names(df)
        renaming_dict = Dict("user_username" => "username",
        "replied_to" => "n_replies",
        "retweeted" => "n_retweets",
        "NULL" => "n_authored",
        "quoted" => "n_quoted",
        "c(\"quoted\", \"replied_to\")" => "n_quoting_replies")

        result_df = @chain df begin
            groupby([:author_id,:user_username,:true_type])
            combine(nrow => :n)
            @orderby(:user_username)
            unstack(:true_type,:n)
            rename(renaming_dict)
            @rtransform(:total = sum(skipmissing([:n_replies,:n_retweets,:n_authored,:n_quoted,:n_quoting_replies])))
            @orderby(-1 .* :total)
        end

    else
        renaming_dict = Dict("user_username" => "username",
        "replied_to" => "n_replies",
        "retweeted" => "n_retweets",
        "NULL" => "n_authored",
        "quoted" => "n_quoted")

        result_df = @chain df begin
            groupby([:author_id,:user_username,:true_type])
            combine(nrow => :n)
            @orderby(:user_username)
            unstack(:true_type,:n)
            rename(renaming_dict)
            @rtransform(:total = sum(skipmissing([:n_replies,:n_retweets,:n_authored,:n_quoted])))
            @orderby(-1 .* :total)
        end

    end

    return result_df[1:k,:]
end

for (df,scandal) in zip(dfs, scandals)
    mkpath("Tweets/k_top_active_users/" * scandal)
    CSV.write( "Tweets/k_top_active_users/" * scandal * "/top_20_users.csv"  , kmost_active_users(df, 20))
    @show scandal
end
