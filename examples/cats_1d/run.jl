# Use Julia package
using Revise
using Infiltrator
using CATEX, MosekTools


# Set the main directory for the toy example
main_dir = @__DIR__

#sys, mod = run_stocapex(; main_dir = main_dir, solver = Mosek.Optimizer, print_model = false) 
sys = init_system(main_dir = main_dir)

println("Finished")

