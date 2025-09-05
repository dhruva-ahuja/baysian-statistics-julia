import CSV
import DataFrames: DataFrame, first, eachcol, names, describe, groupby, combine
dataset = CSV.read("poisson-regression/pctgrowth.csv", DataFrame)

println(first(dataset, 5))

import StatsBase: countmap

countmap(dataset.grp)

describe(dataset)

import Statistics: mean

combine(groupby(dataset, :grp), :y => mean) |> println

import Turing: @model, NUTS, sample
import Distributions: Normal, InverseGamma
import DistributionsAD: filldist

@model function hierarchical_model(y, grp)
    σ² ~ InverseGamma(1, 1)
    τ² ~ InverseGamma(1/2, 2/3)
    μ ~ Normal(0, 1000)

    θ ~ filldist(Normal(μ, sqrt(τ²)), size(unique(grp), 1) )

    for i in eachindex(y)
        y[i] ~ Normal(θ[grp[i]], sqrt(σ²))
    end
end


grp = dataset.grp
y = dataset.y

model = hierarchical_model(dataset.y, dataset.grp)

chains = sample(model, NUTS(), 10000)

describe(chains)


import GLM: lm, @formula, EffectsCoding
import CategoricalArrays: categorical

dataset.grpcat = categorical(dataset.grp)

lm_model = lm(@formula(y ~ grp), dataset, contrasts=Dict(:grp => EffectsCoding()))


group = zeros(5)
group[1] = -0.381452    
group[2] = -1.23521    
group[3] = -0.781048   
group[4] =  0.634786 
group[5] =  0.0100238 

println(group[1])
for i in 2:5
    println(group[1] + group[i])
end