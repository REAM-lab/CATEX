module EnergyStorages

# Use Julia standard libraries and third-party packages
using NamedArrays

# Use internal modules
using ..Utils

# Export variables and functions
export EnergyStorage, load_data

"""
Energy storage represents an energy storage system in the power system.
# Fields:
- es_id: ID of the storage system
- es_tech: technology type of the storage system, for example, "battery", "pumped_hydro". It could be any string.
- bus_id: ID of the bus where the storage system is connected to.
- invest_cost: investment cost per MW of power capacity (USD/MW)
- exist_power_cap: pre-existing power capacity of the storage system (MW)
- exist_energy_cap: pre-existing energy capacity of the storage system (MWh)
- var_om_cost: variable operation and maintenance cost (USD/MW)
- efficiency: round-trip efficiency of the storage system (between 0 and 1)
- duration: duration of the storage system at full power (hours)
"""
struct EnergyStorage 
    es_id:: String
    es_tech:: String
    bus_id:: String
    invest_cost:: Float64
    exist_power_cap:: Float64
    exist_energy_cap:: Float64
    var_om_cost:: Float64
    efficiency:: Float64
    duration:: Float64
end

function load_data(inputs_dir:: String):: NamedArray{EnergyStorage}
    # Get a list of instances of EnergyStorage structures
    ess = to_Structs(EnergyStorage, inputs_dir, "energy_storages.csv")

    # Get a list of the storage IDs
    E = getfield.(ess, :es_id)

    # Transform storage into NamedArray, so we can access storages by their IDs
    ess = NamedArray(ess, (E))

    return ess
end
end # module EnergyStorage