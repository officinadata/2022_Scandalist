using Pkg
using Revise
using Chain
using CairoMakie, AlgebraOfGraphics

cd("Julia")
Pkg.activate(".")
Pkg.instantiate()


include("../src/tweet_mining.jl")
include("01_wrangling.jl")
include("02_plotting.jl")


Pepsi_data = "Data/pepsi.csv" |> read_tw_data

everyone_pepsi = @chain Pepsi_data begin
    @subset(week.(:date) .== 16)
    get_all_username()
end

set_aog_theme!()

sort(Pepsi_data,:quote_count, rev = true)
Pepsi_data

Pepsi_data = add_mentions(Pepsi_data)

# Wrangling functions

get_volume_by(Pepsi_data, week)

get_cumulative_volume_by(Pepsi_data, week)

get_avg_interactions_by(Pepsi_data, dayofyear)

add_mentions(Pepsi_data)

get_avg_mentions_by(Pepsi_data, week)

# Plotting functions

generate_volume_by_plot(Pepsi_data, dayofyear)

generate_cumulative_volume_by_plot(Pepsi_data, dayofyear)

generate_avg_mentions_by_plot(Pepsi_data, dayofyear)