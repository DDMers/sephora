/obj/machinery/ship_weapon/broadside
	name = "\improper SN 'Sucker Punch' Broadside Cannon"
	icon = 'nsv13/icons/obj/broadside.dmi'
	icon_state = "broadside"
	desc = "Line 'em up, knock 'em down."
	anchored = TRUE

	density = TRUE
	safety = FALSE

	bound_width = 64
	bound_height = 128
	ammo_type = /obj/item/ship_weapon/ammunition/broadside_shell
	circuit = /obj/item/circuitboard/machine/broadside

	fire_mode = FIRE_MODE_BROADSIDE

	auto_load = TRUE
	semi_auto = TRUE
	maintainable = FALSE
	max_ammo = 5
	feeding_sound = 'nsv13/sound/effects/ship/freespace2/m_load.wav'
	fed_sound = null
	chamber_sound = null
	broadside = TRUE

	load_delay = 20
	unload_delay = 20
	fire_animation_length = 2 SECONDS

	feed_delay = 0
	chamber_delay_rapid = 0
	chamber_delay = 0
	bang = TRUE
	bang_range = 5
	var/next_sound = 0

/obj/machinery/ship_weapon/broadside/north
	dir = NORTH

/obj/item/circuitboard/machine/broadside
	name = "circuit board (broadside)"
	desc = "Man the cannons!"
	req_components = list(
		/obj/item/stack/sheet/mineral/titanium = 20,
		/obj/item/stack/sheet/iron = 50,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/capacitor = 2,
		/obj/item/stock_parts/matter_bin = 6,
		/obj/item/ship_weapon/parts/firing_electronics = 1
	)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	build_path = /obj/machinery/ship_weapon/broadside

/obj/item/circuitboard/machine/broadside/Initialize(mapload)
	. = ..()
	GLOB.critical_muni_items += src

/obj/item/circuitboard/machine/broadside/Destroy(force=FALSE)
	if(!force)
		return QDEL_HINT_LETMELIVE
	GLOB.critical_muni_items -= src
	return ..()

/datum/ship_weapon/broadside
	name = "SNBC"
	burst_size = 5
	fire_delay = 5 SECONDS
	range_modifier = 10
	default_projectile_type = /obj/item/projectile/bullet/broadside
	select_alert = "<span class='notice'>Locking Broadside Cannons...</span>"
	failure_alert = "<span class='warning'>DANGER: No Shells Loaded In Broadside Cannons!</span>"
	overmap_firing_sounds = list('nsv13/sound/effects/ship/broadside.ogg')
	overmap_select_sound = 'nsv13/sound/effects/ship/mac_load_unjam.ogg'
	weapon_class = WEAPON_CLASS_HEAVY
	miss_chance = 10
	max_miss_distance = 6
	ai_fire_delay = 10 SECONDS
	allowed_roles = OVERMAP_USER_ROLE_GUNNER
	screen_shake = 10

/obj/machinery/ship_weapon/broadside/animate_projectile(atom/target, lateral=TRUE)
	var/obj/item/ship_weapon/ammunition/broadside_shell/T = chambered
	if(T)
		linked.fire_projectile(T.projectile_type, target, FALSE, null, null, TRUE, null, 5, 5, TRUE)

/obj/machinery/ship_weapon/broadside/examine()
	. = ..()
	switch(maint_state)
		if(MSTATE_CLOSED)
			pop(.)
		if(MSTATE_UNSCREWED)
			pop(.)
		if(MSTATE_UNBOLTED)
			pop(.)
	if(panel_open)
		. += "The maintenance panel is <b>unscrewed</b> and the machinery could be <i>pried out</i>. You could flip the cannon by rotating the <u>bolts</u>. You can disengage the shell locks <b>electronically</b>."
	else
		. += "The maintenance panel is <b>closed</b> and could be <i>screwed open</i>."
	. += "<span class ='notice'>It has [get_ammo()]/[max_ammo] shells loaded.</span>"

/obj/machinery/ship_weapon/broadside/screwdriver_act(mob/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "broadside_open", "broadside", tool)

/obj/machinery/ship_weapon/broadside/wrench_act(mob/user, obj/item/tool)
	if(panel_open)
		tool.play_tool_sound(src, 50)
		switch(dir)
			if(NORTH)
				setDir(SOUTH)
				to_chat(user, "<span class='notice'>You rotate the bolts, swiveling the cannon to Port</span>")
			if(SOUTH)
				setDir(NORTH)
				to_chat(user, "<span class='notice'>You rotate the bolts, swiveling the cannon to Starboard</span>")
		return TRUE

/obj/machinery/ship_weapon/broadside/crowbar_act(mob/user, obj/item/tool)
	if(panel_open)
		tool.play_tool_sound(src, 50)
		deconstruct(TRUE)
		return TRUE
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/ship_weapon/broadside/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(RefreshParts)), world.tick_lag)

/obj/machinery/ship_weapon/broadside/overmap_fire(atom/target)
	if(world.time >= next_sound) //Prevents ear destruction from soundspam
		overmap_sound()
		next_sound = world.time + 1 SECONDS
	if(overlay)
		overlay.do_animation()
	animate_projectile(target)

/obj/machinery/ship_weapon/broadside/fire(atom/target, shots = weapon_type.burst_size, manual = TRUE)
	. = ..()
	if(.)
		new /obj/effect/particle_effect/muzzleflash(loc)

/obj/machinery/ship_weapon/broadside/local_fire(shots = weapon_type.burst_size, atom/target) //For the broadside cannons, we want to eject spent casings
	var/obj/R = new /obj/item/ship_weapon/parts/broadside_casing(get_ranged_target_turf(src, NORTH, 4)) //Right
	var/obj/L = new /obj/item/ship_weapon/parts/broadside_casing(get_ranged_target_turf(src, SOUTH, 1)) //Left
	var/turf/S = get_offset_target_turf(src, rand(5)-rand(5), 5+rand(5)) //Starboard
	var/turf/P = get_offset_target_turf(src, rand(5)-rand(5), 0-rand(5)) //Port
	if(dir == 2)
		R.throw_at(S, 12, 20)
	if(dir == 1)
		L.throw_at(P, 12, 20)
	..()

/obj/effect/particle_effect/muzzleflash //Flash Effect when the weapon fires
	name = "muzzleflash"
	light_range = 3
	light_power = 30
	light_color = LIGHT_COLOR_ORANGE
	light_flags = LIGHT_NO_LUMCOUNT
	light_system = STATIC_LIGHT

/obj/effect/particle_effect/muzzleflash/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/particle_effect/muzzleflash/LateInitialize()
	QDEL_IN(src, 3)

/obj/effect/particle_effect/muzzleflash/Destroy()
	return ..()
