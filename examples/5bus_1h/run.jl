# Use Julia package
using Revise
using Infiltrator
using CATEX, MosekTools


# Set the main directory for the toy example
main_dir = @__DIR__

sys, mod = run_stocapex(;   main_dir = main_dir, 
                            solver = Mosek.Optimizer, 
                            solver_settings = Dict(),
                            print_model = false,
                            model_settings = Dict(
                                                    "gen_costs" => "quadratic",
                                                    "consider_shedding" => true,
                                                    "consider_single_storage_injection" => false,
                                                    "consider_line_capacity" => false,
                                                    "consider_bus_max_flow" => true,
                                                    "consider_angle_limits" => true,
                                                    "policies" => []))

#sys = init_system(main_dir)

println("Finished")

