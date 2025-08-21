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

@model function linear_regression(X, y)
    α ~ Normal(0, 1e3)
    β ~ MvNormal(zeros(size(X, 2)), I * 1e6)
    σ² ~ InverseGamma(0.5, 750)
    
    y ~ MvNormal(X * β .+ α, σ² * I)
end

model = linear_regression(Matrix(X), y)
chain = sample(model, NUTS(), 1000)

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
