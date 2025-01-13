/**
Attempt to "board" an AI ship. You can only do this when they're low on health though!
@param map_path_override: Whether this ship should load from its defined list of boarding maps, or if you just want to throw it one.
@param boarder: Who's boarding us, so we know how to link up with them

*/

/obj/structure/overmap/proc/kill_boarding_level(obj/structure/overmap/boarder)
	set waitfor = FALSE
	var/was_fully_loaded = TRUE
	hammerlocked = FALSE
	if(interior_status != INTERIOR_READY) // determines whether this ship can be loaded again
		if(interior_status != INTERIOR_NOT_LOADED)
			message_admins("DEBUG: Deleting the interior for [src] before it was fully loaded")
			log_mapping("DEBUG: Deleting the interior for [src] before it was fully loaded")
		was_fully_loaded = FALSE
	interior_status = INTERIOR_DELETING
	//Free up the boarding level....
	if(boarder)
		boarder.boarding_reservation_z = null
	switch(interior_mode)
		if(INTERIOR_EXCLUSIVE)
			if(boarding_interior && boarding_reservation_z)
				var/datum/space_level/SL = SSmapping.get_level(boarding_reservation_z)
				if(SL)
					SL.linked_overmap = null //Free that level up.
				occupying_levels = list()
				docking_points = list()
				ifflocs = list()
				SSair.can_fire = FALSE
				for(var/turf/T in boarding_interior.get_affected_turfs(locate(1, 1, boarding_reservation_z), FALSE)) //nuke
					T.empty()
					CHECK_TICK
				SSair.can_fire = TRUE
				free_boarding_levels += boarding_reservation_z
				boarding_reservation_z = null
				QDEL_NULL(boarding_interior)
		if(INTERIOR_DYNAMIC)
			if(boarding_interior)
				var/turf/target = locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3])
				for(var/turf/T as () in boarding_interior.get_affected_turfs(target)) //nuke
					T.empty()
					CHECK_TICK
				for(var/entry as() in interior_entry_points)
					docking_points -= entry
				QDEL_LIST(interior_entry_points)
			//Free the reservation.
			QDEL_NULL(roomReservation)
			boarding_interior = null
	if(was_fully_loaded)
		interior_status = INTERIOR_DELETED
	else
		interior_status = INTERIOR_NOT_LOADED

/obj/structure/overmap/proc/board_test()
	var/turf/aaa = locate(x, y-10, z)
	var/obj/structure/overmap/syndicate/ai/destroyer/foo = new(aaa)
	foo.obj_integrity = foo.max_integrity / 3
	foo.ai_controlled = FALSE
	foo.brakes = TRUE
	foo.ai_load_interior(src)
	foo.active_boarding_target = src

/obj/structure/overmap/proc/get_boarding_level()
	if(boarding_reservation_z)
		return
	if(length(free_boarding_levels))
		var/_z = pick_n_take(free_boarding_levels)
		boarding_reservation_z = _z
		return
	SSmapping.add_new_initialized_zlevel("Overmap boarding reservation", ZTRAITS_BOARDABLE_SHIP)
	boarding_reservation_z = world.maxz

/obj/structure/overmap/proc/ai_load_interior(obj/structure/overmap/boarder, map_path_override)
	if(!boarder)
		message_admins("Tried to load [src] for boarding, but we don't know who's boarding it! Aborting.")
		return FALSE
	//You can't harpoon a ship with no supported interior, or that already has an interior defined. Your ship must also have an interior to load this, so we can link the z-levels.
	// -----------------------------
	if(interior_mode == NO_INTERIOR || interior_mode == INTERIOR_DYNAMIC)
		message_admins("[boarder] attempted to board [src], but the target has an incompatible interior_mode.")
		return FALSE
	if(!boarder.boarding_reservation_z)
		boarder.get_boarding_level()
		sleep(5)
	if(interior_status == INTERIOR_READY) // it's loaded already, just let them on
		return TRUE
	else if(interior_status != INTERIOR_NOT_LOADED)
		message_admins("[src] tried to load boarding map while it was already loading, deleting, or had been released. Aborting!")
		return FALSE // If we're currently loading or deleting, stop
	if(!boarder.boarding_reservation_z || !length(possible_interior_maps) || length(occupying_levels) || (boarder.active_boarding_target && !QDELETED(boarder.active_boarding_target)))
		message_admins("[boarder] attempted to board [src], but the pre-mapload checks failed!")
		return FALSE

	interior_status = INTERIOR_LOADING
	//Prepare the boarding interior map. Admins may also force-load this with a path if they want.
	choose_interior(map_path_override)
	if(!boarding_interior?.mappath)
		message_admins("Error parsing boarding interior map for [src]")
		return FALSE

	hammerlocked = TRUE
	current_system = boarder.current_system
	get_overmap_level()
	boarding_reservation_z = boarder.boarding_reservation_z
	var/datum/space_level/SL = SSmapping.get_level(boarding_reservation_z)
	SL.linked_overmap = src
	occupying_levels += SL
	//Just in case...
	if(!length(docking_points))
		docking_points += get_turf(locate(20, world.maxy/2, boarding_reservation_z))
	boarder.relay_to_nearby('nsv13/sound/effects/ship/boarding_pod.ogg', ignore_self=FALSE)

	var/turf/bottom_left = get_turf(locate(1, 1, boarding_reservation_z))
	log_game("Boarding map [boarding_interior.mappath] loading for [src] on Z level [boarding_reservation_z]")
	return load_interior(bottom_left, boarding_interior.width, boarding_interior.height)

/obj/structure/overmap/proc/get_overmap_level()
	//Add a treadmill for this ship as and when needed.
	if(!reserved_z)
		get_reserved_z()
		starting_system = current_system.name //Just fuck off it works alright?
		SSstar_system.add_ship(src)

/obj/structure/overmap/proc/choose_interior(map_path_override)
	if(map_path_override)
		boarding_interior = new/datum/map_template(map_path_override)
	else
		var/chosen = pick(possible_interior_maps)
		boarding_interior = SSmapping.boarding_templates[chosen]

/**
The meat of this file. This will instance the dropship's interior in reserved space land. I HIGHLY recommend you keep these maps small, reserved space code is shitcode.
*/
/obj/structure/overmap/proc/instance_interior()
	if(interior_status == INTERIOR_READY) // it's loaded already, we're done
		return TRUE
	else if(interior_status != INTERIOR_NOT_LOADED)
		message_admins("[src] attempted to load its interior, but it was already loading, deleting, or had been released! (Pretty normal for asteroids)")
		return FALSE // If we're currently loading or deleting, stop

	interior_status = INTERIOR_LOADING
	//Init the template.
	choose_interior()
	if(!boarding_interior?.mappath)
		message_admins("Error parsing boarding interior map for [src]")
		return FALSE

	roomReservation = SSmapping.RequestBlockReservation(boarding_interior.width, boarding_interior.height)
	roomReservation.overmap_fallback = src
	if(!roomReservation)
		message_admins("[src] failed to reserve space for a dropship interior!")
		return FALSE

	var/turf/bottom_left = locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3])
	return load_interior(bottom_left, boarding_interior.width, boarding_interior.height)

/obj/structure/overmap/proc/add_entrypoints(area/target_area)
	for(var/obj/effect/landmark/dropship_entry/entryway in GLOB.landmarks_list)
		if(!entryway.linked && get_area(entryway) == target_area)
			// Please fix asteroids
			if(roomReservation && \
				((entryway.z != roomReservation.bottom_left_coords[3]) || \
				(entryway.x < roomReservation.bottom_left_coords[1]) || \
				(entryway.y < roomReservation.bottom_left_coords[2]) || \
				(entryway.x > roomReservation.top_right_coords[1]) || \
				(entryway.y > roomReservation.top_right_coords[2])))
				continue
			interior_entry_points += entryway
			entryway.linked = src
	if(!length(interior_entry_points))
		var/turf/bottom = get_turf(locate(roomReservation.bottom_left_coords[1] + 2, roomReservation.bottom_left_coords[2] + 2, roomReservation.bottom_left_coords[3]))
		var/obj/effect/landmark/dropship_entry/entryway = new /obj/effect/landmark/dropship_entry(bottom)
		interior_entry_points += entryway
		entryway.linked = src

/obj/structure/overmap/proc/load_interior(turf/bottom_left, width, height)
	SSair.can_fire = FALSE
	if(!boarding_interior.load(bottom_left, centered = FALSE))
		SSair.enqueue()
		message_admins("[ADMIN_LOOKUPFLW(src)] failed to load interior [boarding_interior.mappath]")
		log_mapping("[src] failed to load interior [boarding_interior.mappath]")
	SSair.can_fire = TRUE
	post_load_interior()

	var/turf/center = get_turf(locate(bottom_left.x+boarding_interior.width/2, bottom_left.y+boarding_interior.height/2, bottom_left.z))
	var/area/target_area
	//Now, set up the interior for loading...
	if(center)
		target_area = get_area(center)

	if(interior_mode == INTERIOR_DYNAMIC)
		add_entrypoints(target_area)

	if(!target_area)
		message_admins("WARNING: [src]] FAILED TO FIND AREA TO LINK TO in [boarding_interior.mappath]. ENSURE THAT THE MIDDLE TILE OF THE MAP HAS AN AREA!")
		return FALSE
	if(istype(target_area, /area/dropship/generic))
		target_area.name = "[src.name] interior #[rand(0,999)]" //Avoid naming conflicts.
	else if(!(target_area.area_flags & UNIQUE_AREA))
		target_area.name = src.name
	linked_areas += target_area
	interior_status = INTERIOR_READY
	return TRUE

// Anything that needs to be done after the interior loads
/obj/structure/overmap/proc/post_load_interior()
	if(length(ifflocs)) //Spawn the iff console at a random location!
		var/turf/T = pick(ifflocs)
		var/consolepath = /obj/machinery/computer/iff_console/boarding
		if(faction == "nanotrasen" || faction == "solgov") //We use a default one for NT ships
			consolepath = /obj/machinery/computer/iff_console
		var/obj/C = new consolepath(T)
		C.dir = ifflocs[T]
		ifflocs -= T
		if(length(ifflocs)) //The rest will be blank consoles
			for(var/turf/T2 in ifflocs)
				var/obj/F = new /obj/structure/frame/computer(T2)
				F.dir = ifflocs[T2]
	return

/obj/structure/overmap/proc/get_interior_center()
	if(length(occupying_levels))
		// center of a whole Z level
		var/datum/space_level/level = pick(occupying_levels)
		return get_turf(locate(127, 127, level.z_value))
	else if(roomReservation)
		return get_turf(locate(roomReservation.bottom_left_coords[1]+boarding_interior.width/2, roomReservation.bottom_left_coords[2]+boarding_interior.height/2, roomReservation.bottom_left_coords[3]))
