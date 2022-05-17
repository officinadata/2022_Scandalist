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

dfs = read_files("Data");
scandals = read_names("Data");

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

    result_df = @chain df begin
        groupby([:author_id,:user_username,:true_type])
        combine(nrow => :n)
        @orderby(:user_username)
        unstack(:true_type,:n)
    end

    if "c(\"quoted\", \"replied_to\")" ∈ names(result_df)
        renaming_dict = Dict("user_username" => "username",
        "replied_to" => "n_replies",
        "retweeted" => "n_retweets",
        "NULL" => "n_authored",
        "quoted" => "n_quoted",
        "c(\"quoted\", \"replied_to\")" => "n_quoting_replies")

        out_df = @chain result_df begin
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

        out_df = @chain result_df begin
            rename(renaming_dict)
            @rtransform(:total = sum(skipmissing([:n_replies,:n_retweets,:n_authored,:n_quoted])))
            @orderby(-1 .* :total)
        end

    end

    return out_df[1:k,:]
end

for (df,scandal) in zip(dfs, scandals)
    mkpath("Tweets/k_top_active_users/" * scandal)
    CSV.write( "Tweets/k_top_active_users/" * scandal * "/top_20_users.csv"  , kmost_active_users(df, 20))
    @show scandal
end

## Peak and out of peak tweets

dfs_peak = readdir("CleanData"; join = true) .|> Arrow.Table .|> DataFrame

for df in dfs_peak
    df.date = Date.(df.date)
end

over_mad(x) = median(x) + mad(x)
get_date(x) = Date(x)

function peak_dates(df,thresh_fun = over_mad)
    uqu = get_column_summary(df, :author_id, get_date, length ∘ unique)
    which_date = @subset uqu :y .> over_mad(uqu.y)
    peak_dates = which_date.x

    return peak_dates
end

for (df,scandal) in zip(dfs_peak, scandals)

    peak = peak_dates(df)

    df_in = @subset df @byrow  Date(:date) ∈ peak
    for metric in metrics
        mkpath("Tweets/peak_k_top_tweets_by_metric/" * scandal)
        CSV.write( "Tweets/peak_k_top_tweets_by_metric/" * scandal * "/top_50_" * metric * ".csv"  , kmost_tweets(df_in, 50, metric))
    end

    df_out = @subset df @byrow  Date(:date) ∉ peak
    for metric in metrics
        mkpath("Tweets/outofpeak_k_top_tweets_by_metric/" * scandal)
        CSV.write( "Tweets/outofpeak_k_top_tweets_by_metric/" * scandal * "/top_20_" * metric * ".csv"  , kmost_tweets(df_out, 20, metric))
    end
end

for df in dfs
    df.date = Date.(df.date)
end

for (df,scandal) in zip(dfs, scandals)

    @show scandal

    peak = peak_dates(df)

    df_in = @subset df @byrow  :date ∈ peak
    mkpath("Tweets/peak_k_top_active_users/" * scandal)
    CSV.write( "Tweets/peak_k_top_active_users/" * scandal * "/top_20_users.csv"  , kmost_active_users(df_in, 20))

    df_out = @subset df @byrow  :date ∉ peak
    mkpath("Tweets/outofpeak_k_top_active_users/" * scandal)
    CSV.write( "Tweets/outofpeak_k_top_active_users/" * scandal * "/top_10_users.csv"  , kmost_active_users(df_out, 10))
    println("done\n")
end
