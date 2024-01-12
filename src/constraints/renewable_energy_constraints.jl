# REopt®, Copyright (c) Alliance for Sustainable Energy, LLC. See also https://github.com/NREL/REopt.jl/blob/master/LICENSE.
"""
	add_re_elec_constraints(m,p)

Function to add minimum and/or maximum renewable electricity (as percentage of load) constraints, if specified by user.

!!! note
    When a single outage is modeled (using outage_start_time_step), renewable electricity calculations account for operations during this outage (e.g., the critical load is used during time_steps_without_grid)
	On the contrary, when multiple outages are modeled (using outage_start_time_steps), renewable electricity calculations reflect normal operations, and do not account for expected operations during modeled outages (time_steps_without_grid is empty)
"""
#Renewable electricity constraints
function add_re_elec_constraints(m,p)
	if !isnothing(p.s.site.renewable_electricity_min_fraction)
		@constraint(m, MinREElecCon, m[:AnnualREEleckWh] >= p.s.site.renewable_electricity_min_fraction*m[:AnnualEleckWh])
	end
	if !isnothing(p.s.site.renewable_electricity_max_fraction)
		@constraint(m, MaxREElecCon, m[:AnnualREEleckWh] <= p.s.site.renewable_electricity_max_fraction*m[:AnnualEleckWh])
	end
end


"""
	add_re_elec_calcs(m,p)

Function to calculate annual electricity demand and annual electricity demand derived from renewable energy.

!!! note
    When a single outage is modeled (using outage_start_time_step), renewable electricity calculations account for operations during this outage (e.g., the critical load is used during time_steps_without_grid)
	On the contrary, when multiple outages are modeled (using outage_start_time_steps), renewable electricity calculations reflect normal operations, and do not account for expected operations during modeled outages (time_steps_without_grid is empty)
"""
# Renewable electricity calculation
function add_re_elec_calcs(m,p)

	# TODO: When steam turbine implemented, uncomment code below, replacing p.TechCanSupplySteamTurbine, p.STElecOutToThermInRatio with new names
	# # Steam turbine RE elec calculations 
	# if isempty(p.steam)
	# 	SteamTurbineAnnualREEleckWh = 0 
    # else  
	# 	# Note: SteamTurbine's input p.tech_renewable_energy_fraction = 0 because it is actually a decision variable dependent on fraction of steam generated by RE fuel
	# 	SteamTurbinePercentREEstimate = @expression(m,
	# 		sum(p.tech_renewable_energy_fraction[tst] for tst in p.TechCanSupplySteamTurbine) / length(p.TechCanSupplySteamTurbine)
	# 	)
	# 	# Note: Steam turbine battery losses, curtailment, and exported RE terms are only accurate if all techs that can supply ST 
	# 	#		have equal RE%, otherwise it is an approximation because the general equation is non linear. 
	# 	SteamTurbineAnnualREEleckWh = @expression(m,p.hours_per_time_step * (
	# 		p.STElecOutToThermInRatio * sum(m[:dvThermalToSteamTurbine][tst,ts]*p.tech_renewable_energy_fraction[tst] for ts in p.time_steps, tst in p.TechCanSupplySteamTurbine) # plus steam turbine RE generation 
	# 		- sum(m[:dvProductionToStorage][b,t,ts] * SteamTurbinePercentREEstimate * (1-p.s.storage.attr[b].charge_efficiency*p.s.storage.attr[b].discharge_efficiency) for t in p.steam, b in p.s.storage.types.elec, ts in p.time_steps) # minus battery storage losses from RE from steam turbine
	# 		- sum(m[:dvCurtail][t,ts] * SteamTurbinePercentREEstimate for t in p.steam, ts in p.time_steps) # minus curtailment.
	# 		- (1-p.s.site.include_exported_renewable_electricity_in_total)*sum(m[:dvProductionToGrid][t,u,ts]*SteamTurbinePercentREEstimate for t in p.steam,  u in p.export_bins_by_tech[t], ts in p.time_steps) # minus exported RE from steam turbine, if RE accounting method = 0.
	# 	))
	# end

	m[:AnnualREEleckWh] = @expression(m,p.hours_per_time_step * (
			sum((p.production_factor[t,ts] * p.levelization_factor[t] * m[:dvRatedProduction][t,ts] #total RE elec generation, excl steam turbine
				- m[:dvCurtail][t,ts] #minus curtailment
				- sum(m[:dvProductionToStorage][b,t,ts]
					*(1-p.s.storage.attr[b].charge_efficiency*p.s.storage.attr[b].discharge_efficiency)
					for b in p.s.storage.types.elec)) #minus battery efficiency losses
				* p.tech_renewable_energy_fraction[t]
				for t in p.techs.elec, ts in p.time_steps
			)
			- (1 - p.s.site.include_exported_renewable_electricity_in_total) *
			sum(m[:dvProductionToGrid][t,u,ts]*p.tech_renewable_energy_fraction[t] 
				for t in p.techs.elec,  u in p.export_bins_by_tech[t], ts in p.time_steps
			) # minus exported RE, if RE accounting method = 0.
		)
		# + SteamTurbineAnnualREEleckWh  # SteamTurbine RE Elec, already adjusted for p.hours_per_time_step
	)		
    # Note: if battery ends up being allowed to discharge to grid, need to make sure only RE that is being consumed onsite is counted so battery doesn't become a back door for RE to grid.
	# Note: calculations currently do not ascribe any renewable energy attribute to grid-purchased electricity

	m[:AnnualEleckWh] = @expression(m,p.hours_per_time_step * (
		 	# input electric load
			sum(p.s.electric_load.loads_kw[ts] for ts in p.time_steps_with_grid) 
			+ sum(p.s.electric_load.critical_loads_kw[ts] for ts in p.time_steps_without_grid)
			# tech electric loads
			# + sum(m[:dvThermalProduction][t,ts] for t in p.ElectricChillers, ts in p.time_steps )/ p.ElectricChillerCOP # electric chiller elec load
			# + sum(m[:dvThermalProduction][t,ts] for t in p.AbsorptionChillers, ts in p.time_steps )/ p.AbsorptionChillerElecCOP # absorportion chiller elec load
			# + sum(p.GHPElectricConsumed[g,ts] * m[:binGHP][g] for g in p.GHPOptions, ts in p.time_steps) # GHP elec load
		)
	)
	nothing
end