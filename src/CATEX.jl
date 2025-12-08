"""
CATEX.jl - California Transmission System Expansion Model
A Julia package for modeling capacity expansion and operational 
optimization. Originally developed for the state of California,
it can be adapted for other regions.
"""
module CATEX

# Import Julia packages
using CSV, DataFrames, JuMP, MosekTools, NamedArrays

# Define internal modules
include("utils.jl")
include("scenarios.jl")
include("transmission.jl")
include("generators.jl")
include("energy_storage.jl")
include("timescales.jl")
include("policies.jl")


# Use internal modules
using .Utils, .Scenarios, .Transmission, .Generators, .EnergyStorage, .Timescales, .Policies

# Export the functions we want users to be able to access easily
export init_system, solve_stochastic_capex_model, run_stocapex
export System, Scenario, Bus, Load, Generator, CapacityFactor, Line, EnergyStorageUnit, Timepoint, Timeseries, Policy

"""
System represents the entire power system for the stochastic capacity expansion problem.
# Fields:
- S: Vector containing instances of Scenario structure
- N: Vector containing instances of Bus structure
- loads: multidimensional array of load data
- G: Vector containing instances of Generator structure
- cf: multidimensional array of capacity factors data
- L: Vector containing instances of Line structure
- E: Vector containing instances of EnergyStorage structure
- T: Vector containing instances of Timepoint structure
"""
struct System
    S:: Vector{Scenario}
    T:: Vector{Timepoint}
    TS:: Vector{Timeseries}
    N:: Vector{Bus}
    load:: NamedArray{Union{Missing, Float64}}
    G:: Vector{Generator}
    cf:: NamedArray{Union{Missing, Float64}}
    L:: Vector{Line}
    E:: Vector{EnergyStorageUnit}
    policies:: Policy
end

"""
This function defines how to display the System struct in the REPL or when printed in Julia console.
"""
function Base.show(io::IO, ::MIME"text/plain", sys::System)
    println(io, "CATEX System:")
    println(io, "   ├ N (buses) = ", getfield.(sys.N, :name))
    println(io, "   ├ L (lines) = ", getfield.(sys.L, :name))
    println(io, "   ├ G (generators) = ", getfield.(sys.G, :name))
    println(io, "   ├ E (energy storages) = ", getfield.(sys.E, :name))
    println(io, "   ├ S (scenarios) = ", getfield.(sys.S, :name))
    println(io, "   ├ T (timepoints) = ", getfield.(sys.T, :name))
    println(io, "   ├ TS (timeseries) = ", getfield.(sys.TS, :name))
    println(io, "   ├ Policies: ", fieldnames(Policy))
    println(io, "   ├ Loads.")
    println(io, "   └ Capacity factors.")
end

"""
Initialize the System struct by loading data from CSV files in the inputs directory.
"""
function init_system(;main_dir = pwd())

    println("-------------------------") 
    println(" CATEX  - version 0.1.0") 
    println("-------------------------") 

    # Define the inputs directory
    inputs_dir = joinpath(main_dir, "inputs")

    println("> Loading system data from $inputs_dir :")
    
    filename = "scenarios.csv"
    print(" > $filename ...")
    S = to_structs(Scenario, joinpath(inputs_dir, filename))
    println(" ok.")

    filename = "buses.csv"
    print(" > $filename ...")
    N = to_structs(Bus, joinpath(inputs_dir, filename))
    println(" ok.")

    filename = "lines.csv"
    print(" > $filename ...")
    L = to_structs(Line, joinpath(inputs_dir, filename))
    println(" ok.")

    filename = "generators.csv"
    print(" > $filename ...")
    G = to_structs(Generator, joinpath(inputs_dir, filename))
    println(" ok.")

    filename = "energy_storage.csv"
    print(" > $filename ...")
    E = to_structs(EnergyStorageUnit, joinpath(inputs_dir, filename))
    println(" ok.")

    T, TS = Timescales.load_data(inputs_dir)

    policies = Policies.load_data(joinpath(main_dir, "inputs"))
     
    cf = Generators.process_cf(inputs_dir)

    load = Transmission.process_load(inputs_dir)

    # Create instance of System struct
    sys = System(S, T, TS, N, load, G, cf, L, E, policies)

    return sys
end

"""
Solves a stochastic capacity expansion problem.
""" 
function solve_stochastic_capex_model(sys ;main_dir = pwd(), 
                                    solver = Mosek.Optimizer,
                                    print_model = false)


    println("> Building JuMP model:")

    # Create JuMP model
    mod = Model(optimizer_with_attributes(solver))

    # Initialize Costs for a period
    @expression(mod, eCostPerPeriod, 0)

    # Initialize Costs for a timepoint
    @expression(mod, eCostPerTp[t ∈ sys.T], 0)

    print(" > Generator vars and constraints ... ")
    tep = @elapsed Generators.stochastic_capex_model!(sys, mod)
    println(" ok [$(round(tep, digits = 3)) seconds].")

    print(" > Energy storage vars and constraints ... ")
    tep = @elapsed EnergyStorage.stochastic_capex_model!(sys, mod)
    println(" ok [$(round(tep, digits = 3)) seconds].")

    print(" > Transmission vars and constraints ... ")
    tep = @elapsed Transmission.stochastic_capex_model!(sys, mod)
    println(" ok [$(round(tep, digits = 3)) seconds].")

    print(" > Policy vars and constraints ... ")
    tep = @elapsed Policies.stochastic_capex_model!(sys, mod)
    println(" ok [$(round(tep, digits = 3)) seconds].")

    print(" > Objective function ... ")
    tep = @elapsed @expression(mod, eTotalCost, sum(mod[:eCostPerTp][t]*t.weight for t in sys.T) 
                                                    + mod[:eCostPerPeriod])
    println(" ok [$(round(tep, digits = 3)) seconds].")

    @objective(mod, Min, eTotalCost)

    # Print model to a text file if print_model==true. 
    # By default, it is print_model is false.
    # Useful for debugging purposes.
    if print_model
        filename = "model.txt"
        println(" > $filename printed")
        open(joinpath(main_dir, "outputs", filename), "w") do f
            println(f, m)
        end
    end

    println("> JuMP model completed. Starting optimization: ")
                    
    optimize!(mod)

    print("\n")

    mod_status = termination_status(mod)
    mod_obj = round(value(eTotalCost); digits=3) 
    println("> Optimization status: $mod_status")
    println("> Objective function value: $mod_obj")
    return mod

end

"""
Exports results of the stochastic capacity expansion model to CSV files.
"""
function print_stochastic_capex_results(sys, mod:: Model; main_dir = pwd()) 

    # Define the outputs directory
    outputs_dir = joinpath(main_dir, "outputs")

    println("> Printing files in $outputs_dir")
    
    Generators.toCSV_stochastic_capex(sys, mod, outputs_dir)
    EnergyStorage.toCSV_stochastic_capex(sys, mod, outputs_dir)
    Transmission.toCSV_stochastic_capex(sys, mod, outputs_dir)

    # Print cost expressions
    filename = "costs_itemized.csv"
    costs =  DataFrame(component  = ["CostPerTimepoint", "CostPerPeriod", "TotalCost"], 
                            cost  = [   value(sum(t.weight * mod[:eCostPerTp][t] for t in sys.T)), 
                                        value(mod[:eCostPerPeriod]), 
                                        value(mod[:eTotalCost])]) 
    CSV.write(joinpath(outputs_dir, filename), costs)
    println(" > $filename printed.")

end

function run_stocapex(; main_dir = pwd(), 
                             solver = Mosek.Optimizer,
                             print_model = false)
    
    sys = init_system(main_dir = main_dir)
    mod = solve_stochastic_capex_model(sys; main_dir = main_dir, solver = solver)
    print_stochastic_capex_results(sys, mod; main_dir = main_dir)

    return sys, mod
end

end # module CATEX
