/*
Woe betide ye who tread here.

Been a mess since 2018, we'll fix it someday (probably)
*/

/obj/structure/overmap/small_craft
	name = "Space Fighter"
	icon = 'nsv13/icons/overmap/nanotrasen/fighter.dmi'
	icon_state = "fighter"
	anchored = TRUE
	brakes = TRUE
	armor = list("melee" = 80, "bullet" = 50, "laser" = 80, "energy" = 50, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 80) //temp to stop easy destruction from small arms
	bound_width = 64 //Change this on a per ship basis
	bound_height = 64
	mass = MASS_TINY
	overmap_deletion_traits = DAMAGE_ALWAYS_DELETES
	deletion_teleports_occupants = TRUE
	sprite_size = 32
	damage_states = TRUE
	faction = "nanotrasen"
	max_integrity = 250 //Really really squishy!
	forward_maxthrust = 3.5
	backward_maxthrust = 3.5
	side_maxthrust = 4
	max_angular_acceleration = 180
	torpedoes = 0
	missiles = 0
	speed_limit = 7 //We want fighters to be way more maneuverable
	weapon_safety = TRUE //This happens wayy too much for my liking. Starts ON.
	pixel_w = -16
	pixel_z = -20
	var/flight_pixel_w = -30
	var/flight_pixel_z = -32
	pixel_collision_size_x = 32
	pixel_collision_size_y = 32 //Avoid center tile viewport jank
	req_one_access = list(ACCESS_COMBAT_PILOT)
	var/start_emagged = FALSE
	max_paints = 1 // Only one target per fighter
	var/max_passengers = 0 //Change this per fighter.
	//Component to handle the fighter's loadout, weapons, parts, the works.
	var/loadout_type = LOADOUT_DEFAULT_FIGHTER
	var/datum/component/ship_loadout/loadout = null
	var/obj/structure/fighter_launcher/mag_lock = null //Mag locked by a launch pad. Cheaper to use than locate()
	var/canopy_open = TRUE
	var/master_caution = FALSE //The big funny warning light on the dash.
	var/list/components = list() //What does this fighter start off with? Use this to set what engine tiers and whatever it gets.
	var/maintenance_mode = FALSE //Munitions level IDs can change this.
	var/dradis_type =/obj/machinery/computer/ship/dradis/internal
	autotarget = TRUE
	no_gun_cam = TRUE
	var/obj/machinery/computer/ship/navigation/starmap = null
	var/resize_factor = 1 //How far down should we scale when we fly onto the overmap?
	var/escape_pod_type = /obj/structure/overmap/small_craft/escapepod
	var/mutable_appearance/canopy
	var/random_name = TRUE
	overmap_verbs = list(.verb/toggle_brakes, .verb/toggle_inertia, .verb/toggle_safety, .verb/show_dradis, .verb/cycle_firemode, .verb/show_control_panel, .verb/change_name, .verb/countermeasure)
	var/busy = FALSE

/obj/structure/overmap/small_craft/Destroy()
	var/mob/last_pilot = pilot // Old pilot gets first shot
	for(var/mob/M as() in operators)
		stop_piloting(M, eject_mob=FALSE) // We'll handle kicking them out ourselves
	if(length(mobs_in_ship))
		var/obj/structure/overmap/small_craft/escapepod = null
		if(ispath(escape_pod_type))
			escapepod = create_escape_pod(escape_pod_type, last_pilot)
		if(!escapepod && deletion_teleports_occupants)
			var/list/copy_of_mobs_in_ship = mobs_in_ship.Copy() //Sometimes you really need to iterate on a list while it's getting modified
			for(var/mob/living/M in copy_of_mobs_in_ship)
				to_chat(M, "<span class='warning'>This ship is not equipped with an escape pod! Unable to eject.</span>")
				M.apply_damage(200)
				eject(M, force=TRUE)

	last_overmap?.overmaps_in_ship -= src
	return ..()

/obj/structure/overmap/small_craft/start_piloting(mob/living/carbon/user, position)
	. = ..()
	if(.)
		RegisterSignal(src, COMSIG_MOB_OVERMAP_CHANGE, PROC_REF(pilot_overmap_change))

/obj/structure/overmap/small_craft/key_down(key, client/user)
	if(disruption && prob(min(95, disruption)))
		if(user)
			to_chat(user, "<span class='warning'>The controls buzz angrily!</span>")
		playsound(helm, 'sound/machines/buzz-sigh.ogg', 75, 1)
		return
	. = ..()

/obj/structure/overmap/small_craft/ui_state(mob/user)
	return GLOB.contained_state

/obj/structure/overmap/small_craft/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FighterControls")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/structure/overmap/small_craft/ui_data(mob/user)
	var/list/data = list()
	data["obj_integrity"] = obj_integrity
	data["max_integrity"] = max_integrity
	var/obj/item/fighter_component/armour_plating/A = loadout.get_slot(HARDPOINT_SLOT_ARMOUR)
	data["armour_integrity"] = (A) ? A.obj_integrity : 0
	data["max_armour_integrity"] = (A) ? A.max_integrity : 100

	var/obj/item/fighter_component/battery/B = loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	data["battery_charge"] = B ? B.charge : 0
	data["battery_max_charge"] = B ? B.maxcharge : 0
	data["brakes"] = brakes
	data["inertial_dampeners"] = inertial_dampeners
	data["mag_locked"] = (mag_lock) ? TRUE : FALSE
	data["canopy_lock"] = canopy_open
	data["weapon_safety"] = weapon_safety
	data["master_caution"] = master_caution
	data["rwr"] = length(enemies) ? TRUE : FALSE
	data["target_lock"] = length(target_painted) ? TRUE : FALSE
	data["fuel_warning"] = get_fuel() <= get_max_fuel()*0.4
	data["fuel"] = get_fuel()
	data["max_fuel"] = get_max_fuel()
	data["hardpoints"] = list()
	data["maintenance_mode"] = maintenance_mode //Todo
	var/obj/item/fighter_component/docking_computer/DC = loadout.get_slot(HARDPOINT_SLOT_DOCKING)
	data["docking_mode"] = DC && DC.docking_mode
	data["docking_cooldown"] = is_docking_on_cooldown()
	var/obj/item/fighter_component/countermeasure_dispenser/CD = loadout.get_slot(HARDPOINT_SLOT_COUNTERMEASURE)
	data["countermeasures"] = CD ? CD.charges : 0
	data["max_countermeasures"] = CD ? CD.max_charges : 0
	var/obj/item/fighter_component/primary/P = loadout.get_slot(HARDPOINT_SLOT_PRIMARY)
	data["primary_ammo"] = P ? P.get_ammo() : 0
	data["max_primary_ammo"] = P ? P.get_max_ammo() : 0
	var/obj/item/fighter_component/secondary/S = loadout.get_slot(HARDPOINT_SLOT_SECONDARY)
	data["secondary_ammo"] = S ? S.get_ammo() : 0
	data["max_secondary_ammo"] = S ? S.get_max_ammo() : 0

	var/obj/item/fighter_component/apu/APU = loadout.get_slot(HARDPOINT_SLOT_APU)
	data["fuel_pump"] = APU ? APU.fuel_line : FALSE

	var/obj/item/fighter_component/battery/battery = loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	data["battery"] = battery? battery.active : battery

	data["apu"] = APU.active
	var/obj/item/fighter_component/engine/engine = loadout.get_slot(HARDPOINT_SLOT_ENGINE)
	data["ignition"] = engine ? engine.active() : FALSE
	data["rpm"] = engine? engine.rpm : 0

	var/obj/item/fighter_component/ftl/ftl = loadout.get_slot(HARDPOINT_SLOT_FTL)
	if(ftl)
		data["ftl_capable"] = TRUE
		data["ftl_spool_progress"] = ftl.progress
		data["ftl_spool_time"] = ftl.spoolup_time
		data["jump_ready"] = ftl.progress >= ftl.spoolup_time
		data["ftl_active"] = ftl.active
		data["ftl_target"] = ftl.anchored_to?.name
	else
		data["ftl_capable"] = FALSE
		data["ftl_spool_progress"] = 0
		data["ftl_spool_time"] = 0
		data["jump_ready"] = FALSE
		data["ftl_active"] = FALSE
		data["ftl_target"] = FALSE

	for(var/slot in loadout.equippable_slots)
		var/obj/item/fighter_component/weapon = loadout.hardpoint_slots[slot]
		//Look for any "primary" hardpoints, be those guns or utility slots
		if(!weapon)
			continue
		if(weapon.fire_mode == FIRE_MODE_ANTI_AIR)
			data["primary_ammo"] = weapon.get_ammo()
			data["max_primary_ammo"] = weapon.get_max_ammo()
		if(weapon.fire_mode == FIRE_MODE_TORPEDO)
			data["secondary_ammo"] = weapon.get_ammo()
			data["max_secondary_ammo"] = weapon.get_max_ammo()
	var/list/hardpoints_info = list()
	var/list/occupants_info = list()
	for(var/obj/item/fighter_component/FC in contents)
		if(isliving(FC))
			var/mob/living/L = FC
			var/list/occupant_info = list()
			occupant_info["name"] = L.name
			occupant_info["id"] = "\ref[L]"
			occupant_info["afk"] = (L.mind) ? "Active" : "Inactive (SSD)"
			occupants_info[++occupants_info.len] = occupant_info
			continue
		if(!istype(FC))
			continue
		var/list/hardpoint_info = list()
		hardpoint_info["name"] = FC.name
		hardpoint_info["desc"] = FC.desc
		hardpoint_info["id"] = "\ref[FC]"
		hardpoints_info[++hardpoints_info.len] = hardpoint_info
	data["hardpoints"] = hardpoints_info
	data["occupants_info"] = occupants_info
	return data

/obj/structure/overmap/small_craft/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(. || ((usr != pilot) && (!IsAdminGhost(usr))))
		return
	if(disruption && prob(min(95, disruption)))
		to_chat(usr, "<span class='warning'>The controls buzz angrily!</span>")
		relay('sound/machines/buzz-sigh.ogg')
		return TRUE
	var/atom/movable/target = locate(params["id"])
	switch(action)
		if("examine")
			if(!target)
				return
			to_chat(usr, "<span class='notice'>[target.desc]</span>")
			. = TRUE
		if("eject_hardpoint")
			if(!target)
				return
			var/obj/item/fighter_component/FC = target
			if(!istype(FC))
				return
			to_chat(usr, "<span class='notice'>You start uninstalling [target.name] from [src].</span>")
			if(!do_after(usr, 5 SECONDS, target=src))
				return
			to_chat(usr, "<span class='notice>You uninstall [target.name] from [src].</span>")
			loadout.remove_hardpoint(FC, FALSE)
			. = TRUE
		if("dump_hardpoint")
			if(!target)
				return
			var/obj/item/fighter_component/FC = target
			if(!istype(FC) || !FC.contents?.len)
				return
			to_chat(usr, "<span class='notice'>You start to unload [target.name]'s stored contents...</span>")
			if(!do_after(usr, 5 SECONDS, target=src))
				return
			to_chat(usr, "<span class='notice>You dump [target.name]'s contents.</span>")
			loadout.dump_contents(FC)
			. = TRUE
		if("kick")
			if(!target)
				return
			if(!allowed(usr) || usr != pilot)
				return
			var/mob/living/L = target
			to_chat(L, "<span class='warning'>You have been kicked out of [src] by the pilot.</span>")
			canopy_open = FALSE
			toggle_canopy()
			stop_piloting(L)
			. = TRUE
		if("fuel_pump")
			var/obj/item/fighter_component/apu/APU = loadout.get_slot(HARDPOINT_SLOT_APU)
			if(!APU)
				to_chat(usr, "<span class='warning'>You can't send fuel to an APU that isn't installed.</span>")
				return
			var/obj/item/fighter_component/engine/engine = loadout.get_slot(HARDPOINT_SLOT_ENGINE)
			if(!engine)
				to_chat(usr, "<span class='warning'>[src] does not have an engine installed!</span>")
				return
			APU.toggle_fuel_line()
			playsound(src, 'nsv13/sound/effects/fighters/warmup.ogg', 100, FALSE)
			. = TRUE
		if("battery")
			var/obj/item/fighter_component/battery/battery = loadout.get_slot(HARDPOINT_SLOT_BATTERY)
			if(!battery)
				to_chat(usr, "<span class='warning'>[src] does not have a battery installed!</span>")
				return
			battery.toggle()
			to_chat(usr, "You flip the battery switch.</span>")
			. = TRUE
		if("apu")
			var/obj/item/fighter_component/apu/APU = loadout.get_slot(HARDPOINT_SLOT_APU)
			if(!APU)
				to_chat(usr, "<span class='warning'>[src] does not have an APU installed!</span>")
				return
			APU.toggle()
			playsound(src, 'nsv13/sound/effects/fighters/warmup.ogg', 100, FALSE)
			. = TRUE
		if("ignition")
			var/obj/item/fighter_component/engine/engine = loadout.get_slot(HARDPOINT_SLOT_ENGINE)
			if(!engine)
				to_chat(usr, "<span class='warning'>[src] does not have an engine installed!</span>")
				return
			engine.try_start()
			. = TRUE
		if("canopy_lock")
			var/obj/item/fighter_component/canopy/canopy = loadout.get_slot(HARDPOINT_SLOT_CANOPY)
			if(!canopy)
				return
			toggle_canopy()
			. = TRUE
		if("docking_mode")
			var/obj/item/fighter_component/docking_computer/DC = loadout.get_slot(HARDPOINT_SLOT_DOCKING)
			if(!DC || !istype(DC))
				to_chat(usr, "<span class='warning'>[src] does not have a docking computer installed!</span>")
				return
			to_chat(usr, "<span class='notice'>You [DC.docking_mode ? "disengage" : "engage"] [src]'s docking computer.</span>")
			DC.docking_mode = !DC.docking_mode
			relay('nsv13/sound/effects/fighters/switch.ogg')
			return TRUE
		if("brakes")
			toggle_brakes()
			relay('nsv13/sound/effects/fighters/switch.ogg')
			return TRUE
		if("inertial_dampeners")
			toggle_inertia()
			relay('nsv13/sound/effects/fighters/switch.ogg')
			return TRUE
		if("weapon_safety")
			toggle_safety()
			relay('nsv13/sound/effects/fighters/switch.ogg')
			return TRUE
		if("target_lock")
			relay('nsv13/sound/effects/fighters/switch.ogg')
			dump_locks()
			return TRUE
		if("mag_release")
			if(!mag_lock)
				return
			mag_lock.abort_launch()
			. = TRUE
		if("master_caution")
			set_master_caution(FALSE)
			return TRUE
		if("show_dradis")
			dradis?.ui_interact(usr)
			return TRUE
		if("toggle_ftl")
			var/obj/item/fighter_component/ftl/ftl = loadout.get_slot(HARDPOINT_SLOT_FTL)
			if(!ftl)
				to_chat(usr, "<span class='warning'>FTL unit not properly installed.</span>")
				return
			ftl.toggle()
			relay('nsv13/sound/effects/fighters/switch.ogg')
			. = TRUE
		if("anchor_ftl")
			var/obj/item/fighter_component/ftl/ftl = loadout.get_slot(HARDPOINT_SLOT_FTL)
			if(!ftl)
				to_chat(usr, "<span class='warning'>FTL unit not properly installed.</span>")
				return
			var/obj/structure/overmap/new_target = get_overmap()
			if(new_target)
				ftl.anchored_to = new_target
			else
				to_chat(usr, "<span class='warning'>Unable to update telemetry. Ensure you are in proximity to a Seegson FTL drive.</span>")
			relay('nsv13/sound/effects/fighters/switch.ogg')
			. = TRUE
		if("return_jump")
			var/obj/item/fighter_component/ftl/ftl = loadout.get_slot(HARDPOINT_SLOT_FTL)
			if(!ftl)
				return
			if(ftl.ftl_state != FTL_STATE_READY)
				to_chat(usr, "<span class='warning'>Unable to comply. FTL vector calculation still in progress.</span>")
				return
			if(!ftl.anchored_to)
				to_chat(usr, "<span class='warning'>Unable to comply. FTL tether lost.</span>")
				return
			var/datum/star_system/dest = SSstar_system.ships[ftl.anchored_to]["current_system"]
			if(!dest)
				to_chat(usr, "<span class='warning'>Unable to comply. Target beacon is currently in FTL transit.</span>")
				return
			ftl.jump(dest)
			return TRUE
		if("set_name")
			var/new_name = stripped_input(usr, message="What do you want to name \
				your fighter? Keep in mind that particularly terrible names may be \
				rejected by your employers.", max_length=MAX_CHARTER_LEN)
			if(!new_name || length(new_name) <= 0)
				return
			message_admins("[key_name_admin(usr)] renamed a fighter to [new_name] [ADMIN_LOOKUPFLW(src)].")
			name = new_name
			return TRUE
		if("toggle_maintenance")
			maintenance_mode = !maintenance_mode
			return TRUE

	relay('nsv13/sound/effects/fighters/switch.ogg')

// Bypass the z level checks done by parent
/obj/structure/overmap/small_craft/forceMove(atom/destination)
	return doMove(destination)

/obj/structure/overmap/small_craft/combat/light
	name = "Su-818 Rapier"
	desc = "An Su-818 Rapier space superiorty fighter craft. Designed for high maneuvreability and maximum combat effectiveness against other similar weight classes."
	icon = 'nsv13/icons/overmap/nanotrasen/fighter.dmi'
	armor = list("melee" = 60, "bullet" = 60, "laser" = 60, "energy" = 30, "bomb" = 30, "bio" = 100, "rad" = 90, "fire" = 90, "acid" = 80, "overmap_light" = 10, "overmap_medium" = 5, "overmap_heavy" = 90)
	sprite_size = 32
	damage_states = FALSE //temp
	max_integrity = 200 //Really really squishy!
	max_angular_acceleration = 200
	speed_limit = 10
	pixel_w = -16
	pixel_z = -20
	components = list(/obj/item/fighter_component/fuel_tank,
						/obj/item/fighter_component/avionics,
						/obj/item/fighter_component/apu,
						/obj/item/fighter_component/armour_plating,
						/obj/item/fighter_component/targeting_sensor,
						/obj/item/fighter_component/engine,
						/obj/item/fighter_component/countermeasure_dispenser,
						/obj/item/fighter_component/secondary/ordnance_launcher,
						/obj/item/fighter_component/oxygenator,
						/obj/item/fighter_component/canopy,
						/obj/item/fighter_component/docking_computer,
						/obj/item/fighter_component/battery,
						/obj/item/fighter_component/primary/cannon)

/obj/structure/overmap/small_craft/combat/solgov
	name = "Peregrine class attack fighter"
	desc = "A Peregrine class attack fighter, solgov's only premiere fighter, mounting minature capital grade phasers and a tiny shield generator."
	icon = 'nsv13/icons/overmap/new/solgov/playablefighter.dmi'
	armor = list("melee" = 60, "bullet" = 60, "laser" = 60, "energy" = 30, "bomb" = 30, "bio" = 100, "rad" = 90, "fire" = 90, "acid" = 80, "overmap_light" = 5, "overmap_medium" = 0, "overmap_heavy" = 10)
	sprite_size = 32
	damage_states = FALSE //temp
	max_integrity = 25 //shields.
	max_angular_acceleration = 200
	speed_limit = 10
	pixel_w = -16
	pixel_z = -20
	components = list(/obj/item/fighter_component/fuel_tank,
						/obj/item/fighter_component/avionics,
						/obj/item/fighter_component/apu,
						/obj/item/fighter_component/targeting_sensor,
						/obj/item/fighter_component/engine,
						/obj/item/fighter_component/countermeasure_dispenser,
						/obj/item/fighter_component/oxygenator,
						/obj/item/fighter_component/canopy,
						/obj/item/fighter_component/docking_computer,
						/obj/item/fighter_component/battery,
						/obj/item/fighter_component/primary/laser)   // no armor because >=3, you can still install it though because this thing is made of tissue paper

/obj/structure/overmap/small_craft/combat/solgov/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/overmap_shields, 125, 125, 15) //inital integrity, max integrity, and recharge rate. bound to change most likely


/obj/structure/overmap/small_craft/escapepod
	name = "Escape Pod"
	desc = "An escape pod launched from a space faring vessel. It only has very limited thrusters and is thus very slow."
	icon = 'nsv13/icons/overmap/nanotrasen/escape_pod.dmi'
	icon_state = "escape_pod"
	damage_states = FALSE
	bound_width = 32 //Change this on a per ship basis
	bound_height = 32
	pixel_z = 0
	pixel_w = 0
	max_integrity = 500 //Able to withstand more punishment so that people inside it don't get yeeted as hard
	canopy_open = FALSE
	essential = TRUE
	escape_pod_type = null // This would just be silly
	speed_limit = 2 //This, for reference, will feel suuuuper slow, but this is intentional
	loadout_type = LOADOUT_UTILITY_ONLY
	components = list(/obj/item/fighter_component/fuel_tank,
						/obj/item/fighter_component/avionics,
						/obj/item/fighter_component/apu,
						/obj/item/fighter_component/armour_plating,
						/obj/item/fighter_component/targeting_sensor,
						/obj/item/fighter_component/engine,
						/obj/item/fighter_component/oxygenator,
						/obj/item/fighter_component/canopy,
						/obj/item/fighter_component/docking_computer,
						/obj/item/fighter_component/battery,
						/obj/item/fighter_component/countermeasure_dispenser)

/obj/structure/overmap/small_craft/escapepod/stop_piloting(mob/living/M, eject_mob=TRUE, force=FALSE)
	if(!force && !SSmapping.level_trait(z, ZTRAIT_BOARDABLE))
		return FALSE
	return ..()

/obj/structure/overmap/small_craft/combat/heavy
	name = "Su-410 Scimitar"
	desc = "An Su-410 Scimitar heavy attack craft. It's a lot beefier than its Rapier cousin and is designed to take out capital ships, due to the weight of its modules however, it is extremely slow."
	icon = 'nsv13/icons/overmap/nanotrasen/heavy_fighter.dmi'
	icon_state = "heavy_fighter"
	armor = list("melee" = 80, "bullet" = 80, "laser" = 80, "energy" = 50, "bomb" = 50, "bio" = 100, "rad" = 90, "fire" = 90, "acid" = 80, "overmap_light" = 25, "overmap_medium" = 20, "overmap_heavy" = 90)
	sprite_size = 32
	damage_states = FALSE //TEMP
	max_integrity = 300 //Not so squishy!
	pixel_w = -16
	pixel_z = -20
	speed_limit = 8
	forward_maxthrust = 8
	backward_maxthrust = 8
	side_maxthrust = 7.75
	max_angular_acceleration = 80
	components = list(/obj/item/fighter_component/fuel_tank,
						/obj/item/fighter_component/avionics,
						/obj/item/fighter_component/apu,
						/obj/item/fighter_component/armour_plating,
						/obj/item/fighter_component/targeting_sensor,
						/obj/item/fighter_component/engine,
						/obj/item/fighter_component/countermeasure_dispenser,
						/obj/item/fighter_component/oxygenator,
						/obj/item/fighter_component/canopy,
						/obj/item/fighter_component/docking_computer,
						/obj/item/fighter_component/secondary/ordnance_launcher/torpedo,
						/obj/item/fighter_component/battery,
						/obj/item/fighter_component/primary/cannon/heavy)

//Syndie counterparts.
/obj/structure/overmap/small_craft/combat/light/syndicate //PVP MODE
	name = "Syndicate Light Fighter"
	desc = "The Syndicate's answer to Nanotrasen's light fighter craft, this fighter is designed to maintain aerial supremacy."
	icon = 'nsv13/icons/overmap/syndicate/syn_rapier.dmi'
	req_one_access = ACCESS_SYNDICATE
	faction = "syndicate"
	start_emagged = TRUE

/obj/structure/overmap/small_craft/Initialize(mapload, list/build_components=components)
	. = ..()
	if(random_name)
		name = generate_fighter_name()
	apply_weapons()
	loadout = AddComponent(loadout_type)
	if(dradis_type)
		dradis = new dradis_type(src) //Fighters need a way to find their way home.
		dradis.linked = src
	set_light(4)
	var/obj/structure/overmap/OM = loc.get_overmap()
	if(OM) //Actually register that we are inside the ship when spawned
		OM.overmaps_in_ship |= src
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(handle_moved)) //Used to smoothly transition from ship to overmap
	var/obj/item/fighter_component/engine/engineGoesLast = null
	if(build_components.len)
		for(var/Ctype in build_components)
			var/obj/item/fighter_component/FC = new Ctype(get_turf(src), mapload)
			if(istype(FC, /obj/item/fighter_component/engine))
				engineGoesLast = FC
				continue
			loadout.install_hardpoint(FC)
	//Engines need to be the last thing that gets installed on init, or it'll cause bugs with drag.
	if(engineGoesLast)
		loadout.install_hardpoint(engineGoesLast)
	obj_integrity = max_integrity //Update our health to reflect how much armour we've been given.
	set_fuel(rand(500, 1000))
	if(start_emagged)
		obj_flags ^= EMAGGED
	canopy = mutable_appearance(icon = icon, icon_state = "canopy_open")
	add_overlay(canopy)
	update_visuals()


/obj/structure/overmap/small_craft/attackby(obj/item/W, mob/user, params)
	if(operators && LAZYFIND(operators, user))
		to_chat(user, "<span class='warning'>You can't reach [src]'s exterior from in here.</span>")
		return FALSE
	for(var/slot in loadout.equippable_slots)
		var/obj/item/fighter_component/FC = loadout.get_slot(slot)
		if(FC?.load(src, W))
			return FALSE
	if(istype(W, /obj/item/fighter_component))
		var/obj/item/fighter_component/FC = W
		loadout.install_hardpoint(FC)
		return FALSE
	..()

/obj/structure/overmap/small_craft/MouseDrop_T(atom/movable/target, mob/user)
	. = ..()
	if(!isliving(user))
		return FALSE
	if(isobj(target))
		if(operators && LAZYFIND(operators, user))
			to_chat(user, "<span class='warning'>You can't reach [src]'s exterior from in here..</span>")
			return FALSE
		for(var/slot in loadout.equippable_slots)
			var/obj/item/fighter_component/FC = loadout.get_slot(slot)
			if(FC?.load(src, target))
				return FALSE
	else if(isliving(target))
		if(allowed(user))
			if(!canopy_open)
				playsound(src, 'sound/effects/glasshit.ogg', 75, 1)
				user.visible_message("<span class='warning'>You bang on the canopy.</span>", "<span class='warning'>[user] bangs on [src]'s canopy.</span>")
				return FALSE
			if(operators.len >= max_passengers)
				to_chat(user, "<span class='warning'>[src]'s passenger compartment is full!")
				return FALSE
			to_chat(target, "[(user == target) ? "You start to climb into [src]'s passenger compartment" : "[user] starts to lift you into [src]'s passenger compartment"]")
			if(do_after(user, 2 SECONDS, target=src))
				start_piloting(user, OVERMAP_USER_ROLE_OBSERVER)
				enter(user)
		else
			to_chat(user, "<span class='warning'>Access denied.</span>")

/obj/structure/overmap/small_craft/finish_lockon(obj/structure/overmap/target, data_link)
	if(disruption)
		to_chat(pilot, "<span class='warning'>ERROR: TGP NOT READY.</span>")
		return FALSE
	. = ..()

/obj/structure/overmap/small_craft/proc/enter(mob/user)
	var/obj/structure/overmap/OM = user.get_overmap()
	if(OM)
		OM.mobs_in_ship -= user
	user.forceMove(src)
	mobs_in_ship |= user
	user.last_overmap = src //Allows update_overmap to function properly when the pilot leaves their fighter
	if((user.client?.prefs.toggles & PREFTOGGLE_SOUND_AMBIENCE) && user.can_hear_ambience() && engines_active()) //Disable ambient sounds to shut up the noises.
		SEND_SOUND(user, sound('nsv13/sound/effects/fighters/cockpit.ogg', repeat = TRUE, wait = 0, volume = 50, channel=CHANNEL_SHIP_ALERT))

/obj/structure/overmap/small_craft/stop_piloting(mob/living/M, eject_mob=TRUE, force=FALSE)
	if(eject_mob && !eject(M, force))
		return FALSE
	UnregisterSignal(src, COMSIG_MOB_OVERMAP_CHANGE)
	M.stop_sound_channel(CHANNEL_SHIP_ALERT)
	M.remove_verb(overmap_verbs)
	return ..()

/obj/structure/overmap/small_craft/proc/eject(mob/living/M, force=FALSE)
	var/obj/item/fighter_component/canopy/C = loadout.get_slot(HARDPOINT_SLOT_CANOPY)
	if(!canopy_open && C && !force)
		to_chat(M, "<span class='warning'>[src]'s canopy isn't open.</span>")
		if(prob(50))
			playsound(src, 'sound/effects/glasshit.ogg', 75, 1)
			to_chat(M, "<span class='warning'>You bump your head on [src]'s canopy.</span>")
			visible_message("<span class='warning'>You hear a muffled thud.</span>")
		return FALSE

	if(!force && !SSmapping.level_trait(z, ZTRAIT_BOARDABLE) && !SSmapping.level_trait(z, ZTRAIT_RESERVED))
		to_chat(M, "<span class='warning'>[src] won't let you jump out of it mid flight.</span>")
		return FALSE

	SEND_SOUND(M, sound(null))
	mobs_in_ship -= M
	M.forceMove(get_turf(src))
	return TRUE

/obj/structure/overmap/small_craft/proc/pilot_overmap_change(mob/living/M, obj/structure/overmap/newOM) // in case we get forceMoved outside of the ship somehow
	SIGNAL_HANDLER
	if(newOM != src)
		INVOKE_ASYNC(src, PROC_REF(stop_piloting), M, FALSE, TRUE)

/obj/structure/overmap/small_craft/escapepod/eject(mob/living/M, force=FALSE)
	. = ..()
	if(. && !length(mobs_in_ship) && !(QDELETED(src) || QDESTROYING(src))) // Last one out means we don't need this anymore
		qdel(src)

/obj/structure/overmap/small_craft/proc/create_escape_pod(path, mob/last_pilot)
	// Create pod
	var/obj/structure/overmap/small_craft/escapepod/escape_pod = new path(get_turf(src))
	if(!istype(escape_pod))
		qdel(escape_pod)
		return
	escape_pod.name = "[name] - escape pod"
	escape_pod.faction = faction
	escape_pod.last_overmap = last_overmap
	escape_pod.current_system = current_system
	current_system.system_contents += escape_pod
	escape_pod.desired_angle = 0
	escape_pod.user_thrust_dir = NORTH
	var/obj/item/fighter_component/docking_computer/DC = escape_pod.loadout.get_slot(HARDPOINT_SLOT_DOCKING)
	DC.docking_mode = TRUE
	relay_to_nearby('nsv13/sound/effects/ship/fighter_launch_short.ogg')

	// Transfer occupants
	if(length(mobs_in_ship))
		relay('nsv13/sound/effects/computer/alarm_3.ogg', "<span class=userdanger>EJECT! EJECT! EJECT!</span>")
		visible_message("<span class=userdanger>Auto-Ejection Sequence Enabled! Escape Pod Launched!</span>")

		if(last_pilot && !last_pilot.incapacitated())
			last_pilot.doMove(escape_pod)
			escape_pod.start_piloting(last_pilot, OVERMAP_USER_ROLE_PILOT)
			escape_pod.attack_hand(last_pilot) // Bring up UI
			mobs_in_ship -= last_pilot
			escape_pod.mobs_in_ship |= last_pilot
			last_pilot.overmap_ship = escape_pod

		for(var/mob/M as() in mobs_in_ship)
			M.doMove(escape_pod)
			if(!escape_pod.pilot || escape_pod.pilot.incapacitated()) // Someone please drive this thing
				escape_pod.start_piloting(M, OVERMAP_USER_ROLE_PILOT)
				escape_pod.ui_interact(M)
			else
				escape_pod.start_piloting(M, OVERMAP_USER_ROLE_OBSERVER)
			escape_pod.mobs_in_ship |= M
			M.overmap_ship = escape_pod
	mobs_in_ship.Cut()

	return escape_pod

/obj/structure/overmap/small_craft/attack_hand(mob/user)
	. = ..()
	if(allowed(user))
		if(pilot)
			to_chat(user, "<span class='notice'>[src] already has a pilot.</span>")
			return FALSE
		if(do_after(user, 2 SECONDS, target=src))
			enter(user)
			start_piloting(user, (OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER))
			to_chat(user, "<span class='notice'>You climb into [src]'s cockpit.</span>")
			ui_interact(user)
			to_chat(user, "<span class='notice'>Small craft use directional keys (WASD in hotkey mode) to accelerate/decelerate in a given direction and the mouse to change the direction of craft.\
						Mouse 1 will fire the selected weapon (if applicable).</span>")
			to_chat(user, "<span class='warning'>=Hotkeys=</span>")
			to_chat(user, "<span class='notice'>Use <b>tab</b> to activate hotkey mode, then:</span>")
			to_chat(user, "<span class='notice'>Use the <b> Ctrl + Scroll Wheel</b> to zoom in / out. \
						Press <b>Space</b> to cycle fire modes. \
						Press <b>X</b> to cycle inertial dampners. \
						Press <b>Alt<b> to cycle the handbrake. \
						Press <b>C<b> to cycle mouse free movement.</span>")
			return TRUE

/obj/structure/overmap/small_craft/proc/force_eject(force = FALSE)
	. = list()
	brakes = TRUE
	if(!canopy_open)
		canopy_open = TRUE
		playsound(src, 'nsv13/sound/effects/fighters/canopy.ogg', 100, 1)
	for(var/mob/M in mobs_in_ship)
		stop_piloting(M, TRUE, force)
		M.forceMove(get_turf(src))
		to_chat(M, "<span class='warning'>You have been remotely ejected from [src]!.</span>")
		. += M

//Iconic proc.
/obj/structure/overmap/small_craft/proc/foo()
	set_fuel(1000)
	var/obj/item/fighter_component/apu/APU = loadout.get_slot(HARDPOINT_SLOT_APU)
	APU.fuel_line = TRUE
	var/obj/item/fighter_component/battery/B = loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	B.active = TRUE
	B.charge = B.maxcharge
	var/obj/item/fighter_component/engine/E = loadout.get_slot(HARDPOINT_SLOT_ENGINE)
	E.rpm = ENGINE_RPM_SPUN
	E.try_start()
	toggle_canopy()
	forceMove(locate(250, y, z))
	//check_overmap_elegibility(TRUE)

/obj/structure/overmap/small_craft/proc/throw_pilot(damage = 200) //Used when yeeting a pilot out of an exploding ship
	if(SSmapping.level_trait(z, ZTRAIT_OVERMAP)) //Check if we're on the overmap
		damage *= 2
	var/list/victims = force_eject(TRUE)
	for(var/mob/living/M as() in victims)
		M.apply_damage(damage)


/obj/structure/overmap/small_craft/attackby(obj/item/W, mob/user, params)   //fueling and changing equipment
	add_fingerprint(user)
	if(istype(W, /obj/item/card/id) || istype(W, /obj/item/modular_computer/tablet/pda) && length(operators))
		if(!allowed(user))
			var/ersound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
			playsound(src, ersound, 100, 1)
			to_chat(user, "<span class='warning'>Access denied</span>")
			return
		if(alert("What do you want to do?",name,"Eject Occupants","Maintenance Mode") == "Eject Occupants")
			if(!Adjacent(user))
				return
			to_chat(user, "<span class='warning'>Ejecting all current occupants from [src] and activating inertial dampeners...</span>")
			force_eject()
		else
			if(!Adjacent(user))
				return
			to_chat(user, "<span class='warning'>You swipe your card and [maintenance_mode ? "disable" : "enable"] maintenance protocols.</span>")
			maintenance_mode = !maintenance_mode

	if(istype(W, /obj/item/ship_weapon/ammunition/countermeasure_charge))
		var/obj/item/ship_weapon/ammunition/countermeasure_charge/CC = W
		var/obj/item/fighter_component/countermeasure_dispenser/CD = loadout.get_slot(HARDPOINT_SLOT_COUNTERMEASURE)
		if(CD)
			if(CD.charges == CD.max_charges)
				to_chat("<span class='warning'>You try to insert the countermeasure charge, but there's no space for more charges in the countermeasure dispenser!</span>")
			else
				var/ChargeChange = clamp(CC.restock_amount + CD.charges, CD.max_charges, 0) - CD.charges
				to_chat("<span>You successfully reload the countermeasure dispenser in [src]</span>")
				CC.restock_amount -= ChargeChange
				CD.charges += ChargeChange
				if(CC.restock_amount == 0)
					qdel(W)
		else
			to_chat("<span class='warning'>You try to insert the countermeasure charge, but there's nothing to put it in!</span>")
	return ..()


/obj/structure/overmap/small_craft/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, bypasses_shields = FALSE, nsv_damagesound = TRUE)
	var/obj/item/fighter_component/armour_plating/A = loadout.get_slot(HARDPOINT_SLOT_ARMOUR)
	if(A && istype(A))
		A.take_damage(damage_amount, damage_type, damage_flag, sound_effect)
		if(A.obj_integrity <= 0)
			loadout.remove_hardpoint(A, TRUE)
			qdel(A) //There goes your armour!
		relay(pick('nsv13/sound/effects/ship/freespace2/ding1.wav', 'nsv13/sound/effects/ship/freespace2/ding2.wav', 'nsv13/sound/effects/ship/freespace2/ding3.wav', 'nsv13/sound/effects/ship/freespace2/ding4.wav', 'nsv13/sound/effects/ship/freespace2/ding5.wav'))
	else
		. = ..()
	var/obj/item/fighter_component/canopy/C = loadout.get_slot(HARDPOINT_SLOT_CANOPY)
	if(!C) //Riding without a canopy is not without consequences
		if(prob(30)) //Ouch!
			for(var/mob/living/M in contents)
				to_chat(M , "<span class='warning'>You feel something hit you!</span>")
				M.take_overall_damage(damage_amount/2)
		return
	if(prob(50))
		relay('sound/effects/glasshit.ogg')
		C.take_damage(damage_amount/2, damage_type, damage_flag, sound_effect)
		if(C.obj_integrity <= 0)
			canopy_breach(C)

/obj/structure/overmap/small_craft/proc/canopy_breach(obj/item/fighter_component/canopy/C)
	set waitfor = FALSE
	relay('nsv13/sound/effects/ship/cockpit_breach.ogg') //We're leaking air!
	loadout.remove_hardpoint(HARDPOINT_SLOT_CANOPY, TRUE)
	qdel(C) //Pop off the canopy.
	update_visuals()
	sleep(2 SECONDS)
	relay('nsv13/sound/effects/ship/reactor/gasmask.ogg', "<span class='warning'>The air around you rushes out of the breached canopy!</span>", loop = FALSE, channel = CHANNEL_SHIP_ALERT)

/obj/structure/overmap/small_craft/welder_act(mob/living/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return FALSE
	if(obj_integrity >= max_integrity)
		to_chat(user, "<span class='notice'>[src] isn't in need of repairs.</span>")
		return TRUE
	if(busy)
		to_chat(user, "<span class='warning'>Someone's already repairing [src]!</span>")
		return TRUE
	busy = TRUE
	to_chat(user, "<span class='notice'>You start welding some dents out of [src]'s hull...</span>")
	while(obj_integrity < max_integrity)
		if(!I.use_tool(src, user, 1 SECONDS, volume=100))
			busy = FALSE
			return TRUE
		obj_integrity += 25
		if(obj_integrity >= max_integrity)
			obj_integrity = max_integrity
			break
	to_chat(user, "<span class='notice'>You finish welding[obj_integrity == max_integrity ? "" : " some of"] the dents out of [src]'s hull.</span>")
	busy = FALSE
	return TRUE

/obj/structure/overmap/small_craft/InterceptClickOn(mob/user, params, atom/target)
	if(user.incapacitated() || !isliving(user))
		return FALSE
	if(istype(target, /obj/machinery/button/door) || istype(target, /obj/machinery/turbolift_button))
		target.attack_hand(user)
		return FALSE
	if((target == src) && (user == pilot))
		helm?.ui_interact(user)
		return FALSE
	if((target == src) && (user == gunner))
		tactical?.ui_interact(user)
		return FALSE
	return ..()

/obj/structure/overmap/small_craft/can_friendly_fire()
	if(fire_mode == 1)
		var/obj/item/fighter_component/primary/P = loadout.get_slot(HARDPOINT_SLOT_UTILITY_PRIMARY)
		return (P && istype(P) && P.bypass_safety)
	else if(fire_mode == 2)
		var/obj/item/fighter_component/secondary/S = loadout.get_slot(HARDPOINT_SLOT_UTILITY_SECONDARY)
		return (S && istype(S) && S.bypass_safety)
	return FALSE

/obj/structure/overmap/small_craft/try_repair(amount)
	if(obj_integrity < max_integrity)
		..()
	else
		var/obj/item/fighter_component/armour_plating/armour = loadout.get_slot(HARDPOINT_SLOT_ARMOUR)
		armour.obj_integrity = CLAMP(armour.obj_integrity + amount, 0, armour.max_integrity)

/datum/component/ship_loadout
	can_transfer = FALSE
	var/list/equippable_slots = ALL_HARDPOINT_SLOTS //What slots does this loadout support? Want to allow a fighter to have multiple utility slots?
	var/list/hardpoint_slots = list()
	var/obj/structure/overmap/holder //To get overmap class vars.

/datum/component/ship_loadout/utility
	equippable_slots = HARDPOINT_SLOTS_UTILITY

/datum/component/ship_loadout/Initialize(source)
	. = ..()
	if(!istype(parent, /obj/structure/overmap))
		return COMPONENT_INCOMPATIBLE
	START_PROCESSING(SSobj, src)
	holder = parent
	for(var/hardpoint in equippable_slots)
		hardpoint_slots[hardpoint] = null

/datum/component/ship_loadout/proc/get_slot(slot)
	RETURN_TYPE(/obj/item/fighter_component)
	return hardpoint_slots[slot]

/datum/component/ship_loadout/proc/install_hardpoint(obj/item/fighter_component/replacement)
	var/slot = replacement.slot
	if(slot && !(slot in equippable_slots))
		replacement.visible_message("<span class='warning'>[replacement] can't fit onto [parent]")
		return FALSE
	remove_hardpoint(slot, FALSE)
	replacement.on_install(holder)
	if(slot) //Not every component has a slot per se, as some are just used for construction and can't really be interacted with.
		hardpoint_slots[slot] = replacement

/**
Method to remove a hardpoint from the loadout. It can be passed a slot as a defined flag, or slot as a physical hardpoint (as not all hardpoints have a specific slot.)
args:
slot: Either a slot or a specific component
due_to_damage: Was this called voluntarily (FALSE) or due to damage / external causes (TRUE). Is given to the remove_from() proc and modifies specifics of the removal.
*/
/datum/component/ship_loadout/proc/remove_hardpoint(slot, due_to_damage)
	if(!slot)
		return FALSE

	var/obj/item/fighter_component/component = null
	if(istype(slot, /obj/item/fighter_component))
		component = slot
		hardpoint_slots[component.slot] = null
	else
		component = get_slot(slot)
		hardpoint_slots[slot] = null

	if(component && istype(component))
		component.remove_from(holder, due_to_damage)

/datum/component/ship_loadout/proc/dump_contents(slot)
	var/obj/item/fighter_component/component = null
	if(istype(slot, /obj/item/fighter_component))
		component = slot
	else
		component = get_slot(slot)
	component.dump_contents()

/datum/component/ship_loadout/process(delta_time)
	for(var/slot in equippable_slots)
		var/obj/item/fighter_component/component = hardpoint_slots[slot]
		component?.process(delta_time)

/obj/item/fighter_component
	name = "fighter component"
	desc = "It doesn't really do a whole lot"
	icon = 'nsv13/icons/obj/fighter_components.dmi'
	w_class = WEIGHT_CLASS_GIGANTIC
	//Thanks to comxy on Discord for these lovely tiered sprites o7
	var/tier = 1 // used for multipliers
	var/slot = null //Change me!
	var/weight = 0 //Some more advanced modules will weigh your fighter down some.
	var/power_usage = 0 //Does this module require power to process()?
	var/fire_mode = null //Used if this is a weapon style hardpoint
	var/active = TRUE

/obj/item/fighter_component/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click it to unload its contents.</span>"

/obj/item/fighter_component/proc/toggle()
	active = !active

/obj/item/fighter_component/proc/dump_contents()
	if(!length(contents))
		return FALSE
	. = list()
	for(var/atom/movable/AM in contents)
		AM.forceMove(get_turf(loc))
		. += AM

/obj/item/fighter_component/proc/get_ammo()
	return FALSE

/obj/item/fighter_component/proc/get_max_ammo()
	return FALSE

/obj/item/fighter_component/Initialize(mapload)
	.=..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE) //These all require two hands to pick up

//Overload this method to apply stat benefits based on your module.
/obj/item/fighter_component/proc/on_install(obj/structure/overmap/target)
	forceMove(target)
	apply_drag(target)
	playsound(target, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)
	target.visible_message("<span class='notice'>[src] mounts onto [target]")
	return TRUE

//Allows you to jumpstart a fighter with an inducer.
/obj/structure/overmap/small_craft/get_cell()
	return loadout.get_slot(HARDPOINT_SLOT_BATTERY)

/obj/item/fighter_component/proc/power_tick(dt = 1)
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F) || !active)
		return FALSE
	var/obj/item/fighter_component/battery/B = F.loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	return B?.use_power(power_usage * dt)

/obj/item/fighter_component/process(delta_time)
	return power_tick(delta_time)

//Used for weapon style hardpoints
/obj/item/fighter_component/proc/fire(obj/structure/overmap/target)
	return FALSE

/*
If you need your hardpoint to be loaded with things by clicking the fighter
*/
/obj/item/fighter_component/proc/load(obj/structure/overmap/target, atom/movable/AM)
	return FALSE

/obj/item/fighter_component/proc/apply_drag(obj/structure/overmap/target)
	if(!weight)
		return FALSE
	target.speed_limit -= weight
	target.speed_limit = (target.speed_limit > 0) ? target.speed_limit : 0
	target.forward_maxthrust -= weight
	target.forward_maxthrust = (target.forward_maxthrust > 0) ? target.forward_maxthrust : 0
	target.backward_maxthrust -= weight
	target.backward_maxthrust = (target.backward_maxthrust > 0) ? target.backward_maxthrust : 0
	target.side_maxthrust -= 0.25*weight
	target.side_maxthrust = (target.side_maxthrust > 0) ? target.side_maxthrust : 0
	target.max_angular_acceleration -= weight*10
	target.max_angular_acceleration = (target.max_angular_acceleration > 0) ? target.max_angular_acceleration : 0

/*
Remove from(), a proc that forcemoves a component onto the target's tile and removes the weight penalties caused by the specific component. Usually used for removal, but doesn't actually check if it was on the target, use with care.
args:
target: The overmap structure getting the component's weight penalties removed, aswell as the component being moved to its tile.
due_to_damage: If the removal was caused voluntarily (FALSE), or if it was caused by external sources / damage (TRUE); generally influences some specifics of removal on some components.
*/
/obj/item/fighter_component/proc/remove_from(obj/structure/overmap/target, due_to_damage)
	forceMove(get_turf(target))
	if(!weight)
		return TRUE
	for(var/atom/movable/AM as() in contents)
		AM.forceMove(get_turf(target))
	target.speed_limit += weight
	target.forward_maxthrust += weight
	target.backward_maxthrust += weight
	target.side_maxthrust += 0.25 * weight
	target.max_angular_acceleration += weight*10
	return TRUE

/obj/item/fighter_component/armour_plating
	name = "durasteel armour plates"
	desc = "A set of armour plates which can afford basic protection to a fighter, however heavier plates may slow you down"
	icon_state = "armour_tier1"
	slot = HARDPOINT_SLOT_ARMOUR
	weight = 1
	obj_integrity = 250
	max_integrity = 250
	armor = list("melee" = 50, "bullet" = 40, "laser" = 80, "energy" = 50, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 80) //Armour's pretty tough.
	var/repair_speed = 25 // How much integrity you can repair per second
	var/busy = FALSE

//Sometimes you need to repair your physical armour plates.
/obj/item/fighter_component/armour_plating/welder_act(mob/living/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return FALSE
	if(obj_integrity >= max_integrity)
		to_chat(user, "<span class='notice'>[src] isn't in need of repairs.</span>")
		return TRUE
	if(busy)
		to_chat(user, "<span class='warning'>Someone's already repairing [src]!</span>")
		return TRUE
	busy = TRUE
	to_chat(user, "<span class='notice'>You start welding some dents out of [src]...</span>")
	while(obj_integrity < max_integrity)
		if(!I.use_tool(src, user, 1 SECONDS, volume=100))
			busy = FALSE
			return TRUE
		obj_integrity += 25
		if(obj_integrity >= max_integrity)
			obj_integrity = max_integrity
			break
	to_chat(user, "<span class='notice'>You finish welding[obj_integrity == max_integrity ? "" : " some of"] the dents out of [src].</span>")
	busy = FALSE

/obj/item/fighter_component/armour_plating/tier2
	name = "ultra heavy fighter armour"
	desc = "An extremely thick and heavy set of armour plates. Guaranteed to weigh you down, but it'll keep you flying through brasil itself."
	icon_state = "armour_tier2"
	tier = 2
	weight = 2
	obj_integrity = 450
	max_integrity = 450

/obj/item/fighter_component/armour_plating/tier3
	name = "nanocarbon armour plates"
	desc = "A lightweight set of ablative armour which balances speed and protection at the cost of the average GDP of most third world countries."
	icon_state = "armour_tier3"
	tier = 3
	weight = 1.25
	obj_integrity = 300
	max_integrity = 300

/obj/item/fighter_component/canopy
	name = "glass canopy"
	desc = "A fighter canopy made of standard glass, it's extremely fragile and is so cheaply produced that it serves as little less than a windshield."
	icon_state = "canopy_tier0.5"
	obj_integrity = 100 //Pretty fragile, don't break it you dumblet
	max_integrity = 100
	slot = HARDPOINT_SLOT_CANOPY
	weight = 0.25 //Real pilots just wear pilot goggles and strip out their canopy.
	tier = 0.5

/obj/item/fighter_component/canopy/reinforced
	name = "reinforced glass canopy"
	desc = "A glass fighter canopy that's designed to maintain atmospheric pressure inside of a fighter, this one's pretty robust."
	icon_state = "canopy_tier1"
	obj_integrity = 200
	max_integrity = 200
	tier = 1
	weight = 0.5

/obj/item/fighter_component/canopy/tier2
	name = "nanocarbon glass canopy"
	desc = "A glass fighter canopy that's designed to maintain atmospheric pressure inside of a fighter, this one's very robust."
	icon_state = "canopy_tier2"
	obj_integrity = 350
	max_integrity = 350
	tier = 2
	weight = 0.35

/obj/item/fighter_component/canopy/tier3
	name = "plasma glass canopy"
	desc = "A glass fighter canopy that's designed to maintain atmospheric pressure inside of a fighter, this one's exceptionally robust."
	icon_state = "canopy_tier3"
	obj_integrity = 450
	max_integrity = 450
	tier = 3
	weight = 0.55

/obj/item/fighter_component/battery
	name = "fighter battery"
	icon_state = "battery"
	slot = HARDPOINT_SLOT_BATTERY
	active = FALSE
	var/charge = 10000
	var/maxcharge = 10000
	var/self_charge = FALSE //TODO! Engine powers this.

/obj/item/fighter_component/battery/process()
	if(self_charge)
		give(1000)

/obj/item/fighter_component/battery/proc/give(amount)
	if(charge >= maxcharge)
		return FALSE
	charge += amount
	charge = CLAMP(charge, 0, maxcharge)

/obj/item/fighter_component/battery/proc/use_power(amount)
	if(!active)
		return FALSE
	charge -= amount
	charge = CLAMP(charge, 0, maxcharge)
	if(charge <= 0)
		var/obj/structure/overmap/small_craft/F = loc
		if(!istype(F))
			return FALSE
		if(active)
			F.set_master_caution(TRUE)
			active = FALSE
	return charge > 0

/obj/item/fighter_component/battery/tier2
	name = "upgraded fighter battery"
	icon_state = "battery_tier2"
	tier = 2
	charge = 20000
	maxcharge = 20000

/obj/item/fighter_component/battery/tier3
	name = "mega fighter battery"
	icon_state = "battery_tier3"
	desc = "An electrochemical cell capable of holding a good amount of charge for keeping the fighter's radio on for longer periods without an engine."
	tier = 3
	charge = 40000
	maxcharge = 40000

/obj/item/fighter_component/armour_plating/on_install(obj/structure/overmap/target)
	..()
	target.max_integrity = initial(target.max_integrity)*tier

/obj/item/fighter_component/armour_plating/remove_from(obj/structure/overmap/target, due_to_damage)
	..()
	if(due_to_damage)
		return //We don't reset our health if the plating was destroyed due to hits, or the increase would be useless. It DOES get reset once we install new armor, though.
	target.max_integrity = initial(target.max_integrity)
	//Remove any overheal.
	target.obj_integrity = CLAMP(target.obj_integrity, 0, target.max_integrity)

//Fuel
/obj/structure/overmap/small_craft/proc/get_fuel()
	var/obj/item/fighter_component/fuel_tank/ft = loadout.get_slot(HARDPOINT_SLOT_FUEL)
	var/datum/reagent/cryogenic_fuel/F = locate() in ft?.reagents.reagent_list
	return F ? F.volume : 0

/obj/structure/overmap/small_craft/proc/set_fuel(amount)
	var/obj/item/fighter_component/fuel_tank/ft = loadout.get_slot(HARDPOINT_SLOT_FUEL)
	if(!ft)
		return FALSE
	ft.reagents.add_reagent(/datum/reagent/cryogenic_fuel, amount, reagtemp = 40) //Assert that we have this reagent in the tank.
	for(var/datum/reagent/cryogenic_fuel/F in ft?.reagents.reagent_list)
		if(!istype(F))
			continue
		F.volume = amount
	return amount

/obj/structure/overmap/small_craft/proc/engines_active()
	var/obj/item/fighter_component/engine/E = loadout.get_slot(HARDPOINT_SLOT_ENGINE)//E's are good E's are good, he's ebeneezer goode.
	return E?.active() && get_fuel() > 0

/obj/structure/overmap/small_craft/proc/set_master_caution(state)
	var/master_caution_switch = state
	if(master_caution_switch)
		relay('nsv13/sound/effects/fighters/master_caution.ogg', null, loop=TRUE, channel=CHANNEL_HEARTBEAT)
		master_caution = TRUE
	else
		stop_relay(CHANNEL_HEARTBEAT) //CONSIDER MAKING OWN CHANNEL
		master_caution = FALSE

/obj/structure/overmap/small_craft/proc/use_fuel(force=FALSE)
	if(!engines_active() && !force) //No fuel? don't spam them with master cautions / use any fuel
		return FALSE
	var/fuel_consumption = 0.5*(loadout.get_slot(HARDPOINT_SLOT_ENGINE)?.tier)
	var/amount = (user_thrust_dir) ? fuel_consumption+0.25 : fuel_consumption //When you're thrusting : fuel consumption doubles. Idling is cheap.
	var/obj/item/fighter_component/fuel_tank/ft = loadout.get_slot(HARDPOINT_SLOT_FUEL)
	if(!ft)
		return FALSE
	ft.reagents.remove_reagent(/datum/reagent/cryogenic_fuel, amount)
	if(get_fuel() >= amount)
		return TRUE
	set_master_caution(TRUE)
	return FALSE

/obj/structure/overmap/small_craft/can_move()
	return engines_active()

/obj/structure/overmap/small_craft/escapepod/can_move()
	return TRUE

/obj/structure/overmap/small_craft/escapepod/engines_active()
	return TRUE

/obj/structure/overmap/small_craft/proc/empty_fuel_tank()//Debug purposes, for when you need to drain a fighter's tank entirely.
	var/obj/item/fighter_component/fuel_tank/ft = loadout.get_slot(HARDPOINT_SLOT_FUEL)
	ft?.reagents.clear_reagents()

/obj/structure/overmap/small_craft/proc/get_max_fuel()
	var/obj/item/fighter_component/fuel_tank/ft = loadout.get_slot(HARDPOINT_SLOT_FUEL)
	if(!ft)
		return 0
	return ft.reagents.maximum_volume

/obj/item/fighter_component/fuel_tank
	name = "Fighter Fuel Tank"
	desc = "The fuel tank of a fighter, upgrading this lets your fighter hold more fuel."
	icon_state = "fueltank_tier1"
	var/fuel_capacity = 1000
	slot = HARDPOINT_SLOT_FUEL

/obj/item/fighter_component/fuel_tank/Initialize(mapload)
	. = ..()
	create_reagents(fuel_capacity, DRAINABLE | AMOUNT_VISIBLE)
	reagents.chem_temp = 40

/obj/item/fighter_component/fuel_tank/tier2
	name = "fighter extended fuel tank"
	desc = "A larger fuel tank which allows fighters to stay in combat for much longer"
	icon_state = "fueltank_tier2"
	fuel_capacity = 2500
	tier = 2

/obj/item/fighter_component/fuel_tank/tier3
	name = "massive fighter fuel tank"
	desc = "A super extended capacity fuel tank, allowing fighters to stay in a warzone for hours on end."
	icon_state = "fueltank_tier3"
	fuel_capacity = 4000
	tier = 3

/obj/item/fighter_component/engine
	name = "fighter engine"
	desc = "A mighty engine capable of propelling small spacecraft to high speeds."
	icon_state = "engine_tier1"
	slot = HARDPOINT_SLOT_ENGINE
	active = FALSE
	var/rpm = 0
	var/flooded = FALSE

/obj/item/fighter_component/engine/examine(mob/user)
	. = ..()
	if(flooded)
		. += "<span class='notice'>You can hear liquid sloshing around inside.</span>"
		. += "<span class='notice'>The combustion chamber is <b>screwed<b> closed.</span>"

/obj/item/fighter_component/engine/flooded //made just so I can put it in pilot-specific mail
	desc = "A mighty engine capable of propelling small spacecraft to high speeds. Something doesn't seem right, though..."
	flooded = TRUE

/obj/item/fighter_component/engine/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(!flooded)
		return
	balloon_alert(user, "You start to purge [src] of its flooded fuel.")
	if(do_after(user, 10 SECONDS, target=src))
		balloon_alert(user, "You finish clearing the fuel out of [src].")
		flooded = FALSE
		shake_animation()

/obj/item/fighter_component/engine/proc/active()
	return (active && obj_integrity > 0 && rpm >= ENGINE_RPM_SPUN && !flooded)

/obj/item/fighter_component/engine/process()
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	var/obj/item/fighter_component/apu/APU = F.loadout.get_slot(HARDPOINT_SLOT_APU)
	if(!APU?.fuel_line && rpm > 0)
		rpm -= 1000 //Spool down the engine.
		if(rpm <= 0)
			playsound(loc, 'nsv13/sound/effects/ship/rcs.ogg', 100, TRUE)
			loc.visible_message("<span class='userdanger'>[src] fizzles out!</span>")
			rpm = 0
			F.stop_relay(CHANNEL_SHIP_ALERT)
			active = FALSE
			return FALSE
	if(rpm > 3000)
		var/obj/item/fighter_component/battery/B = F.loadout.get_slot(HARDPOINT_SLOT_BATTERY)
		B.give(500  *tier)
	if(!active())
		return FALSE

/obj/item/fighter_component/engine/proc/apu_spin(amount)
	if(flooded)
		loc.visible_message("<span class='warning'>[src] sputters uselessly.</span>")
		return
	rpm += amount
	rpm = CLAMP(rpm, 0, ENGINE_RPM_SPUN)

/obj/item/fighter_component/engine/proc/try_start()
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	if(rpm >= ENGINE_RPM_SPUN-200) //You get a small bit of leeway.
		active = TRUE
		rpm = ENGINE_RPM_SPUN
		playsound(loc, 'nsv13/sound/effects/fighters/startup.ogg', 100, FALSE)
		F.relay('nsv13/sound/effects/fighters/cockpit.ogg', "<span class='warning'>You hear a loud noise as [F]'s engine kicks in.</span>", loop=TRUE, channel = CHANNEL_SHIP_ALERT)
		return
	else
		playsound(loc, 'sound/machines/clockcult/steam_whoosh.ogg', 100, TRUE)
		loc.visible_message("<span class='warning'>[src] sputters slightly.</span>")
		if(prob(20)) //Don't try and start a not spun engine, flyboys.
			playsound(loc, 'nsv13/sound/effects/ship/rcs.ogg', 100, TRUE)
			loc.visible_message("<span class='userdanger'>[src] violently fizzles out!.</span>")
			F.set_master_caution(TRUE)
			rpm = 0
			flooded = TRUE
			active = FALSE

/obj/item/fighter_component/engine/tier2
	name = "souped up fighter engine"
	desc = "Born to zoom, forced to oom"
	icon_state = "engine_tier2"
	tier = 2

/obj/item/fighter_component/engine/tier3
	name = "\improper Boringheed Marty V12 Super Giga Turbofan Space Engine"
	desc = "An engine which allows a fighter to exceed the legal speed limit in most jurisdictions."
	icon_state = "engine_tier3"
	tier = 3

/obj/item/fighter_component/engine/on_install(obj/structure/overmap/small_craft/target)
	..()
	target.speed_limit = initial(target.speed_limit)*tier
	target.forward_maxthrust = initial(target.forward_maxthrust)*tier
	target.backward_maxthrust = initial(target.backward_maxthrust)*tier
	target.side_maxthrust = initial(target.side_maxthrust)*tier
	target.max_angular_acceleration = initial(target.max_angular_acceleration)*tier
	for(var/slot in target.loadout.equippable_slots)
		var/obj/item/fighter_component/FC = target.loadout.get_slot(slot)
		FC?.apply_drag(target)

/obj/item/fighter_component/engine/remove_from(obj/structure/overmap/target)
	..()
	//No engines? No movement.
	target.speed_limit = 0
	target.forward_maxthrust = 0
	target.backward_maxthrust = 0
	target.side_maxthrust = 0
	target.max_angular_acceleration = 0

//Atmos

/obj/item/fighter_component/oxygenator
	name = "atmospheric regulator"
	desc = "A device which moderates the conditions inside a fighter, it requires fuel to run."
	icon_state = "oxygenator_tier1"
	var/refill_amount = 1 //Starts off really terrible.
	slot = HARDPOINT_SLOT_OXYGENATOR
	weight = 0.5 //Wanna go REALLY FAST? Pack your own O2.
	power_usage = 200

/obj/item/fighter_component/oxygenator/tier2
	name = "upgraded atmospheric regulator"
	icon_state = "oxygenator_tier2"
	tier = 2
	refill_amount = 3
	power_usage = 300

/obj/item/fighter_component/oxygenator/tier3
	name = "super oxygenator"
	desc = "A finely tuned atmospheric regulator to be fitted into a fighter which seems to be able to almost magically create oxygen out of nowhere."
	icon_state = "oxygenator_tier3"
	tier = 3
	refill_amount = 10
	power_usage = 400

/obj/item/fighter_component/oxygenator/plasmaman
	name = "plasmaman atmospheric regulator"
	desc = "An atmospheric regulator to be used in fighters, it's been rigged to fill the cabin with a hospitable environment for plasmamen instead of standard oxygen."
	refill_amount = 3
	tier = 4 //unique! but it has to have a sprite to make it obvious that, yknow, this is for plasmemes.

/obj/item/fighter_component/oxygenator/process()
	//Don't waste power on already fine atmos.
	var/obj/structure/overmap/OM = loc
	if(!istype(OM))
		return FALSE
	if(!..())
		return FALSE
	if(OM.cabin_air.return_pressure()+refill_amount >= WARNING_HIGH_PRESSURE-(2*refill_amount))
		return FALSE //No need to add more air to an already pressurized environment

	//Oxygenator just makes sure you have atmosphere. It doesn't care where it comes from.
	OM.cabin_air.set_temperature(T20C)
	//Gives you a little bit of air.
	refill(OM)
	return TRUE

/obj/item/fighter_component/oxygenator/proc/refill(obj/structure/overmap/OM)
	OM.cabin_air.adjust_moles(GAS_O2, refill_amount*O2STANDARD)
	OM.cabin_air.adjust_moles(GAS_N2, refill_amount*N2STANDARD)
	OM.cabin_air.adjust_moles(GAS_CO2, -refill_amount)

/obj/item/fighter_component/oxygenator/plasmaman/refill(obj/structure/overmap/OM)
	OM.cabin_air.adjust_moles(GAS_PLASMA, refill_amount*N2STANDARD)
	OM.cabin_air.adjust_moles(GAS_O2, -refill_amount)
	OM.cabin_air.adjust_moles(GAS_N2, -refill_amount)

//Construction only components

/obj/item/fighter_component/avionics
	name = "fighter avionics"
	desc = "Avionics for a fighter"
	icon_state = "avionics"
	tier = null

/obj/item/fighter_component/apu
	name = "fighter auxiliary power unit"
	desc = "An Auxiliary Power Unit for a fighter"
	icon_state = "apu_tier1"
	slot = HARDPOINT_SLOT_APU
	active = FALSE
	var/fuel_line = FALSE
	var/next_process = 0

/obj/item/fighter_component/apu/tier2
	name = "upgraded fighter APU"
	icon_state = "apu_tier2"
	tier = 2

/obj/item/fighter_component/apu/tier3
	name = "super fighter APU"
	desc = "A small engine capable of rapidly starting a fighter."
	icon_state = "apu_tier3"
	tier = 3

/obj/item/fighter_component/apu/proc/toggle_fuel_line()
	fuel_line = !fuel_line

/obj/item/fighter_component/apu/process()
	if(!..())
		return
	if(world.time < next_process)
		return
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	next_process = world.time + 4 SECONDS
	if(!fuel_line)
		return //APU needs fuel to drink
	F.relay('nsv13/sound/effects/fighters/apu_loop.ogg')
	var/obj/item/fighter_component/engine/engine = F.loadout.get_slot(HARDPOINT_SLOT_ENGINE)
	F.use_fuel(2, TRUE) //APUs take fuel to run.
	if(engine.active())
		return
	engine.apu_spin(500*tier)


/obj/item/fighter_component/countermeasure_dispenser
	name = "fighter countermeasure dispenser"
	desc = "A device which allows a fighter to deploy countermeasures."
	icon_state = "countermeasure_tier1"
	slot = HARDPOINT_SLOT_COUNTERMEASURE
	var/max_charges = 3
	var/charges = 3

/obj/item/fighter_component/docking_computer
	name = "docking computer"
	desc = "A computer that allows fighters to easily dock to a ship"
	icon_state = "docking_computer"
	slot = HARDPOINT_SLOT_DOCKING
	tier = null //Not upgradable right now.
	var/docking_mode = FALSE
	var/docking_cooldown = FALSE

/*Weaponry!
As a rule of thumb, primaries are small guns that take ammo boxes, secondaries are big guns that require big bulky objects to be loaded into them.
Utility modules can be either one of these types, just ensure you set its slot to HARDPOINT_SLOT_UTILITY
*/
/obj/item/fighter_component/primary
	name = "\improper primary weapon"
	slot = HARDPOINT_SLOT_PRIMARY
	fire_mode = FIRE_MODE_ANTI_AIR
	var/overmap_select_sound = 'nsv13/sound/effects/ship/pdc_start.ogg'
	var/overmap_firing_sounds = list('nsv13/sound/effects/fighters/autocannon.ogg')
	var/accepted_ammo = /obj/item/ammo_box/magazine
	var/obj/item/ammo_box/magazine/magazine = null
	var/list/ammo = list()
	var/burst_size = 1
	var/fire_delay = 0
	var/allowed_roles = OVERMAP_USER_ROLE_GUNNER
	var/bypass_safety = FALSE

/obj/item/fighter_component/primary/dump_contents()
	. = ..()
	for(var/atom/movable/AM as() in .)
		if(AM == magazine)
			magazine = null
			ammo = list()
			playsound(loc, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)

/obj/item/fighter_component/primary/get_ammo()
	return length(ammo)

/obj/item/fighter_component/primary/get_max_ammo()
	return magazine ? magazine.max_ammo : 500 //Default.

//Ensure we get the genericised equipment mounts.
/obj/structure/overmap/small_craft/apply_weapons()
	if(!weapon_types[FIRE_MODE_ANTI_AIR])
		weapon_types[FIRE_MODE_ANTI_AIR] = new/datum/ship_weapon/fighter_primary(src)
	if(!weapon_types[FIRE_MODE_TORPEDO])
		weapon_types[FIRE_MODE_TORPEDO] = new/datum/ship_weapon/fighter_secondary(src)

//Burst arg currently unused for this proc.
/obj/structure/overmap/proc/primary_fire(obj/structure/overmap/target, ai_aim = FALSE, burst = 1)
	hardpoint_fire(target, FIRE_MODE_ANTI_AIR)

/obj/structure/overmap/proc/hardpoint_fire(obj/structure/overmap/target, fireMode)
	if(istype(src, /obj/structure/overmap/small_craft))
		var/obj/structure/overmap/small_craft/F = src
		for(var/slot in F.loadout.equippable_slots)
			var/obj/item/fighter_component/weapon = F.loadout.hardpoint_slots[slot]
			//Look for any "primary" hardpoints, be those guns or utility slots
			if(!weapon || weapon.fire_mode != fireMode)
				continue
			var/datum/ship_weapon/SW = weapon_types[weapon.fire_mode]
			spawn()
				for(var/I = 0; I < SW.burst_size; I++)
					weapon.fire(target)
					sleep(1)
			return TRUE
	return FALSE

//Burst arg currently unused for this proc.
/obj/structure/overmap/proc/secondary_fire(obj/structure/overmap/target, ai_aim = FALSE, burst = 1)
	hardpoint_fire(target, FIRE_MODE_TORPEDO)

/obj/item/fighter_component/primary/load(obj/structure/overmap/target, atom/movable/AM)
	if(!istype(AM, accepted_ammo))
		return FALSE
	if(magazine)
		if(magazine.ammo_count() >= magazine.max_ammo)
			return FALSE
		else
			magazine.forceMove(get_turf(target))
			if(!SSmapping.level_trait(loc.z, ZTRAIT_BOARDABLE))
				QDEL_NULL(magazine) //So bullets don't drop onto the overmap.
	AM.forceMove(src)
	magazine = AM
	ammo = magazine.stored_ammo
	playsound(target, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)
	return TRUE

/obj/item/fighter_component/primary/fire(obj/structure/overmap/target)
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	if(!ammo.len)
		F.relay('sound/weapons/gun_dry_fire.ogg')
		return FALSE
	var/obj/item/ammo_casing/chambered = ammo[ammo.len]
	var/datum/ship_weapon/SW = F.weapon_types[fire_mode]
	SW.default_projectile_type = chambered.projectile_type
	SW.fire_fx_only(target)
	ammo -= chambered
	qdel(chambered)
	return TRUE

/obj/item/fighter_component/primary/on_install(obj/structure/overmap/target)
	. = ..()
	if(!fire_mode)
		return FALSE
	var/datum/ship_weapon/SW = target.weapon_types[fire_mode]
	SW.overmap_firing_sounds = overmap_firing_sounds
	SW.overmap_select_sound = overmap_select_sound
	SW.burst_size = burst_size
	SW.fire_delay = fire_delay
	SW.allowed_roles = allowed_roles

/obj/item/fighter_component/primary/remove_from(obj/structure/overmap/target)
	. = ..()
	magazine = null
	ammo = list()

/obj/item/fighter_component/primary/cannon
	name = "20mm Vulcan Cannon"
	icon_state = "lightcannon"
	accepted_ammo = /obj/item/ammo_box/magazine/nsv/light_cannon
	burst_size = 2
	fire_delay = 0.25 SECONDS

/obj/item/fighter_component/primary/cannon/heavy
	name = "30mm BRRRRTT Cannon"
	icon_state = "heavycannon"
	accepted_ammo = /obj/item/ammo_box/magazine/nsv/heavy_cannon
	weight = 2 //Sloooow down there.
	overmap_select_sound = 'nsv13/sound/effects/ship/pdc_start.ogg'
	overmap_firing_sounds = list('nsv13/sound/effects/fighters/BRRTTTTTT.ogg')
	burst_size = 3
	fire_delay = 0.5 SECONDS

/obj/item/fighter_component/primary/laser
	name = "Stinger Class Phaser Cannon"
	icon_state = "lasercannon"
	weight = 3 //it's a laser. it's light, but the gun is fuckhueg
	accepted_ammo = null
	overmap_select_sound = 'nsv13/sound/effects/ship/phaser_adjust.ogg'
	overmap_firing_sounds = list('nsv13/sound/effects/ship/burst_phaser.ogg', 'nsv13/sound/effects/ship/burst_phaser2.ogg')
	burst_size = 3
	fire_delay = 10 SECONDS
	var/projectile = /obj/item/projectile/beam/laser/phaser
	var/charge_to_fire = 2000   // this is probably not final. needs to be a good balance between having an actual mainship weapon on a fighter, and firing one shot every minute because one shot depletes your entire battery

/obj/item/fighter_component/primary/laser/get_ammo()
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	var/obj/item/fighter_component/battery/B = F.loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	if(!istype(B))
		return 0
	return B.charge

/obj/item/fighter_component/primary/laser/get_max_ammo()
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	var/obj/item/fighter_component/battery/B = F.loadout.get_slot(HARDPOINT_SLOT_BATTERY)
	if(!istype(B))
		return 0
	return B.maxcharge

/obj/item/fighter_component/primary/laser/fire(obj/structure/overmap/target)
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	var/obj/item/fighter_component/battery/B = F.loadout.get_slot(HARDPOINT_SLOT_BATTERY)

	if(B.charge < charge_to_fire)
		F.relay('sound/weapons/gun_dry_fire.ogg')
		return FALSE

	var/datum/ship_weapon/SW = F.weapon_types[fire_mode]
	SW.default_projectile_type = projectile
	SW.fire_fx_only(target, lateral = TRUE)
	B.charge -= charge_to_fire
	return TRUE


/obj/item/fighter_component/secondary
	name = "secondary weapon"
	slot = HARDPOINT_SLOT_SECONDARY
	fire_mode = FIRE_MODE_TORPEDO
	var/overmap_firing_sounds = list(
		'nsv13/sound/effects/ship/torpedo.ogg',
		'nsv13/sound/effects/ship/freespace2/m_shrike.wav',
		'nsv13/sound/effects/ship/freespace2/m_stiletto.wav',
		'nsv13/sound/effects/ship/freespace2/m_tsunami.wav',
		'nsv13/sound/effects/ship/freespace2/m_wasp.wav')
	var/overmap_select_sound = 'nsv13/sound/effects/ship/reload.ogg'
	var/accepted_ammo = /obj/item/ship_weapon/ammunition/missile
	var/list/ammo = list()
	var/max_ammo = 5
	var/burst_size = 1 //Cluster torps...UNLESS?
	var/fire_delay = 0.25 SECONDS
	var/allowed_roles = OVERMAP_USER_ROLE_GUNNER
	var/bypass_safety = FALSE

/obj/item/fighter_component/secondary/dump_contents()
	. = ..()
	for(var/atom/movable/AM in .)
		if(AM in ammo)
			ammo -= AM
			playsound(loc, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)

/obj/item/fighter_component/secondary/get_ammo()
	return ammo.len

/obj/item/fighter_component/secondary/get_max_ammo()
	return max_ammo

/obj/item/fighter_component/secondary/on_install(obj/structure/overmap/target)
	. = ..()
	if(!fire_mode)
		return FALSE
	var/datum/ship_weapon/SW = target.weapon_types[fire_mode]
	SW.overmap_firing_sounds = overmap_firing_sounds
	SW.overmap_select_sound = overmap_select_sound
	SW.burst_size = burst_size
	SW.fire_delay = fire_delay
	SW.allowed_roles = allowed_roles

/obj/item/fighter_component/secondary/remove_from(obj/structure/overmap/target)
	. = ..()
	ammo = list()

//Todo: make fighters use these.
/obj/item/fighter_component/secondary/ordnance_launcher
	name = "fighter missile rack"
	desc = "A huge fighter missile rack capable of deploying missile based weaponry."
	icon_state = "missilerack_tier1"

/obj/item/fighter_component/secondary/ordnance_launcher/tier2
	name = "upgraded fighter missile rack"
	icon_state = "missilerack_tier2"
	tier = 2
	max_ammo = 10

/obj/item/fighter_component/secondary/ordnance_launcher/tier3
	name = "\improper A-11 'Spacehog' Cluster-Freedom Launcher"
	icon_state = "missilerack_tier3"
	tier = 3
	max_ammo = 15
	weight = 1
	burst_size = 2
	fire_delay = 0.10 SECONDS

//Specialist item for the superiority fighter.
/obj/item/fighter_component/secondary/ordnance_launcher/railgun
	name = "fighter railgun"
	desc = "A scaled down railgun designed for use in fighters."
	icon_state = "railgun"
	weight = 1
	accepted_ammo = /obj/item/ship_weapon/ammunition/railgun_ammo
	overmap_firing_sounds = list('nsv13/sound/effects/ship/railgun_fire.ogg')
	burst_size = 1
	fire_delay = 0.2 SECONDS
	max_ammo = 10
	tier = 1

/obj/item/fighter_component/secondary/ordnance_launcher/torpedo
	name = "fighter torpedo launcher"
	desc = "A heavy torpedo rack which allows fighters to fire torpedoes at targets"
	icon_state = "torpedorack"
	accepted_ammo = /obj/item/ship_weapon/ammunition/torpedo
	max_ammo = 2
	weight = 1

/obj/item/fighter_component/secondary/ordnance_launcher/torpedo/tier2
	name = "enhanced torpedo launcher"
	icon_state = "torpedorack_tier2"
	tier = 2
	max_ammo = 4

/obj/item/fighter_component/secondary/ordnance_launcher/torpedo/tier3
	name = "\improper FR33-8IRD torpedo launcher"
	icon_state = "torpedorack_tier3"
	desc = "A massive torpedo launcher capable of deploying enough ordnance to level several small, oil-rich nations."
	tier = 3
	max_ammo = 10
	weight = 2
	burst_size = 2

/obj/item/fighter_component/secondary/ordnance_launcher/load(obj/structure/overmap/target, atom/movable/AM)
	if(!istype(AM, accepted_ammo))
		return FALSE
	if(ammo.len >= max_ammo)
		return FALSE
	AM.forceMove(src)
	ammo += AM
	playsound(target, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)
	return TRUE

/obj/item/fighter_component/secondary/ordnance_launcher/fire(obj/structure/overmap/target)
	var/obj/structure/overmap/small_craft/F = loc
	if(!istype(F))
		return FALSE
	if(!ammo.len)
		F.relay('sound/weapons/gun_dry_fire.ogg')
		return FALSE
	var/proj_type = null //If this is true, we've got a launcher shipside that's been able to fire.
	var/proj_speed = 1
	var/obj/item/ship_weapon/ammunition/americagobrr = pick_n_take(ammo)
	proj_type = americagobrr.projectile_type
	proj_speed = istype(americagobrr.projectile_type, /obj/item/projectile/guided_munition/missile) ? 5 : 1
	qdel(americagobrr)
	if(proj_type)
		var/sound/chosen = pick('nsv13/sound/effects/ship/torpedo.ogg','nsv13/sound/effects/ship/freespace2/m_shrike.wav','nsv13/sound/effects/ship/freespace2/m_stiletto.wav','nsv13/sound/effects/ship/freespace2/m_tsunami.wav','nsv13/sound/effects/ship/freespace2/m_wasp.wav')
		F.relay_to_nearby(chosen)
		F.fire_projectile(proj_type, target, speed=proj_speed, lateral = FALSE)
	return TRUE

//Utility modules.

/obj/item/fighter_component/primary/utility
	name = "No :)"
	slot = HARDPOINT_SLOT_UTILITY_PRIMARY
	allowed_roles = OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER

/obj/item/fighter_component/primary/utility/fire(obj/structure/overmap/target)
	return FALSE

/obj/item/fighter_component/secondary/utility
	name = "Utility Module"
	slot = HARDPOINT_SLOT_UTILITY_SECONDARY
	power_usage = 200
	allowed_roles = OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER

/obj/structure/overmap/small_craft/proc/update_visuals()
	if(canopy)
		cut_overlay(canopy)
	else
		canopy = mutable_appearance(icon = icon, icon_state = "canopy_missing")
	var/obj/item/fighter_component/canopy/C = loadout?.get_slot(HARDPOINT_SLOT_CANOPY)
	if(QDELETED(C))
		canopy.icon_state = "canopy_missing"
	else if(C.obj_integrity <= 20)
		canopy.icon_state = "canopy_breach"
	else if(canopy_open)
		canopy.icon_state = "canopy_open"
	else
		return
	add_overlay(canopy)

/obj/structure/overmap/small_craft/slowprocess(delta_time)
	..()
	if(engines_active())
		use_fuel()
		loadout.process(delta_time)

	var/obj/item/fighter_component/canopy/C = loadout.get_slot(HARDPOINT_SLOT_CANOPY)

	// Leak air if the canopy is missing or broken
	// and air is in the cabin
	// and the fighter's environment isn't pressurized

	if((!C || (C.obj_integrity <= 0)) && cabin_air.total_moles() > 0)
		var/datum/gas_mixture/outside_air = loc.return_air()
		var/outside_pressure = outside_air ? outside_air.return_pressure() : 0
		if(outside_pressure && (cabin_air.return_pressure() > outside_pressure))
			cabin_air.remove(min(cabin_air.total_moles(), 5))

	update_visuals()

/obj/structure/overmap/small_craft/return_air()
	var/obj/item/fighter_component/canopy/C = loadout.get_slot(HARDPOINT_SLOT_CANOPY)
	if(canopy_open || !C || (C.obj_integrity <= 0))
		return loc.return_air()
	return cabin_air

/obj/structure/overmap/small_craft/remove_air(amount)
	var/datum/gas_mixture/air = return_air()
	return air.remove(amount)

/obj/structure/overmap/small_craft/return_analyzable_air()
	return cabin_air

/obj/structure/overmap/small_craft/return_temperature()
	var/datum/gas_mixture/t_air = return_air()
	return t_air.return_temperature()

/obj/structure/overmap/small_craft/portableConnectorReturnAir()
	return return_air()

/obj/structure/overmap/small_craft/assume_air(datum/gas_mixture/giver)
	var/datum/gas_mixture/t_air = return_air()
	return t_air.merge(giver)

/obj/structure/overmap/small_craft/proc/toggle_canopy()
	canopy_open = !canopy_open
	playsound(src, 'nsv13/sound/effects/fighters/canopy.ogg', 100, 1)

