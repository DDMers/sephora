GLOBAL_LIST_EMPTY(asteroid_spawn_markers)		//handles mining asteroids, kind of shitcode but i cant think of what else to do

//Credit to floyd for the backbone of this code

/obj/structure/overmap/asteroid
	name = "Asteroid"
	desc = "A huge asteroid...IN SPACE"
	icon = 'nsv13/icons/overmap/stellarbodies/asteroidfield/asteroid_ice_32x.dmi'
	icon_state = "1"
	obj_integrity = 1000
	max_integrity = 1000
	var/icon_path = "nsv13/icons/overmap/stellarbodies/asteroidfield/asteroid"
	var/asteroid_size = ASTEROID_SIZE_SMALL
	var/asteroid_type = ASTEROID_TYPE_ICE
	var/core_composition = ASTEROID_COMPOSITION_FERROUS
	var/has_ruins = FALSE
	var/required_tier = 0
	armor = list("overmap_light" = 99, "overmap_medium" = 99, "overmap_heavy" = 25)

/obj/structure/overmap/asteroid/apply_weapons()
	return FALSE //Lol, no.

/obj/structure/overmap/asteroid/Initialize()
	. = ..()
	asteroid_size = pick(ASTEROID_SIZE_SMALL, ASTEROID_SIZE_MEDIUM, ASTEROID_SIZE_MEDIUM_LARGE, ASTEROID_SIZE_LARGE)
	asteroid_type = pick(ASTEROID_TYPE_ROCK, ASTEROID_TYPE_ICE)
	core_composition = pick(ASTEROID_COMPOSITION_FERROUS, ASTEROID_COMPOSITION_NONFERROUS, ASTEROID_COMPOSITION_EXOTIC)
	has_ruins = pick(FALSE,TRUE)
	switch(asteroid_type)
		if(ASTEROID_TYPE_ROCK)
			icon_path += "_rock"
		if(ASTEROID_TYPE_ICE)
			icon_path += "_ice"
	switch(asteroid_size)
		if(ASTEROID_SIZE_MEDIUM)
			mass = MASS_MEDIUM
			bound_height = 96
			bound_width = 96
		if(ASTEROID_SIZE_MEDIUM_LARGE)
			mass = MASS_MEDIUM_LARGE
			bound_height = 128
			bound_width = 128
		if(ASTEROID_SIZE_LARGE)
			mass = MASS_LARGE
			bound_height = 192
			bound_width = 192
	icon_path += "[asteroid_size].dmi"
	icon = file(icon_path)
	icon_state = "[rand(1,5)]"
	angle = rand(0,360)
	desired_angle = angle
	required_tier += core_composition

/obj/structure/overmap/asteroid/Destroy()
	. = ..()

/datum/map_template/asteroid
	var/list/core_composition = list(/turf/closed/mineral/iron, /turf/closed/mineral/titanium)

/datum/map_template/asteroid/New(path = null, rename = null, cache = FALSE, var/list/core_comp)
	. = ..()
	if(core_comp)
		core_composition = core_comp

/datum/map_template/asteroid/load(turf/T, centered = FALSE) ///Add in vein if applicable.
	. = ..()
	if(!core_composition.len) //No core composition? you a normie asteroid.
		return
	var/turf/center = locate(T.x+(width/2), T.y+(height/2), T.z)
	for(var/turf/target_turf in orange(rand(3,5), center)) //Give that boi a nice core.
		if(prob(85)) //Bit of random distribution
			var/turf_type = pick(core_composition)
			target_turf.ChangeTurf(turf_type) //Make the core itself

/obj/effect/landmark/asteroid_spawn
	name = "Asteroid Spawn"

/obj/effect/landmark/asteroid_spawn/New()
	..()
	GLOB.asteroid_spawn_markers += src

/obj/effect/landmark/asteroid_spawn/Destroy()
	GLOB.asteroid_spawn_markers -= src
	return ..()

/obj/item/deepcore_upgrade
	name = "Polytrinic non magnetic asteroid arrestor upgrade"
	desc = "A component which, when slotted into an asteroid magnet computer, will allow it to capture increasingly valuable asteroids."
	icon = 'nsv13/icons/obj/computers.dmi'
	icon_state = "minescanner_upgrade"
	var/tier = 2

/obj/item/deepcore_upgrade/max
	name = "Phasic asteroid arrestor upgrade"
	icon_state = "minescanner_upgrade_max"
	tier = 3

/obj/item/mining_sensor_upgrade
	name = "Dradis mineral sensor upgrade (tier II)"
	desc = "A component which, when slotted into an asteroid magnet computer, will allow it to capture increasingly valuable asteroids."
	icon = 'nsv13/icons/obj/computers.dmi'
	icon_state = "minesensor"
	var/tier = 2

/obj/item/mining_sensor_upgrade/max
	name = "Dradis mineral sensor upgrade (tier III)"
	icon_state = "minesensor_max"
	tier = 3

/obj/machinery/computer/ship/mineral_magnet
	name = "Asteroid Magnet Computer"
	icon = 'nsv13/icons/obj/terminals.dmi'
	icon_state = "magnet"
	req_access = list(ACCESS_MINING)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	var/datum/map_template/asteroid/current_asteroid
	var/turf/target_location = null //Where to load the asteroid
	var/cooldown = FALSE
	var/tier = 1 //Upgrade via science
	var/turf_type = /turf/open/space/basic

//Hoc modo operatur. Do not question.
/obj/machinery/computer/ship/mineral_magnet/stupidfuckingbabyaetherwhispmagnetvariantfortoproofdeckbecauseFUCKYOU
	turf_type = /turf/open/floor/plating/airless

/obj/machinery/computer/ship/mineral_magnet/Initialize()
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/ship/mineral_magnet/LateInitialize()
	. = ..()
	//Find our ship's asteroid marker. This allows multi-ship mining.
	for(var/obj/effect/landmark/L in GLOB.asteroid_spawn_markers)
		if(shares_overmap(src, L))
			target_location = get_turf(L)
			return

/obj/machinery/computer/ship/mineral_magnet/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/deepcore_upgrade))
		var/obj/item/deepcore_upgrade/DU = I
		if(DU.tier > tier)
			playsound(src, 'sound/machines/terminal_insert_disc.ogg', 100, 0)
			to_chat(user, "<span class='notice'>You slot [I] into [src], allowing it to lock on to a wider variety of asteroids.</span>")
			tier = DU.tier
			qdel(DU)
			icon_state = "magnet-[tier]"
			return TRUE
	return ..()


/obj/machinery/computer/ship/mineral_magnet/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/computer/ship/mineral_magnet/attack_robot(mob/user)
	attack_hand(user)

/obj/machinery/computer/ship/mineral_magnet/attack_hand(mob/user)
	if(!allowed(user))
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Access denied</span>")
		return
	if(!has_overmap())
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>A warning flashes across [src]'s screen: Unable to locate necessary parameters, no registered ship stored in microprocessor.</span>")
		return
	playsound(src, 'nsv13/sound/effects/computer/hum.ogg', 100, 1)
	if(!target_location)
		return
	var/dat
	dat += "<h2>Current asteroid:  </h2>"
	if(!current_asteroid)
		dat += "<A href='?src=\ref[src];pull_asteroid=1'>Pull in asteroid</font></A><BR>"
	else
		dat += "<A href='?src=\ref[src];push_asteroid=1'>Push away asteroid</font></A><BR>"
	var/datum/browser/popup = new(user, "Pull Asteroids", name, 400, 500)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/ship/mineral_magnet/Topic(href, href_list)
	if(!in_range(src, usr))
		return
	if(href_list["pull_asteroid"])
		pull_in_asteroid(usr)
	if(href_list["push_asteroid"])
		if(alert(usr, "Are you sure you want to release the currently held asteroid?",name,"Yes","No") == "Yes" && Adjacent(usr))
			start_push()

	attack_hand(usr) //Refresh window

/obj/machinery/computer/ship/mineral_magnet/proc/pull_in_asteroid(mob/user)
	if(cooldown)
		say("ERROR: Magnetisation circuits recharging...")
		return FALSE
	if(!has_overmap())
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		return FALSE
	var/list/asteroids = list()
	for(var/obj/structure/overmap/asteroid/AS in orange(5, linked))
		if(AS.required_tier <= tier)
			asteroids += AS
	if(!asteroids.len)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='notice'>Cannot lock on to any asteroids near [linked]</span>")
		return FALSE
	var/obj/structure/overmap/asteroid/AS = input(usr, "Select target:", "Target") as null|anything in asteroids
	if(!AS || !AS.core_composition)
		return FALSE
	linked.relay('nsv13/sound/effects/ship/tractor.ogg', "<span class='warning'>DANGER: Magnet has locked on to an asteroid. Vacate the asteroid cage immediately.</span>")
	cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 1 MINUTES)
	if(prob(20))
		var/list/potential_ruins = flist("_maps/map_files/Mining/nsv13/ruins/")
		current_asteroid = new /datum/map_template/asteroid("_maps/map_files/Mining/nsv13/ruins/[pick(potential_ruins)]", null, FALSE, AS.core_composition) //Set up an asteroid
	else //80% chance to get an actual asteroid
		var/list/potential_asteroids = flist("_maps/map_files/Mining/nsv13/asteroids/")
		current_asteroid = new /datum/map_template/asteroid("_maps/map_files/Mining/nsv13/asteroids/[pick(potential_asteroids)]", null, FALSE, AS.core_composition) //Set up an asteroid
	addtimer(CALLBACK(src, .proc/load_asteroid), 10 SECONDS)
	qdel(AS)

/obj/machinery/computer/ship/mineral_magnet/proc/load_asteroid()
	current_asteroid.load(target_location, FALSE)

/obj/machinery/computer/ship/mineral_magnet/proc/start_push()
	if(!has_overmap())
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		return
	if(cooldown)
		say("ERROR: Magnetisation circuits recharging...")
		return
	cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 1 MINUTES)
	linked.relay('nsv13/sound/effects/ship/general_quarters.ogg', "<span class='warning'>DANGER: An asteroid is now being detached from [linked]. Vacate the asteroid cage immediately.</span>")
	addtimer(CALLBACK(src, .proc/push_away_asteroid), 30 SECONDS)

/obj/machinery/computer/ship/mineral_magnet/proc/push_away_asteroid()
	for(var/i in current_asteroid.get_affected_turfs(target_location, FALSE)) //nuke
		var/turf/T = i
		for(var/atom/A in T.contents)
			if(!ismob(A) && !istype(A, /obj/effect/landmark/asteroid_spawn))
				qdel(A)
		T.ChangeTurf(turf_type)
	QDEL_NULL(current_asteroid)
