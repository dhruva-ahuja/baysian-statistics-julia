import Random
using Turing

Random.seed!(32)

@model function attrition_rate(y)
    μ ~ TDist(1)
    for i in eachindex(y)
        y[i] ~ Normal(μ, 1)
    end
end

# Simulate data
y = [1.2, 1.4, -0.5, 0.3, 0.9, 2.3, 1.0, 0.1, 1.3, 1.9]

# Run MCMC (like JAGS' jags() in R)
chain = sample(attrition_rate(y), MH(), 1000)


summarystats(chain)