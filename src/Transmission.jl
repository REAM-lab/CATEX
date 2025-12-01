"""
Transmission Module for handling bus data in a power system.
"""
module Transmission

# Use Julia standard libraries and third-party packages
using NamedArrays, JuMP

# Use internal modules
using ..Utils

# Export variables and functions
export Bus, Line, load_data, stochastic_capex_model!

"""
Bus represents a bus or node in the power system.
# Fields:
- bus_id: ID of the bus
- kv: voltage level of the bus in kilovolts
- type: type of the bus (e.g., Substation). It could be any string.
- lat: latitude of the bus location
- lon: longitude of the bus location
- slack: boolean (true or false) indicating if the bus is a slack bus. 
         At least there must be one slack bus in the system.
"""
struct Bus
    bus_id:: String
    kv:: Float64
    type:: String
    lat:: Float64
    lon:: Float64
    slack:: Bool
end

"""
Load represents the load demand at a specific bus, scenario, and timepoint.
# Fields:
- bus_id: ID of the bus
- sc_id: ID of the scenario
- t_id: ID of the timepoint
- load: load demand in megawatts (MW)
"""
struct Load
    bus_id:: String
    sc_id:: String
    tp_id:: String
    load:: Float64
end

"""
Line is a π-model transmission line connecting two buses in the power system.
# Fields:
- line_id: ID of the line
- from_bus: ID of the bus where the line starts
- to_bus: ID of the bus where the line ends
- rate: thermal rating of the line (MW)
- r: resistance of the line (p.u.)
- x: reactance of the line (p.u.)
- g: conductance of the shunt at one extreme of the line (p.u.)
- b: susceptance of the shunt at one extreme of the line (p.u.)
"""
struct Line
    line_id:: String
    from_bus:: String
    to_bus:: String
    rate:: Float64
    r:: Float64
    x:: Float64
    g:: Float64
    b:: Float64
end

"""
Load bus data from a CSV file and return it as a NamedArray of Bus structures.
"""
function load_data(inputs_dir:: String):: Tuple{NamedArray{Bus}, NamedArray{Union{Missing, Float64}}, NamedArray{Line}}

    # Get a list of Bus structures
    buses = to_Structs(Bus, inputs_dir, "buses.csv")

    # Get a list of the bus IDs
    N = getfield.(buses, :bus_id)

    # Transform buses into NamedArray, so we can access buses by their IDs
    buses = NamedArray(buses, (N))

    # Load load data
    l = to_Structs(Load, inputs_dir, "loads.csv")
    
    # Transform load data into a multidimensional NamedArray
    load = to_multidim_NamedArray(l, [:bus_id, :sc_id, :tp_id], :load)

    # Get a list of Line structures
    lines = to_Structs(Line, inputs_dir, "lines.csv")

    # Get a list of the line IDs
    L = getfield.(lines, :line_id)

    # Transform lines into NamedArray, so we can access lines by their IDs
    lines = NamedArray(lines, (L))

    return buses, load, lines
end

"""
`build_admittance_matrix(N:: Vector{String}, lines:: Vector{Any}; include_shunts=false) 
                         :: NamedArray{ComplexF64}`

This function builds the admittance matrix of any power system.

## Args:
    - buses: a vector containing the buses of the system. For example, buses=["san_diego", "lima"]
    - lines: A vector or list of instances of the structure Line. The struct Line must
             have the following attributes from_bus, to_bus, r, x, g, b. Note that g and b are the 
             conductance and susceptance, respectively, in one extreme of the line.

## Optional Args:
    - include_shunts: if yes, the conductance (g) and susceptance (b) are considered in the calculation of
                      the admittance matrix.

## Returns:
    - Y: a NamedArray that contains the admittance matrix. Y is commonly defined as a pure array, 
         but here we use a NamedArray, so the user can access entries of Y by two options:
         using strings like "san_diego", "lima", or numerical indices 1, 2 .. 
        for example: these combinations to access Y data work:
            Y["san_diego", "lima"]   = 0+0im
            Y["lima", "san_diego"]  = 0+0im
            Y["lima", "lima"] = 0+0im
            Y["lima", "lima"] =  0+0im 

TODO: add hint type to the lines argument. We may need to import the Line Struct.

"""
function build_admittance_matrix(N:: NamedArray{Bus}, lines; include_shunts=false) :: NamedArray{ComplexF64}

    # Define admittance matrix (actually it is NamedArray)
    # Note: we opt to use a NamedArray so N does not have to be a vector of numbers
    #       then, the user has more flexibility to access the admittance matrix, for example, Y["sandiego", "lima"]
    num_buses = length(N)
    bus_ids = names(N, 1)
    Y =  NamedArray( zeros(Complex, num_buses, num_buses), (bus_ids, bus_ids), (:bus_id, :bus_id))
    
    for line in lines
        # Calculate branch admittance
        z = complex(line.r, line.x)
        y = 1.0 / z
        
        # Extract from_bus and to_bus from line instance
        from_bus = line.from_bus
        to_bus = line.to_bus

        # Off-diagonal elements. Y_ij = -y_ij
        Y[from_bus, to_bus] -= y
        Y[to_bus, from_bus] -= y

        # Diagonal elements. Note: Y_ii = y_1i + y2i + ... + yii + ...
        Y[from_bus, from_bus] += y
        Y[to_bus, to_bus] += y
    end

    if include_shunts
        for line in lines
            # Calculate shunt admittance 
            y_shunt = complex(line.g, line.b)

            # Extract bus 
            from_bus = line.from_bus
            to_bus = line.to_bus
            
            # Add shunt admittance to the current admittance matrix
            Y[from_bus, from_bus] += y_shunt
            Y[to_bus, to_bus] += y_shunt
        end
    end

    return Y
end


"""
    - maxFlow: a dictionary that contains maximum power transfer ber bus. For example:
        Dict{String, Float64} with 2 entries:
            "san_diego" => 500
            "lima"    => 1000

"""
function get_maxFlow(N, lines):: NamedArray{Float64}

    num_buses = length(N)
    bus_ids = names(N, 1)
    maxFlow =  NamedArray( zeros(Float64, num_buses), (bus_ids), :bus_id )

    for line in lines
        # Extract from_bus and to_bus from line instance
        from_bus = line.from_bus
        to_bus = line.to_bus
        rate = line.rate
        
        maxFlow[from_bus] += rate
        maxFlow[to_bus] += rate

    end
    return maxFlow
end

function stochastic_capex_model!(mod:: Model, sys, pol)

    # Extract system data
    N = sys.N
    L = sys.L
    S = sys.S
    T = sys.T
    load = sys.load

    # Build admittance matrix and maxFlow
    Y = build_admittance_matrix(N, L)
    B = imag(Y) # take susceptance matrix
    maxFlow = get_maxFlow(N, L)

    # Get slack bus
    slack_bus = N[ findfirst([n.slack == true for n in N]) ]

    # Define bus angle variables
    @variable(mod, THETA[N, S, T]) 

    # Fix bus angle of slack bus
    fix.(THETA[slack_bus, S, T], 0)

    # Extracting expressions from other submodules
    eGenAtBus = mod[:eGenAtBus]
    
    # DC Power flow transfered from each bus
    @expression(mod, eFlowAtBus[n ∈ N, s ∈ S, t ∈ T], 
                    sum(B[n.bus_id, m.bus_id] * (THETA[n, s, t] - THETA[m, s, t]) for m in N))

    # Maximum power transfered at each bus
    @constraint(mod, cMaxFlowAtBus[n ∈ N, s ∈ S, t ∈ T],
                    -maxFlow[n.bus_id] ≤ eFlowAtBus[n, s, t] ≤ maxFlow[n.bus_id])

    # Power balance at each bus
    @constraint(mod, cGenBalance[n ∈ N, s ∈ S, t ∈ T], 
                    eGenAtBus[n, s, t] ≥ load[n.bus_id, s.sc_id, t.tp_id] + eFlowAtBus[n, s, t])    

end
   
end # module Transmission