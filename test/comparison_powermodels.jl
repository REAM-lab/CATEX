"""
These tests aim to benchmark the power flow formulation in CATEX, i.e. construction of admittance matrix, DC flows, 
power balance equations, transmission limits. Capacity expansion is not validated in these cases.

Therefore, the DCOPF formulation, i.e. construction of admittance matrix, DC flows, power balance equations, 
transmission limits, in CATEX model has been validated. 

As follow, we present the statistics for the difference in power generation (MW) between PowerModels.jl and CATEX,
using Mosek.

For Case 5:
 Row │ variable  mean          min           median        max          nmissing  eltype   
     │ Symbol    Float64       Float64       Float64       Float64      Int64     DataType 
─────┼─────────────────────────────────────────────────────────────────────────────────────
   1 │ diff      -7.01589e-11  -7.38027e-10  -3.21925e-10  9.47466e-10         0  Float64

For CaliforniaTestSystem:
 Row │ variable  mean       min       median   max      nmissing  eltype   
     │ Symbol    Float64    Float64   Float64  Float64  Int64     DataType 
─────┼─────────────────────────────────────────────────────────────────────
   1 │ diff      0.0106017  -14.8912      0.0   22.346         0  Float64

The mean is pretty low in both cases. The max and min are relative big in the California test. We observed that
these outliers happen in generators with zero cost. We then suspect that this is the reason of certain disparity.
In conclusion, the power flow formulation in CATEX has been validated.

Dec 10, 2025
"""

# Load Julia Packages
using CSV, DataFrames, MosekTools, PowerModels, CATEX, JuMP

# Run PowerModels (write CaliforniaTestSystem.m  or  case5.m, in joinpath below)
# -----------------------------------------------------------
data = PowerModels.parse_file(joinpath("test", "CaliforniaTestSystem.m"))
solver = Mosek.Optimizer
solution = PowerModels.solve_opf(data, DCPPowerModel, solver)
objval = solution["objective"]
sol = solution["solution"]
ngens = length(sol["gen"])
pgen = [ 100*sol["gen"][string(i)]["pg"] for i in 1:ngens]

df_pm = DataFrame(gen_name = 1:ngens, DispatchGen_MW_PowerModels = pgen)

# Run CATEX (write cats  or  case5)
main_dir =joinpath("examples", "cats")
sys, mod = run_stocapex(; main_dir = main_dir, solver = Mosek.Optimizer, print_model = false) 
df_catex = CSV.read(joinpath(main_dir, "outputs", "var_gen_dispatch.csv"), DataFrame; select = [:gen_name, :DispatchGen_MW])
rename!(df_catex, "DispatchGen_MW" => "DispatchGen_MW_catex")

# Compare both results
diff_objvalue = (value(mod[:eTotalCost]) - value(objval))/value(objval) *100
df_compare = innerjoin(df_pm, df_catex, on = [:gen_name])
df_compare.diff = df_compare.DispatchGen_MW_catex - df_compare.DispatchGen_MW_PowerModels
describe(df_compare[:, ["diff"]])