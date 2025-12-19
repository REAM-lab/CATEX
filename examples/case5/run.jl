"""
Decription of the case study:

It is the case5 from MATPOWER. The input data from MATPOWER has been re-formated and saved as csv files, 
which are the ones placed in the "inputs" folder. 
"""

# Use Julia package
using Catex, MosekTools

# Set the main directory for the case study
main_dir = joinpath("examples", "case5")

# Run stochastic capacity expansion 
sys, mod = run_stocapex(; main_dir = main_dir, solver = Mosek.Optimizer, print_model = true) 

println("Finished")

