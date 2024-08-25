######################################################
# Readme:
######################################################
# 1. to execute:
# 1.1 open terminal and type julia ()+ enter)
# 1.2 change folder:
#        cd("C:/dev/enerwiz/reopt_julia/REopt.jl/")
# 1.3 On first time of running julia in this folder - use:
#        ] activate .
#        instantiate
# 2. On first time of running julia in this folder - Uncomment the "import" lines below
# 3. Execute by:
#        include("run_reopt.jl")
######################################################

# Import lines:
# import Pkg; Pkg.add("REopt")
# import Pkg; Pkg.add("Cbc")
# import Pkg; Pkg.add("JuMP")
# import Pkg; Pkg.add("JSON")

using Dates
using JSON

scenario_path = "./test/scenarios/"
# uncomment one of lines to run the scenario:
# scenario = "pv_storage"
scenario = "pv_storage_no_tariff_01"
# scenario = "no_techs"
# scenario = "pv"
# scenario = "emissions"
# scenario = "flatloads"
# scenario = "incentives"
# scenario = "multiple_pvs"

ENV["NREL_DEVELOPER_API_KEY"]="H8rvw0EEgCW0OVhCefU4lQT7reOfzVhEalApABly"
using REopt, JuMP, Cbc

m = Model(Cbc.Optimizer)
results = run_reopt(m, "$(scenario_path)$(scenario).json")

# Save the results to the JSON file
timestamp = Dates.format(now(), "yyyy-mm-dd HH-MM-SS")
filename = "./OUTPUT/$(timestamp) output - $(scenario).json"
open(filename, "w") do file
    write(file, JSON.json(results))
end