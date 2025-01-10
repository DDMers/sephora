
//Solgov ships go here
//These need to not be children of nanotrasen come starmap 2
/obj/structure/overmap/nanotrasen/solgov/vnc
	name = "Von Neumann class patrol frigate"
	desc = "A long-range SolGov patrol boat, usually used for clearing asteroid fields."
	icon = 'nsv13/icons/overmap/new/solgov/frigate.dmi'
	icon_state = "frigate"
	mass = MASS_MEDIUM
	sprite_size = 48
	damage_states = FALSE
	bound_width = 32
	bound_height = 32
	obj_integrity = 250
	max_integrity = 250
	armor = list("overmap_light" = 90, "overmap_medium" = 20, "overmap_heavy" = 5)


/obj/structure/overmap/nanotrasen/solgov
	name = "yangtzee-kiang class light cruiser"
	desc = "A mid range SolGov patrol craft, usually relegated to anti-piracy operations."
	icon = 'nsv13/icons/overmap/nanotrasen/solgov_cruiser.dmi'
	icon_state = "cruiser"
	mass = MASS_LARGE
	sprite_size = 48
	damage_states = FALSE
	bound_width = 96
	bound_height = 96
	obj_integrity = 500
	max_integrity = 500
	armor = list("overmap_light" = 90, "overmap_medium" = 50, "overmap_heavy" = 25)

/obj/structure/overmap/nanotrasen/solgov/carrier
	name = "rio-grande class support cruiser"
	desc = "An armoured support cruiser capable of resupplying ships extremely quickly."
	icon = 'nsv13/icons/overmap/nanotrasen/prototype_cruiser.dmi'
	icon_state = "cruiser"
	damage_states = TRUE
	bound_height = 96
	bound_width = 96
	//Tanky
	obj_integrity = 1000
	max_integrity = 1000
	armor = list("overmap_light" = 90, "overmap_medium" = 70, "overmap_heavy" = 20)

/obj/structure/overmap/nanotrasen/solgov/aetherwhisp
	name = "Aetherwhisp class light cruiser"
	desc = "A mid range SolGov exploratory cruiser. These ships are geared for peaceful missions, but can defend themselves if they must."
	icon = 'nsv13/icons/overmap/nanotrasen/aetherbrick.dmi'
	icon_state = "cruiser"
	mass = MASS_MEDIUM_LARGE // A solgov ship has greater maneuverability but not much more than a LARGE NT ship
	sprite_size = 48
	damage_states = FALSE
	bound_height = 128
	bound_width = 128
	obj_integrity = 750
	max_integrity = 750
	armor = list("overmap_light" = 90, "overmap_medium" = 50, "overmap_heavy" = 25)

//Player Versions

/obj/structure/overmap/nanotrasen/solgov/aetherwhisp/starter
	icon = 'nsv13/icons/overmap/nanotrasen/aetherwhisp.dmi'
	role = MAIN_OVERMAP
	obj_integrity = 750
	max_integrity = 750 //She's fragile and relies heavily on shields.
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 99, "overmap_medium" = 50, "overmap_heavy" = 25)

/obj/structure/overmap/nanotrasen/solgov/vnc/starter
	role = MAIN_OVERMAP
	obj_integrity = 500
	max_integrity = 500//you will eat the ROUNDS.
	starting_system = "Staging" //Required for all player ships
	armor = list("overmap_light" = 99, "overmap_medium" = 50, "overmap_heavy" = 25)

//AI Versions

/obj/structure/overmap/nanotrasen/solgov/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_DESTROYER
	combat_dice_type = /datum/combat_dice/destroyer
	shots_left = 10000 //Issa laser.
	torpedoes = 10
	missiles = 10

// Solgov Kadesh? Solgov Kadesh.
/obj/structure/overmap/nanotrasen/solgov/ai/interdictor
	name = "Capiens class medium cruiser"
	desc = "A SolGov pursuit craft, meant for tracking and cornering high value targets."
	icon = 'nsv13/icons/overmap/new/solgov/destroyer.dmi'
	icon_state = "cruiser"
	obj_integrity = 1200
	max_integrity = 1200
	ai_flags = AI_FLAG_BATTLESHIP | AI_FLAG_DESTROYER | AI_FLAG_ELITE
	max_tracking_range = 70
	flak_battery_amount = 2
	combat_dice_type = /datum/combat_dice/cruiser

/obj/structure/overmap/nanotrasen/solgov/ai/interdictor/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/interdiction)

/obj/structure/overmap/nanotrasen/solgov/aetherwhisp/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_DESTROYER
	combat_dice_type = /datum/combat_dice/destroyer

/obj/structure/overmap/nanotrasen/solgov/carrier/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_SUPPLY
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/nanotrasen/solgov/ai/fighter)
	torpedoes = 0
	can_resupply = TRUE
	combat_dice_type = /datum/combat_dice/carrier


/obj/structure/overmap/nanotrasen/solgov/vnc/ai
	ai_controlled = TRUE
	ai_flags = AI_FLAG_DESTROYER
	ai_can_launch_fighters = TRUE //AI variable. Allows your ai ships to spawn fighter craft
	ai_fighter_type = list(/obj/structure/overmap/nanotrasen/solgov/ai/fighter)
	shots_left = 10000 //Issa laser.
	torpedoes = 15
	can_resupply = TRUE
	combat_dice_type = /datum/combat_dice/frigate

//These little bastards are feckin horrible
/obj/structure/overmap/nanotrasen/solgov/ai/fighter //need custom AI behaviour to escort bombers if applicable
	name = "peregrine class attack fighter"
	desc = "A formidable light fighter with a small shield generator and 'stinger' class laser weapons."
	icon = 'nsv13/icons/overmap/new/solgov/fighter.dmi'
	icon_state = "fighter"
	damage_states = FALSE
	brakes = FALSE
	obj_integrity = 125
	max_integrity = 125 //Super squishy!
	sprite_size = 32
	mass = MASS_TINY
	bound_width = 32 //Change this on a per ship basis
	bound_height = 32
	missiles = 0
	torpedoes = 0
	armor = list("overmap_light" = 5, "overmap_medium" = 5,  "overmap_heavy" = 90)
	ai_flags = AI_FLAG_SWARMER | AI_FLAG_ELITE
	combat_dice_type = /datum/combat_dice/fighter

/obj/structure/overmap/nanotrasen/solgov/ai/fighter/apply_weapons()
	// Burst fire on solgov fighters
	var/datum/ship_weapon/SW = new /datum/ship_weapon/burst_phaser( src )
	SW.burst_size = 3
	weapon_types[ FIRE_MODE_RED_LASER ] = SW
	//The bigger the ship, the tankier the shields....
	AddComponent(/datum/component/overmap_shields, mass*600, mass*600, mass*15)

/obj/structure/overmap/nanotrasen/solgov/proc/apply_medium_ai_weapons()
	weapon_types[ FIRE_MODE_RED_LASER ] = new /datum/ship_weapon/burst_phaser( src )
	weapon_types[ FIRE_MODE_BLUE_LASER ] = new /datum/ship_weapon/phaser( src )
	weapon_types[ FIRE_MODE_LASER_PD ] = new /datum/ship_weapon/phaser_pd( src )
	weapon_types[ FIRE_MODE_AMS_LASER ] = new /datum/ship_weapon/laser_ams( src )

	// Need to enable the AI ship's countermeasures mode so they can actually use laser ams
	for( var/datum/ams_mode/atype in src.ams_modes )
		// if ( istype( atype, /datum/ams_mode/countermeasures ) )
		atype.enabled = TRUE

	//The bigger the ship, the tankier the shields....
	AddComponent(/datum/component/overmap_shields, mass*600, mass*600, mass*15)

/obj/structure/overmap/nanotrasen/solgov/proc/apply_light_ai_weapons()  // this is the von neumann only for now, but maybe....
	weapon_types[ FIRE_MODE_RED_LASER ] = new /datum/ship_weapon/burst_phaser( src )
	weapon_types[ FIRE_MODE_LASER_PD ] = new /datum/ship_weapon/phaser_pd( src )
	weapon_types[ FIRE_MODE_AMS_LASER ] = new /datum/ship_weapon/laser_ams( src )
	weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/torpedo_launcher(src)  // Full spread, fire

	// Need to enable the AI ship's countermeasures mode so they can actually use laser ams
	for( var/datum/ams_mode/atype in src.ams_modes )
		// if ( istype( atype, /datum/ams_mode/countermeasures ) )
		atype.enabled = TRUE

	//The bigger the ship, the tankier the shields....
	AddComponent(/datum/component/overmap_shields, mass*600, mass*600, mass*15)

/obj/structure/overmap/nanotrasen/solgov/apply_weapons()
	// Solgov do not need Nanotrasen weapons registered on roundstart. This bloats the ship's weapon_types and makes cycling via spacebar take much longer
	// . = ..()
	weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)

/obj/structure/overmap/nanotrasen/solgov/carrier/ai/apply_weapons() // Kmc why didn't you use /solgov/ai for your ship childtypes
	apply_medium_ai_weapons()

/obj/structure/overmap/nanotrasen/solgov/vnc/ai/apply_weapons()
	apply_light_ai_weapons()

/obj/structure/overmap/nanotrasen/solgov/aetherwhisp/ai/apply_weapons()
	apply_medium_ai_weapons()

/obj/structure/overmap/nanotrasen/solgov/ai/apply_weapons()
	apply_medium_ai_weapons()
