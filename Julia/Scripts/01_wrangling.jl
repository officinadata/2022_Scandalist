using Chain
using DataFrames
using DataFramesMeta
using Dates


include("../src/tweet_mining.jl")


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
average number of quotes and retweets per tweet

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Returns
-  `DataFrame`: Containing date function output, nquotes and nretweets
"""
function get_avg_interactions_by(twit_data::DataFrame, date_func::Function)
    interactions = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nquotes = mean(:quote_count), :nretweets = mean(:retweet_count))
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
average number of mentions per tweet

# Arguments
- `twit_data::DataFrame`: Twitter data
- `date_func::Function`: Date manipulation function

# Returns
-  `DataFrame`: Containing date function output and average number of mentions
"""
function get_avg_mentions_by(twit_data::DataFrame, date_func::Function)
    twit_data = add_mentions(twit_data)
    
    avg_mentions_by = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :avg_n_mentions = mean(:n_mentions))
    end

    rename!(avg_mentions_by, :temp => Symbol(date_func))

    return avg_mentions_by
end