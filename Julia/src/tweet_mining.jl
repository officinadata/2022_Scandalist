using CSV
using DataFrames
using DataFramesMeta
using DataStructures
using Dates
using Statistics
using TimeZones

function read_tw_data(filename)
    
    tw_data = CSV.read(filename,DataFrame, ntasks = 1)
    
    @transform!(tw_data, :date = ZonedDateTime.(:created_at,TW_dt))

    return tw_data

end

mentreg = r"((?<=@)\w+)"
hashreg = r"((?<=#)\w+)"
TW_dt = dateformat"yyyy-mm-ddTHH:MM:SS.sssz"


function get_mentions(tweet;regsel = mentreg)
    [lowercase(capture.match) for capture in eachmatch(regsel,lowercase(tweet))]
end

function get_all_username(dataset)
    everyone = Set(dataset.user_username) ∪ Set(vcat(dataset.mentions...))
    return everyone
end

most_common(c::Accumulator) = most_common(c, length(c))
most_common(c::Accumulator, k) = sort(collect(c), by=kv->kv[2], rev=true)[1:k]

get_mention_count(tweet_data) = counter(vcat(get_mentions.(tweet_data...)))
