
//Nanotrasen ships go here

/**
	Armour quadrants are now automatically set up on anything above fighters in size class. If you want to customize your armour plate setups, use this format (use_armour_quadrants says you've preset the armour already)
	use_armour_quadrants = TRUE
	armour_quadrants = list("forward_port" = list("name" = "Forward Port", "max_armour" = 3000, "current_armour" = 3000),\
							"forward_starboard" = list("name" = "Forward Starboard", "max_armour" = 3000, "current_armour" = 3000),\
							"aft_port" = list("name" = "Aft Port", "max_armour" = 3000, "current_armour" = 3000),\
							"aft_starboard" = list("name" = "Aft Starboard", "max_armour" = 3000, "current_armour" = 3000))

*/

/obj/structure/overmap/nanotrasen
	name = "nanotrasen ship"
	desc = "A NT owned space faring vessel."
	icon = 'nsv13/icons/overmap/default.dmi'
	icon_state = "default"
	faction = "nanotrasen"

/obj/structure/overmap/nanotrasen/light_cruiser
	name = "raptor class light frigate"
	icon = 'nsv13/icons/overmap/new/nanotrasen/frigate.dmi'
	icon_state = "kestrel"
	mass = MASS_SMALL
	sprite_size = 48
	damage_states = FALSE
	bound_height = 32
	bound_width = 32
	obj_integrity = 300
	max_integrity = 300
	armor = list("overmap_light" = 30, "overmap_medium" = 20, "overmap_heavy" = 30)


/obj/structure/overmap/nanotrasen/patrol_cruiser
	name = "lupine class patrol cruiser"
	icon = 'nsv13/icons/overmap/new/nanotrasen/cruiser.dmi'
	icon_state = "heavy_cruiser"
	mass = MASS_LARGE
	sprite_size = 48
	obj_integrity = 450
	max_integrity = 450
	bound_height = 96
	bound_width = 96
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)

/obj/structure/overmap/nanotrasen/frigate //This has nothing to do with missiles
	name = "caracal class frigate"
	icon = 'nsv13/icons/overmap/new/nanotrasen/frigate.dmi'
	icon_state = "frigate"
	mass = MASS_SMALL
	sprite_size = 48
	damage_states = FALSE
	//pixel_z = -96
	//pixel_w = -96
	obj_integrity = 500
	max_integrity = 500
	//collision_positions = list(new /datum/vector2d(-13,71), new /datum/vector2d(-25,52), new /datum/vector2d(-24,-25), new /datum/vector2d(-11,-66), new /datum/vector2d(4,-69), new /datum/vector2d(15,-28), new /datum/vector2d(15,38), new /datum/vector2d(6,61))
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)

/obj/structure/overmap/nanotrasen/heavy_cruiser
	name = "corvid class tactical cruiser"
	icon = 'nsv13/icons/overmap/new/nanotrasen/cruiser.dmi'
	icon_state = "cruiser"
	mass = MASS_LARGE
	sprite_size = 48
	//damage_states = TRUE
	//pixel_z = -32
	//pixel_w = -32
	obj_integrity = 800
	max_integrity = 800
	bound_height = 96
	bound_width = 96
	armor = list("overmap_light" = 90, "overmap_medium" = 80, "overmap_heavy" = 30)

/obj/structure/overmap/nanotrasen/battleship
	name = "jupiter class battlestar"
	desc = "A flying fortress specialising in levelling large, stationary targets such as space stations or planetside colonies."
	icon = 'nsv13/icons/overmap/new/nanotrasen/titan.dmi'
	icon_state = "titan"
	mass = MASS_TITAN
	sprite_size = 48
	damage_states = FALSE
	bound_width = 192
	bound_height = 192
	obj_integrity = 1000
	max_integrity = 1000
	armor = list("overmap_light" = 95, "overmap_medium" = 75, "overmap_heavy" = 50)

/obj/structure/overmap/nanotrasen/carrier
	name = "enterprise class carrier"
	desc = "A gigantic ship which is capable of staying deployed in space for extended periods while supporting an impressive complement of fighters."
	icon = 'nsv13/icons/overmap/new/nanotrasen/cruiser.dmi'
	icon_state = "cruiser"
	bound_width = 96
	bound_height = 96
	mass = MASS_LARGE
	sprite_size = 48
	damage_states = FALSE //TODO
	obj_integrity = 700
	max_integrity = 700
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 10)

/obj/structure/overmap/nanotrasen/battlecruiser
	name = "corvid class tactical cruiser"
	icon = 'nsv13/icons/overmap/new/nanotrasen/cruiser.dmi'
	icon_state = "cruiser"
	mass = MASS_LARGE
	sprite_size = 48
	//damage_states = TRUE
	//pixel_z = -32
	//pixel_w = -32
	obj_integrity = 1000
	max_integrity = 1000 //Max health
	bound_height = 96
	bound_width = 96
	armor = list("overmap_light" = 95, "overmap_medium" = 75, "overmap_heavy" = 50)

//Instanced Versions

/obj/structure/overmap/nanotrasen/gunstar
	name = "Acropolis class heavy cruiser"
	desc = "A prototype gunship typically reserved for the admiralty which is capable of delivering an overwhelming amount of firepower for its size. Its design crams the firepower of a battlestar into a cruiser frame to deliver extreme punishment using cutting edge weapons research."
	icon = 'nsv13/icons/overmap/nanotrasen/gunstar.dmi'
	icon_state = "gunstar"
	mass = MASS_LARGE //Big beefy lad with a lot of firepower.
	sprite_size = 48
	damage_states = FALSE //I'm lazy
	obj_integrity = 1200
	max_integrity = 1200 //Max health
	armor = list("overmap_light" = 95, "overmap_medium" = 60, "overmap_heavy" = 10)
	bound_height = 320
	bound_width = 320
	role = INSTANCED_MIDROUND_SHIP

/obj/structure/overmap/nanotrasen/gunstar/apply_weapons()
	. = ..()
	weapon_types[FIRE_MODE_RED_LASER] = new /datum/ship_weapon/burst_phaser(src)
	weapon_types[FIRE_MODE_BLUE_LASER] = new /datum/ship_weapon/phaser(src)

/obj/structure/overmap/nanotrasen/serendipity
	name = "DLV Serendipity"
	desc = "a serendipity class exploration and research vessel"
	icon = 'nsv13/icons/overmap/new/nanotrasen/serendipity.dmi'
	icon_state = "serendipity"
	mass = MASS_SMALL
	sprite_size = 48
	damage_states = FALSE
	bound_height = 32
	bound_width = 32
	obj_integrity = 1250
	max_integrity = 1250
	armor = list("overmap_light" = 30, "overmap_medium" = 20, "overmap_heavy" = 30)
	plasma_caster = TRUE //One day we'll assign these a smarter way..

//Player Versions
// deletion_behavior = DAMAGE_STARTS_COUNTDOWN
// starting_system = "Staging"
/obj/structure/overmap/nanotrasen/light_cruiser/starter //Currently assigned to Eclipse
	role = MAIN_OVERMAP
	obj_integrity = 1400
	max_integrity = 1400 //Max health
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 50, "overmap_heavy" = 10)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/frigate/starter/shrike //TEMP UNTIL WE DIVERSIFY TYPES MORE
	icon_state = "shrike"

/obj/structure/overmap/nanotrasen/frigate/starter/shrike/apply_weapons()
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	weapon_types[FIRE_MODE_HYBRID_RAIL] = new /datum/ship_weapon/hybrid_railgun(src)

/obj/structure/overmap/nanotrasen/frigate/starter //Currently assigned to Jeppison and Atlas
	role = MAIN_OVERMAP
	obj_integrity = 800
	max_integrity = 800
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 90, "overmap_medium" = 50, "overmap_heavy" = 10)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/patrol_cruiser/starter //Currently assigned to the Snake
	role = MAIN_OVERMAP
	obj_integrity = 1000
	max_integrity = 1000
	bound_width = 64
	bound_height = 64
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 50, "overmap_heavy" = 10)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN
	broadside = TRUE

/obj/structure/overmap/nanotrasen/heavy_cruiser/starter //Currently assigned to Hammerhead
	icon = 'nsv13/icons/overmap/new/nanotrasen/heavy_cruiser.dmi'
	icon_state = "heavy_cruiser"
	role = MAIN_OVERMAP
	obj_integrity = 1400
	max_integrity = 1400
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 60, "overmap_heavy" = 20)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN
	broadside = TRUE

/obj/structure/overmap/nanotrasen/heavy_cruiser/starter/spec_collision_handling(obj/structure/overmap/other_ship, list/impact_powers, impact_angle)
	var/modified_angle = 360 - ((angle + 630) % 360)
	var/angle_diff = impact_angle - modified_angle
	if(abs(angle_diff) > HAMMERHEAD_COLLISION_GUARD_ANGLE)
		return
	impact_powers[1] *= 0.5 // x 0.5 self damage
	impact_powers[2] *= 2.5 // x 2.5 other damage

/obj/structure/overmap/nanotrasen/heavy_cruiser/starter/apply_weapons()
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	weapon_types[FIRE_MODE_BROADSIDE] = new /datum/ship_weapon/broadside(src)

/obj/structure/overmap/nanotrasen/carrier/starter //NOT CURRENTLY ASSIGNED
	role = MAIN_OVERMAP
	obj_integrity = 2000
	max_integrity = 2000
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 65, "overmap_heavy" = 20)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/battlecruiser/starter //Currently assigned to Tycoon and Gladius
	role = MAIN_OVERMAP
	obj_integrity = 1600
	max_integrity = 1600
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 75, "overmap_heavy" = 50) //Cruisers should be able to take substantially more damage than Frigates and destroyers
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/battleship/starter //Galactica
	role = MAIN_OVERMAP //Player controlled variant
	obj_integrity = 2400
	max_integrity = 2400
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 98, "overmap_medium" = 95, "overmap_heavy" = 65) //This ship is a dreadnaught, is armored accordingly and should largely not care about lighter munitions.
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/serendipity/starter
	role = MAIN_OVERMAP
	obj_integrity = 1200
	max_integrity = 1200
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 95, "overmap_medium" = 50, "overmap_heavy" = 10)
	overmap_deletion_traits = DAMAGE_STARTS_COUNTDOWN

/obj/structure/overmap/nanotrasen/serendipity/starter/apply_weapons()
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
	weapon_types[FIRE_MODE_PHORON] = new /datum/ship_weapon/plasma_caster(src)

//AI Versions

/obj/structure/overmap/nanotrasen/ai //Generic good guy #10000.
	name = "raptor class light frigate"
	icon = 'nsv13/icons/overmap/new/nanotrasen/frigate.dmi'
	icon_state = "kestrel"
	mass = MASS_SMALL
	sprite_size = 48
	damage_states = FALSE
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	mass = MASS_MEDIUM
	sprite_size = 48
	ai_flags= AI_FLAG_DESTROYER
	combat_dice_type = /datum/combat_dice/frigate

/obj/structure/overmap/nanotrasen/patrol_cruiser/ai
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	obj_integrity = 450
	max_integrity = 450 //Max health
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)
	ai_flags  = AI_FLAG_BATTLESHIP | AI_FLAG_DESTROYER
	combat_dice_type = /datum/combat_dice/destroyer

/obj/structure/overmap/nanotrasen/heavy_cruiser/ai
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	obj_integrity = 800
	max_integrity = 800 //Max health
	armor = list("overmap_light" = 90, "overmap_medium" = 80, "overmap_heavy" = 30)
	ai_flags = AI_FLAG_BATTLESHIP
	combat_dice_type = /datum/combat_dice/cruiser

/obj/structure/overmap/nanotrasen/battleship/ai
	obj_integrity = 1000
	max_integrity = 1000
	armor = list("overmap_light" = 95, "overmap_medium" = 75, "overmap_heavy" = 50)
	ai_controlled = TRUE
	ai_flags = AI_FLAG_BATTLESHIP
	combat_dice_type = /datum/combat_dice/battleship

/obj/structure/overmap/nanotrasen/frigate/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_DESTROYER
	torpedoes = 10 //it's vago, alright?
	missiles = 10
	obj_integrity = 500
	max_integrity = 500
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 20)
	combat_dice_type = /datum/combat_dice/cruiser

/obj/structure/overmap/nanotrasen/battlecruiser/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_BATTLESHIP
	obj_integrity = 450
	max_integrity = 450
	armor = list("overmap_light" = 90, "overmap_medium" = 70, "overmap_heavy" = 30)
	combat_dice_type = /datum/combat_dice/cruiser

/obj/structure/overmap/nanotrasen/carrier/ai
	ai_controlled = TRUE
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/nanotrasen/ai/fighter)
	torpedoes = 0
	can_resupply = TRUE
	ai_flags = AI_FLAG_SUPPLY
	obj_integrity = 700
	max_integrity = 700
	armor = list("overmap_light" = 90, "overmap_medium" = 60, "overmap_heavy" = 10)
	combat_dice_type = /datum/combat_dice/carrier

/obj/structure/overmap/nanotrasen/carrier/ai/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src) //AI ships want to be able to use gauss too. I say let them...
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)

/obj/structure/overmap/nanotrasen/carrier/ai/get_max_firemode() //This boy really doesn't need a railgun
	return FIRE_MODE_ANTI_AIR

/obj/structure/overmap/nanotrasen/ai/fighter
	name = "Viper class light fighter"
	icon = 'nsv13/icons/overmap/new/nanotrasen/fighter_overmap.dmi'
	icon_state = "fighter"
	damage_states = FALSE
	mass = MASS_TINY
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	weapon_safety = FALSE
	faction = "nanotrasen"
	armor = list("overmap_light" = 5, "overmap_medium" = 0, "overmap_heavy" = 90)
	obj_integrity = 75
	max_integrity = 75 //Super squishy!
	ai_flags = AI_FLAG_SWARMER
	bound_width = 32 //Change this on a per ship basis
	bound_height = 32
	combat_dice_type = /datum/combat_dice/fighter

/obj/structure/overmap/nanotrasen/ai/fighter/apply_weapons()
	weapon_types[FIRE_MODE_ANTI_AIR] = new/datum/ship_weapon/light_cannon(src)
	weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)



