import CSV
import DataFrames: DataFrame, Not

dataset = CSV.read("poisson-regression/callers.csv", DataFrame)

println(first(dataset, 5))

import StatsPlots: boxplot, @df

@df dataset boxplot(:isgroup2, :calls ./ :days_active)

import Turing: @model, sample, NUTS
import Distributions: Poisson, Normal
import DistributionsAD: filldist
import StatsFuns: exp


@model function poisson_regression(X, days_active, calls)
    β₀ ~ Normal(0, 10)
    β ~ filldist(Normal(0, 10), size(X, 2))

    λ = exp.(β₀ .+ X * β)

    for i in 1:size(X, 1)
        calls[i] ~ Poisson(λ[i] * days_active[i])
    end
end

calls = dataset[!, :calls]
days_active = dataset[!, :days_active]
calls = dataset[!, :calls]
X = Matrix(dataset[!, [:age, :isgroup2]])

model = poisson_regression(X, days_active, calls)
chain = sample(model, NUTS(), 10_000)

group_coeff = chain.value[iter=1001:end, var=Symbol("β[2]"), chain=1]

sum(group_coeff.data .> 1, dims=1) / size(group_coeff, 1)