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
    return draw(ratio_df)
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

    return draw(volume)
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

    return draw(cumulative_volume)
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

    return draw(mentions)
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

    return draw(mentions)
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

    return draw(mentions)
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

    return draw(mentions)
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

    return draw(mentions)
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

    return draw(mentions)
end


function get_unique_users(twit_data::DataFrame, date_func::Function)
    users = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nusers = length(unique(:author_id)))
    end

    rename!(users, :temp => Symbol(date_func))

    return users
end


function generate_unique_users(twit_data::DataFrame, date_func::Function)
    df = get_unique_users(twit_data, date_func)
    users = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nusers => "N unique users")

    return draw(users)
end


function get_quote_volume(twit_data::DataFrame, date_func::Function)
    quotes = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nquotes = count(i -> (i=="quoted" || "quoted" in split(strip(i,['[', ']']),", ")), :sourcetweet_type))
    end

    rename!(quotes, :temp => Symbol(date_func))

    return quotes
end


function generate_quote_volume(twit_data::DataFrame, date_func::Function)
    df = get_quote_volume(twit_data, date_func)
    quotes = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nquotes => "N quote tweets")

    return draw(quotes)
end


function get_retweet_volume(twit_data::DataFrame, date_func::Function)
    df = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nretweets = count(i -> (i=="retweeted" || "retweeted" in split(strip(i,['[', ']']),", ")), :sourcetweet_type))
    end

    rename!(df, :temp => Symbol(date_func))

    return df
end


function generate_retweet_volume(twit_data::DataFrame, date_func::Function)
    df = get_retweet_volume(twit_data, date_func)
    quotes = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nretweets => "N quote tweets")

    return draw(quotes)
end

function get_reply_volume(twit_data::DataFrame, date_func::Function)
    df = @chain twit_data begin
        @transform(:temp = date_func.(:date))
        @by(:temp, :nreplies = count(i -> (i!="NA"), :in_reply_to_user_id))
    end

    rename!(df, :temp => Symbol(date_func))

    return df
end


function generate_reply_volume(twit_data::DataFrame, date_func::Function)
    df = get_reply_volume(twit_data, date_func)
    quotes = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nreplies => "N reply tweets")

    return draw(quotes)
end


function get_unique_user_rate(twit_data::DataFrame, date_func::Function)
    df = @chain twit_data begin
        @transform(:temp1 = minute.(:date), :temp2 = hour.(:date), :temp3 = dayofyear.(:date))
        @by([:temp1, :temp2, :temp3], :nunique = length(unique(:author_id)))
        @by(:temp3, :nuniqueAvg = mean(:nunique))
    end

    rename!(df, :temp3 => Symbol(date_func))

    return df
end


function generate_unique_user_rate(twit_data::DataFrame, date_func::Function)
    df = get_unique_user_rate(twit_data, date_func)
    quotes = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nuniqueAvg => "Unique user tweet rate")

    return draw(quotes)
end


function get_quote_rate(twit_data::DataFrame, date_func::Function)
    is_quote(type) = type == "quoted" || "quoted" in split(strip(type,['[', ']']),", ")
    twit_data = filter(:sourcetweet_type => is_quote, twit_data)
    df = @chain twit_data begin
        @transform(:temp1 = minute.(:date), :temp2 = hour.(:date), :temp3 = dayofyear.(:date))
        @by([:temp1, :temp2, :temp3], :nunique = length(unique(:author_id)))
        @by(:temp3, :nuniqueAvg = mean(:nunique))
    end

    rename!(df, :temp3 => Symbol(date_func))

    return df
end


function generate_quote_rate(twit_data::DataFrame, date_func::Function)
    df = get_quote_rate(twit_data, date_func)
    quotes = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nuniqueAvg => "Quote tweet rate")

    return draw(quotes)
end


function get_retweet_rate(twit_data::DataFrame, date_func::Function)
    is_retweet(type) = type == "retweeted" || "retweeted" in split(strip(type,['[', ']']),", ")
    twit_data = filter(:sourcetweet_type => is_retweet, twit_data)
    df = @chain twit_data begin
        @transform(:temp1 = minute.(:date), :temp2 = hour.(:date), :temp3 = dayofyear.(:date))
        @by([:temp1, :temp2, :temp3], :nunique = length(unique(:author_id)))
        @by(:temp3, :nuniqueAvg = mean(:nunique))
    end

    rename!(df, :temp3 => Symbol(date_func))

    return df
end


function generate_retweet_rate(twit_data::DataFrame, date_func::Function)
    df = get_retweet_rate(twit_data, date_func)
    retweets = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nuniqueAvg => "Retweet rate")

    return draw(retweets)
end


function get_reply_rate(twit_data::DataFrame, date_func::Function)
    is_reply(type) = type != "NA"
    twit_data = filter(:in_reply_to_user_id => is_reply, twit_data)
    df = @chain twit_data begin
        @transform(:temp1 = minute.(:date), :temp2 = hour.(:date), :temp3 = dayofyear.(:date))
        @by([:temp1, :temp2, :temp3], :nunique = length(unique(:author_id)))
        @by(:temp3, :nuniqueAvg = mean(:nunique))
    end

    rename!(df, :temp3 => Symbol(date_func))

    return df
end


function generate_reply_rate(twit_data::DataFrame, date_func::Function)
    df = get_reply_rate(twit_data, date_func)
    replys = data(df) *
        visual(Lines) *
        mapping(Symbol(date_func) => string(date_func), :nuniqueAvg => "reply tweet rate")

    return draw(replys)
end
