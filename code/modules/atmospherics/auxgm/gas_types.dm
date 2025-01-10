/datum/gas/oxygen
	id = GAS_O2
	specific_heat = 20
	name = "Oxygen"
	oxidation_temperature = T0C - 100 // it checks max of this and fire temperature, so rarely will things spontaneously combust
	powermix = 1
	heat_penalty = 1
	transmit_modifier = 1.5

/datum/gas/oxygen/generate_TLV()
	return new/datum/tlv(16, 19, 40, 50)

/datum/gas/nitrogen
	id = GAS_N2
	specific_heat = 20
	name = "Nitrogen"
	powermix = -1
	heat_penalty = -1.5
	fire_burn_rate = 1
	fire_temperature = 2300
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_nitro",
			alert_type = /atom/movable/screen/alert/not_enough_nitro
		),
		too_much_alert = list(
			alert_category = "too_much_nitro",
			alert_type = /atom/movable/screen/alert/too_much_nitro
		)
	)

/datum/gas/carbon_dioxide //what the fuck is this?
	id = GAS_CO2
	specific_heat = 30
	name = "Carbon Dioxide"
	powermix = 1
	heat_penalty = 0.1
	powerloss_inhibition = 1
	breath_results = GAS_O2
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_co2",
			alert_type = /atom/movable/screen/alert/not_enough_co2
		),
		too_much_alert = list(
			alert_category = "too_much_co2",
			alert_type = /atom/movable/screen/alert/too_much_co2
		)
	)
	fusion_power = 3
	enthalpy = -393500

/datum/gas/carbon_dioxide/generate_TLV()
	return new/datum/tlv(-1, -1, 5, 10)

/datum/gas/plasma
	id = GAS_PLASMA
	specific_heat = 200
	name = "Plasma"
	gas_overlay = "plasma"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	heat_penalty = 15
	transmit_modifier = 4
	powermix = 1
	fire_burn_rate = OXYGEN_BURN_RATE_BASE // named when plasma fires were the only fires, surely
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	enthalpy = FIRE_PLASMA_ENERGY_RELEASED // 3000000, 3 megajoules, 3000 kj
	breath_alert_info = list(
			not_enough_alert = list(
					alert_category = "not_enough_tox",
					alert_type = /atom/movable/screen/alert/not_enough_tox,
			),
			too_much_alert = list(
					alert_category = "too_much_tox",
					alert_type = /atom/movable/screen/alert/too_much_tox,
			)
	)

/datum/gas/nitrous_oxide
	id = GAS_NITROUS
	specific_heat = 40
	name = "Nitrous Oxide"
	gas_overlay = "nitrous_oxide"
	moles_visible = MOLES_GAS_VISIBLE * 2
	flags = GAS_FLAG_DANGEROUS
	fire_products = list(GAS_N2 = 1)
	oxidation_rate = 0.5
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100
	enthalpy = 81600
	heat_resistance = 6

/datum/gas/water_vapor
	id = GAS_H2O
	specific_heat = 40
	name = "Water Vapor"
	gas_overlay = "water_vapor"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 8
	heat_penalty = 8
	enthalpy = -241800 // FIRE_HYDROGEN_ENERGY_RELEASED is actually what this was supposed to be
	powermix = 1
	breath_reagent = /datum/reagent/water


/datum/gas/pluoxium
	id = GAS_PLUOXIUM
	specific_heat = 80
	name = "Pluoxium"
	fusion_power = 10
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 25 // it is VERY stable
	oxidation_rate = 8 // when it can oxidize, it can oxidize a LOT
	enthalpy = -2000000 // but it reduces the heat output a great deal (plasma fires add 3000000 per mole)
	powermix = -1
	heat_penalty = -1
	transmit_modifier = -5
	heat_resistance = 3
	price = 6

/datum/gas/pluoxium/generate_TLV()
	return new/datum/tlv(-1, -1, 5, 6)

/datum/gas/tritium
	id = GAS_TRITIUM
	specific_heat = 10
	name = "Tritium"
	gas_overlay = "tritium"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 1
	powermix = 1
	heat_penalty = 10
	transmit_modifier = 30
	fire_products = list(GAS_H2O = 1)
	enthalpy = 300000
	fire_burn_rate = 2
	fire_radiation_released = 50 // arbitrary number, basically 60 moles of trit burning will just barely start to harm you
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 50
	price = 7

/datum/gas/nitryl
	id = GAS_NITRYL
	specific_heat = 20
	name = "Nitrogen dioxide"
	gas_overlay = "nitryl"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 15
	fire_products = list(GAS_N2 = 0.5)
	enthalpy = 33200
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 50
	price = 3

/datum/gas/hypernoblium
	id = GAS_HYPERNOB
	specific_heat = 2000
	name = "Hyper-noblium"
	gas_overlay = "freon"
	moles_visible = MOLES_GAS_VISIBLE
	price = 50

/datum/gas/bz
	id = GAS_BZ
	specific_heat = 20
	name = "BZ"
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 8
	powermix = 1
	heat_penalty = 5
	enthalpy = FIRE_CARBON_ENERGY_RELEASED // it is a mystery
	transmit_modifier = -2
	radioactivity_modifier = 5
	price = 3

/datum/gas/stimulum
	id = GAS_STIMULUM
	specific_heat = 5
	odor = "the color blue" // fast
	odor_strength = 10
	name = "Stimulum"
	fusion_power = 7
	price = 25

/datum/gas/constricted_plasma //NSV13 - words C++ monstermos expects 14 gas types to exist, we only had 13
	id = "constricted_plasma"
	specific_heat = 250
	name = "Constricted plasma"
	gas_overlay = "constricted_plasma"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS

/datum/gas/nucleium //NSV13
	id = "nucleium"
	specific_heat = 450 //jesus god why
	name = "Nucleium"
	gas_overlay = "nucleium"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
