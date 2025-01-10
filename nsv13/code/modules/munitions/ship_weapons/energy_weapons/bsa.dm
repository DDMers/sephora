/obj/machinery/ship_weapon/energy/beam/bsa
	name = "\improper Superliminal Bluespace Artillery"
	desc = "A massive machine which can accelerate a bolt of concentrated quark-gluon plasma to superliminal speeds, tearing clean through targets and annihilating everything in its path. <b>Ensure it has a clear firing path to space!</b>"
	icon = 'nsv13/icons/obj/cannon.dmi'
	icon_state = "cannon"

	charge_rate = 1000000//1 MW / tick base.
	charge_per_shot = 7.5e+7 //75 MW to fire once.
	max_charge = 7.5e+7 //This thing chews through power.
	power_modifier_cap = 3 //Can go up to 225 MW for a oneshot instadeath beam.
	energy_weapon_type = /datum/ship_weapon/bsa
	obj_integrity = 2000
	max_integrity = 2000

	var/mutable_appearance/top_layer
	pixel_y = -32
	pixel_x = -192
	bound_width = 352
	bound_x = -192
	appearance_flags = NONE //Removes default TILE_BOUND
	dir = EAST //Default.
	var/id = null
	fire_mode = FIRE_MODE_RAILGUN
	var/built = FALSE //Station goal fuckery
	//circuit =

//Note to mappers. If you REALLY need a north/south facing one go get a spriter to sprite it and I'll add support...
/obj/machinery/ship_weapon/energy/beam/bsa/west
	pixel_x = -192
	dir = WEST

/obj/machinery/ship_weapon/energy/beam/bsa/built
	built = TRUE

/obj/machinery/ship_weapon/energy/beam/bsa/wrench_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/ship_weapon/energy/beam/bsa/ui_state()
	return GLOB.conscious_state

//You have to use the special computer to open settings...

/obj/machinery/ship_weapon/energy/beam/bsa/attack_hand(mob/user)
	return FALSE

/obj/machinery/ship_weapon/energy/beam/bsa/attack_ai(mob/user)
	return FALSE

/obj/machinery/ship_weapon/energy/beam/bsa/attack_robot(mob/user)
	return FALSE

//Ship-to-ship BSA control...
/obj/machinery/computer/sts_bsa_control
	name = "\improper Superliminal Bluespace Artillery control"
	desc = "A computer which lets you interface with anti-capital super weapons."
	icon = 'nsv13/goonstation/icons/obj/computer.dmi'
	icon_state = "computer"
	icon_screen = "bsa"
	circuit = /obj/item/circuitboard/computer/sts_bsa_control
	var/obj/machinery/ship_weapon/energy/beam/bsa/cannon = null
	var/id = null

/obj/item/circuitboard/computer/sts_bsa_control
	name = "\improper Superliminal Bluespace Artillery control (circuit)"
	build_path = /obj/machinery/computer/sts_bsa_control

/obj/machinery/computer/sts_bsa_control/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/sts_bsa_control/LateInitialize()
	. = ..()
	for(var/obj/machinery/ship_weapon/energy/beam/bsa/bsa in GLOB.machines)
		if(id && bsa.id && id == bsa.id || !id)
			cannon = bsa
			break

/obj/machinery/computer/sts_bsa_control/multitool_act(mob/living/user, obj/item/I)
	..()
	. = TRUE
	var/obj/item/multitool/M = I
	if(!M.buffer || !istype(M.buffer, /obj/machinery/ship_weapon/energy/beam/bsa))
		return
	cannon = M.buffer
	to_chat(user, "<span class='warning'>Successfully linked to [M.buffer]...</span>")

/obj/machinery/computer/sts_bsa_control/attack_hand(mob/living/user)
	. = ..()
	if(!cannon)
		to_chat(user, "<span class='warning'>Console not linked to any weaponry.</span>")
		return FALSE
	ui_interact(user)

/obj/machinery/computer/sts_bsa_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EnergyWeapons")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/sts_bsa_control/ui_data(mob/user)
	return cannon.ui_data(user)

/obj/machinery/computer/sts_bsa_control/ui_act(action, params)
	if(..())
		return
	var/value = text2num(params["input"])
	switch(action)
		if("power")
			cannon.power_modifier = value
		if("activeToggle")
			cannon.active = !cannon.active
	return


/obj/machinery/computer/sts_bsa_control/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/computer/sts_bsa_control/attack_robot(mob/user)
	attack_hand(user)

/obj/machinery/ship_weapon/energy/beam/bsa/Initialize(mapload, cannon_direction=dir)
	. = ..()
	setDir(cannon_direction)
	top_layer = top_layer || mutable_appearance(icon, layer = ABOVE_MOB_LAYER)
	top_layer.icon_state = "top"
	add_overlay(top_layer)

/obj/machinery/ship_weapon/energy/beam/bsa/proc/get_front_turf()
	switch(dir)
		if(WEST)
			return locate(x - 7,y,z)
		if(EAST)
			return locate(x + 4,y,z)
	return get_turf(src)

/obj/machinery/ship_weapon/energy/beam/bsa/proc/get_back_turf()
	switch(dir)
		if(WEST)
			return locate(x + 4,y,z)
		if(EAST)
			return locate(x - 6,y,z)
	return get_turf(src)

/obj/machinery/ship_weapon/energy/beam/bsa/proc/kickback()
	set waitfor = FALSE
	var/cached_pixel_x = pixel_x
	var/new_pixel_x = (dir == EAST) ? pixel_x - 30 : pixel_x + 30
	animate(src, pixel_x = new_pixel_x, time = 0.25 SECONDS)
	sleep(0.25)
	animate(src, pixel_x = cached_pixel_x, time = 0.25 SECONDS)

/obj/machinery/ship_weapon/energy/beam/bsa/animate_projectile(atom/target)
	var/turf/point = get_front_turf()
	var/turf/turf_target = null
	//Get the target turf that we fire the beam at...
	switch(src.dir)
		if(EAST)
			turf_target = get_turf(locate(world.maxx, y, z))
		if(WEST)
			turf_target = get_turf(locate(1, y, z))
	if(!turf_target)
		message_admins("Invalid dir setting on [src]. It only fires EAST / WEST. Please remedy this.")
		return FALSE
	var/atom/movable/blocker
	for(var/T in getline(get_step(point, dir), turf_target))
		var/turf/tile = T
		if(tile.density || SEND_SIGNAL(tile, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
			blocker = tile
		else
			for(var/atom/movable/AM in tile)
				if(AM == src)
					continue
				if(isliving(AM))
					var/mob/living/L = AM
					L.gib()
					continue
				if(AM.density || SEND_SIGNAL(AM, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
					blocker = AM
					break
		if(blocker)
			turf_target = tile
			break
	kickback()
	point.Beam(turf_target, icon_state = "bsa_beam", time = 50, maxdistance = world.maxx) //ZZZAP
	new /obj/effect/temp_visual/bsa_splash(point, dir)
	//Recharging...
	linked.relay_to_nearby(weapon_type.overmap_select_sound)
	if(blocker) //We hit something on the ship
		var/turf/location = get_turf(blocker)
		var/admin_message = "The ship BSA has hit [blocker] at [ADMIN_VERBOSEJMP(location)]!"
		var/log_message = "The ship BSA has hit [blocker] at [AREACOORD(location)]!"
		var/firer = linked.pilot //Fired by the pilot
		if(!firer)
			firer = src
			admin_message += " BSA fired by [firer]!"
		else
			admin_message += " BSA fired by [ADMIN_LOOKUPFLW(firer)]!"
		if(istype(blocker, /obj/machinery/the_singularitygen)) //What did you do
			var/evilperson = get_mob_by_ckey(blocker.fingerprintslast)
			GLOB.bombers += evilperson
			admin_message += " [blocker] was last touched by [ADMIN_LOOKUPFLW(evilperson)]!"
			log_message += " [blocker] was last touched by [key_name_admin(evilperson)]!"
			new /obj/anomaly/singularity(location, 2500)
			var/turf/overmaplocation = get_turf(linked)
			if(overmaplocation)
				new /obj/effect/overmap_anomaly/singularity(overmaplocation, linked.current_system)
		message_admins(admin_message)
		log_game(log_message)
		explosion(blocker, GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE, GLOB.MAX_EX_FLASH_RANGE)
	else
		. = ..() //Then actually fire it.

/obj/item/projectile/beam/laser/heavylaser/bsa
	name = "bluespace artillery beam"
	damage = 1000
	flag = "overmap_heavy"
	hitscan = TRUE //Obscenely powerful
	icon_state = "omnilaser"
	light_color = LIGHT_COLOR_BLUE
	impact_effect_type = /obj/effect/temp_visual/nuke_impact
	tracer_type = /obj/effect/projectile/tracer/bsa
	muzzle_type = /obj/effect/projectile/muzzle/bsa
	impact_type = /obj/effect/projectile/impact/bsa
	movement_type = FLYING
	projectile_piercing = ALL
	relay_projectile_type = /obj/item/projectile/beam/laser/heavylaser/bsa/relayed

/obj/effect/projectile/muzzle/bsa
	alpha = 0

/obj/effect/projectile/tracer/bsa
	name = "bsa"
	icon_state = "bsa_beam"

/obj/effect/projectile/impact/bsa
	name = "bsa"
	icon_state = "bsa_impact"

/obj/item/projectile/beam/laser/heavylaser/bsa/relayed
	projectile_piercing = PASSGLASS|PASSGRILLE|PASSTABLE

/obj/item/projectile/beam/laser/heavylaser/bsa/relayed/on_hit(atom/target, blocked)
	. = ..()
	if(isliving(target))
		var/mob/living/goodbye = target
		goodbye.dust(TRUE, FALSE)
	explosion(get_turf(target), 6, 8, 9, 12, ignorecap = TRUE, flame_range = 6) //I have to keep myself from letting it just truncate ships because thats a bit annoying to fix for the receiving side, even if accurate to appearance.


/obj/machinery/ship_weapon/energy/beam/bsa/after_fire()  //NT gets to cheat and have no degadation or heating on their weapon because muni has enough to do and the BSA doesn't need buffs/nerfs
	. = ..()
	heat = 0
	alignment = 100
	freq = 100
