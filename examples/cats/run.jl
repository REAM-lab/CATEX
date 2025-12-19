# Use Julia package
using CATEX, MosekTools


# Set the main directory for the toy example
main_dir = joinpath("examples", "cats")

sys, mod = run_stocapex(; main_dir = main_dir, solver = Mosek.Optimizer, print_model = false) 

println("Finished")

