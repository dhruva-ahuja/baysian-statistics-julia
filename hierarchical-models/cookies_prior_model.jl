import DataFrames: DataFrame, groupby, combine, unstack, nrow
import CSV

df = CSV.read("hierarchical-models/cookies.dat", DataFrame, delim=' ', header=true)

first(df, 5)

cookie_location_table = combine(groupby(df, [:location]), nrow => :Count)
println(cookie_location_table)

import StatsPlots: @df, boxplot

@df df boxplot(:location, :chips,
    xlabel="Location",
    ylabel="chips",
    legend=false,
    title="Boxplot of chips by Location")


import Random: seed!, rand

seed!(112)


import Distributions: Exponential
n_sim = 500

α_prior = rand(Exponential(2), n_sim)
β_prior = rand(Exponential(1/5), n_sim)

μ_prior = α_prior ./ β_prior
σ_prior = sqrt.(α_prior ./ β_prior.^2)

import StatsBase: mean, median, quantile

mean(μ_prior), median(μ_prior), quantile(μ_prior, 0.025), quantile(μ_prior, 0.975)

mean(σ_prior), median(σ_prior), quantile(σ_prior, 0.025), quantile(σ_prior, 0.975)