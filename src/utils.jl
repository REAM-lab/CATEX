module utils

using DataFrames, JuMP, CSV

export to_stacked_Dict, to_Dict, to_tupled_Dict, to_Df, build_admittance_matrix, to_Structs

function to_Structs(structure::DataType, inputs_dir:: String, filename:: String):: Vector{structure}
    file_dir = joinpath(inputs_dir, filename)
    struct_names = fieldnames(structure)
    struct_types = fieldtypes(structure)

    first_csvlines = CSV.File(joinpath(inputs_dir, filename); limit=1)
    csv_header = Tuple(propertynames(first_csvlines))

    @assert csv_header == struct_names """Column names of $filename does not match the fields of the structure $structure."""

    df = CSV.read(file_dir, DataFrame; types=Dict(zip(struct_names, struct_types)))
    cols = Tuple(df[!, col] for col in names(df))
    V = structure.(cols...)    
    
    return V
end

function to_multidim_NamedArray(structures:: Vector{T}, dims:: Vector{Symbol}, value:: Symbol):: NamedArray{Union{Missing, Float64}} where {T} 
  
    vals_in_dim = [unique(getfield.(structures, d)) for (i, d) in enumerate(dims)]
    
    arr = Array{Union{Missing, Float64}}(missing, length.(vals_in_dim)...)
    arr = NamedArray(arr, vals_in_dim, dims)

    for s in structures
        arr[getfield.(Ref(s), dims)...] = getfield(s, value)
    end

    return arr
end

"""
Rehashing and Resizing: When a Dict grows beyond its current allocated capacity, 
it needs to be resized, which often involves rehashing all existing key-value pairs 
and moving them to a larger memory location. This process can be computationally expensive, 
especially with a large number of elements
"""
function to_stacked_Dict(data:: DataFrame, key:: String, value:: String)
    col_key = data[!, Symbol(key)]
    col_value = data[!, Symbol(value)]

    tuples = collect(zip(col_key, col_value))

    stacked_dict = Dict()

    for (key, value) in tuples
        if haskey(stacked_dict, key)
            push!(stacked_dict[key], value)
        else
            stacked_dict[key] = [value]
        end
    end
    
    return stacked_dict
end

function to_Dict(data:: DataFrame, key:: Symbol, value:: Symbol)
    return Dict(Pair.(data[:, key], data[:, value]))
end

function to_tupled_Dict(data:: DataFrame, keys:: Vector{Symbol}, value:: Symbol)
    col_keys = Tuple.(eachrow(data[:, keys]))
    col_value = data[:, value]
    return Dict(Pair.(col_keys, col_value))
end


"""
`to_Df(var_name:: JuMP.Containers.DenseAxisArray, header:: Vector, outputs_dir:: String, filename:: String; print_csv = true)`

This function returns a csv file with the numerical solution of a JuMP variable once the optimization has been finished.

## Args:
    - var_name: variable name defined in the JuMP model, e.g., GEN, CAP.
    - header:   a vector with headers for the dataframe. It should be consistent with the dimensions.
                For example, if it is GEN[G, TPS], then header is [:generation_project, :timepoint, :DispatchGen_MW]
    - dir_file: directory where the csv will be saved. It must include the name, for example: /Users/paul/Documents/CATSExpand/examples/toy_example1/dispatch.csv
## Returns:
    - A csv file in the specified directory.
"""
function to_Df(var_name:: JuMP.Containers.DenseAxisArray, header:: Vector, outputs_dir:: String, filename:: String; print_csv = true)
    dir_file = joinpath(outputs_dir, filename)
    df = DataFrame(Containers.rowtable(value, var_name; header = header))
    if print_csv
        CSV.write(dir_file, df)
        println(" > $filename printed.")
    end
    return df
end





end # ends utils module