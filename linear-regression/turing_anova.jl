import RDatasets

plantgrowth = RDatasets.dataset("datasets", "PlantGrowth")

print(first(plantgrowth, 5))

import StatsPlots: boxplot

boxplot(plantgrowth[!, :Group], plantgrowth[!, :Weight])

import GLM: lm, @formula

lm_model = lm(@formula(Weight ~ Group), plantgrowth)


import Turing: @model
import Distributions: MvNormal, InverseGamma

@model function anova_imp(X, y)
    μ ~ MvNormal(zeros(3), I(3)*1.0e3)
    σ² ~ InverseGamma(5.0/2, 5.0/2)

    y ~ MvNormal(μ, σ² * I(3))
end

model = anova_imp(plantgrowth[!, :Group], plantgrowth[!, :Weight])
