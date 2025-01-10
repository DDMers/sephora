///Has the ship begin an emergency jump. Very hazardous.
/obj/structure/overmap/proc/emergency_jump()
	var/datum/star_system/target_system = current_system
	var/list/viable_systems = SSstar_system.systems.Copy()
	shuffle_inplace(viable_systems)
	for(var/datum/star_system/potential_target as() in viable_systems)
		if(current_system.dist(potential_target) > EMERGENCY_FTL_RANGE)
			continue
		if(potential_target.hidden)
			continue
		if(potential_target.sector != current_system.sector)
			continue
		target_system = potential_target
		break
	next_emergency_jump = world.time + EMERGENCY_FTL_COOLDOWN
	ftl_drive.jump(target_system, misjump = TRUE) //Buckle up, here we go.

///Called on jump start if the jump is a misjump.
/obj/structure/overmap/proc/on_misjump_start(datum/star_system/target_system, jump_length)
	if(!occupying_levels || !linked_areas)
		take_damage(0.4 * max_integrity, BRUTE, bypasses_shields = TRUE, sound_effect = FALSE)
		return
	else
		take_damage((rand(5, 10) / 100) * max_integrity, BRUTE, bypasses_shields = TRUE, sound_effect = FALSE)
	handle_concerning_noises(jump_length)
	addtimer(CALLBACK(src, PROC_REF(fry_phasestate)), rand(35, 180) SECONDS)
	disjoint_phasestate()

///Called on jump end if the jump is a misjump.
/obj/structure/overmap/proc/on_misjump_end(datum/star_system/target_system)
	if(!occupying_levels || !linked_areas)
		take_damage(0.5 * max_integrity, BRUTE, bypasses_shields = TRUE, sound_effect = FALSE, nsv_damagesound = FALSE)
		return
	else
		var/structure_stress = prob(25) ? 10 : rand(15,75)
		var/structure_damage = (structure_stress / 100) * max_integrity
		take_damage(structure_damage, BRUTE, bypasses_shields = TRUE, sound_effect = FALSE, nsv_damagesound = FALSE)

	var/fun_meteors = pick(0,0,0,0,1,2,2,3,4)
	var/oops_asteroid_collision = 25
	for(var/obj/structure/overmap/asteroid/asteroid in target_system.system_contents)
		oops_asteroid_collision += 5
	oops_asteroid_collision = CLAMP(oops_asteroid_collision, 25, 90)
	fry_phasestate()
	if(prob(oops_asteroid_collision))
		handle_asteroid_phase_collision()
	if(fun_meteors > 0)
		handle_meteor_launches(fun_meteors)

///Provides occassional concerning noises while emergency jumping, also occasionally distorts the drive bubble, creating anomalies.
/obj/structure/overmap/proc/handle_concerning_noises(jump_length)
	new /datum/misjump_noise_handler(src, jump_length)

//Creates fun and engaging noises, self deletes shortly before jump end, or on end, or if the owner deletes. Also does some other stuff.
/datum/misjump_noise_handler
	///Linked overmap
	var/obj/structure/overmap/linked
	///Next world.time or above to do things at
	var/next_noise = 0
	///Sounds to choose from
	var/static/list/yowie_sounds = list('nsv13/sound/ambience/ship_damage/creak5.ogg' = 10, 'nsv13/sound/ambience/ship_damage/creak6.ogg' = 10, 'nsv13/sound/ambience/ship_damage/creak7.ogg' = 2)
	///The timer that tracks our time-based deletion
	var/deletetimer

/datum/misjump_noise_handler/New(obj/structure/overmap/linked_ship, jump_length)
	. = ..()
	if(!linked_ship)
		log_runtime("A misjump noise handler was created without a linked ship :(")
	linked = linked_ship
	deletetimer = addtimer(CALLBACK(src, PROC_REF(on_timer_expire)), jump_length - (20 SECONDS), TIMER_STOPPABLE)
	RegisterSignal(linked, COMSIG_PARENT_QDELETING, PROC_REF(cease_noise)) //If we are somehow faster than we expected.
	RegisterSignal(linked, COMSIG_SHIP_ARRIVED, PROC_REF(cease_noise))
	START_PROCESSING(SSprocessing, src)

///Handles deletion if our timer runs out.
/datum/misjump_noise_handler/proc/on_timer_expire()
	deletetimer = null
	qdel(src)

///Handles deletion if one of our two signals gets triggered.
/datum/misjump_noise_handler/proc/cease_noise()
	SIGNAL_HANDLER
	qdel(src)

/datum/misjump_noise_handler/Destroy(force, ...)
	if(deletetimer)
		deltimer(deletetimer)
		deletetimer = null
	UnregisterSignal(linked, COMSIG_PARENT_QDELETING)
	UnregisterSignal(linked, COMSIG_SHIP_ARRIVED)
	linked = null
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/misjump_noise_handler/process(delta_time)
	if(next_noise > world.time)
		return
	var/yowie_sound = pickweight(yowie_sounds)
	linked.relay(yowie_sound)
	if(prob(1))
		var/oops_reality_distortion = pick(/obj/effect/anomaly/stormdrive, /obj/effect/anomaly/stormdrive/sheer, /obj/effect/anomaly/bluespace)
		var/list/possible_areas = linked.linked_areas.Copy() //we really should have a different space area for the NSV huh (and we even already have nearstation)
		shuffle_inplace(possible_areas)
		var/area/target_area
		for(var/area/possible_area in possible_areas)
			if(istype(possible_area, /area/space))
				continue
			target_area = possible_area
			break
		var/turf/target_turf
		for(var/turf/possible_target in target_area.contents)
			target_turf = possible_target
			break
		if(target_turf)
			new oops_reality_distortion(target_turf)
		if(linked.reserved_z)
			var/turf/hmmm = locate(rand(TRANSITIONEDGE, world.maxx - TRANSITIONEDGE), rand(TRANSITIONEDGE, world.maxy - TRANSITIONEDGE), linked.reserved_z)
			if(hmmm)
				new /obj/structure/overmap/ref_0x000000(hmmm, linked)
	if(linked.structure_crit && prob(20)) //Bad times.
		var/datum/space_level/picked_z = pick(linked.occupying_levels)
		var/turf/explode_turf = locate(rand(TRANSITIONEDGE, world.maxx - TRANSITIONEDGE), rand(TRANSITIONEDGE, world.maxy - TRANSITIONEDGE), picked_z.z_value)
		if(isturf(explode_turf) && !isspaceturf(explode_turf)) //If we roll space, you got lucky.
			new /obj/effect/temp_visual/explosion_telegraph(explode_turf, 100 * round(((world.time - linked.structure_crit_init) / (1 MINUTES)) + 1))
	next_noise = world.time + 8 SECONDS

///Launches a meteor from the front side somewhere towards the vessel.
/obj/structure/overmap/proc/handle_meteor_launches(fun_meteors = 0)
	var/list/possible_areas = linked_areas.Copy()
	for(var/i = 1; i <= fun_meteors; i++)
		shuffle_inplace(possible_areas)
		var/area/main_target_area
		for(var/area/possible_area in possible_areas)
			if(istype(possible_area, /area/space))
				continue
			main_target_area = possible_area
			break
		var/turf/main_target_turf
		for(var/turf/possible_target_turf in main_target_area.contents)
			main_target_turf = possible_target_turf
			break
		if(!main_target_turf) //huh?
			continue
		var/turf/spawn_turf = locate(world.maxx - (TRANSITIONEDGE+1), main_target_turf.y, main_target_turf.z)
		var/turf/real_target = locate((TRANSITIONEDGE+1), main_target_turf.y, main_target_turf.z)
		if(!spawn_turf || !real_target)
			continue
		var/meteor_type = pickweight(GLOB.meteors_threatening)
		new meteor_type(spawn_turf, real_target)

// ~
/obj/structure/overmap/ref_0x000000
	name = "??????"
	max_integrity = 10000
	obj_integrity = 10000
	desc = null
	alpha = 0
	layer = EFFECTS_LAYER
	opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_MAXIMUM
	resistance_flags = INDESTRUCTIBLE
	destruction_effects = FALSE
	///Linked overmap
	var/obj/structure/overmap/linked
	brakes = FALSE
	inertial_dampeners = FALSE
	sensor_profile = 255

/obj/structure/overmap/ref_0x000000/handle_cloak(state)
	return

/obj/structure/overmap/ref_0x000000/take_damage(damage_amount, damage_type, damage_flag, sound_effect, bypasses_shields, nsv_damagesound)
	return

/obj/structure/overmap/ref_0x000000/bullet_act(obj/item/projectile/P)
	return BULLET_ACT_FORCE_PIERCE

/obj/structure/overmap/ref_0x000000/ex_act()
	return

/obj/structure/overmap/ref_0x000000/singularity_act()
	return

/obj/structure/overmap/ref_0x000000/apply_weapons()
	return

/obj/structure/overmap/ref_0x000000/is_sensor_visible(obj/structure/overmap/observer)
	return SENSOR_VISIBILITY_VERYFAINT

/obj/structure/overmap/ref_0x000000/Initialize(mapload, obj/structure/overmap/linked_ship)
	. = ..()
	linked = linked_ship
	RegisterSignal(linked, COMSIG_SHIP_ARRIVED, PROC_REF(self_delete))
	velocity.a += (rand() - 0.5) * 2
	velocity.e += (rand() - 0.5) * 2
	QDEL_IN(src, rand(2,4) MINUTES)

///Handles self deletion if signal is triggered
/obj/structure/overmap/ref_0x000000/proc/self_delete()
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/overmap/ref_0x000000/Destroy(force)
	UnregisterSignal(linked, COMSIG_SHIP_ARRIVED)
	linked = null
	return ..()

///Called if the ship decides to leave drive space in a very bad spot.
/obj/structure/overmap/proc/handle_asteroid_phase_collision()
	if(!occupying_levels)
		return
	var/datum/space_level/target_z_level = pick(occupying_levels)
	var/target_z = target_z_level.z_value
	var/target_x = rand(40, world.maxx -40)
	var/target_y = rand(40, world.maxy -40)
	var/core_turf = locate(target_x, target_y, target_z)
	var/list/potential_asteroids = flist("_maps/map_files/Mining/nsv13/asteroids/")
	var/datum/map_template/asteroid_template = new /datum/map_template/asteroid("_maps/map_files/Mining/nsv13/asteroids/[pick(potential_asteroids)]", null, FALSE, list(/turf/closed/mineral/iron, /turf/closed/mineral/titanium, /turf/closed/mineral/plasma, /turf/closed/mineral/bscrystal))
	var/list/asteroidbounds = asteroid_template.load(core_turf, TRUE, TRUE)
	var/turf/bound1 = locate(asteroidbounds[MAP_MINX], asteroidbounds[MAP_MINY], asteroidbounds[MAP_MINZ])
	var/turf/bound2 = locate(asteroidbounds[MAP_MAXX], asteroidbounds[MAP_MAXY], asteroidbounds[MAP_MAXZ])
	if(!bound1 || !bound2)
		return
	for(var/y_iter = bound1.y, y_iter <= bound2.y, y_iter++)
		for(var/x_iter = bound1.x, x_iter <= bound2.x, x_iter++)
			var/turf/squish = locate(x_iter, y_iter, target_z)
			if(!isclosedturf(squish))
				continue
			for(var/mob/living/squished in squish)
				if(squished.client)
					to_chat(squished, "<span class='userdanger'>You are suddenly crushed by something solid materializing in your own space!</span>")
				squished.gib()

///Messes with turf spacetime in a certain area.
/obj/structure/overmap/proc/disjoint_phasestate()
	for(var/mob/living/cloned in mobs_in_ship)
		var/turf/target_turf = get_turf(cloned)
		if(!target_turf)
			continue
		var/obj/effect/abstract/phase_ghost/ghost = new(target_turf)
		ghost.set_up(cloned)
	var/list/possible_areas = linked_areas.Copy()
	shuffle_inplace(possible_areas)
	var/area/target_area
	for(var/area/possible_area in possible_areas)
		if(istype(possible_area, /area/space))
			continue
		target_area = possible_area
		break
	var/turf/target_turf
	for(var/turf/possible_turf in target_area.contents)
		target_turf = possible_turf //Why in the name of Ratvar is there no turf area list.
		break
	if(!target_turf)
		return
	var/list/turfs = spiral_range_turfs(12, target_turf)
	if(!turfs.len)
		return
	var/list/turf_steps = list()
	var/length = round(turfs.len * 0.5)
	for(var/i in 1 to length)
		turf_steps[pick_n_take(turfs)] = pick_n_take(turfs)
	if(turfs.len > 0)
		var/turf/loner = pick(turfs)
		turf_steps[loner] = get_turf(pick(target_area.contents))

	var/list/effects = list()
	for(var/V in turf_steps)
		var/turf/T0 = V
		var/turf/T1 = turf_steps[V]
		var/obj/effect/cross_action/spacetime_dist/STD0 = new /obj/effect/cross_action/spacetime_dist(T0)
		var/obj/effect/cross_action/spacetime_dist/STD1 = new /obj/effect/cross_action/spacetime_dist(T1)
		STD0.linked_dist = STD1
		STD0.add_overlay(T1.photograph())
		STD1.linked_dist = STD0
		STD1.add_overlay(T0.photograph())
		STD1.set_light(4, 30, "#c9fff5")
		effects += STD0
		effects += STD1
	addtimer(CALLBACK(src, PROC_REF(clear_distortion), effects), rand(4,6) MINUTES)

///Resets things after the timer expires
/obj/structure/overmap/proc/clear_distortion(list/effects)
	for(var/effect in effects)
		qdel(effect)

///Causes permanent spatial displacement.
/obj/structure/overmap/proc/fry_phasestate()
	var/num = rand(1,3)
	var/list/possible_area_picks = linked_areas.Copy() //we really should have a different space area for the NSV huh (and we even already have nearstation)
	shuffle_inplace(possible_area_picks)
	for(var/area/possible_area in possible_area_picks)
		if(istype(possible_area, /area/space))
			possible_area_picks -= possible_area
	num = min(num, length(possible_area_picks))
	for(var/frycount = 1; frycount <= num; frycount++)
		var/area/target_area = pick_n_take(possible_area_picks)
		var/turf/target_turf = get_turf(pick(target_area.contents))
		if(!target_turf)
			continue
		var/list/to_scrungle = RANGE_TURFS(3, target_turf)
		shuffle_inplace(to_scrungle)
		for(var/i = 1; i <= length(to_scrungle)-1; i += 2)
			///Turf doing the swapping
			var/turf/turf1 = to_scrungle[i]
			///Turf being swapped with.
			var/turf/turf2 = to_scrungle[i+1]
			///Type of second turf.
			var/turf2_type = turf2.type
			///Baseturfs of second turf.
			var/list/turf2_originals
			if(islist(turf2.baseturfs)) //Why can baseturfs both be a single non-list path or a list of them..
				turf2_originals = turf2.baseturfs.Copy()
			else
				turf2_originals = turf2.baseturfs
			///Contents of the second turf.
			var/list/turf2_contents = turf2.contents.Copy()
			if(islist(turf1.baseturfs))
				turf2.ChangeTurf(turf1.type, turf1.baseturfs.Copy(), CHANGETURF_INHERIT_AIR)
			else
				turf2.ChangeTurf(turf1.type, turf1.baseturfs, CHANGETURF_INHERIT_AIR)
			for(var/atom/movable/thing in turf1)
				thing.forceMove(turf2)
			turf1.ChangeTurf(turf2_type, turf2_originals, CHANGETURF_INHERIT_AIR)
			for(var/atom/movable/thing in turf2_contents)
				thing.forceMove(turf1)
