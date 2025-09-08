import RDatasets: dataset

ome_dataset = dataset("MASS", "OME")
ome_dataset = filter(row -> row.OME != "N/A", ome_dataset)
first(ome_dataset, 5)

dat = copy(ome_dataset)
dat.Prob = dat.Correct ./ dat.Trials
dat.OMElow = ifelse.(dat.OME .== "low", 1, 0)
dat.NoiseCoherent = ifelse.(dat.Noise .== "coherent", 1, 0)
first(dat, 5)


import LinearAlgebra: dot
import Turing: @model, sample, NUTS, Gibbs
import DistributionsAD: filldist
import CategoricalArrays: categorical, levelcode

using Distributions, DataFrames
import StatsFuns: logistic

@model function prob_regression(X, y)
    μ ~ Normal(0, 10)
    τ² ~ InverseGamma(0.5, 0.5)

    a ~ filldist(Normal(μ, sqrt(τ²)), size(unique(X.ID), 1))
    b ~ filldist(Normal(0, 4), 4)

    ϕ = logistic.(a[X.level] .+ b[1] * X.Age .+ b[2] * X.OMElow .+ b[3] * X.Loud .+ b[4] * X.NoiseCoherent)

    for i in eachindex(y)
        y[i] ~ Binomial(X[i, :Trials], ϕ[i])
    end
end

dat.ID = categorical(dat.ID)
dat.level = levelcode.(dat.ID)

t_model = prob_regression(dat[!, Not(:Prob, :Correct)], dat.Correct)

chains = sample(t_model, NUTS(), 5000)

describe(chains)

import MCMCChains: traceplot, autocorplot, meanplot

traceplot(chains)
density(chains)
autocorplot(chains)
meanplot(chains)

import Statistics: mean


# To do: Compute DIC, values not matching for complex hierarchical model
function compute_DIC(dat, chains, log_likelihood, parameter_names)
    # Extract samples for the parameters
    samples = chains.value[:, parameter_names, 1]
    n_samples = size(samples, 1)

    # Compute deviance for each sample
    deviances = [-2 * log_likelihood(dat, samples[i, :]) for i in 1:n_samples]
    mean_deviance = mean(deviances)

    # Compute deviance at the mean of the parameters
    mean_params = mean(samples, dims=1)[1, :]
    deviance_at_mean = -2 * log_likelihood(dat, mean_params)

    # Compute DIC
    DIC = 2 * mean_deviance - deviance_at_mean
    return DIC, mean_deviance - deviance_at_mean
end

log_likelihood(dat, params) = begin
    b1, b2, b3, b4 = params[ [Symbol("b[$i]") for i in 1:4] ]
    a = params[ [Symbol("a[$i]") for i in 1:63] ]
    ϕ = logistic.(a[dat.level] .+ b1 .* dat.Age .+ b2 .* dat.OMElow .+ b3 .* dat.Loud .+ b4 .* dat.NoiseCoherent)
    sum(logpdf.(Binomial.(dat.Trials, ϕ), dat.Correct))
end


model_vars = [:μ, :τ², Symbol("a[1]"), Symbol("a[2]"), Symbol("a[3]"), Symbol("a[4]"), Symbol("a[5]"), Symbol("a[6]"), Symbol("a[7]"), Symbol("a[8]"), Symbol("a[9]"), Symbol("a[10]"), Symbol("a[11]"), Symbol("a[12]"), Symbol("a[13]"), Symbol("a[14]"), Symbol("a[15]"), Symbol("a[16]"), Symbol("a[17]"), Symbol("a[18]"), Symbol("a[19]"), Symbol("a[20]"), Symbol("a[21]"), Symbol("a[22]"), Symbol("a[23]"), Symbol("a[24]"), Symbol("a[25]"), Symbol("a[26]"), Symbol("a[27]"), Symbol("a[28]"), Symbol("a[29]"), Symbol("a[30]"), Symbol("a[31]"), Symbol("a[32]"), Symbol("a[33]"), Symbol("a[34]"), Symbol("a[35]"), Symbol("a[36]"), Symbol("a[37]"), Symbol("a[38]"), Symbol("a[39]"), Symbol("a[40]"), Symbol("a[41]"), Symbol("a[42]"), Symbol("a[43]"), Symbol("a[44]"), Symbol("a[45]"), Symbol("a[46]"), Symbol("a[47]"), Symbol("a[48]"), Symbol("a[49]"), Symbol("a[50]"), Symbol("a[51]"), Symbol("a[52]"), Symbol("a[53]"), Symbol("a[54]"), Symbol("a[55]"), Symbol("a[56]"), Symbol("a[57]"), Symbol("a[58]"), Symbol("a[59]"), Symbol("a[60]"), Symbol("a[61]"), Symbol("a[62]"), Symbol("a[63]"), Symbol("b[1]"), Symbol("b[2]"), Symbol("b[3]"), Symbol("b[4]")]

compute_DIC(dat, chains, log_likelihood, model_vars)


