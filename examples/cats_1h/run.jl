# Use Julia package
using CATEX, MosekTools
using Profile
# Set the main directory for the toy example
main_dir = @__DIR__

sys, mod =  run_stocapex(;   main_dir = main_dir, 
                            solver = Mosek.Optimizer, 
                            print_model = false,
                            gen_costs = "quadratic") 

                            # Open a file and print the profile results to it

println("Finished")

