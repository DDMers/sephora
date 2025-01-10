/datum/supply_pack/munitions
	group = "Munitions"
	access_any = list(ACCESS_MUNITIONS, ACCESS_SYNDICATE_REQUISITIONS)
	crate_type = /obj/structure/closet/crate/secure/weapon

/datum/supply_pack/munitions/railgun
	name = "Naval Artillery Shells (x10)"
	desc = "A set of naval artillery shells to be fired by the eponymous weapon. Must be armed before firing. WARNING: HIGHLY EXPLOSIVE."
	cost = 2000
	contains = list(/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery,
					/obj/item/ship_weapon/ammunition/naval_artillery)
	crate_name = "Naval Artillery Shells"

/datum/supply_pack/munitions/cannonshot
	name = "Cannonballs (x10)"
	desc = "For munitions teams on a budget, cannonballs serve as a cheap but still somewhat effective ammunition for Naval Artillery. Made from the finest cutlery the NT fleet has to offer."
	cost = 1000
	contains = list(/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball,
					/obj/item/ship_weapon/ammunition/naval_artillery/cannonball)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "Captain Plasmasalt's finest cannonshot"

/datum/supply_pack/munitions/gunpowder
	name = "Powder bags (x10)"
	desc = "Naval Gunpowder bags for use in artillery weapons, WARNING: Volatile."
	cost = 1000
	contains = list(/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag,
					/obj/item/powder_bag)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "Captain Plasmasalt's finest gunpowder"

/datum/supply_pack/munitions/muni_pointer
	name = "Munitions Pinpointer"
	desc = "Clown spaced your turrets? MAA slipped and threw their pointer into the recycler? This is the solution to your problems!"
	cost = 5000 //Don't lose yours, MAA.
	contains = list(/obj/item/pinpointer/munitions)

/datum/supply_pack/munitions/muni_pointer/fill(obj/structure/closet/crate/C)
	if(prob(1))
		new /obj/item/pinpointer/munitions/not_puce(C)
	else
		new /obj/item/pinpointer/munitions(C)

/datum/supply_pack/munitions/pdc_ammo
	name = "PDC mount rounds (x5)"
	desc = "5 boxes of PDC rounds, ideal for repelling torpedoes and missiles."
	cost = 1000
	contains = list(/obj/item/ammo_box/magazine/nsv/pdc,
					/obj/item/ammo_box/magazine/nsv/pdc,
					/obj/item/ammo_box/magazine/nsv/pdc,
					/obj/item/ammo_box/magazine/nsv/pdc,
					/obj/item/ammo_box/magazine/nsv/pdc)
	crate_name = "PDC ammunition crate"

/datum/supply_pack/munitions/trolley
	name = "Replacement munitions trolley (x1)"
	desc = "A munitions trolley for hauling ammunition. Ordnance sold separately."
	cost = 2000
	contains = list(/obj/structure/munitions_trolley)
	crate_name = "Munitions trolley crate"

/datum/supply_pack/munitions/torpedo_construction
	name = "Torpedo construction kit"
	desc = "Due to the volatility of torpedoes, we are unable to offer pre-built munitions, however this kit contains common torpedo parts and some casings to put them in. Included: 3x standard warhead, 3x torpedo casings (trolley sold separately), 3x guidance system modules, 3x propulsion modules, 3x IFF cards."
	cost = 3000
	contains = list(/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card)
	crate_name = "Basic torpedo construction kit"

/datum/supply_pack/munitions/torpedo_casings
	name = "Torpedo casings"
	desc = "A set of 10 torpedo casings, prebuilt but not pre-assembled. Ideal when used with our line of torpedo components."
	cost = 750
	contains = list(/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing,
					/obj/item/ship_weapon/ammunition/torpedo/torpedo_casing)
	crate_name = "Blank torpedo casings"

/datum/supply_pack/munitions/torpedo_construction_guidance
	name = "Payload Guidance Modules"
	desc = "A bulk order of 10 torpedo guidance modules. Warheads sold separately!"
	cost = 1500
	contains = list(/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system)
	crate_name = "Munition Guidance Systems"

/datum/supply_pack/munitions/payload_construction_propulsion
	name = "Payload Propulsion Systems"
	desc = "A bulk order of 10 payload propulsion units. Warheads sold separately!"
	cost = 1500
	contains = list(/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system)
	crate_name = "Munition Propulsion Systems"

/datum/supply_pack/munitions/payload_construction_iff
	name = "Payload IFF Cards"
	desc = "A bulk order of 10 payload IFF cards. Warheads sold separately!"
	cost = 1500
	contains = list(/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card)
	crate_name = "Identify Friend of Foe Cards"

/datum/supply_pack/munitions/standard_warheads
	name = "Torpedo warheads (standard)"
	desc = "A pack of 10 standard torpedo warheads with a 40 isotonne yield, ideal for general usage."
	cost = 1500
	contains = list(/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo,
					/obj/item/ship_weapon/parts/missile/warhead/torpedo)
	crate_name = "Standard torpedo warheads"

/datum/supply_pack/munitions/bb_warheads
	name = "Torpedo warheads (armour piercing)"
	desc = "A pack of 10 armour piercing torpedo warheads with a 80 isotonne combined yield, these warheads excel at dealing massive damage to a target."
	cost = 2500
	contains = list(/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster,
					/obj/item/ship_weapon/parts/missile/warhead/bunker_buster)
	crate_name = "Armour piercing torpedo warheads"

/datum/supply_pack/munitions/decoy_warheads
	name = "ECM Missile Warheads"
	desc = "A pack of 10 electronic countermeasure warheads which excel at distracting the enemy's autonomous targeting system."
	cost = 700
	contains = list(/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy,
					/obj/item/ship_weapon/parts/missile/warhead/decoy)
	crate_name = "Decoy missile warheads"

/datum/supply_pack/munitions/freight_warheads
	name = "Torpedo warheads (freight)"
	desc = "A pack of 3 freight torpedo warheads for delivering cargo to trade stations."
	cost = 350
	contains = list(/obj/item/ship_weapon/parts/missile/warhead/freight,
					/obj/item/ship_weapon/parts/missile/warhead/freight,
					/obj/item/ship_weapon/parts/missile/warhead/freight)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "Freight torpedo warheads"

/datum/supply_pack/munitions/pilot_outfitting
	name = "Pilot Outfitting Crate"
	desc = "A full set of of gear for a new pilot"
	cost = 1200
	contains = list(/obj/item/clothing/under/ship/pilot,
					/obj/item/clothing/shoes/jackboots,
					/obj/item/clothing/gloves/color/black,
					/obj/item/clothing/head/beret/ship/pilot,
					/obj/item/radio/headset/munitions/pilot,
					/obj/item/clothing/suit/space/hardsuit/pilot)
	crate_name = "Pilot outfitting crate"

/datum/supply_pack/munitions/missile_warheads
	name = "Missile Warheads"
	desc = "A pack of 10 standard missile warheads."
	cost = 1000
	contains = list(/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead)
	crate_name = "Standard missile warheads"

/datum/supply_pack/munitions/missile_construction
	name = "Missile construction kit"
	desc = "Due to the volatility of missiles, we are unable to offer pre-built munitions, however this kit contains common missile parts and some casings to put them in. Included: 3x standard warhead, 3x missile casings (trolley sold separately), 3x guidance system modules, 3x propulsion modules, 3x IFF cards."
	cost = 2500
	contains = list(/obj/item/ship_weapon/ammunition/missile/missile_casing,
					/obj/item/ship_weapon/ammunition/missile/missile_casing,
					/obj/item/ship_weapon/ammunition/missile/missile_casing,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/warhead,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/guidance_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/propulsion_system,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card,
					/obj/item/ship_weapon/parts/missile/iff_card)
	crate_name = "Basic missile construction kit"

/datum/supply_pack/munitions/countermeasure_charges
	name = "Fighter countermeasure tri-charges (x5)"
	desc = "5 tri-charges of chaff countermeasures for a fighter."
	cost = 3500
	contains = list(/obj/item/ship_weapon/ammunition/countermeasure_charge,
					/obj/item/ship_weapon/ammunition/countermeasure_charge,
					/obj/item/ship_weapon/ammunition/countermeasure_charge,
					/obj/item/ship_weapon/ammunition/countermeasure_charge,
					/obj/item/ship_weapon/ammunition/countermeasure_charge)
	crate_name = "Fighter Countermeasure Charges"

/datum/supply_pack/munitions/fighter_construction
	name = "Light Fighter Starter Kit"
	desc = "This kit contains all the parts needed to start your own fleet like the space admiral of your dreams."
	cost = 9000
	contains = list(/obj/structure/fighter_frame,
					/obj/item/fighter_component/fuel_tank,
					/obj/item/fighter_component/avionics,
					/obj/item/fighter_component/apu,
					/obj/item/fighter_component/armour_plating,
					/obj/item/fighter_component/targeting_sensor,
					/obj/item/fighter_component/engine,
					/obj/item/fighter_component/countermeasure_dispenser,
					/obj/item/fighter_component/secondary/ordnance_launcher,
					/obj/item/fighter_component/oxygenator,
					/obj/item/fighter_component/canopy,
					/obj/item/fighter_component/docking_computer,
					/obj/item/fighter_component/battery,
					/obj/item/fighter_component/primary/cannon)
	crate_name = "Light fighter starter kit"

/datum/supply_pack/munitions/fighter_construction/heavy
	name = "Heavy Fighter Starter Kit"
	desc = "A DIY fighter kit that allows you to produce Scimitar class heavy fighters, heavy assault craft guaranteed to level cities."
	cost = 15000
	contains = list(/obj/structure/fighter_frame/heavy,
					/obj/item/fighter_component/fuel_tank,
					/obj/item/fighter_component/avionics,
					/obj/item/fighter_component/apu,
					/obj/item/fighter_component/armour_plating,
					/obj/item/fighter_component/targeting_sensor,
					/obj/item/fighter_component/engine,
					/obj/item/fighter_component/countermeasure_dispenser,
					/obj/item/fighter_component/oxygenator,
					/obj/item/fighter_component/canopy,
					/obj/item/fighter_component/docking_computer,
					/obj/item/fighter_component/secondary/ordnance_launcher/torpedo,
					/obj/item/fighter_component/battery,
					/obj/item/fighter_component/primary/cannon/heavy)
	crate_name = "Heavy fighter starter kit"

/datum/supply_pack/munitions/fighter_construction/utility
	name = "Utility Fighter Starter Kit"
	desc = "A DIY fighter kit which lets you manufacture Sabre class support vessels, capable of resupplying and repairing fighters in combat."
	cost = 10000
	contains = list(/obj/structure/fighter_frame/utility,
					/obj/item/fighter_component/fuel_tank/tier2,
					/obj/item/fighter_component/avionics,
					/obj/item/fighter_component/apu,
					/obj/item/fighter_component/armour_plating,
					/obj/item/fighter_component/targeting_sensor,
					/obj/item/fighter_component/engine,
					/obj/item/fighter_component/oxygenator,
					/obj/item/fighter_component/canopy,
					/obj/item/fighter_component/docking_computer,
					/obj/item/fighter_component/battery,
					/obj/item/fighter_component/secondary/utility/hold,
					/obj/item/fighter_component/primary/utility/refuel,
					/obj/item/fighter_component/countermeasure_dispenser)
	crate_name = "Utility fighter starter kit"

/datum/supply_pack/munitions/light_cannon
	name = "Light Cannon Ammunition"
	desc = "10 boxes of light cannon ammunition for use in fighters."
	cost = 1000
	contains = list(/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon,
					/obj/item/ammo_box/magazine/nsv/light_cannon)
	crate_name = "Light cannon ammunition crate"

/datum/supply_pack/munitions/heavy_cannon
	name = "Heavy Cannon Ammunition"
	desc = "10 boxes of heavy cannon ammunition for use in fighters."
	cost = 1000
	contains = list(/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon,
					/obj/item/ammo_box/magazine/nsv/heavy_cannon)
	crate_name = "Heavy cannon ammunition crate"

/datum/supply_pack/munitions/broadside_casings
	name = "Empty Broadside Casings"
	desc = "15 empty casings for broadside shells."
	cost = 1000
	contains = list(/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing)
	crate_name = "Empty broadside casings crate"

/datum/supply_pack/munitions/broadside_loads
	name = "Broadside Loads"
	desc = "15 loads for broadside shells."
	cost = 1000
	contains = list(/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load)
	crate_name = "Broadside loads crate"

/datum/supply_pack/munitions/broadside_pack
	name = "Broadside Pack"
	desc = "Enough casings, loads, and powder for one full load of an SNBC."
	cost = 1000
	contains = list(/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_load,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/ship_weapon/parts/broadside_casing,
					/obj/item/powder_bag)
	crate_name = "Broadside Full Load Crate"

/datum/supply_pack/security/armory/peacekeeper_rifles
	name = "M2A45 pulse rifles (x3)"
	desc = "A pack of 3 M2A45 pulse rifles, preloaded with nonlethal stun slugs."
	cost = 9000
	contains = list(/obj/item/gun/ballistic/automatic/peacekeeper,
					/obj/item/gun/ballistic/automatic/peacekeeper,
					/obj/item/gun/ballistic/automatic/peacekeeper)
	crate_name = "M2A45 crate"

/datum/supply_pack/security/armory/peacekeeper_rifles_single
	name = "M2A45 Pulse Rifle Single-Pack"
	desc = "A single M2A45 pulse rifle, preloaded with nonlethal stun slugs."
	cost = 3500
	small_item = TRUE
	contains = list(/obj/item/gun/ballistic/automatic/peacekeeper)

/datum/supply_pack/security/glock
	name = "Glock-13s (x3)"
	desc = "A pack of 3 Security Glock-13s, preloaded with rubber bullets."
	cost = 5000
	contains = list(/obj/item/gun/ballistic/automatic/pistol/glock,
					/obj/item/gun/ballistic/automatic/pistol/glock,
					/obj/item/gun/ballistic/automatic/pistol/glock)
	crate_name = "Glock-13 crate"

/datum/supply_pack/security/glock_single
	name = "Glock-13 Single-Pack"
	desc = "A single Security Glock-13, preloaded with rubber bullets."
	cost = 2000
	small_item = TRUE
	contains = list(/obj/item/gun/ballistic/automatic/pistol/glock)

/datum/supply_pack/security/edged_weapons
	name = "Surviving edged weapons: Informational manual"
	desc = "A manual which can help you learn jujitsu!"
	cost = 7000
	contains = list(/obj/item/book/granter/martial/jujitsu)
	crate_name = "Jujitsu manual crate"

/datum/supply_pack/security/glock_ammo
	name = "Glock-13 ammo (nonlethal)"
	desc = "5 magazines of nonlethal ammo for security sidearms."
	cost = 1500
	contains = list(/obj/item/ammo_box/magazine/glock,
					/obj/item/ammo_box/magazine/glock,
					/obj/item/ammo_box/magazine/glock,
					/obj/item/ammo_box/magazine/glock,
					/obj/item/ammo_box/magazine/glock,
					/obj/item/ammo_box/c9mm/rubber)
	crate_name = "Glock-13 nonlethal ammunition crate"

/datum/supply_pack/security/glock_lethal
	name = "Glock-13 ammo (lethal)"
	desc = "5 magazines of lethal ammo for security sidearms."
	cost = 1500
	contains = list(/obj/item/ammo_box/magazine/glock/lethal,
					/obj/item/ammo_box/magazine/glock/lethal,
					/obj/item/ammo_box/magazine/glock/lethal,
					/obj/item/ammo_box/magazine/glock/lethal,
					/obj/item/ammo_box/magazine/glock/lethal,
					/obj/item/ammo_box/c9mm)
	crate_name = "Glock-13 lethal ammunition crate"
	access = ACCESS_ARMORY

/datum/supply_pack/security/ballistic_tazer
	name = "Czanek Corp Tazer Crate"
	desc = "2 Czanek Corp tazers and some ammo for them (WARNING: MAY CAUSE HEART ATTACKS)."
	cost = 5000
	contains = list(/obj/item/ammo_box/magazine/tazer_cartridge_storage,
					/obj/item/ammo_box/magazine/tazer_cartridge_storage,
					/obj/item/gun/ballistic/tazer,
					/obj/item/gun/ballistic/tazer)
	crate_name = "Czanek corp tazer crate"

/datum/supply_pack/security/armory/peacekeeper_ammo
	name = "M2A45 pulse rifle ammo (nonlethal)"
	desc = "5 magazines of nonlethal ammo for peacekeeper rifles."
	cost = 800
	contains = list(/obj/item/ammo_box/magazine/peacekeeper,
					/obj/item/ammo_box/magazine/peacekeeper,
					/obj/item/ammo_box/magazine/peacekeeper,
					/obj/item/ammo_box/magazine/peacekeeper,
					/obj/item/ammo_box/magazine/peacekeeper)
	crate_name = "M2A45 nonlethal ammunition crate"

/datum/supply_pack/security/armory/peacekeeper_ammo_lethal
	name = "M2A45 pulse rifle ammo (lethal)"
	desc = "5 magazines of lethal ammunition for peacekeeper rifles."
	cost = 1200
	contains = list(/obj/item/ammo_box/magazine/peacekeeper/lethal,
					/obj/item/ammo_box/magazine/peacekeeper/lethal,
					/obj/item/ammo_box/magazine/peacekeeper/lethal,
					/obj/item/ammo_box/magazine/peacekeeper/lethal,
					/obj/item/ammo_box/magazine/peacekeeper/lethal)
	crate_name = "M2A45 lethal ammunition crate"
	access = ACCESS_ARMORY

/datum/supply_pack/security/armory/laser // NSV - We've got to have them somewhere, apparently.
	name = "Lasers Crate"
	desc = "Contains three lethal, high-energy laser guns."
	cost = 2000
	contains = list(/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser)
	crate_name = "laser crate"

/datum/supply_pack/security/mparmor
	name = "Military Police Replacement Crate"
	desc = "Three vests of MP armor vests complete with MP undershirts, everything to replace which fire razed to the ground."
	cost = 3600
	contains = list(/obj/item/clothing/suit/ship/squad/military_police,
					/obj/item/clothing/suit/ship/squad/military_police,
					/obj/item/clothing/suit/ship/squad/military_police,
					/obj/item/clothing/under/ship/military_police,
					/obj/item/clothing/under/ship/military_police,
					/obj/item/clothing/under/ship/military_police,
					/obj/item/clothing/head/helmet/ship/squad/leader,
					/obj/item/clothing/head/helmet/ship/squad/leader,
					/obj/item/clothing/head/helmet/ship/squad/leader)
	crate_name = "MP armor crate"

/datum/supply_pack/security/armory/m45single
	name = "M1911 handgun Single-pack"
	desc = "Single M1911 with a .45 magazine to fit inside of it."
	cost = 1500
	contains = list(/obj/item/gun/ballistic/automatic/pistol/m1911/no_mag,
				/obj/item/ammo_box/magazine/m45)
	crate_name = "1911 single crate"

/datum/supply_pack/security/armory/m45guns
	name = "M1911 handgun Crate"
	desc = "Holds 3 M1911's with 3 magazines to fit in each one of them."
	cost = 4200
	contains = list(/obj/item/gun/ballistic/automatic/pistol/m1911/no_mag,
					/obj/item/gun/ballistic/automatic/pistol/m1911/no_mag,
					/obj/item/gun/ballistic/automatic/pistol/m1911/no_mag,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45)
	crate_name = "1911 single gun crate"

/datum/supply_pack/security/armory/m45ammo
	name = "M1911 Ammo Crate"
	desc = "Contains 6 magazines and 2 ammoboxes which hold 3 loads each, which should contain enough lead for that holy crusade your chaplain always wanted."
	cost = 2200
	contains = list(/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/magazine/m45,
					/obj/item/ammo_box/c45/m45,
					/obj/item/ammo_box/c45/m45) // yes, they use the C20R ammo, funny KMC
	crate_name = "1911 ammo crate"

/datum/supply_pack/munitions/fighter_fuel
	name = "Fighter fuel"
	desc = "One cryogenic Tyrosene fuel pump, capable of fully refuelling 3 fighters. Handle with care."
	cost = 1500
	contains = list(/obj/structure/reagent_dispensers/fueltank/cryogenic_fuel)
	crate_name = "Fighter fuel crate"

/datum/supply_pack/engineering/control_rods
	name = "Nanocarbon Reactor Control Rods (x5)"
	desc = "5 nanocarbon reactor control rods for a stormdrive reactor."
	cost = 3000
	contains = list(/obj/item/control_rod,
					/obj/item/control_rod,
					/obj/item/control_rod,
					/obj/item/control_rod,
					/obj/item/control_rod)
	crate_name = "Nanocarbon Reactor Control Rods"

/datum/supply_pack/engineering/superior_control_rods
	name = "Crystaline Nanocarbon Reactor Control Rods (x5)"
	desc = "5 crystaline nanocarbon reactor control rods for a stormdrive reactor."
	cost = 8000
	contains = list(/obj/item/control_rod/superior,
					/obj/item/control_rod/superior,
					/obj/item/control_rod/superior,
					/obj/item/control_rod/superior,
					/obj/item/control_rod/superior)
	crate_name = "Crystaline Nanocarbon Reactor Control Rods"

/datum/supply_pack/engineering/armour_plating_nanorepair_well
	name = "Armour Plating Nano-repair Well Machine Board"
	desc = "A replacement machine board for the APNW."
	access = ACCESS_CE
	cost = 50000 //These are *really* not meant to be cheap
	contains = list(/obj/item/circuitboard/machine/armour_plating_nanorepair_well)
	crate_name = "Armour Plating Nano-repair Well Machine Board"

/datum/supply_pack/engineering/armour_plating_nanorepair_pump
	name = "Armour Plating Nano-repair Pump Machine Board"
	desc = "A replacement machine board for a APNP."
	access = ACCESS_CE
	cost = 25000 //Make sure you look after these
	contains = list(/obj/item/circuitboard/machine/armour_plating_nanorepair_pump)
	crate_name = "Armour Plating Nano-repair Pump Machine Board"

/datum/supply_pack/engine/stormdrive_core
	name = "Stormdrive Reactor Core Crate"
	desc = "This crate contains a live reactor core for a class iv nuclear storm drive."
	cost = 35000
	access = ACCESS_CE
	contains = list(/obj/item/stormdrive_core)
	crate_name = "stormdrive reactor core crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/costumes_toys/wardrobes/munitions
	name = "Munitions Wardrobe Supply Crate"
	desc = "This crate contains a refill for the Munidrobe."
	cost = 750
	contains = list(/obj/item/vending_refill/wardrobe/muni_wardrobe)
	crate_name = "munidrobe supply crate"

/datum/supply_pack/security/armory/mp_smg
	name = "MP-16A4 Military Police SMG Crate"
	desc = "Contains three standard issue military police SMGs, designed for concealed carry during shipside and boarding operations. Requires Armory access to open."
	cost = 3280 //20%
	contains = list(/obj/item/gun/ballistic/automatic/mp_smg,
					/obj/item/gun/ballistic/automatic/mp_smg,
					/obj/item/gun/ballistic/automatic/mp_smg)
	crate_name = "MP-16A4 SMG crate"

/datum/supply_pack/security/armory/mp_smgammo
	name = "MP-16A4 Military Police SMG Ammo Crate"
	desc = "Contains two 21-round magazines for the peacekeeper SMG and two 9mm ammo boxes. Requires Armory access to open."
	cost = 1700
	contains = list(/obj/item/ammo_box/magazine/smgm9mm,
					/obj/item/ammo_box/magazine/smgm9mm,
					/obj/item/ammo_box/c9mm,
					/obj/item/ammo_box/c9mm)
	crate_name = "MP-16A4 ammo crate"

/datum/supply_pack/security/armory/marine_rifle
	name = "M4A-16A1 Assault Rifle Crate"
	desc = "Contains three high-powered, fully automatic assault rifles chambered in 5.56mm. These highly powerful assault weapons are frequently used by marines during boarding. Requires Armory access to open."
	cost = 4000 //20%
	contains = list(/obj/item/gun/ballistic/automatic/marine_rifle,
					/obj/item/gun/ballistic/automatic/marine_rifle,
					/obj/item/gun/ballistic/automatic/marine_rifle)
	crate_name = "M4A-16A1 assault rifle crate"

/datum/supply_pack/security/armory/marine_rifle_ammo
	name = "M4A-16A1 Assault Rifle Ammo Crate"
	desc = "Contains four 5.56 30-round magazines for the M4A16A1 rifle and two 9mm ammo boxes to fill them with. Requires Armory access to open."
	cost = 2000
	contains = list(/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556,
					/obj/item/ammo_box/magazine/m556)
	crate_name = "M4A-16A1 ammo crate"

/datum/supply_pack/engineering/hulljuice
	name = "Hulljuice Tank Crate"
	desc = "Keep yourself afloat aboard the ship with some healthy hull repair JUICE! It includes one tank and two extinguishers. Apply liberally to damaged hull plates"
	cost = 1200
	contains = list(/obj/structure/reagent_dispensers/foamtank/hull_repair_juice,
					/obj/item/extinguisher/advanced/hull_repair_juice,
					/obj/item/extinguisher/advanced/hull_repair_juice)
	crate_name = "engineering crate"

//Bottle chem packs - yes I have taken some liberties
/datum/supply_pack/medical/chemical_supply_compounds
	name = "Chemical Supply Crate - Organic Compounds"
	desc = "This crate contains 3x bottles of ethanol and sugar"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/ethanol,
					/obj/item/reagent_containers/glass/bottle/ethanol,
					/obj/item/reagent_containers/glass/bottle/ethanol,
					/obj/item/reagent_containers/glass/bottle/sugar,
					/obj/item/reagent_containers/glass/bottle/sugar,
					/obj/item/reagent_containers/glass/bottle/sugar)
	crate_name = "Chemical Supply Crate - Organic Compounds"

/datum/supply_pack/medical/chemical_supply_metals
	name = "Chemical Supply Crate - Metals"
	desc = "This crate contains 3x bottles of copper, iron, silver and mercury"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/copper,
					/obj/item/reagent_containers/glass/bottle/copper,
					/obj/item/reagent_containers/glass/bottle/copper,
					/obj/item/reagent_containers/glass/bottle/iron,
					/obj/item/reagent_containers/glass/bottle/iron,
					/obj/item/reagent_containers/glass/bottle/iron,
					/obj/item/reagent_containers/glass/bottle/silver,
					/obj/item/reagent_containers/glass/bottle/silver,
					/obj/item/reagent_containers/glass/bottle/silver,
					/obj/item/reagent_containers/glass/bottle/mercury,
					/obj/item/reagent_containers/glass/bottle/mercury,
					/obj/item/reagent_containers/glass/bottle/mercury)
	crate_name = "Chemical Supply Crate - Metals"

/datum/supply_pack/medical/chemical_supply_alkali_metals
	name = "Chemical Supply Crate - Alkali Metals"
	desc = "This crate contains 3x bottles of hydrogen, lithium, sodium and potassium"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/hydrogen,
					/obj/item/reagent_containers/glass/bottle/hydrogen,
					/obj/item/reagent_containers/glass/bottle/hydrogen,
					/obj/item/reagent_containers/glass/bottle/lithium,
					/obj/item/reagent_containers/glass/bottle/lithium,
					/obj/item/reagent_containers/glass/bottle/lithium,
					/obj/item/reagent_containers/glass/bottle/sodium,
					/obj/item/reagent_containers/glass/bottle/sodium,
					/obj/item/reagent_containers/glass/bottle/sodium,
					/obj/item/reagent_containers/glass/bottle/potassium,
					/obj/item/reagent_containers/glass/bottle/potassium,
					/obj/item/reagent_containers/glass/bottle/potassium)
	crate_name = "Chemical Supply Crate - Alkali Metals"

/datum/supply_pack/medical/chemical_supply_pnictogens
	name = "Chemical Supply Crate - Pnictogens"
	desc = "This crate contains 3x bottles of nitrogen and phosphorus"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/nitrogen,
					/obj/item/reagent_containers/glass/bottle/nitrogen,
					/obj/item/reagent_containers/glass/bottle/nitrogen,
					/obj/item/reagent_containers/glass/bottle/phosphorus,
					/obj/item/reagent_containers/glass/bottle/phosphorus,
					/obj/item/reagent_containers/glass/bottle/phosphorus)
	crate_name = "Chemical Supply Crate - Pnictogens"

/datum/supply_pack/medical/chemical_supply_tetrels
	name = "Chemical Supply Crate - Tetrels"
	desc = "This crate contains 3x bottles of carbon, silicon and plasma"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/carbon,
					/obj/item/reagent_containers/glass/bottle/carbon,
					/obj/item/reagent_containers/glass/bottle/carbon,
					/obj/item/reagent_containers/glass/bottle/silicon,
					/obj/item/reagent_containers/glass/bottle/silicon,
					/obj/item/reagent_containers/glass/bottle/silicon,
					/obj/item/reagent_containers/glass/bottle/plasma,
					/obj/item/reagent_containers/glass/bottle/plasma,
					/obj/item/reagent_containers/glass/bottle/plasma)
	crate_name = "Chemical Supply Crate - Tetrels"

/datum/supply_pack/medical/chemical_supply_alkaline_earth_metals_triels
	name = "Chemical Supply Crate - Alkaline Earth Metals & Triels"
	desc = "This crate contains 3x bottles of radium and aluminium"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/radium,
					/obj/item/reagent_containers/glass/bottle/radium,
					/obj/item/reagent_containers/glass/bottle/radium,
					/obj/item/reagent_containers/glass/bottle/aluminium,
					/obj/item/reagent_containers/glass/bottle/aluminium,
					/obj/item/reagent_containers/glass/bottle/aluminium)
	crate_name = "Chemical Supply Crate - Alkaline Earth Metals & Triels"

/datum/supply_pack/medical/chemical_supply_halogens
	name = "Chemical Supply Crate - Halogens"
	desc = "This crate contains 3x bottles of fluorine, chlorine, bromine and iodine"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/fluorine,
					/obj/item/reagent_containers/glass/bottle/fluorine,
					/obj/item/reagent_containers/glass/bottle/fluorine,
					/obj/item/reagent_containers/glass/bottle/chlorine,
					/obj/item/reagent_containers/glass/bottle/chlorine,
					/obj/item/reagent_containers/glass/bottle/chlorine,
					/obj/item/reagent_containers/glass/bottle/bromine,
					/obj/item/reagent_containers/glass/bottle/bromine,
					/obj/item/reagent_containers/glass/bottle/bromine,
					/obj/item/reagent_containers/glass/bottle/iodine,
					/obj/item/reagent_containers/glass/bottle/iodine,
					/obj/item/reagent_containers/glass/bottle/iodine)
	crate_name = "Chemical Supply Crate - Halogens"

/datum/supply_pack/medical/chemical_supply_chalcogens
	name = "Chemical Supply Crate - Chalcogens"
	desc = "This crate contains 3x bottles of oxygen, sulfur and sulfuric acid"
	cost = 1000
	hidden = TRUE
	contains = list(/obj/item/reagent_containers/glass/bottle/oxygen,
					/obj/item/reagent_containers/glass/bottle/oxygen,
					/obj/item/reagent_containers/glass/bottle/oxygen,
					/obj/item/reagent_containers/glass/bottle/sulfur,
					/obj/item/reagent_containers/glass/bottle/sulfur,
					/obj/item/reagent_containers/glass/bottle/sulfur,
					/obj/item/reagent_containers/glass/bottle/sacid,
					/obj/item/reagent_containers/glass/bottle/sacid,
					/obj/item/reagent_containers/glass/bottle/sacid)
	crate_name = "Chemical Supply Crate - Chalcogens"

/datum/supply_pack/medical/robotic_firstaid
	name = "Synthethic Treatment Kits Crate"
	desc = "Contains three robotic first aid kits for all of your synthetic repairing needs. Tools, radioactive disinfectant and system cleaner medipens included."
	contains = list(/obj/item/storage/firstaid/robot,
					/obj/item/storage/firstaid/robot,
					/obj/item/storage/firstaid/robot)
	cost = 1400
	small_item = TRUE
	crate_name = "synthethic treatment kits crate"

/datum/supply_pack/materials/plasma_canister //Purely used for the Serendipity's plasma caster
	name = "Phoron Canister"
	desc = "A single can of phoron gas, for all your plasma needs!"
	cost = 2500
	contains = list(
		/obj/machinery/portable_atmospherics/canister/toxins)
	hidden = TRUE
	crate_name = "Phoron Portable Gas Canister"

//Coffee Related Packs
/datum/supply_pack/service/coffee_kit
	name = "Emergency Coffee Resupply Kit"
	desc = "Did the Marines drink the last of the ship's coffee and are now fertilizing the hydroponic trays? Did the clown destroy your coffee mugs while Runtime knocked the coffee pot onto the floor, making it shatter? Fear not, this crate contains everything you might need to get that liquid ambrosia flowing again!"
	cost = 1000 //It's a starter pack, so we're not completely greedy, unlike the grill.
	contains = list(/obj/item/reagent_containers/food/drinks/mug,
					/obj/item/reagent_containers/food/drinks/mug,
					/obj/item/reagent_containers/food/drinks/mug,
					/obj/item/reagent_containers/glass/coffeepot,
					/obj/item/coffee_cartridge,
					/obj/item/coffee_cartridge)
	crate_type = /obj/structure/closet/crate/secure // We don't mess around when it comes to those desperate for coffee.
	crate_name = "Emergency Coffee Supply Crate"

/datum/supply_pack/service/coffee_cartridge
	name = "Navy Coffee Cartridge Resupply"
	desc = "Five cartridges containing our finest navy coffee beans for the glorious coffeemaker."
	cost = 3000 //Two thousand more than the Emergency kit, because it's a refill.
	contains = list(/obj/item/coffee_cartridge,
					/obj/item/coffee_cartridge,
					/obj/item/coffee_cartridge,
					/obj/item/coffee_cartridge,
					/obj/item/coffee_cartridge)
	crate_type = /obj/structure/closet/crate/secure // We still don't mess around with our coffee supply, this thing is getting to that machine one way or another
	crate_name = "Coffee Cartridge Supply Crate"

/datum/supply_pack/service/coffee_cartridge_fancy
	name = "Fancy Garbage Coffee Cartridge Resupply"
	desc = "We don't know why you would possibly want this garbage tasting coffee compared to the glorious ambrosia taste of Navy Coffee, but here you go. Contains 5 cartridges."
	cost = 5000 //It's fancy coffee, so it's pretty expensive because the Navy wants to hoard it all from you.
	contains = list(/obj/item/coffee_cartridge/fancy,
					/obj/item/coffee_cartridge/fancy,
					/obj/item/coffee_cartridge/fancy,
					/obj/item/coffee_cartridge/fancy,
					/obj/item/coffee_cartridge/fancy)
	crate_type = /obj/structure/closet/crate/secure
	crate_name = "Garbage Coffee Supply Crate"

/datum/supply_pack/service/coffeekit
	name = "Coffee Equippment Crate"
	desc = "A complete kit to setup your own cozy coffee shop. For some reason, the coffeemaker is not included."
	cost = 2000
	contains = list(/obj/item/storage/box/coffeepack/robusta,
					/obj/item/storage/box/coffeepack/arabica,
					/obj/item/reagent_containers/glass/coffeepot,
					/obj/item/storage/fancy/coffee_condi_display,
					/obj/item/reagent_containers/food/drinks/bottle/cream,
					/obj/item/reagent_containers/food/condiment/milk,
					/obj/item/reagent_containers/food/condiment/soymilk,
					/obj/item/reagent_containers/food/condiment/sugar,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/caramel)
	crate_name = "coffee equpment crate"

/datum/supply_pack/service/coffeemaker
	name = "Pendulum Coffeemaker Crate"
	desc = "An assembled Pendulum model coffeemaker."
	cost = 4000
	contains = list(/obj/machinery/coffeemaker/pendulum)
	crate_name = "coffeemaker crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/organic/syrup
	name = "Coffee Syrups Box"
	desc = "A packaged box of various syrups, perfect to make your delicious coffee even more diabetic."
	cost = 3000
	contains = list(/obj/item/reagent_containers/glass/bottle/syrup_bottle/caramel,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/liqueur,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/honey,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/vanilla,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/tea,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/creme_de_cacao,
					/obj/item/reagent_containers/glass/bottle/syrup_bottle/creme_de_menthe)
	crate_name = "coffee syrups box"
	crate_type = /obj/structure/closet/cardboard
