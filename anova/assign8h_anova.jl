import RDatasets

warpbreaks = RDatasets.dataset("datasets", "warpbreaks")

missings_per_col = map(col -> sum(ismissing, col), eachcol(warpbreaks))

warpbreaks[1:5, :] |> println

import StatsBase: countmap
import DataFrames: combine, groupby, nrow, unstack

countmap(warpbreaks.Tension)

wool_tension_table = combine(groupby(warpbreaks, [:Wool, :Tension]), nrow => :Count)

wool_tension_table |> println

pivot_table = unstack(wool_tension_table, :Wool, :Tension, :Count)
println(pivot_table)

using Plots, StatsPlots

Plots.backend(:gr)

@df warpbreaks boxplot(string.(:Wool, "-", :Tension), :Breaks,
    xlabel="Wool-Tension",
    ylabel="Breaks",
    legend=false,
    title="Boxplot of Breaks by Wool and Tension")

@df warpbreaks boxplot(string.(:Wool, "-", :Tension), log.(:Breaks),
    xlabel="Wool-Tension",
    ylabel="log(Breaks)",
    legend=false,
    title="Boxplot of log(Breaks) by Wool and Tension")

# --------------------------------------------------------------------------------------- #

import Turing: @model, NUTS, sample, filldist, describe
import Distributions: Normal, InverseGamma

@model function anova_warp(grp, y)
    n_itr = size(y, 1)
    grps = size(unique(grp), 1)

    μ ~ filldist(Normal(0, 10^3), grps)
    σ² ~ InverseGamma(5/2, 5)

    for i in 1:n_itr
        y[i] ~ Normal(μ[grp[i]], sqrt(σ²))
    end
end

import CategoricalArrays: CategoricalArray, levelcode

X = warpbreaks[:, :Tension] |> CategoricalArray .|> levelcode
y = log.(warpbreaks.Breaks)

t_model = anova_warp(X, y)

chains = sample(t_model, NUTS(), 1000)

describe(chains)

coeffs = chains.value[chain=1, var=[Symbol("μ[1]"), Symbol("μ[2]"), Symbol("μ[3]"), :σ², :loglikelihood]]



μ = coeffs[iter=:, var=[Symbol("μ[$i]") for i in 1:3]]
σ² = coeffs[iter=:, var=:σ²]


import Distributions: logpdf, MvNormal
import Statistics: mean

mean_μ = mean(μ, dims=1)[:]
mean_var = mean(σ²)

function compute_dic(X, y, coeffs, loglik)
    n_iter = size(coeffs, 1)

    mean_deviance = -2 * mean([loglik(coeffs[iter=i], X, y) for i in 1:n_iter])
    mean_coeffs = mean(coeffs, dims=1)[1, :]
    deviance_at_mean = -2 * loglik(mean_coeffs, X, y)

    p_D = mean_deviance - deviance_at_mean

    DIC = mean_deviance + p_D

    return mean_deviance, p_D, DIC

end

import LinearAlgebra: I

function compute_loglikelihood_simple(coeff, X, y)
    μ = coeff[[Symbol("μ[$i]") for i in 1:3]]
    σ² = coeff[var=:σ²]
    sum(logpdf.(Normal.(μ.data[X], sqrt(σ²)), y))
end


dic_val = compute_dic(X, y, coeffs, compute_loglikelihood_simple)