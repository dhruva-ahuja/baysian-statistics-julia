# Todo: Check for validity of these results.

import RDatasets
import DataFrames
import Plots

Plots.gr(size=(800, 600))

dataset = RDatasets.dataset("car", "Anscombe") 
first(dataset, 5) |> print

# ----------------------------------------------------------------- #

import Turing: @model, NUTS, describe, sample, summarize
import LinearAlgebra: I
import Distributions: Normal, MvNormal, InverseGamma

X, y = dataset[!, [:Income, :Young, :Urban]], dataset[!, :Education]

import Statistics: mean, std
scale(A) = (A .- mean(A, dims=1)) ./ std(A, dims=1)

import Distributions: Laplace, mean, var
import DistributionsAD: filldist

@model function linear_regression(X, y)
    β ~ filldist(Laplace(0, 1), size(X, 2))
    σ² ~ InverseGamma(0.5, 2)
    
    y ~ MvNormal(X * β, σ² * I)
end

model = linear_regression(scale(Matrix(X)), y)
chain = sample(model, NUTS(), 100_000)

describe(chain)

# ----------------------------------------------------------------- #

import StatsPlots: density, scatter
import MCMCChains: traceplot, autocorplot, meanplot

traceplot(chain)
density(chain)
autocorplot(chain)
meanplot(chain)

# ----------------------------------------------------------------- #

import MCMCDiagnosticTools: ess_rhat
import GLM: lm, @formula, residuals, predict, coeftable

ess_rhat(chain)

lm_model = lm(@formula(Education ~ Income + Young + Urban), dataset)
scatter(predict(lm_model), residuals(lm_model), label="Data", xlabel="Predicted Values", ylabel="Residuals")

coeftable(lm_model)

# ----------------------------------------------------------------- #

import AxisArrays: permutedims

coeffs = chain.value[iter=:, var=[:σ², Symbol("β[1]"), Symbol("β[2]"), Symbol("β[3]")], chain=1]

import Distributions: logpdf
import LinearAlgebra: I, transpose


mean_coeffs = mean(coeffs, dims=1)[1, :]
mean_coeffs = coeffs[iter=1]



function compute_DIC(X, y, coeffs)
    n_iter = size(coeffs, 1)
    mean_deviance = -2 * mean([compute_loglikelihood(coeffs[iter=i], X, y) for i in n_iter])
    mean_coeffs = mean(coeffs, dims=1)[1, :]
    deviance_at_mean = -2 * compute_loglikelihood(mean_coeffs, X, y)

    DIC = 2 * mean_deviance - deviance_at_mean

    return DIC, mean_deviance - deviance_at_mean
end


function compute_loglikelihood(coeff, X, y)
    β = coeff[[Symbol("β[$i]") for i in 1:3]]
    σ² = coeff[:σ²]

    logpdf(MvNormal(X * β, σ² * I), y)
end

compute_DIC(scale(Matrix(X)), y, coeffs)