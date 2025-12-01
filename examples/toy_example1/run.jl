using Infiltrator, Revise
using CATSExpand, ProgressMeter

main_dir ="/Users/paul/Documents/CATSExpand/examples/toy_example1"
sys = init_system(main_dir= main_dir)
pol = init_policies(main_dir= main_dir)
model = build_stochastic_capex_model(sys, pol, main_dir = main_dir)