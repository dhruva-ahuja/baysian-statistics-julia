import RDatasets

df = RDatasets.dataset("car", "Anscombe")

df[1:5, :] |> print

import StatsBase: countmap
import DataFrames: unique

unique(df.State)