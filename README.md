# :zap:CATEX:zap:

Welcome! This repository contains CATEX—**CA**lifornia **T**ransmission System **EX**pansion, a Julia package for modeling capacity expansion and operations optimization. Originally developed for the state of California, but it can be adapted for other systems.

## Installation 

1. **Julia**: Make sure you have [Julia 1.12.2](https://julialang.org) (or greater) installed on your machine. 
   1. We recommend installing with `juliaup` to more easily manage multiple versions of Julia on your machine. To do so, please refer to the installation instructions listed on the [`juliaup` website](https://github.com/JuliaLang/juliaup).

2. **Optimizer**: Next install a [supported JuMP optimizer](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers), if you don't already have one on your machine. We recommend using [Mosek](https://github.com/MOSEK/Mosek.jl), given the size of this model.
3. **CATSX.jl**: Finally clone this repository and navigating into the CATEX directory.
    ```
    $ git clone https://github.com/REAM-lab/CATEX
    $ cd CATEX
    ```
    We use Julia's built in package manager `Pkg` to resolve package versioning and dependencies. Open a Julia 1.12.2 REPL and open the package manager by typing `]`. Then type `activate .`, to activate the project package environment, followed by `instantiate` to install all packages in the project `Manifest.toml` file. In the commandline this should look like:
    ```
    $ julia +release 
    julia> ]
    (@v1.12) pkg> activate .
    (CATEX) pkg> instantiate
    ```
4. **Verification**: We recommend verifying that CATEX was installed correctly by running an toy example system, `/examples/toy_example1`. This can be done by launching a Julia REPL and running
   ```julia
   julia> run_stocapex(main_dir=joinpath(pwd(), "examples", "toy_example1"))
   ```
