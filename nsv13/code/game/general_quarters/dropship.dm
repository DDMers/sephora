//FULL CREDIT FOR THE DROPSHIP INTERIORS GOES TO CM.

/turf/closed/indestructible/dropship
	name = "dropship"
	desc = "A piece of a mighty spaceship."
	icon = 'nsv13/icons/turf/dropship.dmi'
	icon_state = "brown_fr"

/turf/open/indestructible/dropship
	name = "dropship floor"
	desc = "A piece of a mighty spaceship."
	icon = 'nsv13/icons/turf/dropship_floor.dmi'
	icon_state = "rasputin1"

/obj/effect/landmark/dropship_entry
	name = "dropship entry point"
	var/linked = FALSE

/turf/closed/indestructible/dropship/entry
	name = "Hangar Bay Doors"
	desc = "Heavyset doors that lock mid-flight."
	icon_state = "79"

/turf/closed/indestructible/dropship/entry/Bumped(atom/movable/AM)
	. = ..()
	var/obj/structure/overmap/small_craft/transport/OM = get_overmap()
	if(OM && istype(OM) && !(SSmapping.level_trait(OM.z, ZTRAIT_OVERMAP)))
		OM.exit(AM)

/obj/structure/chair/fancy/dropship
	name = "acceleration chair"
	desc = "A seat which clamps down onto its occupant to keep them safe during flight."
	icon = 'nsv13/icons/obj/chairs.dmi'
	icon_state = "shuttle_chair"
	item_chair = null

/obj/structure/chair/fancy/dropship/Initialize(mapload)
	. = ..()
	update_armrest()

/obj/structure/chair/fancy/dropship/GetArmrest()
	return mutable_appearance('nsv13/icons/obj/chairs.dmi', "[initial(icon_state)]_[has_buckled_mobs() ? "closed" : "open"]")

/obj/structure/chair/fancy/dropship/update_armrest()
	cut_overlay(armrest)
	QDEL_NULL(armrest)
	armrest = GetArmrest()
	armrest.layer = ABOVE_MOB_LAYER
	add_overlay(armrest)

/area/dropship
	name = "NSV Sephora"
	icon_state = "shuttle"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	has_gravity = STANDARD_GRAVITY
	always_unpowered = FALSE
	lighting_colour_tube = "#e6af68"
	lighting_colour_bulb = "#e6af68"
	area_flags = 0 // Not a unique area and spawns are not allowed
	teleport_restriction = TELEPORT_ALLOW_NONE
	var/obj/structure/overmap/small_craft/transport/linked_dropship

/area/dropship/get_virtual_z(turf/T)
	if(linked_dropship)
		return linked_dropship.get_interior_virtual_z()
	return ..()

//If we ever want to let them build these things..
/area/dropship/generic
	name = "dropship"

/area/dropship/generic/syndicate
	name = "dropship"
	lighting_colour_tube = "#d34330"
	lighting_colour_bulb = "#d34330"

/obj/item/fighter_component/fuel_tank/tier2/dropship
	name = "Dropship Fuel Tank"
	desc = "A fuel tank large enough for troop transports."
	icon_state = "fueltank_tier2"
	fuel_capacity = 3000
	tier = 2
	weight = 2

/obj/structure/overmap/small_craft/transport/enter(mob/user)
	if(!interior_entry_points?.len)
		message_admins("[src] has no interior or entry points and [user] tried to board it.")
		return FALSE
	var/turf/T = get_turf(pick(interior_entry_points))
	var/atom/movable/AM
	if(user.pulling)
		AM = user.pulling
		playsound(src, 'nsv13/sound/effects/footstep/ladder2.ogg')
		AM.forceMove(T)
		user.forceMove(T)
		user.start_pulling(AM)
		if(ismob(AM))
			mobs_in_ship |= AM
	else
		playsound(src, 'nsv13/sound/effects/footstep/ladder2.ogg')
		user.forceMove(T)
	mobs_in_ship |= user

/obj/structure/overmap/small_craft/transport/update_visuals()
	if(canopy)
		cut_overlay(canopy)

/obj/structure/overmap/small_craft/transport/proc/exit(mob/user)
	var/turf/T = get_turf(src)
	var/atom/movable/AM
	if(user.pulling)
		AM = user.pulling
		playsound(src, 'nsv13/sound/effects/footstep/ladder2.ogg')
		AM.forceMove(T)
		user.forceMove(T)
		user.start_pulling(AM)
		if(ismob(AM))
			mobs_in_ship -= AM
	else
		playsound(src, 'nsv13/sound/effects/footstep/ladder2.ogg')
		user.forceMove(T)
	mobs_in_ship -= user

/obj/structure/overmap/small_craft/transport/attack_robot(mob/user)
	if(user.Adjacent(src))
		return attack_hand(user)

/obj/structure/overmap/small_craft/transport/attack_hand(mob/user)
	if(allowed(user))
		if(do_after(user, 2 SECONDS, target=src))
			enter(user)
			to_chat(user, "<span class='notice'>You climb into [src]'s passenger compartment.</span>")
			return TRUE

/obj/structure/overmap/small_craft/transport/MouseDrop_T(atom/movable/target, mob/user)
	if(!isliving(user))
		return FALSE
	for(var/slot in loadout.equippable_slots)
		var/obj/item/fighter_component/FC = loadout.get_slot(slot)
		if(FC?.load(src, target))
			return FALSE
	if(allowed(user))
		if(ismecha(user.loc))
			enter(user.loc)
			return
		else
			to_chat(target, "[(user == target) ? "You start to climb into [src]'s passenger compartment" : "[user] starts to lift you into [src]'s passenger compartment"]")
		if(do_after(user, 2 SECONDS, target=src))
			enter(user)
	else
		to_chat(user, "<span class='warning'>Access denied.</span>")

//Bit jank but w/e

/obj/structure/overmap/small_craft/transport/force_parallax_update(ftl_start)
	for(var/area/AR in linked_areas)
		AR.parallax_movedir = (ftl_start ? EAST : null)
	for(var/mob/M in mobs_in_ship)
		if(M && M.client && M.hud_used && length(M.client.parallax_layers))
			M.hud_used.update_parallax(force=TRUE)

/obj/machinery/computer/ship/helm/console/dropship
	name = "Dropship Flight Station"
	desc = "A modified console that allows you to interface with a fighter's systems remotely."
	circuit = /obj/item/circuitboard/computer/ship/helm/dropship

/obj/item/circuitboard/computer/ship/helm/dropship
	name = "circuit board (dropship helm computer)"
	build_path = /obj/machinery/computer/ship/helm/console/dropship

/obj/machinery/computer/ship/helm/console/dropship/attack_hand(mob/living/user)
	. = ..()
	var/obj/structure/overmap/OM = has_overmap()
	OM?.start_piloting(user, position)
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

/obj/machinery/computer/ship/helm/console/dropship/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FighterControls")
		ui.open()
		ui.set_autoupdate(TRUE) // Fuel gauge, ammo, etc

/obj/machinery/computer/ship/helm/console/dropship/ui_data(mob/user)
	var/obj/structure/overmap/OM = get_overmap()
	var/list/data = OM.ui_data(user)
	return data

/obj/machinery/computer/ship/helm/console/dropship/ui_act(action, params, datum/tgui/ui)
	var/obj/structure/overmap/small_craft/transport/OM = get_overmap()
	if(..() || !OM)
		return
	if(action == "kick")
		return
	OM.ui_act(action, params, ui)

/obj/structure/overmap/small_craft/transport/stop_piloting(mob/living/M, eject_mob=FALSE, force=FALSE) // Just changes eject default to false
	return ..()
