/datum/star_system/proc/add_ship(obj/structure/overmap/OM, turf/target_turf)
	if(!system_contents.Find(OM))
		system_contents += OM	//Lets be safe while I cast some black magic.
	var/did_restore_system = FALSE
	if(!occupying_z && OM.z) //Does this system have a physical existence? if not, we'll set this now so that any inbound ships jump to the same Z-level that we're on.
		if(!SSmapping.level_trait(OM.z, ZTRAIT_OVERMAP))
			occupying_z = OM.get_reserved_z()
		else
			occupying_z = OM.z
		did_restore_system = TRUE
	else if(!occupying_z && ((OM.overmap_flags & OVERMAP_FLAG_ZLEVEL_CARRIER) || length(OM.mobs_in_ship))) //If someone is inside, or we always want it loaded, load it.
		occupying_z = OM.get_reserved_z()
		did_restore_system = TRUE
	if(did_restore_system)
		if(fleets.len)
			for(var/datum/fleet/F in fleets)
				if(!F.current_system)
					F.current_system = src
				F.encounter(OM)
		restore_contents()
	var/turf/destination
	if(target_turf)
		destination = target_turf
	else if(istype(OM, /obj/structure/overmap))
		var/obj/structure/overmap/OMS = OM
		if(!OMS.faction)
			destination = locate(rand(40, world.maxx - 39), rand(40, world.maxy - 39), occupying_z)
		else if(OMS.faction == "nanotrasen" || OMS.faction == "solgov")	//NT and ally fleets arrive on the left side of the system. Syndies on the right side.
			destination = locate(rand(40, round(world.maxx/2) - 10), rand(40, world.maxy - 39), occupying_z)
		else
			destination = locate(rand(round(world.maxx/2) + 10, world.maxx - 39), rand(40, world.maxy - 39), occupying_z)
	else
		destination = locate(rand(40, world.maxx - 39), rand(40, world.maxy - 39), occupying_z)

	if(!destination)
		message_admins("WARNING: The [name] system has no exit point for ships! Something has caused this Z-level to despawn erroneously, please contact Kmc immediately!.")
		return
	var/turf/exit = get_turf(pick(orange(15, destination)))
	OM.forceMove(exit)
	if(istype(OM, /obj/structure/overmap))
		OM.current_system = src //Debugging purposes only
		after_enter(OM)
	else if(istype(OM, /obj/effect/overmap_anomaly))
		var/obj/effect/overmap_anomaly/anomaly_OM = OM
		anomaly_OM.current_system = src

/datum/star_system/proc/after_enter(obj/structure/overmap/OM)
	SEND_SIGNAL(src, COMSIG_STAR_SYSTEM_AFTER_ENTER, OM)
	if(desc)
		OM.relay(null, "<span class='notice'><h2>Now entering [name]...</h2></span>")
		OM.relay(null, "<span class='notice'>[desc]</span>")
	//End the round upon entering O45.
	if(system_traits & STARSYSTEM_END_ON_ENTER)
		if(OM.role == MAIN_OVERMAP)
			priority_announce("[station_name()] has successfully returned to [src] for resupply and crew transfer, excellent work crew.", "Naval Command")
			GLOB.crew_transfer_risa = TRUE
			SSticker.mode.check_finished()
			SSticker.news_report = SHIP_VICTORY
			SSblackbox.record_feedback("text", "nsv_endings", 1, "succeeded")
	if(!length(audio_cues))
		return FALSE
	//If we have an audio cue, ensure it doesn't overlap with a fleet's one...
	for(var/datum/fleet/F as() in fleets)
		if(length(F.audio_cues) && F.alignment != OM.faction && !F.federation_check(OM))
			return TRUE
	OM.play_music(pick(audio_cues))

/datum/star_system/proc/restore_contents()
	if(enemy_queue)
		for(var/X in enemy_queue)
			SSstar_system.spawn_ship(X, src)
			enemy_queue -= X
	if(!length(contents_positions))
		return //Nothing stored, no need to restore.
	for(var/atom/movable/ship in system_contents)
		if(!contents_positions[ship])
			continue
		var/list/info = contents_positions[ship]
		ship.forceMove(get_turf(locate(info["x"], info["y"], occupying_z))) //Let's unbox that ship. Nice.
		if(istype(ship, /obj/structure/overmap))
			var/obj/structure/overmap/OM = ship
			START_PROCESSING(SSphysics_processing, OM) //And let's restart its processing too..
			if(OM.physics2d)
				START_PROCESSING(SSphysics_processing, OM.physics2d) //Respawn this ship's collider so it can start colliding once more
	contents_positions = null
	contents_positions = list()

/datum/star_system/proc/remove_ship(obj/structure/overmap/OM, turf/new_location, is_ftl_jump = TRUE)
	var/list/other_player_ships = list()
	for(var/atom/X in system_contents)
		if(istype(X, /obj/structure/overmap))
			var/obj/structure/overmap/ship = X
			if(ship.reserved_z && ship != OM)
				other_player_ships += ship
	if(OM.reserved_z == occupying_z && other_player_ships.len) //Alright, this is our Z-level but we're jumping out of it and there are still people here.
		var/obj/structure/overmap/ship = pick(other_player_ships)
		var/temp = ship.get_reserved_z()
		ship.reserved_z = OM.reserved_z
		OM.reserved_z = temp
		OM.forceMove(new_location ? new_location : locate(OM.x, OM.y, OM.reserved_z)) //Annnd actually kick them out of the current system.
		system_contents -= OM
		if(is_ftl_jump)
			ftl_pull_small_craft(OM)
		return //Early return here. This means that another player ship is already holding the system, and we really don't need to double-check for this.

	OM.forceMove(new_location ? new_location : locate(OM.x, OM.y, OM.reserved_z)) //Annnd actually kick them out of the current system.
	system_contents -= OM

	if(!OM.reserved_z)	//If this isn't actually a big ship with its own interior, do not pull ships, as only those get their own reserved z.
		return
	if(other_player_ships.len)	//There's still other ships here, only pull ships of our own faction.
		if(is_ftl_jump)
			ftl_pull_small_craft(OM)
		return

	for(var/atom/movable/X in system_contents)	//Do a last check for safety so we don't stasis a player ship that slid by our other checks somehow.
		if(istype(X, /obj/structure/overmap))
			var/obj/structure/overmap/ship = X
			if(ship != OM && ship.reserved_z) //If there's somehow a player ship in the system that is somehow not in other_player_ships, emergency return.
				message_admins("Somehow [ship] got by the initial checks for system exits. This probably shouldn't happen, yell at a coder and / or check ftl.dm")
				if(is_ftl_jump)
					ftl_pull_small_craft(OM)
				return
	if(is_ftl_jump)
		ftl_pull_small_craft(OM, FALSE)
	else //We are leaving the overmap while holding system and with no other current holders, which risks nullspacing
		for(var/obj/structure/overmap/last_chance in system_contents)
			if(!last_chance.spec_pre_system_unload())
				continue
			last_chance.reserved_z = OM.reserved_z //We are about to nullspace something that should preserve z. Hand over your z instead.
			OM.reserved_z = null
			return

	for(var/atom/movable/X in system_contents)
		contents_positions[X] = list("x" = X.x, "y" = X.y) //Cache the ship's position so we can regenerate it later.
		X.moveToNullspace() //Anything that's an NPC should be stored safely in nullspace until we return.
		if(istype(X, /obj/structure/overmap))
			var/obj/structure/overmap/foo = X
			STOP_PROCESSING(SSphysics_processing, foo) //And let's stop it from processing too.
			if(foo.physics2d)
				STOP_PROCESSING(SSphysics_processing, foo.physics2d) //Despawn this ship's collider, to avoid wasting time figuring out if it's colliding with things or not.
	occupying_z = 0 //Alright, no ships are holding it anymore. Stop holding the Z-level

/datum/star_system/proc/ftl_pull_small_craft(var/obj/structure/overmap/jumping, var/same_faction_only = TRUE)
	if(!jumping)
		return	//No.

	for(var/atom/movable/AM in system_contents)
		if(!istype(AM, /obj/structure/overmap))
			continue
		var/obj/structure/overmap/OM = AM
		//Ships that have a Z reserved are on the active FTL plane.
		if(OM.reserved_z)
			continue
		if(isasteroid(OM))
			continue
		if((!length(OM.operators) && !length(OM.mobs_in_ship)) || OM.ai_controlled)	//AI ships / ships without a pilot just get put in stasis.
			continue
		if(same_faction_only && jumping.faction != OM.faction)	//We don't pull all small craft in the system unless we were the last ship here.
			continue
		OM.relay("<span class='warning'>You're caught in [jumping]'s bluespace wake!</span>")
		SEND_SIGNAL(OM, COMSIG_FTL_STATE_CHANGE)
		OM.forceMove(locate(OM.x, OM.y, jumping.reserved_z))
		system_contents -= OM


/obj/structure/overmap/proc/begin_jump(datum/star_system/target_system, force=FALSE, misjump = FALSE)
	relay(ftl_drive.ftl_start, channel = CHANNEL_IMPORTANT_SHIP_ALERT)
	desired_angle = 90 //90 degrees AKA face EAST to match the FTL parallax.
	addtimer(CALLBACK(src, PROC_REF(jump_start), target_system, force, misjump), ftl_drive.ftl_startup_time)

/obj/structure/overmap/proc/force_return_jump()
	SIGNAL_HANDLER
	var/datum/star_system/target_system = SSstar_system.return_system
	SSovermap_mode.already_ended = TRUE
	if(ftl_drive && target_system) //Do we actually have an ftl drive?
		ftl_drive.lockout = TRUE //Prevent further jumps
		if(ftl_drive.ftl_state == FTL_STATE_JUMPING)
			RegisterSignal(src, COMSIG_SHIP_ARRIVED, PROC_REF(force_return_jump))
			message_admins("[src] is already jumping, delaying recall")
			log_game("DEBUG: force_return_jump: Players were already jumping, trying again when jump is complete")
		else
			SSstar_system.return_system.hidden = FALSE //Reveal where we are going
			UnregisterSignal(src, COMSIG_SHIP_ARRIVED)
			log_game("DEBUG: force_return_jump: Beginning jump to [target_system.name]")
			ftl_drive.force_jump(target_system) //Jump home
			addtimer(CALLBACK(src, PROC_REF(check_return_jump)), SSstar_system.ships[src]["to_time"] + 35 SECONDS)

	else if(target_system)
		message_admins("Failed to force return jump! [src] does not have an FTL Drive!")
		log_runtime("DEBUG: force_return_jump: [src] had no FTL drive")
	else
		message_admins("Failed to force return jump! No target system was found! (Tell a coder)")
		log_runtime("DEBUG: force_return_jump: No target system")

/obj/structure/overmap/proc/check_return_jump()
	log_game("DEBUG: check_return_jump called")
	var/datum/star_system/S = SSstar_system.return_system
	if(current_system != S && SSstar_system.ships[src]["target_system"] != S) // Not in 45 and not on our way there
		log_runtime("DEBUG: check_return_jump detected bad state, trying to force_return_jump")
		force_return_jump()


/obj/structure/overmap/proc/force_parallax_update(ftl_start)
	if(reserved_z) //Actual overmap parallax behaviour
		var/datum/space_level/SL = SSmapping.z_list[reserved_z]
		if(ftl_start)
			SL.set_parallax("transit", EAST)
		else
			SL.set_parallax(current_system.parallax_property, null)
	for(var/datum/space_level/SL as() in occupying_levels)
		if(ftl_start)
			SL.set_parallax("transit", EAST)
		else
			SL.set_parallax(current_system.parallax_property, null)
	for(var/mob/M as() in mobs_in_ship)
		if(M && M.client && M.hud_used && length(M.client.parallax_layers))
			M.hud_used.update_parallax(force=TRUE)

/obj/structure/overmap/proc/jump_start(datum/star_system/target_system, force=FALSE, misjump = FALSE)
	if(ftl_drive?.ftl_state != FTL_STATE_JUMPING)
		if((force || misjump) && ftl_drive)
			ftl_drive.ftl_state = FTL_STATE_JUMPING
		else
			log_runtime("DEBUG: jump_start: aborted jump to [target_system], drive state = [ftl_drive?.ftl_state]")
			return

	var/interdict_return = SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CHECK_INTERDICT, src)
	if(!force && ((interdict_return & STRONG_INTERDICT) || ((interdict_return & WEAK_INTERDICT) && !misjump))) // Override interdiction if the game is over, flying unsafe also bypasses non-fielddisruptive interdiction.
		ftl_drive.radio.talk_into(ftl_drive, "Warning. Local energy anomaly detected - calculated jump parameters invalid. Performing emergency reboot.", ftl_drive.radio_channel)
		relay('sound/magic/lightning_chargeup.ogg', channel=CHANNEL_IMPORTANT_SHIP_ALERT)
		ftl_drive.depower()
		return

	relay_to_nearby('nsv13/sound/effects/ship/FTL.ogg', null, ignore_self=TRUE)//Ships just hear a small "crack" when another one jumps
	if(reserved_z) //Actual overmap parallax behaviour
		var/datum/space_level/SL = SSmapping.z_list[reserved_z]
		SL.set_parallax("transit", EAST)
	for(var/datum/space_level/SL as() in occupying_levels)
		SL.set_parallax("transit", EAST)

	relay(ftl_drive.ftl_loop, "<span class='warning'>You feel the ship lurch forward</span>", loop=TRUE, channel = CHANNEL_SHIP_ALERT)
	var/datum/star_system/curr = SSstar_system.ships[src]["current_system"]
	SEND_SIGNAL(src, COMSIG_SHIP_DEPARTED) // Let missions know we have left the system
	curr.remove_ship(src)
	var/drive_speed = ftl_drive.get_jump_speed()
	if(drive_speed <= 0) //Assumption: If we got into this proc with speed 0, we want it to jump anyways, as it should be caught before otherwise. Using very slow speed in this case.
		drive_speed = 1 //Div-by-0s are not fun.
	var/speed = (curr.dist(target_system) / (drive_speed * 10)) //TODO: FTL drive speed upgrades.
	if(misjump)
		speed = max(speed, 3)
	SSstar_system.ships[src]["to_time"] = world.time + speed MINUTES
	SEND_SIGNAL(src, COMSIG_FTL_STATE_CHANGE)
	if(role == MAIN_OVERMAP) //Scuffed please fix
		priority_announce("Attention: All hands brace for FTL translation. Destination: [target_system]. Projected arrival time: [station_time_timestamp("hh:mm", world.time + speed MINUTES)] (Local time)","Automated announcement")
		if(structure_crit && !istype(src, /obj/structure/overmap/small_craft)) //Tear the ship apart if theyre trying to limp away.
			for(var/i = 0, i < rand(4,8), i++)
				var/name = pick(GLOB.teleportlocs)
				var/area/target = GLOB.teleportlocs[name]
				var/turf/T = pick(get_area_turfs(target))
				new /obj/effect/temp_visual/explosion_telegraph(T, damage_amount = ((world.time - structure_crit_init)/30))
	SSstar_system.ships[src]["target_system"] = target_system
	SSstar_system.ships[src]["from_time"] = world.time
	SSstar_system.ships[src]["current_system"] = null
	addtimer(CALLBACK(src, PROC_REF(jump_end), target_system, misjump), speed MINUTES)
	ftl_drive.depower(ftl_drive.auto_spool_enabled)
	jump_handle_shake()
	if(misjump)
		on_misjump_start(target_system, (speed MINUTES))
	force_parallax_update(TRUE)

/obj/structure/overmap/proc/jump_handle_shake(ftl_start)
	for(var/mob/M in mobs_in_ship)
		var/nearestDistance = INFINITY
		var/obj/machinery/inertial_dampener/nearestMachine = null

		// Going to helpfully pass this in after seasickness checks, to reduce duplicate machine checks
		for(var/obj/machinery/inertial_dampener/machine as anything in GLOB.inertia_dampeners)
			var/dist = get_dist( M, machine )
			if ( dist < nearestDistance && machine.on )
				nearestDistance = dist
				nearestMachine = machine

		if(iscarbon(M))
			var/mob/living/carbon/L = M
			if(HAS_TRAIT(L, TRAIT_SEASICK))
				if ( nearestMachine )
					var/newNausea = nearestMachine.reduceNausea( nearestDistance, 70 )
					if ( newNausea > 10 )
						to_chat(L, "<span class='warning'>You can feel your head start to swim...</span>")
					L.adjust_disgust( newNausea )
				else
					to_chat(L, "<span class='warning'>You can feel your head start to swim...</span>")
					L.adjust_disgust(pick(70, 100))
		shake_with_inertia(M, 4, 1, list(distance=nearestDistance, machine=nearestMachine))


/obj/structure/overmap/proc/jump_end(datum/star_system/target_system, misjump = FALSE)
	if(reserved_z) //Actual overmap parallax behaviour
		var/datum/space_level/SL = SSmapping.z_list[reserved_z]
		SL.set_parallax( (current_system != null) ?  current_system.parallax_property : target_system.parallax_property, null)
	for(var/datum/space_level/SL as() in occupying_levels)
		SL.set_parallax( (current_system != null) ?  current_system.parallax_property : target_system.parallax_property, null)

	log_runtime("DEBUG: jump_end: exiting hyperspace into [target_system]")
	SSstar_system.ships[src]["target_system"] = null
	SSstar_system.ships[src]["current_system"] = target_system
	SSstar_system.ships[src]["last_system"] = target_system
	SSstar_system.ships[src]["from_time"] = 0
	SSstar_system.ships[src]["to_time"] = 0
	SEND_SIGNAL(src, COMSIG_FTL_STATE_CHANGE)
	if(!misjump)
		relay(ftl_drive.ftl_exit, "<span class='warning'>You feel the ship lurch to a halt</span>", loop=FALSE, channel = CHANNEL_SHIP_ALERT)
	else
		var/exit_sound = pick(list('nsv13/sound/effects/ship/misjump/misjump_exit_01.ogg', 'nsv13/sound/effects/ship/misjump/misjump_exit_02.ogg'))
		relay(message = "<span class='warning'>You feel the ship violently leave drive space!</span>")
		for(var/mob/mob in mobs_in_ship)
			if(!mob.client)
				continue
			mob.playsound_local(soundin = exit_sound, vol = 100, vary = FALSE) //Going for direct sound over relay because people should hear this, while system related sounds sometimes override relay.

	var/list/pulled = list()
	for(var/obj/structure/overmap/SOM as() in GLOB.overmap_objects) //Needs to go through global objects due to being in jumpspace not a system.
		if(!SOM.z || SOM.z != reserved_z)
			continue
		if(SOM == src)
			continue
		if(!SOM.z)
			continue
		LAZYADD(pulled, SOM)
	target_system.add_ship(src) //Get the system to transfer us to its location.
	for(var/obj/structure/overmap/SOM in pulled)
		target_system.add_ship(SOM)

	SEND_SIGNAL(src, COMSIG_SHIP_ARRIVED) // Let missions know we have arrived in the system
	jump_handle_shake()
	if(misjump)
		on_misjump_end(target_system)
	force_parallax_update(FALSE)

/obj/item/ftl_slipstream_chip
	name = "Quantum slipstream field generation matrix (tier II)"
	desc = "An upgrade to the ship's FTL computer, allowing it to benefit from cutting edge calculation technologies to result in faster jump times by changing the way in which it allows the ship to incurse into bluespace."
	icon = 'nsv13/icons/obj/computers.dmi'
	icon_state = "quantum_slipstream"
	var/tier = 2

/obj/item/ftl_slipstream_chip/warp
	name = "Warp drive chip"
	desc = "A highly experimental chip which appears to be able to accelerate starships to ludicrous speeds without the use of bluespace. Further testing required."
	icon_state = "warpchip"
	tier = 3

/datum/design/ftl_slipstream_chip
	name = "Quantum slipstream field generation matrix"
	desc = "An upgrade for Thirring Drive computers which allows for much more efficient FTL translations."
	id = "ftl_slipstream_chip"
	build_type = PROTOLATHE
	materials = list(/datum/material/plasma = 25000,/datum/material/diamond = 15000, /datum/material/silver = 20000)
	build_path = /obj/item/ftl_slipstream_chip
	category = list("Ship Components")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_SCIENCE

/datum/techweb_node/ftl_slipstream
	id = "ftl_slipstream"
	display_name = "Quantum slipstream technology"
	description = "Cutting edge upgrades for the Thirring Drive computer, allowing for more efficient FTL travel."
	prereq_ids = list("comptech")
	design_ids = list("ftl_slipstream_chip")
	research_costs = list(TECHWEB_POINT_TYPE_WORMHOLE = 5000) //You need to have fully probed a wormhole to unlock this.
	export_price = 15000 //This is EXTREMELY valuable to NT because it'll let their ships go super fast.

