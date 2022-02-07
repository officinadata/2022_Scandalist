using Chain
using DataFrames
using DataFramesMeta
using Dates


"""
Takes a DataFrame of Twitter data and a date manipulation function to group on and calculates volume

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Returns
-  `DataFrame`: Containing date function output and n volume 
"""
function get_volume_by(twit_data::DataFrame, date_func::Function)
    volume_by = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        combine(groupby(_, :temp), nrow)
    end
      
    rename!(volume_by, :nrow => "n")
    rename!(volume_by, :temp => Symbol(date_func))

    return volume_by
end


"""
Takes a DataFrame of Twitter data and a date manipulation function to group on and calculates cumulative volume

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Returns
-  `DataFrame`: Containing date function output and n cumulative volume
"""
function get_cumulative_volume_by(twit_data::DataFrame, date_func::Function)
    volume_by = get_volume_by(twit_data, date_func)
    volume_by = @transform(volume_by, :n = cumsum(:n))

    return volume_by
end


"""
Takes a DataFrame of Twitter data and a date manipulation function to group on and calculates
number of quotes and retweets

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function
- `manip_func::Function`: Column manipulation function (default mean)

# Returns
-  `DataFrame`: Containing date function output, nquotes and nretweets
"""
function get_interactions_by(twit_data::DataFrame, date_func::Function, manip_func::Function = mean)
    interactions = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nquotes = manip_func(:quote_count), :nretweets = manip_func(:retweet_count))
    end

    rename!(interactions, :temp => Symbol(date_func))

    return interactions
end


"""
Takes a DataFrame of Twitter data and extracts mention data

# Arguments
- `twit_data::DataFrame`: Twitter data

# Returns
-  `DataFrame`: Containing original twitter data plus mentions and Nmentions columns
"""
function add_mentions(twit_data::DataFrame)
    twit_data.mentions = get_mentions.(lowercase.(twit_data.text))
    twit_data.n_mentions = length.(twit_data.mentions)
    
    return twit_data
end



"""
Takes a DataFrame of Twitter data and a date manipulation function to group on and calculates
number of mentions

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function
- `manip_func::Function`: Column manipulation function (default mean)

# Returns
-  `DataFrame`: Containing date function output and number of mentions
"""
function get_mentions_by(twit_data::DataFrame, date_func::Function, manip_func::Function = mean)
    twit_data = add_mentions(twit_data)
    
    mentions_by = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nmentions = manip_func(:n_mentions))
    end

    rename!(mentions_by, :temp => Symbol(date_func))

    return mentions_by
end


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
    mentions = data(get_mentions_by(twit_data, date_func, mean)) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nmentions => "Average number of mentions per tweet")

    draw(mentions)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the total number of mentions grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of total mentions by date function grouping
"""
function generate_total_mentions_by_plot(twit_data::DataFrame, date_func::Function)
    mentions = data(get_mentions_by(twit_data, date_func, sum)) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nmentions => "Total number of mentions")

    draw(mentions)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the average number of retweets per tweet grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of average retweets by date function grouping
"""
function generate_avg_retweets_by_plot(twit_data::DataFrame, date_func::Function)
    df = select(get_interactions_by(twit_data, date_func, mean), Not(:nquotes))
    mentions = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nretweets => "Average number of retweets per tweet")

    draw(mentions)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the total number of grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of total retweets by date function grouping
"""
function generate_total_retweets_by_plot(twit_data::DataFrame, date_func::Function)
    df = select(get_interactions_by(twit_data, date_func, sum), Not(:nquotes))
    mentions = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nretweets => "Total number of retweets")

    draw(mentions)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the average number of quotes per tweet grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of average quote tweets by date function grouping
"""
function generate_avg_quotes_by_plot(twit_data::DataFrame, date_func::Function)
    df = select(get_interactions_by(twit_data, date_func, mean), Not(:nretweets))
    mentions = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nquotes => "Average number of quotes per tweet")

    draw(mentions)
end


"""
Takes a DataFrame of Twitter data and date manipulation function and produces a plot
of the total number of quotes grouped by the date manipulation function

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Output
A plot of total quote tweets by date function grouping
"""
function generate_total_quotes_by_plot(twit_data::DataFrame, date_func::Function)
    df = select(get_interactions_by(twit_data, date_func, sum), Not(:nretweets))
    mentions = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nquotes => "Total number of quotes")

    draw(mentions)
end