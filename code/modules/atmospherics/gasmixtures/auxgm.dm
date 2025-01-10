GLOBAL_LIST_INIT(hardcoded_gases, list(GAS_O2, GAS_N2, GAS_CO2, GAS_PLASMA)) //the main four gases, which were at one time hardcoded
GLOBAL_LIST_INIT(nonreactive_gases, typecacheof(list(GAS_O2, GAS_N2, GAS_CO2, GAS_PLUOXIUM, GAS_STIMULUM, GAS_NITRYL))) //unable to react amongst themselves

// Auxgm
// It's a send-up of XGM, like what baystation got.
// It's got the same architecture as XGM, but it's structured
// differently to make it more convenient for auxmos.

// Most important compared to TG is that it does away with hardcoded typepaths,
// which lead to problems on the auxmos end anyway. We cache the string value
// references on the Rust end, so no performance is lost here.

// Also allows you to add new gases at runtime

/datum/auxgm
	var/done_initializing = FALSE
	var/list/datums = list()
	var/list/specific_heats = list()
	var/list/names = list()
	var/list/visibility = list()
	var/list/overlays = list()
	var/list/flags = list()
	var/list/ids = list()
	var/list/typepaths = list()
	var/list/fusion_powers = list()
	var/list/TLV = list()
	var/list/breathing_classes = list()
	var/list/breath_results = list()
	var/list/breath_reagents = list()
	var/list/breath_reagents_dangerous = list()
	var/list/breath_alert_info = list()
	var/list/oxidation_temperatures = list()
	var/list/oxidation_rates = list()
	var/list/fire_temperatures = list()
	var/list/enthalpies = list()
	var/list/fire_products = list()
	var/list/fire_burn_rates = list()
	var/list/supermatter = list()
	var/list/groups_by_gas = list()
	var/list/groups = list()
	var/list/TLVs = list()
	var/list/odors = list()
	var/list/odor_strengths = list()
	var/list/prices = list()

/datum/gas
	var/id = ""
	var/specific_heat = 0
	var/name = ""
	var/gas_overlay = "" //icon_state in icons/effects/atmospherics.dmi
	var/color = "#ffff" // Tints the overlay by this color. Use instead of gas_overlay, usually (but not necessarily).
	var/odor = null // Odor string. Null means none; if not null, anyone who breathes the gas will smell it.
	var/odor_strength = INFINITY // How strong the odor is; minimal partial pressure to smell, so lower = more.
	var/moles_visible = null
	var/flags = NONE //currently used by canisters
	var/group = null // groups for scrubber/filter listing
	var/fusion_power = 0 // How much the gas destabilizes a fusion reaction
	var/breath_results = GAS_CO2 // what breathing this breathes out
	var/datum/reagent/breath_reagent = null // what breathing this adds to your reagents
	var/datum/reagent/breath_reagent_dangerous = null // what breathing this adds to your reagents IF it's above a danger threshold
	var/list/breath_alert_info = null // list for alerts that pop up when you have too much/not enough of something
	var/price = 0 // How much this gas is worth when sold, per mole.
	var/oxidation_temperature = null // temperature above which this gas is an oxidizer; null for none
	var/oxidation_rate = 1 // how many moles of this can oxidize how many moles of material
	var/fire_temperature = null // temperature above which gas may catch fire; null for none
	var/list/fire_products = null // what results when this gas is burned (oxidizer or fuel); null for none
	var/enthalpy = 0 // Standard enthalpy of formation in joules, used for fires
	var/fire_burn_rate = 1 // how many moles are burned per product released
	var/fire_radiation_released = 0 // How much radiation is released when this gas burns
	var/powermix = 0 // how much this gas contributes to the supermatter's powermix ratio
	var/heat_penalty = 0 // heat and waste penalty from having the supermatter crystal surrounded by this gas; negative numbers reduce
	var/transmit_modifier = 0 // bonus to supermatter power generation (multiplicative, since it's % based, and divided by 10)
	var/radioactivity_modifier = 0 // improves effect of transmit modifiers, must be from -10 to 10
	var/heat_resistance = 0 // makes the crystal more resistant against heat damage.
	var/powerloss_inhibition = 0 // Reduces how much power the supermatter loses each tick

/datum/gas/proc/generate_TLV()
	if(flags & GAS_FLAG_DANGEROUS)
		return new/datum/tlv/dangerous
	else
		return new/datum/tlv(-1, -1, 1000, 1000)

/datum/gas/proc/breath(partial_pressure, light_threshold, heavy_threshold, moles, mob/living/carbon/C, obj/item/organ/lungs/lungs)
	// This is only called on gases with the GAS_FLAG_BREATH_PROC flag. When possible, do NOT use this--
	// greatly prefer just adding a reagent. This is mostly around for legacy reasons.
	return null

/datum/auxgm/proc/add_gas(datum/gas/gas)
	var/g = gas.id
	if(g)
		datums[g] = gas
		specific_heats[g] = gas.specific_heat
		names[g] = gas.name
		TLVs[g] = gas.generate_TLV()
		if(gas.moles_visible)
			visibility[g] = gas.moles_visible
			overlays[g] = new /list(FACTOR_GAS_VISIBLE_MAX)
			for(var/i in 1 to FACTOR_GAS_VISIBLE_MAX)
				var/obj/effect/overlay/gas/overlay = new(gas.gas_overlay)
				overlay.color = gas.color
				overlay.alpha = i * 255 / FACTOR_GAS_VISIBLE_MAX
				overlays[g][i] = overlay
		else
			visibility[g] = 0
			overlays[g] = 0
		flags[g] = gas.flags
		ids[g] = g
		typepaths[g] = gas.type
		fusion_powers[g] = gas.fusion_power

		if(gas.breath_alert_info)
			breath_alert_info[g] = gas.breath_alert_info
		breath_results[g] = gas.breath_results
		if(gas.breath_reagent)
			breath_reagents[g] = gas.breath_reagent
		if(gas.breath_reagent_dangerous)
			breath_reagents_dangerous[g] = gas.breath_reagent_dangerous

		if(gas.oxidation_temperature)
			oxidation_temperatures[g] = gas.oxidation_temperature
			oxidation_rates[g] = gas.oxidation_rate
			if(gas.fire_products)
				fire_products[g] = gas.fire_products
			enthalpies[g] = gas.enthalpy
		else if(gas.fire_temperature)
			fire_temperatures[g] = gas.fire_temperature
			fire_burn_rates[g] = gas.fire_burn_rate
			if(gas.fire_products)
				fire_products[g] = gas.fire_products
			enthalpies[g] = gas.enthalpy
		if(gas.group)
			if(!(gas.group in groups))
				groups[gas.group] = list()
			groups[gas.group] += g
			groups_by_gas[g] = gas.group
		if(gas.odor)
			odor_strengths[g] = gas.odor_strength
			odors[g] = gas.odor
		if(gas.price)
			prices[g] = gas.price
		_auxtools_register_gas(gas)
		if(done_initializing)
			for(var/r in SSair.gas_reactions)
				var/datum/gas_reaction/R = r
				R.init_reqs()
			SSair.auxtools_update_reactions()

/datum/auxgm/New()
	for(var/gas_path in subtypesof(/datum/gas))
		var/datum/gas/gas = new gas_path
		add_gas(gas)
	for(var/breathing_class_path in subtypesof(/datum/breathing_class))
		var/datum/breathing_class/class = new breathing_class_path
		breathing_classes[breathing_class_path] = class
	done_initializing = TRUE
	finalize_gas_refs()

/datum/auxgm/proc/get_by_flag(flag)
	var/static/list/gases_by_flag
	if(!gases_by_flag)
		gases_by_flag = list()
	if(!(flag in gases_by_flag))
		gases_by_flag += flag
		gases_by_flag[flag] = list()
		for(var/g in flags)
			if(flags[g] & flag)
				gases_by_flag[flag] += g
	return gases_by_flag[flag]

GLOBAL_DATUM_INIT(gas_data, /datum/auxgm, new)

/obj/effect/overlay/gas
	icon = 'icons/effects/atmospherics.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE  // should only appear in vis_contents, but to be safe
	layer = FLY_LAYER
	appearance_flags = TILE_BOUND
	vis_flags = NONE

/obj/effect/overlay/gas/New(state)
	. = ..()
	icon_state = state
