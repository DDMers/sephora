
/////////////////////////////////////////////////////////////////////////////////
// ACKNOWLEDGEMENTS:  Credit to yogstation (Monster860) for the movement code. //
// I had no part in writing the movement engine, that's his work               //
/////////////////////////////////////////////////////////////////////////////////

/mob
	var/obj/structure/overmap/overmap_ship //Used for relaying movement, hotkeys etc.

/obj/structure/overmap
	name = "overmap ship"
	desc = "A space faring vessel."
	icon = 'nsv13/icons/overmap/default.dmi'
	icon_state = "default"
	density = TRUE
	dir = NORTH
	layer = ABOVE_MOB_LAYER
	animate_movement = NO_STEPS // Override the inbuilt movement engine to avoid bouncing
	req_one_access = list(ACCESS_HEADS, ACCESS_MUNITIONS, ACCESS_SEC_DOORS, ACCESS_ENGINE) //Bridge assistants/heads, munitions techs / fighter pilots, security officers, engineering personnel all have access.

	move_resist = MOVE_FORCE_OVERPOWERING //THIS MAY BE A BAD IDEA - (okay I downgraded from INFINITE)
	anchored = FALSE
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF // Overmap ships represent massive craft that don't burn

	//Handling for deleting ships with interiors, see nsv13/code/__DEFINES/overmap.dm
	//Defaults are set for AI ships
	var/block_deletion = FALSE // used to avoid killing objectives
	var/overmap_deletion_traits = DAMAGE_DELETES_UNOCCUPIED | DAMAGE_STARTS_COUNTDOWN
	var/deletion_teleports_occupants = FALSE

	var/sprite_size = 64 //Pixels. This represents 64x64 and allows for the bullets that you fire to align properly.
	var/area_type = null //Set the type of the desired area you want a ship to link to, assuming it's not the main player ship.
	var/impact_sound_cooldown = FALSE //Avoids infinite spamming of the ship taking damage.
	///Handles cooldown between collisions to avoid certain very bad times :)
	var/next_collision = 0
	var/datum/star_system/current_system //What star_system are we currently in? Used for parallax.
	var/resize = 0 //Factor by which we should shrink a ship down. 0 means don't shrink it.
	var/list/docking_points = list() //Where we can land on this ship. Usually right at the edge of a z-level.
	var/last_slowprocess = 0

	var/list/linked_areas = list() //List of all areas that we control
	var/datum/gas_mixture/cabin_air //Cabin air mix used for small ships like fighters (see overmap/fighters/fighters.dm)
	var/obj/machinery/portable_atmospherics/canister/internal_tank //Internal air tank reference. Used mostly in small ships. If you want to sabotage a fighter, load a plasma tank into its cockpit :)
	CanAtmosPass = ATMOS_PASS_YES

	// Health, armor, and damage
	max_integrity = 300 //Max internal integrity
	integrity_failure = 0 //If you want to use this you will have to implement obj_break() for overmaps aswell as a method to restore functionality if repaired.
	var/armour_plates = 0 //You lose max integrity when you lose armour plates.
	var/sensor_profile = 0	//A penalty (or, possibly even bonus) to from how far away one can be detected. Affected by things like sending out a active ping, which will make you glow like a christmas tree.
	var/cloak_factor = 255 // Min alpha of a ship during cloak. 0-255
	var/max_armour_plates = 0
	var/list/dent_decals = list() //Ships get visibly damaged as they get shot
	var/damage_states = FALSE //Did you sprite damage states for this ship? If yes, set this to true
	///Hullburn time, this is basically a DoT effect on ships. One day I'll have to add actual ship status effects, siiiigh.
	var/hullburn = 0
	///Hullburn strength is what determines the damage per tick, the strongest damage usually goes. Which means, a weaker weapon could be used to lengthen the duration of a strong but short one.
	var/hullburn_power = 0
	var/disruption = 0	//Causes bad effects proportional to how significant. Most significant for AI ships (or fighters) hit by disruption weapons.

	var/use_armour_quadrants = FALSE //Does the object use the armour quadrant system?
	var/max_armour = 0 //Max armour amount per quad
	var/current_armour = 0 //Per quad
	var/list/armour_quadrants = list("forward_port" = list(), "forward_starboard" = list(), "aft_port" = list(), "aft_starboard" = list()) //Our four quadrants
	var/linked_apnw = null //Our linked APNW

	var/structure_crit = FALSE //Handles when the ship's integrity has failed
	var/structure_crit_no_return = FALSE //Override for handling point of no return
	var/structure_crit_init = null //Timer ID for point of no return
	var/structure_crit_alert = 0 //Incremental warning states
	var/last_critprocess = 0 //Keeper for SS Crit timing
	var/explosion_cooldown = FALSE

	//Movement Variables
	var/offset_x = 0 // like pixel_x/y but in tiles
	var/offset_y = 0
	var/angle = 0 // degrees, clockwise
	var/keyboard_delta_angle_left = 0 // Set by use of turning key
	var/keyboard_delta_angle_right = 0 // Set by use of turning key
	var/movekey_delta_angle = 0 // A&D support
	var/desired_angle = null // set by pilot moving his mouse or by keyboard steering
	var/angular_velocity = 0 // degrees per second
	var/max_angular_acceleration = 180 // in degrees per second per second
	var/speed_limit = 3.5 //Stops ships from going too damn fast. This can be overridden by things like fighters launching from tubes, so it's not a const.
	var/last_thrust_forward = 0
	var/last_thrust_right = 0
	var/last_rotate = 0
	var/should_open_doors = FALSE //Should we open airlocks? This is off by default because it was HORRIBLE.
	var/inertial_dampeners = TRUE

	var/user_thrust_dir = 0

	//Movement speed variables
	var/forward_maxthrust = 6
	var/backward_maxthrust = 3
	var/side_maxthrust = 1
	var/mass = MASS_SMALL //The "mass" variable will scale the movespeed according to how large the ship is.

	var/bump_impulse = 0.6
	var/bounce_factor = 0.7 // how much of our velocity to keep on collision
	var/lateral_bounce_factor = 0.95 // mostly there to slow you down when you drive (pilot?) down a 2x2 corridor

	var/brakes = FALSE //Helps you stop the ship
	var/rcs_mode = FALSE //stops you from swivelling on mouse move
	var/move_by_mouse = FALSE //Mouse guided turning

	//Logging
	var/list/weapon_log = list() //Shows who did the firing thing

	// Mobs
	var/mob/living/pilot //Physical mob that's piloting us. Cameras come later
	var/mob/living/gunner //The person who fires the guns.
	var/list/gauss_gunners = list() //Anyone sitting in a gauss turret who should be able to commit pew pew against syndies.
	var/list/operators = list() //Everyone who needs their client updating when we move.
	var/list/mobs_in_ship = list() //A list of mobs which is inside the ship. This is generated by our areas.dm file as they enter / exit areas
	var/list/overmaps_in_ship = list() //A list of smaller overmaps inside the ship

	//Beacons
	var/list/beacons_in_ship = list()

	// Controlling equipment

	/*
	These are probably more okay not being lists since only one person can control either of these two slots at a time.
	*/
	var/obj/machinery/computer/ship/helm/helm //Relay beeping noises when we act
	var/obj/machinery/computer/ship/tactical/tactical

	/*
		|| THIS SHOULD BE A LIST, there could be a billion dradises that can keep fighting for which one is considered the ship dradis any time someone interacts with one!!!
		|| When you change this, also change the reference cleaning on del for this var from being on the dradis to being on the ship listening for the console's QDEL signal.
		\/ I'm not feeling like refactoring that right now though. Maybe in the future. -Delta
	*/
	var/obj/machinery/computer/ship/dradis/dradis //So that pilots can check the radar easily

	// Ship weapons
	var/list/weapon_types[MAX_POSSIBLE_FIREMODE]
	var/list/weapon_numkeys_map = list() // I hate this

	var/fire_mode = FIRE_MODE_TORPEDO //What gun do we want to fire? Defaults to railgun, with PDCs there for flak
	var/weapon_safety = FALSE //Like a gun safety. Entirely un-used except for fighters to stop brainlets from shooting people on the ship unintentionally :)
	var/faction = null //Used for target acquisition by AIs

	var/list/weapon_overlays = list()
	var/obj/weapon_overlay/last_fired //Last weapon overlay that fired, so we can rotate guns independently
	var/atom/last_target //Last thing we shot at, used to point the railgun at an enemy.

	var/static/ai_resupply_time = 1.5 MINUTES
	var/ai_resupply_scheduled = FALSE
	var/torpedoes = 0 //If this starts at above 0, then the ship can use torpedoes when AI controlled
	var/missiles = 0 //If this starts at above 0, then the ship can use missiles when AI controlled

	var/list/torpedoes_to_target = list() //Torpedoes that have been fired explicitly at us, and that the PDCs need to worry about.
	var/atom/target_lock = null // Our "locked" target. This is what manually fired guided weapons will track towards.
	var/can_lock = TRUE //Can we lock on to people or not
	var/lockon_time = 2 SECONDS
	var/list/target_painted = list() // How many targets we've "painted" for AMS/relay targeting, associated with the ship supplying the datalink (if any)
	var/list/target_last_tracked = list() // When we last tracked a target
	var/max_paints = 3 // The maximum amount of paints we can sustain at any one time.
	var/target_loss_time = 3 SECONDS
	var/autotarget = FALSE // Whether we autolock onto painted targets or not.
	var/no_gun_cam = FALSE // Var for disabling the gunner's camera
	var/list/ams_modes = list()
	var/list/ams_data_source = AMS_LOCKED_TARGETS
	var/next_ams_shot = 0
	var/ams_targeting_cooldown = 1.5 SECONDS
	var/ams_shot_limit = 5
	var/ams_shots_fired = 0

	// Railgun aim helper
	var/last_tracer_process = 0
	var/aiming = FALSE
	var/aiming_lastangle = 0
	var/lastangle = 0
	var/list/obj/effect/projectile/tracer/current_tracers
	var/mob/listeningTo
	var/obj/aiming_target
	var/aiming_params
	var/atom/autofire_target = null

	// Trader delivery locations
	var/list/trader_beacons = null

	var/uid = 0 //Unique identification code
	var/static/list/free_treadmills = list()
	var/static/list/free_boarding_levels = list()
	var/starting_system = null //Where do we start in the world?

	// Large/Modern ships will use the modular FTL core. But the proc names and args are aligned so BYOND lets us use either object as just one object path
	// It's terrible I know, but until we decide/are bothered enough to throw out the legacy drive (or subtype it), this'll have to do
	var/obj/machinery/computer/ship/ftl_core/ftl_drive

	//Misc variables
	var/list/scanned = list() //list of scanned overmap anomalies
	var/reserved_z = 0 //The Z level we were spawned on, and thus inhabit. This can be changed if we "swap" positions with another ship.
	var/list/occupying_levels = list() //Refs to the z-levels we own for setting parallax and that, or for admins to debug things when EVERYTHING INEVITABLY BREAKS
	var/torpedo_type = /obj/item/projectile/guided_munition/torpedo
	var/next_maneuvre = 0 //When can we pull off a fancy trick like boost or kinetic turn?
	var/flak_battery_amount = 0
	var/broadside = FALSE //Whether the ship is allowed to have broadside cannons or not
	var/plasma_caster = FALSE //Wehther the ship is allowed to have plasma gun or not
	var/role = NORMAL_OVERMAP

	var/list/missions = list()

	var/last_radar_pulse = 0

	//Our verbs tab
	var/list/overmap_verbs = list()

	var/ghost_controlled = FALSE //Is our overmap currently being controlled by a ghost?

	//NPC combat
	var/datum/combat_dice/npc_combat_dice
	var/combat_dice_type = /datum/combat_dice

	//Boarding
	var/interior_status = INTERIOR_NOT_LOADED
	var/datum/turf_reservation/roomReservation = null
	var/datum/map_template/boarding_interior = null
	var/list/possible_interior_maps = null
	var/interior_mode = NO_INTERIOR
	var/list/interior_entry_points = list()
	var/list/ifflocs = list() // List of potential IFF console locations
	var/boarding_reservation_z = null //Do we have a reserved Z-level for boarding? This is set up on instance_overmap. Ships being boarded copy this value from the boarder.
	var/obj/structure/overmap/active_boarding_target = null
	var/static/next_boarding_time = 0 // This is stupid and lazy but it's 5am and I don't care anymore
	var/hammerlocked = FALSE //Is this ship currently being hammerlocked? Currently used to ensure IFF consoles on boarded ships stay emmaged
/**
Proc to spool up a new Z-level for a player ship and assign it a treadmill.
@return OM, a newly spawned overmap sitting on its treadmill as it ought to be.
*/

/proc/instance_overmap(_path, folder = null, interior_map_files = null, traits = null, default_traits = ZTRAITS_BOARDABLE_SHIP, midround=FALSE) //By default we apply the boardable ship traits, as they make fighters and that lark work
	if(!islist(interior_map_files))
		interior_map_files = list(interior_map_files)
	if(!_path)
		_path = /obj/structure/overmap/nanotrasen/heavy_cruiser/starter
	RETURN_TYPE(/obj/structure/overmap)
	var/datum/space_level/new_ship_z = SSmapping.add_new_zlevel("Overmap ship level [length(SSmapping.z_list)+1]", ZTRAITS_OVERMAP)
	if(!folder || !interior_map_files)
		SSmapping.setup_map_transitions(new_ship_z) //We usually recalculate transitions later, but not if there's no interior.
	repopulate_sorted_areas()
	smooth_zlevel(new_ship_z.z_value)
	log_game("Z-level [new_ship_z.z_value] loaded for overmap treadmills.")
	var/turf/exit = get_turf(locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), new_ship_z.z_value)) //Plop them bang in the center of the system.
	var/obj/structure/overmap/OM = new _path(exit) //Ship'll pick up the info it needs, so just domp eet at the exit turf.
	OM.reserved_z = new_ship_z.z_value
	OM.overmap_flags |= OVERMAP_FLAG_ZLEVEL_CARRIER
	OM.current_system = SSstar_system.find_system(OM)
	if(OM.role == MAIN_OVERMAP) //If we're the main overmap, we'll cheat a lil' and apply our status to all of the Zs under "station"
		for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
			var/datum/space_level/SL = SSmapping.z_list[z]
			SL.linked_overmap = OM
			OM.occupying_levels += SL
	if(folder && interior_map_files) //If this thing comes with an interior.
		var/previous_maxz = world.maxz //Ok. Store the current number of Zs. Anything that we add on top of this due to this proc will then be conted as decks of our ship.
		var/list/errorList = list()
		var/list/loaded = SSmapping.LoadGroup(errorList, "[OM.name] interior Z level", "[folder]", interior_map_files, traits, default_traits, silent = TRUE, orbital_body_type = null)
		if(errorList.len)	// failed to load :(
			message_admins("[_path]'s interior failed to load! Check you used instance_overmap correctly...")
			log_game("[_path]'s interior failed to load! Check you used instance_overmap correctly...")
			return OM
		for(var/datum/parsed_map/PM in loaded)
			PM.initParsedTemplateBounds()
		repopulate_sorted_areas()
		SSmapping.setup_map_transitions() // Allows interior borders to function properly
		var/list/occupying = list()
		for(var/I = ++previous_maxz; I <= world.maxz; I++) //So let's say we started loading interior Z-levels at Z index 4 and we have 2 decks. That means that Z 5 and 6 belong to this ship's interior, so link them
			occupying += I;
			OM.linked_areas += SSmapping.areas_in_z["[I]"]
		for(var/z in occupying)
			var/datum/space_level/SL = SSmapping.z_list[z]
			SL.linked_overmap = OM
			OM.occupying_levels += SL
			log_game("Z-level [SL] linked to [OM].")
		if(midround)
			overmap_lighting_force(OM)


	return OM

/obj/weapon_overlay
	name = "Weapon overlay"
	layer = 4
	mouse_opacity = FALSE
	layer = WALL_OBJ_LAYER
	var/angle = 0 //Debug

/obj/weapon_overlay/proc/do_animation()
	return

/obj/weapon_overlay/railgun //Railgun sits on top of the ship and swivels to face its target
	name = "Railgun"
	icon_state = "railgun"

/obj/weapon_overlay/railgun_overlay/do_animation()
	flick("railgun_charge",src)

/obj/weapon_overlay/laser
	name = "Laser cannon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "conduit-red"

/obj/weapon_overlay/laser/do_animation()
	flick("laser",src)

/obj/structure/overmap/Initialize(mapload)	//If I see one more Destroy() or Initialize() split into multiple files I'm going to lose my mind.
	GLOB.overmap_objects += src
	. = ..()
	var/icon/I = icon(icon,icon_state,SOUTH) //SOUTH because all overmaps only ever face right, no other dirs.
	pixel_collision_size_x = I.Width()
	pixel_collision_size_y = I.Height()
	offset = new /matrix/vector()
	last_offset = new /matrix/vector()
	position = new /matrix/vector(x*32,y*32)
	velocity = new /matrix/vector(0, 0)
	overlap = new /matrix/vector(0, 0)
	if(collision_positions.len)
		physics2d = AddComponent(/datum/component/physics2d)
		physics2d.setup(collision_positions, angle)

	for(var/atype in subtypesof(/datum/ams_mode))
		ams_modes.Add(new atype)

	if(obj_integrity != max_integrity)
		message_admins("Failsafe triggered: [src] Initialized with integrity of [obj_integrity], but max integrity of [max_integrity]. Setting integrity to max integrity to prevent issues.")
		obj_integrity = max_integrity	//Failsafe

	if(!combat_dice_type)
		message_admins("[src] didn't get any combat dice! This may lead to problems in npc fleet combat and shouldn't happen.")
	else
		npc_combat_dice = new combat_dice_type()

	if(!istype(src, /obj/structure/overmap/asteroid))
		GLOB.poi_list += src
	return INITIALIZE_HINT_LATELOAD

/obj/structure/overmap/LateInitialize()
	. = ..()
	armor = armor.setRating(arglist(OM_ARMOR)) //add the default armor values
	if(role > NORMAL_OVERMAP)
		SSstar_system.add_ship(src)
		//reserved_z = src.z //Our "reserved" Z will always be kept for us, no matter what. If we, for example, visit a system that another player is on and then jump away, we are returned to our own Z.
		// AddComponent(/datum/component/nsv_mission_arrival_in_system) // Adds components needed to track jumps for missions
		// AddComponent(/datum/component/nsv_mission_departure_from_system)
	// AddComponent(/datum/component/nsv_mission_killships)
	current_tracers = list()
	START_PROCESSING(SSphysics_processing, src)

	vector_overlay = new()
	vector_overlay.appearance_flags |= KEEP_APART
	vector_overlay.appearance_flags |= RESET_TRANSFORM
	vector_overlay.icon = icon
	vis_contents += vector_overlay
	update_icon()
	find_area()
	//If we're larger than a fighter and don't have our armour preset, set it now.
	if(mass > MASS_TINY && !use_armour_quadrants && role != MAIN_MINING_SHIP)
		use_armour_quadrants = TRUE
		//AI ships get weaker armour to allow you to kill them more easily.
		var/armour_efficiency = (role > NORMAL_OVERMAP) ? obj_integrity / 2 : obj_integrity / 4
		armour_quadrants = list("forward_port" = list("name" = "Forward Port", "max_armour" = armour_efficiency, "current_armour" = armour_efficiency),\
							"forward_starboard" = list("name" = "Forward Starboard", "max_armour" = armour_efficiency, "current_armour" = armour_efficiency),\
							"aft_port" = list("name" = "Aft Port", "max_armour" = armour_efficiency, "current_armour" = armour_efficiency),\
							"aft_starboard" = list("name" = "Aft Starboard", "max_armour" = armour_efficiency, "current_armour" = armour_efficiency))
	switch(mass) //Scale speed with mass (tonnage)
		if(MASS_TINY) //Tiny ships are manned by people, so they need air.
			forward_maxthrust = 2
			backward_maxthrust = 2
			side_maxthrust = 2
			max_angular_acceleration = 100
			cabin_air = new
			cabin_air.set_temperature(T20C)
			cabin_air.set_volume(200)
			//101 kPa =
			// PV=nRT
			// PV/RT = n
			cabin_air.set_moles(GAS_O2, O2STANDARD*ONE_ATMOSPHERE*cabin_air.return_volume()/(R_IDEAL_GAS_EQUATION*cabin_air.return_temperature()))
			cabin_air.set_moles(GAS_N2, N2STANDARD*ONE_ATMOSPHERE*cabin_air.return_volume()/(R_IDEAL_GAS_EQUATION*cabin_air.return_temperature()))
			bounce_factor = 1 //Stops dead in its tracks
			lateral_bounce_factor = 1
			move_by_mouse = TRUE //You'll want this. Trust.
			inertial_dampeners = FALSE

		//Very easy to kite. Super balanced movement. Strong thrusters on all sides...
		if(MASS_SMALL)
			forward_maxthrust = 0.75
			backward_maxthrust = 0.75
			side_maxthrust = 0.75
			max_angular_acceleration = 12
			bounce_factor = 0.75
			lateral_bounce_factor = 0.75
		//Similar to small, but you'll notice a detriment to movement here. Movement is no longer equally balanced, you'll have to fight the controls more.
		if(MASS_MEDIUM)
			forward_maxthrust = 0.75
			backward_maxthrust = 0.5
			side_maxthrust = 0.45
			max_angular_acceleration = 10
			bounce_factor = 0.55 //Throw your weight around more, though!
			lateral_bounce_factor = 0.55

		if(MASS_MEDIUM_LARGE)
			forward_maxthrust = 0.65
			backward_maxthrust = 0.45
			side_maxthrust = 0.35
			max_angular_acceleration = 8
			bounce_factor = 0.40 //Throw your weight around more, though!
			lateral_bounce_factor = 0.40

		//Weightey ships, much harder to steer, generally less responsive. You'll need to use boost tactically.
		if(MASS_LARGE)
			forward_maxthrust = 0.5
			backward_maxthrust = 0.35
			side_maxthrust = 0.25
			max_angular_acceleration = 6
			bounce_factor = 0.20 //But you can plow through enemy ships with ease.
			lateral_bounce_factor = 0.20
			//If we've not already got a special flak battery amount set.
			if(flak_battery_amount <= 0)
				flak_battery_amount = 1
		//Supercapitals are EXTREMELY hard to move, you'll find that they fight your every command, it's a side-effect of their immense power.
		if(MASS_TITAN)
			forward_maxthrust = 0.35
			backward_maxthrust = 0.10
			side_maxthrust = 0.10
			max_angular_acceleration = 2.75
			bounce_factor = 0.10// But nothing can really stop you in your tracks.
			lateral_bounce_factor = 0.10
			//If we've not already got a special flak battery amount set.
			if(flak_battery_amount <= 0)
				flak_battery_amount = 2
	switch(role)
		if(MAIN_OVERMAP)
			name = station_name()
			SSstar_system.main_overmap = src
		if(MAIN_MINING_SHIP)
			SSstar_system.mining_ship = src
	var/datum/star_system/sys = SSstar_system.find_system(src)
	if(sys)
		current_system = sys
	addtimer(CALLBACK(src, PROC_REF(force_parallax_update)), 20 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(check_armour)), 20 SECONDS)

	//Boarding / Interior bits...
	switch(interior_mode)
		//If we didn't get it preset, Ie, we're not a dropship
		if(NO_INTERIOR)
			interior_mode = (possible_interior_maps?.len) ? INTERIOR_EXCLUSIVE : NO_INTERIOR
		//Allows small ships to have a small interior.
		if(INTERIOR_DYNAMIC)
			RegisterSignal(src, COMSIG_INTERIOR_DONE_LOADING, PROC_REF(after_init_load_interior))
			SSstar_system.queue_for_interior_load(src)

	RegisterSignal(src, list(COMSIG_FTL_STATE_CHANGE, COMSIG_SHIP_KILLED), PROC_REF(dump_locks)) // Setup lockon handling
	//We have a lot of types but not that many weapons per ship, so let's just worry about the ones we do have
	if(interior_mode != INTERIOR_DYNAMIC)
		apply_weapons()
		for(var/firemode = 1; firemode <= MAX_POSSIBLE_FIREMODE; firemode++)
			var/datum/ship_weapon/SW = weapon_types[firemode]
			if(istype(SW) && (SW.allowed_roles & OVERMAP_USER_ROLE_GUNNER))
				weapon_numkeys_map += firemode

///Listens for when the interior is done initing and finishes up some variables when it is.
/obj/structure/overmap/proc/after_init_load_interior()
	SIGNAL_HANDLER
	UnregisterSignal(src, COMSIG_INTERIOR_DONE_LOADING)
	apply_weapons()
	for(var/firemode = 1; firemode <= MAX_POSSIBLE_FIREMODE; firemode++)
		var/datum/ship_weapon/SW = weapon_types[firemode]
		if(istype(SW) && (SW.allowed_roles & OVERMAP_USER_ROLE_GUNNER))
			weapon_numkeys_map += firemode

//Method to apply weapon types to a ship. Override to your liking, this just handles generic rules and behaviours
/obj/structure/overmap/proc/apply_weapons()
	//Prevent fighters from getting access to the AMS.
	if(mass <= MASS_TINY)
		weapon_types[FIRE_MODE_ANTI_AIR] = new /datum/ship_weapon/light_cannon(src)
	//Gauss is the true PDC replacement...
	else
		weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
	if(mass >= MASS_SMALL || length(occupying_levels))
		weapon_types[FIRE_MODE_AMS] = new /datum/ship_weapon/vls(src)
		weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	if(flak_battery_amount > 0)
		weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	if(mass > MASS_MEDIUM || length(occupying_levels))
		weapon_types[FIRE_MODE_MAC] = new /datum/ship_weapon/mac(src)
	if(ai_controlled)
		weapon_types[FIRE_MODE_MISSILE] = new/datum/ship_weapon/missile_launcher(src)
		weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/torpedo_launcher(src)
	if(broadside)
		weapon_types[FIRE_MODE_BROADSIDE] = new/datum/ship_weapon/broadside(src)
	if(plasma_caster)
		weapon_types[FIRE_MODE_PHORON] = new/datum/ship_weapon/plasma_caster(src)

/obj/item/projectile/Destroy()
	if(physics2d)
		QDEL_NULL(physics2d)
	return ..()

/obj/structure/overmap/Destroy()
	if(block_deletion || (CHECK_BITFIELD(overmap_deletion_traits, NEVER_DELETE_OCCUPIED) && has_occupants()))
		message_admins("[src] has occupants and will not be deleted")
		return QDEL_HINT_LETMELIVE

	GLOB.poi_list -= src
	if(current_system)
		current_system.system_contents.Remove(src)
		if(faction != "nanotrasen" && faction != "solgov")
			current_system.enemies_in_system.Remove(src)
		if(current_system.contents_positions[src])	//If we got destroyed while not loaded, chances are we should kill off this reference.
			current_system.contents_positions.Remove(src)

	if(fleet)
		fleet.stop_reporting_all(src)

	STOP_PROCESSING(SSphysics_processing, src)
	for(var/mob/living/M in operators)
		stop_piloting(M)
	GLOB.overmap_objects -= src
	relay('nsv13/sound/effects/ship/damage/ship_explode.ogg')
	relay_to_nearby('nsv13/sound/effects/ship/damage/disable.ogg') //Kaboom.
	new /obj/effect/temp_visual/fading_overmap(get_turf(src), name, icon, icon_state)
	for(var/obj/structure/overmap/OM in enemies) //If target's in enemies, return
		var/sound = pick('nsv13/sound/effects/computer/alarm.ogg','nsv13/sound/effects/computer/alarm_2.ogg')
		var/message = "<span class='warning'>ATTENTION: [src]'s reactor is going supercritical. Destruction imminent.</span>"
		OM?.tactical?.relay_sound(sound, message)
		OM.enemies -= src //Stops AI from spamming ships that are already dead
	overmap_explode(linked_areas)
	if(role == MAIN_OVERMAP)
		priority_announce("WARNING: ([rand(10,100)]) Attempts to establish DRADIS uplink with [station_name()] have failed. Unable to ascertain operational status. Presumed status: TERMINATED","Central Intelligence Unit", 'nsv13/sound/effects/ship/reactor/explode.ogg')
		Cinematic(CINEMATIC_NSV_SHIP_KABOOM,world)
		SSticker.mode.check_finished(TRUE)
		SSticker.news_report = SHIP_DESTROYED
		SSblackbox.record_feedback("text", "nsv_endings", 1, "destroyed")
		SSticker.force_ending = 1
	SEND_SIGNAL(src,COMSIG_SHIP_KILLED)
	QDEL_LIST(current_tracers)
	QDEL_LIST(target_painted)
	if(cabin_air)
		QDEL_NULL(cabin_air)
	//Free up memory refs here.
	if(physics2d)
		QDEL_NULL(physics2d)
	if(npc_combat_dice)
		QDEL_NULL(npc_combat_dice)

	if(deletion_teleports_occupants)
		var/turf/T = get_turf(src) // Drop them outside if we're parked, forceMove protection will kick in if we're on the overmap
		for(var/mob/living/M in mobs_in_ship)
			if(M)
				M.forceMove(T)
				M.apply_damage(200)
	kill_boarding_level()
	if(current_system)
		current_system.remove_ship(src, is_ftl_jump = FALSE) //bit risky call since we already do some things before but probably should still work.
	if(reserved_z)
		free_treadmills += reserved_z
		reserved_z = null
	current_system = null //I'm not sure why we never dropped this variable.
	return ..()

/obj/structure/overmap/forceMove(atom/destination)
	if(destination && !SSmapping.level_trait(destination.z, ZTRAIT_OVERMAP))
		return //No :)
	return ..()

/obj/structure/overmap/proc/find_area()
	if(role == MAIN_OVERMAP) //We're the hero ship, link us to every ss13 area.
		for(var/X in GLOB.teleportlocs) //Teleportlocs = ss13 areas that aren't special / centcom
			var/area/A = GLOB.teleportlocs[X]
			linked_areas += A

/obj/structure/overmap/proc/InterceptClickOn(mob/user, params, atom/target)
	if(user.incapacitated() || !isliving(user))
		return FALSE
	if(weapon_safety && !can_friendly_fire())
		return FALSE
	if(istype(target, /obj/machinery/button))
		return target.attack_hand(user)
	var/list/params_list = params2list(params)
	if(target == src || istype(target, /atom/movable/screen) || (target in user.GetAllContents()) || params_list["alt"] || params_list["shift"])
		return FALSE
	if(LAZYFIND(gauss_gunners, user)) //Special case for gauss gunners here. Takes priority over them being the regular gunner.
		var/datum/component/overmap_gunning/user_gun = user.GetComponent(/datum/component/overmap_gunning)
		if(user_gun)
			user_gun.onClick(target)
			return TRUE
		else
			log_runtime("BUG: User [user] is in [src]'s gauss_gunners list but has no overmap_gunning component!")
			message_admins("BUG: User [ADMIN_LOOKUPFLW(user)]  is in [src]'s gauss_gunners list but has no overmap_gunning component! Attempting to eject them and remove them from the list...")
			var/obj/machinery/ship_weapon/gauss_gun/G = user.loc
			if(istype(G))
				G.remove_gunner()
			if(LAZYFIND(gauss_gunners, user))
				log_runtime("BUG: User [user] was still in gauss_gunners list after trying to kick them out, modifying the list directly")
				message_admins("BUG: [user] was still in gauss_gunners list after trying to kick them out, modifying the list directly")
				gauss_gunners -= user
	if(user != gunner)
		if(user == pilot)
			for(var/mode = 1; mode <= MAX_POSSIBLE_FIREMODE; mode++)
				var/datum/ship_weapon/SW = weapon_types[mode] //For annoying ships like whisp
				if(!SW || !(SW.allowed_roles & OVERMAP_USER_ROLE_PILOT))
					continue
				var/list/loaded = SW?.weapons["loaded"]
				if(length(loaded))
					fire_weapon(target, mode)
		return FALSE
	if(tactical && prob(80))
		var/sound = pick(GLOB.computer_beeps)
		playsound(tactical, sound, 100, 1)
	if(params_list["ctrl"]) //Ctrl click to lock on to people
		start_lockon(target)
		ams_shots_fired = 0
		return TRUE
	if(user == gunner)
		var/datum/ship_weapon/SW = weapon_types[fire_mode]
		if(!SW || !(SW.allowed_roles & OVERMAP_USER_ROLE_GUNNER))
			return FALSE
	fire(target)
	return TRUE

// Placeholder to allow targeting with utility modules
/obj/structure/overmap/proc/can_friendly_fire()
	return FALSE

/obj/structure/overmap/proc/start_lockon(obj/structure/overmap/target)
	if(!istype(target))
		return FALSE
	if((target.faction == faction) && !can_friendly_fire())
		return FALSE
	if(LAZYFIND(target_painted, target))
		dump_lock(target)
		if(gunner)
			to_chat(gunner, "<span class='notice'>Target painting cancelled on [target].</span>")
		return FALSE
	relay('nsv13/sound/effects/fighters/being_locked.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
	addtimer(CALLBACK(src, PROC_REF(finish_lockon), target), lockon_time)

/obj/structure/overmap/proc/finish_lockon(obj/structure/overmap/target, obj/structure/overmap/data_link_origin)
	if(!target || !istype(target) || target == src || target.current_system != current_system) // No target/invalid target
		return
	if(LAZYFIND(target_painted, target)) // already locked
		return
	if(!data_link_origin && target.is_sensor_visible(src) < SENSOR_VISIBILITY_TARGETABLE)
		return
	if(length(target_painted) >= max_paints)
		to_chat(gunner, "<span class='notice'>Target painting at maximum capacity. Cancelling painting of [target_painted[1]] to support new target.</span>")
		dump_lock(target_painted[1])
	if(data_link_origin)
		target_painted[target] = data_link_origin
		RegisterSignal(data_link_origin, COMSIG_LOCK_LOST, PROC_REF(check_datalink))
	else
		target_painted[target] = FALSE
		target_last_tracked[target] = world.time
	to_chat(gunner, "<span class='notice'>Target painted.</span>")
	relay('nsv13/sound/effects/fighters/locked.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
	RegisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_FTL_STATE_CHANGE), PROC_REF(dump_lock))
	SEND_SIGNAL(src, COMSIG_TARGET_PAINTED, target)
	if(autotarget)
		select_target(target) //autopaint our target

/obj/structure/overmap/proc/select_target(obj/structure/overmap/target)
	if(QDELETED(target) || !istype(target) || !locate(target) in target_painted)
		target_lock = null
		update_gunner_cam()
		dump_lock(target)
		return
	if(target_lock == target)
		target_lock = null
		update_gunner_cam()
		return
	target_lock = target
	SEND_SIGNAL(src, COMSIG_TARGET_LOCKED, target)

/obj/structure/overmap/proc/dump_lock(obj/structure/overmap/target) // Our locked target got destroyed/moved, dump the lock
	SIGNAL_HANDLER
	SEND_SIGNAL(src, COMSIG_LOCK_LOST, target)
	target_painted -= target
	target_last_tracked -= target
	UnregisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_FTL_STATE_CHANGE))
	if(target_lock == target)
		update_gunner_cam()
		target_lock = null

/obj/structure/overmap/proc/dump_locks() // clears all target locks.
	SIGNAL_HANDLER
	update_gunner_cam()
	for(var/obj/structure/overmap/OM in target_painted)
		dump_lock(OM)

// Can we pass targets to friendlies?
/obj/structure/overmap/proc/can_use_datalink()
	return TRUE

// Handles the passing of said targets.
/obj/structure/overmap/proc/datalink_transmit(obj/structure/overmap/target)
	if(!can_use_datalink() || target == src || target.faction != faction || !target_lock)
		return FALSE
	if(target.ai_controlled || !target.gunner)
		return FALSE
	if(length(target.target_painted) < target.max_paints)
		target.finish_lockon(target_lock, src)
		to_chat(target.gunner, "<span class='notice'>Targeting data for [target] recieved from [src] via datalink.</span>")
		to_chat(gunner, "<span class='notice'>Targeting paramaters relayed.</span>")

// Called when we lose a target's datalink signal.
/obj/structure/overmap/proc/check_datalink(obj/structure/overmap/data_link_origin, obj/structure/overmap/target)
	SIGNAL_HANDLER
	if(target_painted[target] == data_link_origin)
		if(overmap_dist(src, target) > max(dradis?.sensor_range * 2, target.sensor_profile))
			// We can't see the target, get rid of the lock
			UnregisterSignal(data_link_origin, COMSIG_LOCK_LOST)
			dump_lock(target)
			return

		// We can see the target, so un-datalink
		UnregisterSignal(data_link_origin, COMSIG_LOCK_LOST)
		target_painted[target] = FALSE
		target_last_tracked[target] = world.time

/obj/structure/overmap/proc/update_gunner_cam(atom/target)
	if(!gunner)
		return
	var/mob/camera/ai_eye/remote/overmap_observer/cam = gunner.remote_control
	if(!cam)
		return
	if(target == cam.ship_target) // Allows us to use this as a toggle
		target = null
	cam.track_target(target)

// This is so ridicously expensive, who made this.
/obj/structure/overmap/onMouseMove(object,location,control,params)
	if(!pilot || !pilot.client || pilot.incapacitated() || !move_by_mouse || control !="mapwindow.map" ||!can_move()) //Check pilot status, if we're meant to follow the mouse, and if theyre actually moving over a tile rather than in a menu
		return // I don't know what's going on.
	desired_angle = getMouseAngle(params, pilot)
	update_icon()


/obj/structure/overmap/proc/getMouseAngle(params, mob/M)
	var/list/params_list = params2list(params)
	var/list/sl_list = splittext(params_list["screen-loc"],",")
	if(!sl_list.len)
		return
	var/list/sl_x_list = splittext(sl_list[1], ":")
	var/list/sl_y_list = splittext(sl_list[2], ":")
	var/view_list = isnum(M.client.view) ? list("[M.client.view*2+1]","[M.client.view*2+1]") : splittext(M.client.view, "x")
	var/dx = text2num(sl_x_list[1]) + (text2num(sl_x_list[2]) / world.icon_size) - 1 - text2num(view_list[1]) / 2
	var/dy = text2num(sl_y_list[1]) + (text2num(sl_y_list[2]) / world.icon_size) - 1 - text2num(view_list[2]) / 2
	if(sqrt(dx*dx+dy*dy) > 1)
		return 90 - ATAN2(dx, dy)
	else
		return null

/obj/structure/overmap/proc/enable_dampeners(mob/user)
	if(HAS_TRAIT(src, TRAIT_NODAMPENERS))
		if(user)
			to_chat(user, "<span class='danger'>WARNING: Inertia Dampeners Unavailable! Potential causes: Gravity above tolerance, malfunctions, damage, spontanious bluespace displacement.</span>")
		return FALSE
	inertial_dampeners = TRUE
	return TRUE

/obj/structure/overmap/proc/disable_dampeners(mob/user)
	inertial_dampeners = FALSE
	return TRUE

/obj/structure/overmap/proc/toggle_dampeners(mob/user)
	if(inertial_dampeners)
		return disable_dampeners(user)
	else
		return enable_dampeners(user)

/obj/structure/overmap/relaymove(mob/user, direction)
	if(user != pilot || pilot.incapacitated())
		return
	user_thrust_dir = direction
	// Since they can't strafe with IAS on, they can also turn with A and D
	if(inertial_dampeners)
		if(direction & WEST)
			movekey_delta_angle = -15
			user_thrust_dir = direction - WEST
		else if(direction & EAST)
			movekey_delta_angle = 15
			user_thrust_dir = direction - EAST

//relay('nsv13/sound/effects/ship/rcs.ogg')

// This is overly expensive, most of these checks are already ran in physics. TODO: optimize
/obj/structure/overmap/update_icon() //Adds an rcs overlay
	apply_damage_states()
	if(last_fired) //Swivel the most recently fired gun's overlay to aim at the last thing we hit
		last_fired.icon = icon
		last_fired.setDir(get_dir(src, last_target))
	cut_overlay("rcs_left")
	cut_overlay("rcs_right")
	cut_overlay("thrust")
	if(angle == desired_angle)
		return //No RCS needed if we're already facing where we want to go
	if(prob(20) && desired_angle)
		playsound(src, 'nsv13/sound/effects/ship/rcs.ogg', 30, 1)
	var/list/left_thrusts = list()
	left_thrusts.len = 8
	var/list/right_thrusts = list()
	right_thrusts.len = 8
	var/back_thrust = 0
	for(var/cdir in GLOB.cardinals)
		left_thrusts[cdir] = 0
		right_thrusts[cdir] = 0
	if(last_thrust_right != 0)
		var/tdir = last_thrust_right > 0 ? WEST : EAST
		left_thrusts[tdir] = abs(last_thrust_right) / side_maxthrust
		right_thrusts[tdir] = abs(last_thrust_right) / side_maxthrust
	if(last_thrust_forward > 0)
		back_thrust = last_thrust_forward / forward_maxthrust
	if(last_thrust_forward < 0)
		left_thrusts[NORTH] = -last_thrust_forward / backward_maxthrust
		right_thrusts[NORTH] = -last_thrust_forward / backward_maxthrust
	if(last_rotate != 0)
		var/frac = abs(last_rotate) / max_angular_acceleration
		for(var/cdir in GLOB.cardinals)
			if(last_rotate > 0)
				right_thrusts[cdir] += frac
			else
				left_thrusts[cdir] += frac
	for(var/cdir in GLOB.cardinals)
		var/left_thrust = left_thrusts[cdir]
		var/right_thrust = right_thrusts[cdir]
		if(left_thrust)
			add_overlay("rcs_left")
		if(right_thrust)
			add_overlay("rcs_right")
	if(back_thrust)
		add_overlay("thrust")

/obj/structure/overmap/proc/apply_damage_states()
	if(!damage_states)
		return
	var/progress = obj_integrity //How damaged is this shield? We examine the position of index "I" in the for loop to check which directional we want to check
	var/goal = max_integrity //How much is the max hp of the shield? This is constant through all of them
	progress = CLAMP(progress, 0, goal)
	progress = round(((progress / goal) * 100), 25)//Round it down to 20%. We now apply visual damage
	icon_state = "[initial(icon_state)]-[progress]"

/obj/structure/overmap/proc/relay(S, var/message=null, loop = FALSE, channel = null) //Sends a sound + text message to the crew of a ship
	for(var/mob/M as() in mobs_in_ship)
		if(M.can_hear())
			if(channel) //Doing this forbids overlapping of sounds
				SEND_SOUND(M, sound(S, repeat = loop, wait = 0, volume = 100, channel = channel))
			else
				SEND_SOUND(M, sound(S, repeat = loop, wait = 0, volume = 100))
		if(message)
			to_chat(M, message)
	for(var/obj/structure/overmap/O as() in overmaps_in_ship) //Of course they get relayed the same message if they're in the same ship too
		if(length(O.mobs_in_ship))
			O.relay(S,message,loop,channel)

/obj/structure/overmap/proc/stop_relay(channel) //Stops all playing sounds for crewmen on N channel.
	for(var/mob/M as() in mobs_in_ship)
		M.stop_sound_channel(channel)
	for(var/obj/structure/overmap/O as() in overmaps_in_ship) //Of course they get relayed the same message if they're in the same ship too
		if(length(O.mobs_in_ship))
			O.stop_relay(channel)

/obj/structure/overmap/proc/relay_to_nearby(S, message, ignore_self=FALSE, sound_range=20, faction_check=FALSE) //Sends a sound + text message to nearby ships
	for(var/obj/structure/overmap/ship as() in GLOB.overmap_objects) //Might be called in hyperspace or by fighters, so shouldn't use a system check.
		if(ignore_self)
			if(ship == src)
				continue
		if(ship?.current_system != current_system)	//If we aren't in the same system this shouldn't be happening.
			continue
		if(get_dist(src, ship) <= sound_range) //Sound doesnt really travel in space, but space combat with no kaboom is LAME
			if(faction_check)
				if(src.faction == ship.faction)
					continue
			ship.relay(S,message)

/obj/structure/overmap/proc/boost(direction)
	if(world.time < next_maneuvre)
		to_chat(pilot, "<span class='notice'>Engines on cooldown to prevent overheat</span>")
		return FALSE
	relay('nsv13/sound/effects/ship/afterburner.ogg', message="<span class='warning'>You feel the ship lurch suddenly.</span>", loop=FALSE)
	if(helm && prob(80))
		var/sound = pick(GLOB.computer_beeps)
		playsound(helm, sound, 100, 1)
	next_maneuvre = world.time + 15 SECONDS
	addtimer(CALLBACK(src, PROC_REF(reset_boost), forward_maxthrust, backward_maxthrust, side_maxthrust, max_angular_acceleration, speed_limit), 6 SECONDS)
	speed_limit += 5
	add_overlay("thrust")
	switch(direction)
		if(NORTH)
			max_angular_acceleration *= 0.5 //Kick it forward, but kill turn rate as youre going super fast
			forward_maxthrust *= 5
			backward_maxthrust *= 5
		if(SOUTH)
			max_angular_acceleration *= 0.5
			forward_maxthrust *= 5
			backward_maxthrust *= 5
		if(EAST)
			max_angular_acceleration *= 5
			max_angular_acceleration = CLAMP(max_angular_acceleration, 0, 360)
			side_maxthrust *= 5
		if(WEST)
			max_angular_acceleration *= 5
			max_angular_acceleration = CLAMP(max_angular_acceleration, 0, 360)
			side_maxthrust *= 5
	addtimer(CALLBACK(src, PROC_REF(check_throwaround), angle, direction), 3 SECONDS)
	user_thrust_dir = direction
	shake_everyone(10)

/// Intended to be used with a timer, sets all agility controlling variables, saves us making 6 varset timers
/obj/structure/overmap/proc/reset_boost(forward_maxthrust, backward_maxthrust, side_maxthrust, max_angular_acceleration, speed_limit)
	src.forward_maxthrust = forward_maxthrust
	src.backward_maxthrust = backward_maxthrust
	src.side_maxthrust = side_maxthrust
	src.max_angular_acceleration = max_angular_acceleration
	src.speed_limit = speed_limit

/// Check how aggressively the pilots are turning
/obj/structure/overmap/proc/check_throwaround(theAngle, direction)
	var/delta = abs(angular_velocity) //Where we started.
	if(delta < 20) //This is the canterbury, prepare for FLIP AND BURN.
		return
	if(!length(mobs_in_ship))
		return
	if(!length(linked_areas))
		for(var/mob/living/M in mobs_in_ship)
			//Black out viper jockies who turn too often and too hard.
			M.adjustStaminaLoss(30)
			switch(M.staminaloss)
				if(0 to 30)
					continue
				if(50 to 70)
					to_chat(M, "<span class='warning'>You feel lightheaded.</span>")
				if(71 to 89)
					to_chat(M, "<span class='warning'>Colour starts to drain from your vision. You feel like you're starting to black out....</span>")
					if(HAS_TRAIT(M, TRAIT_GFORCE_WEAKNESS))
						M.gravity_crush(3)
				if(90 to 100) //Blackout. Slow down on the turns there kid!
					to_chat(M, "<span class='userdanger'>You black out!</span>")
					M.Sleeping(5 SECONDS)
					if(HAS_TRAIT(M, TRAIT_GFORCE_WEAKNESS))
						M.gravity_crush(4)
		return
	if(!direction)
		return
	for(var/mob/living/M as() in mobs_in_ship)
		if(M.buckled) //Good for you, you strapped in!
			continue
		if(M.mob_negates_gravity()) //Wear magboots and you're good.
			continue
		var/atom/throw_target
		switch(direction) //Assuming that all our ships face east...
			if(NORTH)
				throw_target = locate(M.x-10, M.y, M.z)
			if(SOUTH)
				throw_target = locate(M.x+10, M.y, M.z)
			if(EAST)
				throw_target = locate(M.x, M.y+10, M.z)
			if(WEST)
				throw_target = locate(M.x, M.y-10, M.z)
		if(!throw_target)
			continue
		if(iscarbon(M))
			var/mob/living/carbon/L = M
			if(HAS_TRAIT(L, TRAIT_SEASICK))
				to_chat(L, "<span class='warning'>Your head swims as the ship violently turns!</span>")
				if(prob(40)) //Take a roll! First option makes you puke and feel terrible. Second one makes you feel iffy.
					L.adjust_disgust(20)
				else
					L.adjust_disgust(10)
		M.throw_at(throw_target, 4, 3)
		M.Knockdown(2 SECONDS)

/obj/structure/overmap/proc/can_change_safeties()
	// Safeties can be toggled on the overmap or on small dockable maps like ruins and asteroids
	return (SSmapping.level_trait(loc.z, ZTRAIT_OVERMAP) || SSmapping.level_trait(loc.z, ZTRAIT_RESERVED))

/obj/structure/overmap/proc/can_brake()
	return TRUE //See fighters.dm

/**
  * Dynamic allocation of overmap Zs.
  * DON'T CALL THIS IF YOU DON'T WANT ONE TO BE ASSIGNED TO YOU
  */
/obj/structure/overmap/proc/get_reserved_z()
	if(reserved_z)
		return reserved_z
	if(ftl_drive)
		if(!free_treadmills?.len)
			var/datum/space_level/new_level = SSmapping.add_new_initialized_overmap_zlevel()
			reserved_z = new_level.z_value
		else
			var/_z = pick_n_take(free_treadmills)
			reserved_z = _z
		return reserved_z

///Special proc called right before a system is nullspaced and a last chance to assume a z. Returns TRUE if the ship should not be unloaded.
/obj/structure/overmap/proc/spec_pre_system_unload()
	if(!ai_controlled && length(mobs_in_ship))
		return TRUE
	return FALSE

/obj/structure/overmap/small_craft/spec_pre_system_unload()
	. = ..()
	if(.)
		return
	if(ftl_drive)
		return TRUE
	return FALSE

/**
 * Handles special modifications or effects an overmap has for collisions.
 * * other_ship = the ship this collides with.
 * * impact_powers = the strength of the impact for (this ship, other ship). Done this way because list pointer allows inplace var access.
 * * impact_angle = The angle of the impact.
 *
 * This does NOT return the modified impact powers, as it is not neccessary due to inplace handling!
 */
/obj/structure/overmap/proc/spec_collision_handling(obj/structure/overmap/other_ship, list/impact_powers, impact_angle)
	return
