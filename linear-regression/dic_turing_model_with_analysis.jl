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

# -------------------------------------------------

import MCMCChains: Chains
import Distributions: logpdf

# helper: pull parameter arrays out of the chain
function posterior_draws_linear(chain::Chains, p::Int)
    # α
    α = vec(Array(chain[:α]))
    sigma2_sym = Symbol("σ²")
    σ² = vec(Array(chain[sigma2_sym]))
    # β[1:p]
    β = hcat([vec(Array(chain[Symbol("β[$j]")])) for j in 1:p]...)  # size: (n_samples, p)
    return α, β, σ²
end

# deviance for the linear regression with homoskedastic Normal errors
function deviance_linear(α::Real, β::AbstractVector, σ²::Real, X::AbstractMatrix, y::AbstractVector)
    μ = X * β .+ α
    n = length(y)

    # full MVN likelihood, includes determinant term that depends on σ²
    ll = logpdf(MvNormal(μ, σ² * I(n)), y)
    return -2 * ll
end

# DIC computation
function dic_linear(chain::Chains, X::AbstractMatrix, y::AbstractVector)
    _, p = size(X)
    α, β, σ² = posterior_draws_linear(chain, p)
    n_samps = length(α)

    # pointwise deviances over posterior draws
    Ds = similar(α)
    for s in 1:n_samps
        Ds[s] = deviance_linear(α[s], @view(β[s, :]), σ²[s], X, y)
    end
    Dbar = mean(Ds)

    # deviance at posterior mean parameters
    αhat  = mean(α)
    βhat  = vec(mean(β; dims=1))
    σ²hat = mean(σ²)
    Dhat  = deviance_linear(αhat, βhat, σ²hat, X, y)

    pD  = Dbar - Dhat           # effective number of parameters
    DIC = Dbar + pD             # = 2*Dbar - Dhat

    return (; Dbar, Dhat, pD, DIC)
end

import Statistics: mean

# === run it on your objects ===
Xmat = Matrix(X)
res = dic_linear(chain, Xmat, y)
println(res)

# Finding the probability that coefficient of Income is positive. 
sum(vec(chain[Symbol("β[1]")]) .> 0) / length(chain[Symbol("β[1]")])
