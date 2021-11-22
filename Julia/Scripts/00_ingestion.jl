using Pkg

Pkg.activate(".")
Pkg.instantiate()

using Revise

include("src/tweet_mining.jl")

using Chain

Pepsi_data = "Data/pepsi.csv" |> read_tw_data

using CairoMakie, AlgebraOfGraphics

volume_by_day = @chain Pepsi_data begin
    @transform(:day = dayofyear.(:date))
    @by(:day,
    :nquotes = mean(:quote_count),
    :nretweets = mean(:retweet_count))
#    @combine(:week = :week, :n = nrow)
end

Pdata = @chain Pepsi_data begin
    @transform(:day = dayofyear.(:date))
    @by(:day,
    :nquotes = mean(:quote_count),
    :nretweets = mean(:retweet_count))
#    @combine(:week = :week, :n = nrow)
end

volume_by_day.CumulativeVolume = cumsum(volume_by_day.n)

set_aog_theme!()

volume_pepsi = data(volume_by_day)

volume_cumulative_pepsi = volume_pepsi *
    mapping(:day => "Days",:CumulativeVolume => "Cumulative number of posts")

volume_daily_pepsi = data(Pepsi_data) *
    mapping(:quote_count => "N Quotes",:retweet_count => "N Retweets")

draw(volume_cumulative_pepsi)

draw(volume_daily_pepsi)


sort(Pepsi_data,:quote_count, rev = true)

Pepsi_data

Pepsi_data.mentions = get_mentions.(lowercase.(Pepsi_data.text))
Pepsi_data.Nmentions = length.(Pepsi_data.mentions)

mentions_avg_by_day = @chain Pepsi_data begin
    @transform(:week = week.(:date))
    @by(:week, :AvgNMentions = mean(:Nmentions))
#    @combine(:week = :week, :n = nrow)
end


mention_pepsi = data(mentions_avg_by_day) * visual(Lines)

mentions = mention_pepsi *
    mapping(:week => "Weeks",:AvgNMentions => "Average number of mentions per tweet")

volume_daily_pepsi = volume_pepsi *
    mapping(:day => "Days",:n => "Number of posts")

draw(mentions)

draw(volume_daily_pepsi)

everyone_pepsi = @chain Pepsi_data begin
    @subset(week.(:date) .== 16)
    get_all_username()
end