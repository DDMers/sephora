
//Syndicate ships go here

/obj/structure/overmap/syndicate
	name = "syndicate ship"
	desc = "A syndicate owned space faring vessel, it's painted with an ominous black and red motif."
	icon = 'nsv13/icons/overmap/default.dmi'
	icon_state = "default"
	faction = "syndicate"
	supply_pod_type = /obj/structure/closet/supplypod/syndicate_odst
	returns_rejected_cargo = FALSE // We won't send freight torpedoes to our enemies, we'll send actual torpedoes to our enemies

//Player Versions

/obj/structure/overmap/syndicate/pvp //Syndie PVP ship.
	name = "SSV Nebuchadnezzar"
	icon = 'nsv13/icons/overmap/syndicate/tuningfork.dmi'
	icon_state = "tuningfork"
	desc = "A highly modular cruiser setup which, despite its size, is capable of delivering devastating firepower."
	mass = MASS_MEDIUM
	sprite_size = 96
	damage_states = FALSE
	obj_integrity = 1000
	max_integrity = 1000
	ai_controlled = FALSE
	//collision_positions = list(new /datum/vector2d(-27,62), new /datum/vector2d(-30,52), new /datum/vector2d(-30,11), new /datum/vector2d(-32,-16), new /datum/vector2d(-30,-45), new /datum/vector2d(-24,-58), new /datum/vector2d(19,-60), new /datum/vector2d(33,-49), new /datum/vector2d(35,24), new /datum/vector2d(33,60))
	bound_width = 128
	bound_height = 128
	role = PVP_SHIP
	starting_system = "Rubicon" //Relatively safe start, fleets won't hotdrop you here.
	armor = list("overmap_light" = 99, "overmap_medium" = 45, "overmap_heavy" = 20)

/obj/structure/overmap/syndicate/pvp/elco
	name = "SSV Elco"
	icon = 'nsv13/icons/overmap/new/syndicate/pt_boat.dmi'
	icon_state = "pt_boat"
	sprite_size = 256
	bound_width = 256
	bound_height = 256

/obj/structure/overmap/syndicate/pvp/apply_weapons()
	weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	if(flak_battery_amount > 0)
		weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/mac(src)

/obj/structure/overmap/syndicate/pvp/hulk //Larger PVP ship for larger pops.
	name = "SSV Hulk"
	icon = 'nsv13/icons/overmap/syndicate/syn_patrol_cruiser.dmi'
	icon_state = "patrol_cruiser"
	bound_width = 128
	bound_height = 256
	mass = MASS_LARGE
	sprite_size = 48
	pixel_z = -96
	pixel_w = -96
	obj_integrity = 1100
	max_integrity = 1100 //Max health
	role = PVP_SHIP
	armor = list("overmap_light" = 99, "overmap_medium" = 55, "overmap_heavy" = 30)

//AI Versions

/obj/structure/overmap/syndicate/ai/Initialize(mapload)
	. = ..()
	name = "[name] ([rand(0,999)])"

/obj/structure/overmap/hostile/ai/fighter/Initialize()
	. = ..()
	name = "[name] ([rand(0,999)])"

/obj/structure/overmap/syndicate/ai/Destroy()
	SSstar_system.bounty_pool += bounty //Adding payment for services rendered
	. = ..()

/datum/map_template/boarding
    name = "Mako class patrol frigate (interior)"
    mappath = "_maps/templates/boarding/syndicate/mako.dmm"

/datum/map_template/boarding/mako
    name = "Mako class patrol frigate (interior)"
    mappath = "_maps/templates/boarding/syndicate/mako.dmm"

/obj/structure/overmap/syndicate/ai //Generic bad guy #10000. GRR.
	name = "Mako class patrol frigate"
	icon = 'nsv13/icons/overmap/new/syndicate/frigate.dmi'
	icon_state = "mako"
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	mass = MASS_SMALL
	bound_height = 96
	bound_width = 96
	sprite_size = 48
	damage_states = FALSE
	obj_integrity = 300
	max_integrity = 300
	area_type = /area/ruin/powered/nsv13/gunship
	var/bounty = 1000
	armor = list("overmap_light" = 30, "overmap_medium" = 20, "overmap_heavy" = 30)
	ai_flags = AI_FLAG_DESTROYER
	combat_dice_type = /datum/combat_dice/frigate
	possible_interior_maps = list(/datum/map_template/boarding/mako)


/datum/map_template/boarding/mako_carrier
    name = "Sturgeon class escort carrier (interior)"
    mappath = "_maps/templates/boarding/syndicate/mako_carrier.dmm"

/obj/structure/overmap/syndicate/ai/mako_carrier
	name = "Sturgeon class escort carrier"
	icon_state = "mako_carrier"
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/syndicate/ai/fighter)
	obj_integrity = 400
	max_integrity = 400
	armor = list("overmap_light" = 30, "overmap_medium" = 30, "overmap_heavy" = 30)
	combat_dice_type = /datum/combat_dice/carrier
	possible_interior_maps = list(/datum/map_template/boarding/mako_carrier)

/obj/structure/overmap/syndicate/ai/mako_flak
	name = "Mauler class flak frigate"
	icon_state = "mako_flak"
	flak_battery_amount = 1
	mines_left = 10
	mass = MASS_MEDIUM
	combat_dice_type = /datum/combat_dice/frigate

/datum/map_template/boarding/nuclear
    name = "Thermonuclear destroyer (interior)"
    mappath = "_maps/templates/boarding/syndicate/nukefrigate.dmm"

/obj/structure/overmap/syndicate/ai/conflagration
	name = "Hellfire destroyer"
	icon = 'nsv13/icons/overmap/new/syndicate/nuke_frigate.dmi'
	icon_state = "megamouth"
	bound_height = 160
	bound_width = 160
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/hellfire
	obj_integrity = 900
	max_integrity = 900 //Max health
	shots_left = 7
	torpedoes = 5
	missiles = 10
	armor = list("overmap_light" = 90, "overmap_medium" = 75, "overmap_heavy" = 30)
	combat_dice_type = /datum/combat_dice/destroyer/conflagration
	possible_interior_maps = list(/datum/map_template/boarding/nuclear)

/obj/structure/overmap/syndicate/ai/conflagration/elite
	name = "Nightmare class hellfire deterrent"
	icon_state = "megamouth_elite"
	shots_left = 15
	torpedoes = 10
	missiles = 15
	obj_integrity = 1200
	max_integrity = 1200 //Max health
	bounty = 15000
	armor = list("overmap_light" = 90, "overmap_medium" = 75, "overmap_light" = 50)
	ai_flags = AI_FLAG_DESTROYER | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/destroyer/conflagration

/datum/map_template/boarding/destroyer
    name = "Hammerhead class missile destroyer (interior)"
    mappath = "_maps/templates/boarding/syndicate/destroyer.dmm"

/obj/structure/overmap/syndicate/ai/destroyer
	name = "Hammerhead class missile destroyer"
	icon = 'nsv13/icons/overmap/new/syndicate/destroyer.dmi'
	icon_state = "hammerhead_flak"
	bound_height = 96
	bound_width = 96
	mass = MASS_MEDIUM
	obj_integrity = 500
	max_integrity = 500
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)
	missiles = 6
	bounty = 1000
	combat_dice_type = /datum/combat_dice/destroyer
	possible_interior_maps = list(/datum/map_template/boarding/destroyer)

/obj/structure/overmap/syndicate/ai/destroyer/spec_collision_handling(obj/structure/overmap/other_ship, list/impact_powers, impact_angle)
	var/modified_angle = 360 - ((angle + 630) % 360)
	var/angle_diff = impact_angle - modified_angle
	if(abs(angle_diff) > HAMMERHEAD_COLLISION_GUARD_ANGLE)
		return
	impact_powers[1] *= 0.5 // x 0.5 self damage
	impact_powers[2] *= 2.5 // x 2.5 other damage

/obj/structure/overmap/syndicate/ai/destroyer/elite
	name = "Special Ops Torpedo Destroyer"
	icon_state = "hammerhead_elite"
	obj_integrity = 900
	max_integrity = 900
	armor = list("overmap_light" = 90, "overmap_medium" = 80, "overmap_heavy" = 40)
	missiles = 8
	torpedoes = 4
	bounty = 1500
	ai_flags = AI_FLAG_DESTROYER | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/destroyer

/obj/structure/overmap/syndicate/ai/destroyer/flak
	name = "Hammerhead class flak destroyer"
	icon_state = "hammerhead"
	mass = MASS_LARGE
	flak_battery_amount = 2
	missiles = 0
	torpedoes = 0
	obj_integrity = 450
	max_integrity = 450
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)
	combat_dice_type = /datum/combat_dice/destroyer/flycatcher

/obj/structure/overmap/syndicate/ai/cruiser
	name = "Barracuda class tactical cruiser"
	icon = 'nsv13/icons/overmap/new/syndicate/cruiser.dmi'
	icon_state = "barracuda_flak"
	bound_height = 128
	bound_width = 128
	mass = MASS_LARGE
	armor = list("overmap_light" = 90, "overmap_medium" = 70, "overmap_heavy" = 30)
	obj_integrity = 450
	max_integrity = 450
	bounty = 3000
	ai_flags = AI_FLAG_BATTLESHIP
	combat_dice_type = /datum/combat_dice/cruiser
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/cruiser/elite
	name = "Special ops tactical cruiser"
	icon_state = "barracuda_elite"
	armor = list("overmap_light" = 90, "overmap_medium" = 70, "overmap_heavy" = 30)
	obj_integrity = 1000
	max_integrity = 1000
	missiles = 10
	bounty = 4000
	ai_flags = AI_FLAG_BATTLESHIP | AI_FLAG_ELITE

/datum/map_template/boarding/carrier
	name = "carrier (interior)"
	mappath = "_maps/templates/boarding/syndicate/carrier.dmm"

/obj/structure/overmap/syndicate/ai/carrier
	name = "Syndicate combat carrier"
	icon = 'nsv13/icons/overmap/new/syndicate/carrier.dmi'
	icon_state = "redtip"
	mass = MASS_LARGE
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/syndicate/ai/fighter)
	sprite_size = 48
	damage_states = FALSE
	bound_height = 128
	bound_width = 128
	obj_integrity = 600
	max_integrity = 600 //Tanky so that it can survive to deploy multiple fighter waves.
	bounty = 3000
	torpedoes = 0
	mines_left = 5 //As a treat
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 10)
	can_resupply = TRUE
	ai_flags = AI_FLAG_SUPPLY
	combat_dice_type = /datum/combat_dice/carrier
	possible_interior_maps = list(/datum/map_template/boarding/carrier)

/obj/structure/overmap/syndicate/ai/carrier/elite
	name = "Special ops escort carrier"
	icon_state = "redtip_elite"
	bounty = 5000
	obj_integrity = 1400
	max_integrity = 1400 //Tanky so that it can survive to deploy multiple fighter waves.
	armor = list("overmap_light" = 80, "overmap_medium" = 70, "overmap_heavy" = 25)
	//This scary one can launch bombers, which absolutely wreak havoc
	ai_fighter_type = list(/obj/structure/overmap/syndicate/ai/fighter,
							/obj/structure/overmap/syndicate/ai/bomber)
	ai_flags = AI_FLAG_SUPPLY | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/carrier
	possible_interior_maps = list(/datum/map_template/boarding/carrier)

/obj/structure/overmap/syndicate/ai/carrier/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = new /datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/battleship //Larger ship which is much harder to kill
	name = "SSV Sol's Revenge"
	desc = "Death incarnate."
	icon = 'nsv13/icons/overmap/syndicate/battleship.dmi'
	icon_state = "battleship"
	mass = MASS_TITAN
	sprite_size = 48
	damage_states = TRUE
	obj_integrity = 5000
	max_integrity = 5000 //Max health
	bounty = 20000
	shots_left = 500 //A monster.
	bound_width = 640
	bound_height = 640
	armor = list("overmap_light" = 100, "overmap_medium" = 85, "overmap_heavy" = 50)
	ai_flags = AI_FLAG_BATTLESHIP | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/battleship
	possible_interior_maps = list()
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/hellfire

/obj/structure/overmap/syndicate/ai/battleship/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/mac(src)

/obj/structure/overmap/syndicate/ai/assault_cruiser //A big box of tank which is hard to take down, and lethal up close.
	name = "Inquisitior class assault cruiser"
	desc = "A heavily armoured cruiser designed for close quarters engagement."
	icon_state = "assault"
	mass = MASS_MEDIUM_LARGE
	sprite_size = 48
	damage_states = FALSE
	obj_integrity = 800
	max_integrity = 800 //Max health
	missiles = 0
	torpedoes = 0
	armor = list("overmap_light" = 90, "overmap_medium" = 80, "overmap_heavy" = 30)
	ai_flags = AI_FLAG_DESTROYER
	speed_limit = 3
	combat_dice_type = /datum/combat_dice/cruiser
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/assault_cruiser/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = null
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = null

/datum/map_template/boarding/boarding_frigate
    name = "Astartes class marine frigate (interior)"
    mappath = "_maps/templates/boarding/syndicate/marine_frigate.dmm"

/obj/structure/overmap/syndicate/ai/assault_cruiser/boarding_frigate //A big box of tank which is hard to take down, and lethal up close.
	name = "Astartes class marine frigate"
	desc = "Deus Vult"
	icon = 'nsv13/icons/overmap/new/syndicate/frigate.dmi'
	icon_state = "boarding"
	missiles = 5 //It's able to do basic anti-air when not able to find a good boarding target.
	ai_flags = AI_FLAG_ANTI_FIGHTER | AI_FLAG_BOARDER //It likes to go after fighters really
	speed_limit = 4 //So we have at least a chance of getting within boarding range.
	bound_height = 96
	bound_width = 96
	damage_states = FALSE
	obj_integrity = 750
	max_integrity = 750
	armor = list("overmap_light" = 90, "overmap_medium" = 80, "overmap_light" = 30)
	combat_dice_type = /datum/combat_dice/destroyer/flycatcher	//Cruiser subtype, called frigate? Guess it gets the combat dice inbetween both.
	possible_interior_maps = list(/datum/map_template/boarding/boarding_frigate)

/obj/structure/overmap/syndicate/ai/assault_cruiser/boarding_frigate/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = null
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/gunboat //A big box of tank which is hard to take down, and lethal up close.
	name = "Syndicate anti-air frigate"
	desc = "A nimble, but lightly armoured frigate which specialises in taking down enemy fighters."
	icon = 'nsv13/icons/overmap/syndicate/gunboat.dmi'
	icon_state = "gunboat"
	mass = MASS_MEDIUM
	sprite_size = 48
	damage_states = TRUE
	bound_width = 160
	bound_height = 160
	obj_integrity = 450
	max_integrity = 450 //Max health
	missiles = 5
	shots_left = 5
	torpedoes = 0
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 15)
	ai_flags = AI_FLAG_ANTI_FIGHTER
	damage_states = FALSE
	combat_dice_type = /datum/combat_dice/destroyer/flycatcher
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/gunboat/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = null
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/submarine //A big box of tank which is hard to take down, and lethal up close.
	name = "Aspala class sub-spacemarine"
	desc = "A highly advanced Syndicate cruiser which can mask its sensor signature drastically."
	icon = 'nsv13/icons/overmap/new/syndicate/cruiser.dmi'
	icon_state = "aspala"
	mass = MASS_MEDIUM
	sprite_size = 48
	obj_integrity = 500
	max_integrity = 500 //Max health
	bound_height = 128
	bound_width = 128
	missiles = 10
	torpedoes = 10 //Torp boat!
	mines_left = 15 //And mine layer!
	shots_left = 10
	armor = list("overmap_light" = 80, "overmap_medium" = 45, "overmap_heavy" = 10)
	ai_flags = AI_FLAG_DESTROYER
	cloak_factor = 100 //Not a perfect cloak, mind you.
	combat_dice_type = /datum/combat_dice/destroyer
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/disruptor
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/submarine/Initialize(mapload)
	. = ..()
	handle_cloak(TRUE)

/obj/structure/overmap/syndicate/ai/submarine/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/light_cannon/integrated(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher/burst_disruptor(src)
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/submarine/elite
	name = "Stalker class sub-spacemarine"
	icon_state = "aspala_elite"
	obj_integrity = 1000
	max_integrity = 1000 //Max health
	integrity_failure = 200 //At this integrity it will start phase 2
	armor = list("overmap_light" = 90, "overmap_medium" = 65, "overmap_heavy" = 35)
	shots_left = 35
	torpedoes = 20 //Many torps 4u
	missiles = 15
	bounty = 3500
	ai_flags = AI_FLAG_DESTROYER | AI_FLAG_ELITE
	cloak_factor = 80 //Harder to see
	combat_dice_type = /datum/combat_dice/destroyer
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/disruptor

/obj/structure/overmap/syndicate/ai/submarine/elite/try_repair(amount)
	. = ..()
	if(obj_integrity > integrity_failure) //Reset our torp type if we have been healed
		torpedo_type = initial(torpedo_type)

/obj/structure/overmap/syndicate/ai/submarine/elite/obj_break() //Unused for overmaps, so we just steal it to make damage phases :3c
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/viscerator
	torpedoes = CLAMP((torpedoes),2 , 3) //This is their secret weapon, they only have a few of these

/obj/structure/overmap/syndicate/ai/kadesh	//I sure wonder what this one does....
	name = "Kadesh class advanced cruiser"
	desc = "An experimental Syndicate cruiser capable of projecting energy bursts powerful enough to disrupt drive systems."
	obj_integrity = 1200	//Pretty thick hull due to it being a priority target
	max_integrity = 1200
	icon = 'nsv13/icons/overmap/syndicate/syn_light_cruiser.dmi'
	icon_state = "advanced_cruiser"
	damage_states = FALSE	//Maybe later
	sprite_size = 96
	bound_height = 128
	bound_width = 128
	armor = list("overmap_light" = 90, "overmap_medium" = 70, "overmap_heavy" = 50)
	ai_flags = AI_FLAG_BATTLESHIP | AI_FLAG_DESTROYER | AI_FLAG_ELITE
	max_tracking_range = 70	//Big sensors, they gotta be useful
	flak_battery_amount = 2
	mass = MASS_LARGE
	shots_left = 26	//8 for missiles, 18 for the main gun.
	missiles = 8
	torpedoes = 0
	combat_dice_type = /datum/combat_dice/cruiser
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/kadesh/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/interdiction)

/obj/structure/overmap/syndicate/ai/kadesh/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = null
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/mac(src)
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	weapon_types[FIRE_MODE_MISSILE] = new /datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/kadesh/on_interdict()
	add_sensor_profile_penalty(150, 10 SECONDS)

/obj/structure/overmap/syndicate/ai/fistofsol
	name = "SSV Fist of Sol"
	icon = 'nsv13/icons/overmap/syndicate/tuningfork.dmi'
	icon_state = "tuningfork"
	desc = "A terrifying vessel packing every inch of the Syndicate's abhorrent arsenal."
	mass = MASS_LARGE
	sprite_size = 128
	bound_width = 128
	bound_height = 128
	damage_states = FALSE
	max_weapon_range = 85
	obj_integrity = 5000
	max_integrity = 5000
	speed_limit = 16
	flak_battery_amount = 3
	max_tracking_range = 90
	armor = list("overmap_light" = 99, "overmap_medium" = 65, "overmap_heavy" = 40)
	ai_controlled = TRUE
	shots_left = 500
	missiles = 30
	ai_behaviour = AI_AGGRESSIVE
	ai_flags = AI_FLAG_ELITE | AI_FLAG_BATTLESHIP
	can_resupply = TRUE
	combat_dice_type = /datum/combat_dice/battleship
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/syndicate/ai/fighter,
							/obj/structure/overmap/syndicate/ai/bomber)

/obj/structure/overmap/syndicate/ai/fistofsol/apply_weapons()
	weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/twinmac(src)
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/hailstorm(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/quadgauss(src)
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_MISSILE] = new /datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/syndicate/ai/fistofsol/Destroy()
	if(!current_system)
		return ..()
	for(var/obj/structure/overmap/survivor in (current_system.system_contents - src)) //In case for some reason our Fist is piloted
		if(survivor.ai_controlled)
			continue
		for(var/mob/living/victorious_mob in survivor.mobs_in_ship)
			if(!victorious_mob.client)
				continue
			victorious_mob.client.give_award(/datum/award/achievement/misc/fist_breaker, victorious_mob)
	return ..()

/obj/structure/overmap/hostile/ai/alicorn
	name = "SGV Alicorn"
	desc = "One Billion Lives!"
	icon = 'nsv13/icons/overmap/alicorn.dmi'
	icon_state = "alicorn"
	faction = "hostile"
	mass = MASS_LARGE
	sprite_size = 128
	damage_states = FALSE
	bound_width = 128
	bound_height = 128
	obj_integrity = 4750
	max_integrity = 4750
	cloak_factor = 100
	shots_left = 350
	torpedoes = 60
	ai_controlled = TRUE
	armor = list("overmap_light" = 99, "overmap_medium" = 70, "overmap_heavy" = 65)
	can_resupply = TRUE
	ai_flags = AI_FLAG_BATTLESHIP | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/carrier
	ai_can_launch_fighters = TRUE
	ai_fighter_type = list(/obj/structure/overmap/hostile/ai/fighter)
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/hellfire
	flak_battery_amount = 3

/obj/structure/overmap/hostile/ai/alicorn/Initialize(mapload)
	. = ..()
	handle_cloak(TRUE)

/obj/structure/overmap/hostile/ai/alicorn/apply_weapons()
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/quadgauss(src)
	weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/prototype_bsa(src)
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)

/obj/structure/overmap/hostile/ai/fighter
	name = "Rattlesnake Strike fighter"
	icon = 'nsv13/icons/overmap/alicorn.dmi'
	icon_state = "alifighter"
	damage_states = FALSE
	mass = MASS_TINY
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	weapon_safety = FALSE
	faction = "hostile"
	armor = list("overmap_light" = 10, "overmap_medium" = 5, "overmap_heavy" = 95)
	obj_integrity = 115
	max_integrity = 115 //Slightly less squishy!
	ai_flags = AI_FLAG_SWARMER
	bound_width = 32
	bound_height = 32
	torpedoes = 1
	missiles = 4
	combat_dice_type = /datum/combat_dice/fighter
	torpedo_type = /obj/item/projectile/guided_munition/torpedo/disruptor

/obj/structure/overmap/hostile/ai/fighter/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new/datum/ship_weapon/light_cannon(src)
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)


/obj/structure/overmap/syndicate/ai/fighter //need custom AI behaviour to escort bombers if applicable
	name = "Syndicate interceptor"
	icon = 'nsv13/icons/overmap/new/nanotrasen/fighter_overmap.dmi'
	icon_state = "fighter_syndicate"
	damage_states = FALSE
	brakes = FALSE
	obj_integrity = 75
	max_integrity = 75 //Super squishy!
	sprite_size = 32
	faction = "syndicate"
	mass = MASS_TINY
	bound_width = 32 //Change this on a per ship basis
	bound_height = 32
	missiles = 4
	torpedoes = 0
	bounty = 250
	armor = list("overmap_light" = 5, "overmap_medium" = 0, "overmap_heavy" = 90)
	ai_flags = AI_FLAG_SWARMER
	combat_dice_type = /datum/combat_dice/fighter
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/fighter/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new/datum/ship_weapon/light_cannon(src)
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)


/obj/structure/overmap/syndicate/ai/bomber //need custom AI behaviour to target capitals only
	name = "Syndicate Bomber"
	icon = 'nsv13/icons/overmap/new/nanotrasen/fighter_overmap.dmi'
	icon_state = "bomber_syndicate"
	damage_states = FALSE
	brakes = FALSE
	obj_integrity = 100
	max_integrity = 100
	sprite_size = 32
	faction = "syndicate"
	mass = MASS_TINY
	missiles = 0
	torpedoes = 3
	bounty = 250
	armor = list("overmap_light" = 20, "overmap_medium" = 10, "overmap_heavy" = 90)
	ai_flags = AI_FLAG_DESTROYER | AI_FLAG_SWARMER
	combat_dice_type = /datum/combat_dice/bomber
	possible_interior_maps = list()

/obj/structure/overmap/syndicate/ai/bomber/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new/datum/ship_weapon/light_cannon(src)
	weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/torpedo_launcher(src)


