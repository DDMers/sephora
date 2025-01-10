//Ship tech
/datum/techweb_node/ship_shield_tech
	id = "ship_shield_tech"
	display_name = "Experimental Shield Technology"
	description = "Highly experimental shield technology to vastly increase survivability in ships. Although Nanotrasen researchers have had access to this technology for quite some time, the incredible amount of power required to maintain shields has proven to be the greatest challenge in implementing them."
	design_ids = list("shield_fan", "shield_capacitor", "shield_modulator", "shield_interface", "shield_frame")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	export_price = 5000
	tech_tier = 5
	hidden = TRUE

/datum/techweb_node/ship_circuits
	id = "ship_circuitry"
	display_name = "Ship computer circuitry"
	description = "Allows you to rebuild the CIC when it inevitably gets bombed."
	prereq_ids = list("comptech")
	design_ids = list("helm_circuit", "navigation_console_circuit", "tactical_comp_circuit", "astrometrics_console", "dradis_console", "cargo_dradis_console")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	export_price = 1000
	tech_tier = 1

//Munitions tech
/datum/techweb_node/maa_circuits
	id = "maa_circuitry"
	display_name = "Munitions computer circuitry"
	description = "Allows you to rebuild Munitions computers after they suffer from gunpowder overdose."
	prereq_ids = list("comptech")
	design_ids = list("fighter_computer_circuit", "ordnance_comp_circuit", "fighter_launcher_circuit", "ammo_sorter_computer", "ammo_sorter", "munitions_computer_circuit")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	export_price = 1000
	tech_tier = 1

/datum/techweb_node/basic_torpedo_components
	id = "basic_torpedo_components"
	display_name = "Guided Munitions I"
	description = "Parts to construct basic explosive, guided ordnance."
	prereq_ids = list("explosive_weapons")
	design_ids = list("warhead", "missile_warhead", "decoy_warhead", "freight_warhead", "guidance_system", "propulsion_system", "iff_card")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	export_price = 2000
	tech_tier = 3

/datum/techweb_node/advanced_torpedo_components
	id = "advanced_torpedo_components"
	display_name = "Guided Munitions II"
	description = "More advanced torpedo components"
	prereq_ids = list("basic_torpedo_components", "exotic_ammo")
	design_ids = list("bb_warhead", "hellfire_warhead", "probe_warhead")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 7500
	tech_tier = 4

/datum/techweb_node/prototype_disruption_warheads
	id = "prototype_disruption_warheads"
	display_name = "Disruption Warhead Prototype"
	description = "Experimental Disruption Torpedo warheads, fresh from R&Ds reverse engineering department."
	prereq_ids = list("advanced_torpedo_components", "emp_adv")
	design_ids = list("proto_disruption_warhead")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 6500)
	export_price = 7000
	tech_tier = 4

/datum/techweb_node/advanced_ballistics
	id = "adv_ballistics"
	display_name = "Advanced Ballistics"
	description = "More guns means better guns... Right?"
	prereq_ids = list("ballistic_weapons")
	design_ids = list("naval_shell", "powder_bag", "naval_artillery_comp", "artillery_loader", "powder_loader", "payload_gate", "broadside_casing", "broadside_load", "broadside_packer", "plasma_core")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 5000
	tech_tier = 3

/datum/techweb_node/macro_ballistics
	id = "macro_ballistics"
	display_name = "Macro-Ballistics"
	description = "Asking important questions, like what if we made even bigger guns?"
	prereq_ids = list("adv_ballistics", "adv_plasma")
	design_ids = list("naval_shell_ap", "plasma_accelerant", "deck_gun_autorepair", "deck_gun_autoelevator", "gauss_rack_upgrade")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)
	export_price = 10000
	tech_tier = 4

/datum/techweb_node/missile_automation
	id = "missile_automation"
	display_name = "Automated Missile Construction"
	description = "Machines and tools to automate missile construction."
	prereq_ids = list("explosive_weapons")
	design_ids = list("missilebuilder", "slowconveyor", "missilewelder", "missilescrewer", "missilewirer", "missileassembler")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	export_price = 5000
	tech_tier = 3

//Fighter tech
/datum/techweb_node/countermeasure_charge
	id = "countermeasure_charge"
	display_name = "Countermeasure Charge Fabrication"
	description = "Instructional information on how to correctly wrap countermeasures."
	prereq_ids = list("fighter_tier1")
	design_ids = list("countermeasure_charge")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	export_price = 1000

/datum/techweb_node/fighter_fabrication
	id = "fighter_fabrication"
	display_name = "Fighter Construction"
	description = "Research into aircraft frames and how they can be turned into aircraft."
	design_ids = list("light_frame", "heavy_frame", "utility_frame")
	prereq_ids = list("base")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	export_price = 1000
	tech_tier = 1

/datum/techweb_node/fighter_tier1
	id = "fighter_tier1"
	display_name = "Standard Fighter Parts"
	description = "Research into the components that make up an aircraft and what makes them tick. Required for the construction of basic fighters."
	design_ids = list("fuel_tank", "avionics", "apu", "armour_plating", "targeting_sensor", "fighter_engine", "countermeasure_dispenser", "oxygenator","docking_computer", "fighter_battery", "refuel_kit", "cargo_hold", "resupply")
	prereq_ids = list("fighter_fabrication")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	export_price = 1000
	tech_tier = 2

/datum/techweb_node/fighter_tier2
	id = "fighter_tier2"
	display_name = "Advanced Fighter Parts"
	description = "Production of non-standard, upgraded fighter parts to upgrade the ship's fighter complement."
	design_ids = list("fuel_tank_tier2", "apu_tier2", "armour_plating_tier2", "fighter_engine_tier2", "oxygenator_tier2", "fighter_battery_tier2", "refuel_kit_tier2", "cargo_hold_tier2", "resupply_tier2")
	prereq_ids = list("fighter_tier1", "adv_engi")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 4000
	tech_tier = 3

/datum/techweb_node/fighter_tier3
	id = "fighter_tier3"
	display_name = "Experimental Fighter Parts"
	description = "Research into highly theoretical fighter parts which, if constructed, could guarantee air superiority."
	design_ids = list("fuel_tank_tier3", "apu_tier3", "armour_plating_tier3", "fighter_engine_tier3", "oxygenator_tier3", "fighter_battery_tier3", "refuel_kit_tier3", "cargo_hold_tier3", "resupply_tier3")
	prereq_ids = list("fighter_tier2", "bluespace_travel", "bluespace_power")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)
	export_price = 7500
	tech_tier = 4

/datum/techweb_node/fighter_guns_tier1
	id = "fightergun1"
	display_name = "Standard Fighter Weapons"
	description = "Production of standard fighter-based armaments."
	design_ids = list("ordnance_launcher", "fighter_missile_launcher", "primary_cannon")
	prereq_ids = list("fighter_tier1", "weaponry")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	export_price = 1000
	tech_tier = 2

/datum/techweb_node/fighter_guns_tier2
	id = "fightergun2"
	display_name = "Advanced Fighter Weapons"
	description = "Research into advanced ballistic fighter weapons."
	design_ids = list("ordnance_launcher_tier2","fighter_missile_launcher_tier2", "heavy_cannon")
	prereq_ids = list("fightergun1", "ballistic_weapons")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 2500
	tech_tier = 3

/datum/techweb_node/fighter_guns_tier3
	id = "fightergun3"
	display_name = "Experimental Fighter Weapons"
	description = "Researching of cutting edge missile launching equipment"
	design_ids = list("ordnance_launcher_tier3","fighter_missile_launcher_tier3")
	prereq_ids = list("fightergun2", "adv_weaponry")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 5000
	tech_tier = 4

/datum/techweb_node/fighter_mining
	id = "fightermining"
	display_name = "Aircraft Mining Equipment"
	description = "Reasearch into mounting exosuit-grade mining equipment to utility vessels."
	design_ids = list("r_cutter")
	prereq_ids = list("fighter_tier1", "adv_mining", "adv_plasma")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	export_price = 1000
	tech_tier = 3

/datum/techweb_node/autoinjector
	id = "autoinjector"
	display_name = "Autoinjector Medipens"
	description = "Research of instant reagent delivery into patient bloodstreams"
	design_ids = list("autoinjector")
	prereq_ids = list("adv_biotech","adv_surgery")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	export_price = 1500
	tech_tier = 4

/datum/techweb_node/xenoorgan_biotech
	id = "xenoorgan_bio"
	display_name = "Xeno-organ Biology"
	description = "Plasmaman, Ethereals, Lizardpeople... What makes our non-human crewmembers tick?"
	prereq_ids = list("adv_biotech")
	design_ids = list("limbdesign_felinid", "limbdesign_lizard", "limbdesign_plasmaman", "limbdesign_ethereal", "limbdesign_moth", "limbdesign_apid")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 6500)
	export_price = 9000
	tech_tier = 1

//Vehicle Hardpoint tech
/datum/techweb_node/vehicle_start
	id = "vehicle_start"
	display_name = "Mechanical Research"
	description = "Researching the possibility of expanding the usage behind those useless Tugs"
	design_ids = list("vehicle_engine_pathetic")
	prereq_ids = list("engineering")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
	export_price = 1000
	tech_tier = 1

/datum/techweb_node/vehicle_utility
	id = "vehicle_utility"
	display_name = "Vehicle Utilities"
	description = "Researching the value behind Bobbleheads and Tug Air Fresheners."
	design_ids = list("vehicle_crate_loader", "vehicle_cryo_stasis")
	prereq_ids = list("vehicle_start")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)
	export_price = 2000
	tech_tier = 1

/datum/techweb_node/vehicle_tier1
	id = "vehicle_tier1"
	display_name = "Standard Vehicle Parts"
	description = "Researching the strange spinning thingies found attached to the side of the Tug and what the loud rumbling box inside the Tug does."
	design_ids = list("vehicle_engine", "vehicle_tyres")
	prereq_ids = list("vehicle_start")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	export_price = 2500
	tech_tier = 1

/datum/techweb_node/vehicle_tier2
	id = "vehicle_tier2"
	display_name = "Advanced Vehicle Parts"
	description = "Researching the strange connection between drifting and a string of Murders caused by Janitors."
	design_ids = list("vehicle_engine_upgraded", "vehicle_tyres_upgraded")
	prereq_ids = list("vehicle_tier1")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	export_price = 3500
	tech_tier = 2

/datum/techweb_node/vehicle_tier3
	id = "vehicle_tier3"
	display_name = "Glorious Trukk Parts"
	description = "DA RED WUNS GO FASTA!!!"
	design_ids = list("vehicle_engine_maxupgrade", "vehicle_tyres_maxupgrade")
	prereq_ids = list("vehicle_tier2")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 5000
	tech_tier = 3

/// Munitions Upgrade for Engineering Borg
/datum/techweb_node/cyborg_upg_muni
	id = "cyborg_upg_muni"
	tech_tier = 4
	display_name = "Cyborg Upgrades: Munitions"
	description = "Munition related upgrades for cyborgs."
	prereq_ids = list("adv_robotics", "adv_engi" , "adv_ballistics")
	design_ids = list("borg_upgrade_muniapp")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	export_price = 5000

/// Munitions Upgrade for Energy Weapons
/datum/techweb_node/weapon_cooling
	id = "weapon_cooling"
	tech_tier = 4
	display_name = "Subspace Manipulation"
	description = "Experimental uses of subspace for more than just communications"
	prereq_ids = list("comptech" , "adv_engi" , "adv_power")
	design_ids = list("subspace_storage" , "subspace_cooler" , "heatsink")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)
	export_price = 5000
	hidden = FALSE //Todo, make this specific
