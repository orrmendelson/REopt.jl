# *********************************************************************************
# REopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

struct ExistingBoiler <: AbstractThermalTech  # useful to create AbstractHeatingTech or AbstractThermalTech?
    max_kw::Real
    efficiency::Real
    fuel_cost_series::AbstractVector{<:Real}
end


"""
`ExistingBoiler` is an optional REopt input with the following keys:
```julia
    max_heat_demand_kw::Real=0,
    production_type::String = "hot_water",
    chp_prime_mover::String = "",
    max_thermal_factor_on_peak_load::Real = 1.25,
    efficiency::Real = 0.0,
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = 0.0,
    time_steps_per_hour::Int = 1
```

!!! note "Max ExistingBoiler size" 
    The maximum size [kW] of the `ExistingBoiler` will be set based on the peak heat demand as follows:
    ```julia 
    max_kw = max_heat_demand_kw * max_thermal_factor_on_peak_load
    ```

!!! note "ExistingBoiler operating costs" 
    The `ExistingBoiler` default operating cost is zero. Please provide the `fuel_cost_per_mmbtu` field
    for the `ExistingBoiler` if you want non-zero BAU heating costs. The `fuel_cost_per_mmbtu` can be
    a scalar, a list of 12 monthly values, or a time series of values for every time step.

!!! note "Determining `efficiency`" 
    Must supply either: `efficiency`, `chp_prime_mover`, or `production_type`.
    
    If `efficiency` is not supplied (or if set to 0.0), the `production_type` and `efficiency` will be determined based on the 
    `chp_prime_mover` (one of ["recip_engine", "micro_turbine", "combustion_turbine", "fuel_cell"]) as follows:
    ```julia    
    production_type_by_chp_prime_mover = Dict(
            "recip_engine" => "hot_water",
            "micro_turbine" => "hot_water",
            "combustion_turbine" => "steam",
            "fuel_cell" => "hot_water"
    )
    efficiency_defaults = Dict(
        "hot_water" => 0.8,
        "steam" => 0.75
    )
    ```

"""
function ExistingBoiler(;
    max_heat_demand_kw::Real=0,
    production_type::String = "hot_water",
    chp_prime_mover::String = "",
    max_thermal_factor_on_peak_load::Real = 1.25,
    efficiency::Real = 0.0,
    fuel_cost_per_mmbtu::Union{<:Real, AbstractVector{<:Real}} = 0.0,
    time_steps_per_hour::Int = 1
    # fuel_type::String = "natural_gas"  # "restrict_to": ["natural_gas", "landfill_bio_gas", "propane", "diesel_oil"],
    # can_supply_steam_turbine::Bool,
    # emissions_factor_lb_CO2_per_mmbtu::Real,
)
    @assert production_type in ["steam", "hot_water"]

    if sum(fuel_cost_per_mmbtu) ≈ 0.0
        @warn "The ExistingBoiler.fuel_cost_per_mmbtu sums to zero. No fuel costs will be accounted for."
    end

    production_type_by_chp_prime_mover = Dict(
        "recip_engine" => "hot_water",
        "micro_turbine" => "hot_water",
        "combustion_turbine" => "steam",
        "fuel_cell" => "hot_water"
    )

    fuel_cost_per_kwh = fuel_cost_per_mmbtu / KWH_PER_MMBTU
    fuel_cost_series = per_hour_value_to_time_series(fuel_cost_per_kwh, time_steps_per_hour, 
                                                     "ExistingBoiler.fuel_cost_per_mmbtu")

    efficiency_defaults = Dict(
        "hot_water" => 0.8,
        "steam" => 0.75
    )

    if efficiency == 0.0
        if !isempty(chp_prime_mover)
            production_type = production_type_by_chp_prime_mover[chp_prime_mover]
        end
        efficiency = efficiency_defaults[production_type]
    end

    max_kw = max_heat_demand_kw * max_thermal_factor_on_peak_load

    ExistingBoiler(
        max_kw,
        efficiency,
        fuel_cost_series
    )
end
