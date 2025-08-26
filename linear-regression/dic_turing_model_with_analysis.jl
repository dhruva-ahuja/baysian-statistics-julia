import RDatasets

dataset = RDatasets.dataset("car", "Anscombe")

import Turing: @model, NUTS, sample
import LinearAlgebra: I
import Distributions: Normal, MvNormal, InverseGamma
import DataFrames: dropmissing!

dropmissing!(dataset)

X, y = dataset[!, [:Income, :Young, :Urban]], dataset[!, :Education]

@model function linear_regression(X, y)
    α ~ Normal(0, 1e3)
    β ~ MvNormal(zeros(size(X, 2)), I * 1e6)
    σ² ~ InverseGamma(0.5, 750)
    
    y ~ MvNormal(X * β .+ α, σ² * I)
end

model = linear_regression(Matrix(X), y)
chain = sample(model, NUTS(), 1000)

import MCMCChains: namesingroup 

namesingroup(chain, :β)
fieldnames(typeof(chain))

chain.name_map.internals


