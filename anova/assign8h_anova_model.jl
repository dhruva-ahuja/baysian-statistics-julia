import RDatasets

warpbreaks = RDatasets.dataset("datasets", "warpbreaks")

# --------------------------------------------------------------------------------------- #

import Turing: @model, NUTS, sample, filldist, describe
import Distributions: Normal, InverseGamma

@model function anova_warp(grp, y)
    n_itr = size(y, 1)
    grps = size(unique(grp), 1)

    μ ~ filldist(Normal(0, 5e3), grps)
    σ² ~ InverseGamma(5/2, 5)

    for i in 1:n_itr
        y[i] ~ Normal(μ[grp[i]], sqrt(σ²))
    end
end

import CategoricalArrays: CategoricalArray, levelcode
import DataFrames: unique

warpbreaks[:, :Group] = string.(warpbreaks[:, :Wool], "-", warpbreaks[:, :Tension])


X = warpbreaks[:, :Group] |> CategoricalArray .|> levelcode
y = log.(warpbreaks.Breaks)

t_model = anova_warp(X, y)

chains = sample(t_model, NUTS(), 1000)

describe(chains)


import Distributions: logpdf, MvNormal
import Statistics: mean

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
    μ = coeff[[Symbol("μ[$i]") for i in 1:size(unique(X), 1)]]
    σ² = coeff[var=:σ²]
    sum(logpdf.(Normal.(μ.data[X], sqrt(σ²)), y))
end

chains.value

dic_val = compute_dic(
    X, y, 
    chains.value[iter=:, var=[[Symbol("μ[$i]") for i in 1:size(unique(X), 1)]..., :σ²], chain=1], compute_loglikelihood_simple
)
