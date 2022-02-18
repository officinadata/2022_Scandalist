using Pkg

using Revise

include("../src/tweet_mining.jl")

using DataFrames
using DataFramesMeta
using Dates


function read_files(dir)
    files = readdir(dir, join=true)
    dfs = []
    
    for name in files
        df = name |> read_tw_data
        df = sort(df, order(:created_at))
        push!(dfs, df)
    end

    return dfs
end


function read_names(dir)
    files = getindex.(split.(readdir(dir), ".csv"), 1)
    return files
end