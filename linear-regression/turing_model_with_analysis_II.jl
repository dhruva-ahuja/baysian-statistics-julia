import RDatasets
import DataFrames
import Plots

Plots.gr(size=(800, 600))

dataset = RDatasets.dataset("car", "Leinhardt")
first(dataset, 5)

# ----------------------------------------------------------------- #

import Turing: @model, NUTS, describe, sample, summarize
import LinearAlgebra: I
import Distributions: Normal, MvNormal, InverseGamma, MvTDist, Exponential
import Plots: scatter, plot, plot!, hline!

DataFrames.dropmissing!(dataset)

X, y = log.(dataset[!, [:Income]]), log.(dataset[!, :Infant])
scatter(X[!, :Income], y)

X_cor = hcat(X, DataFrames.DataFrame(Oil=map(x -> x == "yes" ? 1 : 0, dataset[!, :Oil])))

@model function linear_regression(X, y)
    α ~ Normal(0, 1e3)
    β ~ MvNormal(zeros(size(X, 2)), I * 1e6)
    σ² ~ InverseGamma(5.0/2, 5*10.0/2)
    
    df ~ Exponential(1) 
    n = length(y)
    Σ = σ² * Matrix(I, n, n)

    y ~ MvTDist(df, X * β .+ α, Σ)
end

model = linear_regression(Matrix(X), y)
chain = sample(model, NUTS(), 1000)

describe(chain)

# ----------------------------------------------------------------- #

import StatsPlots: density, scatter
import MCMCChains: traceplot, autocorplot, meanplot
import MCMCDiagnosticTools: ess_rhat

traceplot(chain)
density(chain)
autocorplot(chain)
meanplot(chain)

ess_rhat(chain)
# ----------------------------------------------------------------- #

import GLM: lm, @formula, residuals, predict, coeftable

lm_model = lm(@formula(Infant ~ Income + Oil), hcat(X, DataFrames.DataFrame(Infant=y, Oil = map(x -> x == "yes" ? 1 : 0, dataset[!, :Oil]))))
scatter(predict(lm_model), residuals(lm_model), label="Data", xlabel="Predicted Values", ylabel="Residuals")
hline!([0])

coeftable(lm_model)
# ----------------------------------------------------------------- #
