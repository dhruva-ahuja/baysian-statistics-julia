# Todo: Check for validity of these results.

import RDatasets
import DataFrames
import Plots

Plots.gr(size=(800, 600))

dataset = RDatasets.dataset("car", "Anscombe")
first(dataset, 5)

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
