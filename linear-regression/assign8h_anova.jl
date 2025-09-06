using RDatasets

warpbreaks = dataset("datasets", "warpbreaks")

missings_per_col = map(col -> sum(ismissing, col), eachcol(warpbreaks))
println(missings_per_col)

import StatsBase: countmap
using DataFrames

wool_tension_table = combine(groupby(warpbreaks, [:Wool, :Tension]), nrow => :Count)
println(wool_tension_table)

pivot_table = unstack(wool_tension_table, :Wool, :Tension, :Count)
println(pivot_table)

using Plots, StatsPlots

Plots.backend(:gr)

@df warpbreaks boxplot(string.(:Wool, "-", :Tension), :Breaks,
    xlabel="Wool-Tension",
    ylabel="Breaks",
    legend=false,
    title="Boxplot of Breaks by Wool and Tension")

@df warpbreaks boxplot(string.(:Wool, "-", :Tension), log.(:Breaks),
    xlabel="Wool-Tension",
    ylabel="log(Breaks)",
    legend=false,
    title="Boxplot of log(Breaks) by Wool and Tension")