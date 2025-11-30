"""
Generators module defines structure and functions for handling generator data in a power system.
"""
module Generators

# Use Julia standard libraries and third-party packages
using NamedArrays

# Use internal modules
using ..utils

# Export variables and functions
export Generator, load_data

"""
Generator represents a generation project or existing generator in the power system.
# Fields:
- gen_id: ID of the generation project
- gen_tech: technology type of the generator, for example, "solar", "wind", "gas_cc". It could be any string.
- bus_id: ID of the bus where the generator is connected to.
- c2: quadratic coefficient of the generation cost function (USD/MW²)
- c1: linear coefficient of the generation cost function (USD/MW)
- c0: fixed coefficient of the generation cost function (USD)
- invest_cost: investment cost per MW of capacity (USD/MW)
- exist_cap: pre-existing capacity of the generator (MW)
- cap_limit: maximum build capacity of the generator (MW)
- var_om_cost: variable operation and maintenance cost (USD/MW)
"""
struct Generator
    gen_id:: String
    gen_tech:: String
    bus_id:: String
    c2:: Float64
    c1:: Float64
    c0:: Float64
    invest_cost:: Float64
    exist_cap:: Float64
    cap_limit:: Float64
    var_om_cost:: Float64
end

"""
Load generator data from a CSV file and return it as a NamedArray of Generator structures.
"""
function load_data(inputs_dir:: String):: NamedArray{Generator}

    # Get a list of instances of generators structures
    gens = to_Structs(Generator, inputs_dir, "generators.csv")

    # Get a list of the generator IDs
    G = getfield.(gens, :gen_id)

    # Transform gens into NamedArray, so we can access generators by their IDs
    gens = NamedArray(gens, (G), :gen_id)

    return gens
end

end # module Generators