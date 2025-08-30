import RDatasets

plantgrowth = RDatasets.dataset("datasets", "PlantGrowth")

print(first(plantgrowth, 5))

import StatsPlots: boxplot
import Plots: scatter

boxplot(plantgrowth[!, :Group], plantgrowth[!, :Weight])

import GLM: lm, @formula, coeftable, residuals, predict

lm_model = lm(@formula(Weight ~ Group), plantgrowth)
scatter(predict(lm_model), residuals(lm_model))

coeftable(lm_model)

# --------------------------------------------------------
import CategoricalArrays: categorical, levelcode, levels

plantgrowth.GroupCat = levelcode.(categorical(plantgrowth.Group))
plantgrowth.GroupCat = plantgrowth.GroupCat

y = plantgrowth.Weight
J = levels(plantgrowth.GroupCat)
group = plantgrowth.GroupCat

import Turing: @model, sample, NUTS, MCMCThreads, describe
import Distributions: MvNormal, InverseGamma, filldist, Normal
import LinearAlgebra: I
import DistributionsAD: filldist

@model function anova_pg(grp, y, J)
    μ ~ MvNormal(zeros(length(J)), 1.0e6 * I)
    σ² ~ filldist(InverseGamma(5.0/2, 5.0/2), length(J))

    for i in eachindex(y)
        y[i] ~ Normal(μ[grp[i]], sqrt(σ²[grp[i]]))
    end
end

model = anova_pg(group, y, J)

chains = sample(model, NUTS(), 10_000)


import StatsPlots: density, scatter
import MCMCChains: traceplot, autocorplot, meanplot

traceplot(chains)
density(chains)
autocorplot(chains)
meanplot(chains)

describe(chains)

chains.value
group_means = chains.value[iter=:, var=[Symbol("μ[1]"), Symbol("μ[2]"), Symbol("μ[3]")], chain=1].data

import ArviZ: hdi

hdi(group_means[:, 3] - group_means[:, 1]; prob=0.95)