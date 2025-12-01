using Infiltrator, Revise
using CATSExpand, MosekTools, JuMP, DataFrames, CSV, NamedArrays

main_dir ="/Users/paul/Documents/CATSExpand/examples/toy_example1"
#sys = init_system(main_dir= main_dir)
#pol = init_policies(main_dir= main_dir)
#model = solve_stochastic_capex_model(sys, pol, main_dir = main_dir)
sys, pol, mod = run_stocapex(; main_dir = main_dir, solver = Mosek.Optimizer, print_model = false)

var_name = mod[:GEN]
header = [:gen_id, :tp_id, :DispatchGen_MW]
df = DataFrame(Containers.rowtable(value, var_name; header = header))
for h in header[begin:end-1]
    df[!, h] = getfield.(df[!, h], h)
end
