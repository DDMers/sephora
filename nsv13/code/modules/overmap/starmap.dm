#define SHIPINFO 0
#define STARMAP 1

/**
	Starmap code largely copied from FT13's starmap, so credit to them! (And monster860...again)
*/

/datum/asset/simple/starmap
	assets = list(
		"space.png" = 'nsv13/icons/assets/space.png')

/obj/machinery/computer/ship/navigation
	name = "\improper FTL Navigation console"
	desc = "A computer which can interface with the Thirring Drive to allow the ship to travel vast distances in space."
	icon_screen = "ftl"
	var/datum/star_system/selected_system = null
	var/screen = STARMAP
	var/can_control_ship = TRUE
	var/current_sector = SECTOR_NEUTRAL
	circuit = /obj/item/circuitboard/computer/ship/navigation

/obj/machinery/computer/ship/navigation/LateInitialize()
	addtimer(CALLBACK(src, PROC_REF(has_overmap)), 15 SECONDS)


/obj/machinery/computer/ship/navigation/can_interact(mob/user) //Override this code to allow people to use consoles when flying the ship.
	if(user in linked?.operators)
		return TRUE
	return ..()

/obj/machinery/computer/ship/navigation/public
	name = "Starmap Console"
	desc = "A computer which shows the current position of the ship in the universe."
	can_control_ship = FALSE

/obj/machinery/computer/ship/navigation/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/ship/navigation/ui_interact(mob/user, datum/tgui/ui)
	if(!linked)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		var/datum/asset/assets = get_asset_datum(/datum/asset/simple/starmap)
		assets.send(user)
		ui = new(user, src, "Starmap")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/ship/navigation/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(. && !IsAdminGhost(usr))
		return
	if(!linked)
		return
	switch(action)
		if("map")
			screen = STARMAP
		if("shipinf")
			screen = SHIPINFO
		if("sector")
			var/sector = input(usr, "Swap to what sector?","Sector Selection", null) as null|anything in list(ALL_STARMAP_SECTORS)
			if(!sector)
				return
			current_sector = sector
		if("select_system")
			var/datum/star_system/target = locate(params["star_id"])
			if(!istype(target))
				return
			selected_system = target
			screen = 2
			. = TRUE
		if("jump")
			if(linked.ftl_drive.lockout)
				to_chat(usr, "<span class='warning'>[icon2html(src, viewers(src))] Unable to comply. Invalid authkey to unlock remove override code.</span>")
				return
			if(linked.ftl_safety_override)
				if(linked.next_emergency_jump > world.time)
					say("Drive Emergency Capacitor is still recharging. Emergency jump unavailable.")
					return TRUE
				linked.ftl_drive.request_emergency_ftl_confirm()
			else
				linked.ftl_drive.jump(selected_system)
			. = TRUE
		if("cancel_jump")
			if(linked.ftl_drive.lockout)
				to_chat(usr, "<span class='warning'>[icon2html(src, viewers(src))] Unable to comply. Invalid authkey to unlock remove override code.</span>")
				return
			if(linked.ftl_drive.cancel_ftl())
				linked.stop_relay(CHANNEL_IMPORTANT_SHIP_ALERT)
				linked.relay('nsv13/sound/effects/ship/ftl_stop.ogg', channel=CHANNEL_IMPORTANT_SHIP_ALERT)


/obj/machinery/computer/ship/navigation/ui_data(mob/user)
	if(!has_overmap())
		return
	var/list/data = list()
	var/list/info = SSstar_system.ships[linked]
	var/list/lines = list()
	if(!info?.len)
		return data

	var/datum/star_system/current_system = info["current_system"]
	SSstar_system.update_pos(linked)
	if(linked.ftl_drive)
		if(istype(linked.ftl_drive))
			data["ftl_progress"] = linked.ftl_drive.progress
			data["ftl_goal"] = linked.ftl_drive.req_charge
		else // yes this is so bad I know but I don't want to rework a legacy system that is probably EoL, so this'll do for now
			var/obj/machinery/computer/ship/ftl_computer/bodge = linked.ftl_drive
			data["ftl_progress"] = bodge.progress
			data["ftl_goal"] = bodge.spoolup_time
	data["travelling"] = FALSE
	switch(screen)
		if(0) // ship information
			var/datum/star_system/target_system = info["target_system"]
			if(!target_system)
				data["in_transit"] = FALSE
				data["star_id"] = "\ref[current_system]"
				data["star_name"] = current_system.name
			else
				data["in_transit"] = TRUE
				var/datum/star_system/last_system = info["last_system"]
				data["from_star_id"] = "\ref[last_system]"
				data["from_star_name"] = last_system.name
				data["to_star_id"] = "\ref[target_system]"
				data["to_star_name"] = target_system.name
				data["time_left"] = max(0, (info["to_time"] - world.time) / 1 MINUTES)

		if(1) // star system map screen thing
			var/list/systems_list = list()
			if(info["current_system"])
				var/datum/star_system/curr = info["current_system"]
				data["focus_x"] = curr.x
				data["focus_y"] = curr.y
			else
				data["focus_x"] = info["x"]
				data["focus_y"] = info["y"]
			for(var/datum/star_system/system in SSstar_system.systems) // for each system
				if(system.hidden || system.sector != current_sector)
					continue
				var/list/system_list = list()
				system_list["name"] = system.name
				if(current_system)
					system_list["in_range"] = is_in_range(current_system, system) || return_jump_check(system)
					system_list["distance"] = "[current_system.dist(system) > 0 ? "[current_system.dist(system)] LY" : "You are here."]"
				else
					system_list["in_range"] = 0
				system_list["x"] = system.x
				system_list["y"] = system.y
				system_list["star_id"] = "\ref[system]"
				system_list["is_current"] = (system == current_system)
				system_list["alignment"] = system.alignment
				system_list["visited"] = is_visited(system)
				system_list["hidden"] = FALSE
				var/label = ""
				if(system.is_hypergate)
					label += " HYPERGATE"
				if(system.is_capital && !label)
					label += "CAPITAL"
				if(system.trader && system.sector != SECTOR_NEUTRAL) //Use shortnames in brazil for readability
					label += " [system.trader.name]"
				if(system.trader && system.sector == SECTOR_NEUTRAL) //Use shortnames in brazil for readability
					label += " [system.trader.shortname]"
				if(system.mission_sector)
					label += " OCCUPIED"
				if(system.objective_sector)
					label += " MISSION"
				system_list["label"] = label
				for(var/thename in system.adjacency_list) //Draw the lines joining our systems
					var/datum/star_system/sys = SSstar_system.system_by_id(thename)
					if(!sys)
						message_admins("[thename] exists in a system adjacency list, but does not exist. Go create a starsystem datum for it.")
						continue
					var/is_wormhole = (LAZYFIND(sys.wormhole_connections, system.name) || LAZYFIND(system.wormhole_connections, sys.name))
					var/is_bidirectional = (LAZYFIND(sys.adjacency_list, system.name) && LAZYFIND(system.adjacency_list, sys.name))
					if((!is_bidirectional && system != current_system) || sys.hidden || sys.sector != system.sector) //Secret One way wormholes show you faint, purple paths.
						continue
					var/thecolour = "#FFFFFF" //Highlight available routes with blue.
					var/opacity = 1
					if(LAZYFIND(current_system?.adjacency_list, thename)) //Don't flood the map with wormhole paths, the idea is that you find them yourself!
						if(is_wormhole)
							thecolour = "#BA55D3"
							opacity = 0.85
					//	else //Couldnt get this to work :/
						//	to_chat(world, "[thename] is in [current_system]")
						//	thecolour = "#193a7a"
					var/list/line = list()
					var/dx = sys.x - system.x
					var/dy = sys.y - system.y
					var/len = sqrt(dx*dx+dy*dy)
					var/angle = 90 - ATAN2(dy, dx)
					line["x"] = system.x
					line["y"] = system.y
					line["len"] = len
					line["angle"] = -angle
					line["colour"] = thecolour
					line["priority"] = (sys != current_system) ? 1 : 2
					line["opacity"] = opacity //Wormholes show faint, purple lines.
					lines[++lines.len] = line
				systems_list[++systems_list.len] = system_list
			if(info["to_time"] > 0)
				data["freepointer_x"] = info["x"]
				data["freepointer_y"] = info["y"]
				var/datum/star_system/last = info["last_system"]
				var/datum/star_system/targ = info["target_system"]
				var/dist = last.dist(targ)
				var/dx = targ.x - last.x
				var/dy = targ.y - last.y
				data["freepointer_cos"] = dx / dist
				data["freepointer_sin"] = dy / dist
				data["travelling"] = TRUE
			data["star_systems"] = systems_list
			data["lines"] = lines
		if(2) // show info about system screen
			data["star_id"] = "\ref[selected_system]"
			data["star_name"] = selected_system?.name
			data["alignment"] = capitalize(selected_system?.alignment)
			if(info["current_system"])
				var/datum/star_system/curr = info["current_system"]
				data["star_dist"] = curr.dist(selected_system)
				data["can_jump"] = (current_system.dist(selected_system) < linked.ftl_drive?.max_range && linked.ftl_drive.ftl_state == FTL_STATE_READY && LAZYFIND(current_system.adjacency_list, selected_system.name)) || (linked.ftl_safety_override && linked.ftl_drive && linked.ftl_drive.ftl_state != FTL_STATE_JUMPING)
				if(return_jump_check(selected_system) && linked.ftl_drive.ftl_state == FTL_STATE_READY)
					data["can_jump"] = TRUE
				if(!can_control_ship) //For public consoles
					data["can_jump"] = FALSE
					data["can_cancel"] = FALSE
	data["ftl_safety_override"] = linked?.ftl_safety_override
	data["screen"] = screen
	data["can_cancel"] = linked?.ftl_drive?.ftl_state == FTL_STATE_JUMPING && linked?.ftl_drive?.can_cancel_jump && !linked?.ftl_safety_override
	return data

/obj/machinery/computer/ship/navigation/proc/is_in_range(datum/star_system/current_system, datum/star_system/system)
	return LAZYFIND(current_system?.adjacency_list, system?.name)

/obj/machinery/computer/ship/navigation/proc/is_visited(datum/star_system/system)
	return system.visited

/obj/machinery/computer/ship/navigation/proc/return_jump_check(datum/star_system/system)
	return ((SSovermap_mode.already_ended || SSovermap_mode.round_extended) && istype(system, /datum/star_system/outpost))

#undef SHIPINFO
#undef STARMAP
