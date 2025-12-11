module Policies 

# Use Julia standard libraries and third-party packages
using CSV, DataFrames, JuMP

# Use internal modules
using ..Utils

# Export variables and functions
export Policy, load_data, stochastic_capex_model!


"""
Policy struct to hold policy parameters, additional restrictions, etc for the power system.
# Fields:
- budget: total budget available for investments
- bus_angle_diff: maximum allowable bus angle difference (in radians)
- max_CO2_emissions: maximum allowable CO2 emissions (in tons) (currently commented out)
"""
struct Policy
    # budget:: Float64
    # max_diffangle:: Float64
    # max_CO2_emissions:: Float64
end

function load_data(inputs_dir:: String):: Policy

    # Read policies from CSV files
    # It is suggested to keep policies in different files as they can have different formats
    # or indices. For example, budget is a single value, while max CO2 emissions could be 
    # defined for certain time periods.
    
    #max_diffangle = CSV.read(joinpath(inputs_dir, filename), DataFrame;
    #                        types=[Float64])
    #max_diffangle = max_diffangle[1, :deg] * π/180 # convert degrees to radians
    #println(" ok")

    return Policy()
    # return Policy(budget, bus_angle_diff, max_CO2_emissions)
end

function stochastic_capex_model!(sys, mod:: Model)

    N = @views sys.N
    S = @views sys.S
    T = @views sys.T
    policies = @views sys.policies
                   
end

end # module Policies