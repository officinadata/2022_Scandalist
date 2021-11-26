using Chain
using DataFrames
using DataFramesMeta
using Dates
using CairoMakie, AlgebraOfGraphics


include("01_wrangling.jl")


"""
Takes a DataFrame of Twitter data and plots the 'ratio' or number retweets against the number of quotes

# Arguments
- `twit_data::DataFrame`: Twitter data

# Output
A plot of retweets against quotes
"""
function generate_ratio_plot(twit_data::DataFrame)
    ratio_df = data(twit_data) *
        mapping(:quote_count => "N Quotes",:retweet_count => "N Retweets")
    draw(ratio_df)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the volume of tweets grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of tweet volume by date function grouping
"""
function generate_volume_by_plot(twit_data::DataFrame, date_func::Function)
    volume = data(get_volume_by(twit_data, date_func)) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :n => "Number of posts")

    draw(volume)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the cumulative volume of tweets grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of cumulative tweet volume by date function grouping
"""
function generate_cumulative_volume_by_plot(twit_data::DataFrame, date_func::Function)
    cumulative_volume = data(get_cumulative_volume_by(twit_data, date_func)) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :n => "Cumulative number of posts")

    draw(cumulative_volume)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the average number of mentions per tweet grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of average mentions by date function grouping
"""
function generate_avg_mentions_by_plot(twit_data::DataFrame, date_func::Function)
    mentions = data(get_avg_mentions_by(twit_data, date_func)) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :avg_n_mentions => "Average number of mentions per tweet")

    draw(mentions)
end