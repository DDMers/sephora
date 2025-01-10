//PUMP GOES HERE
/obj/machinery/armour_plating_nanorepair_pump
	name = "\improper Armour Plating Nano-repair Pump"
	desc = "AP thingies that link to the Well"
	icon = 'nsv13/icons/obj/machinery/armour_pump.dmi'
	icon_state = "pump"
	pixel_x = -16
	density = TRUE
	anchored = TRUE
	idle_power_usage = 50
	active_power_usage = 0
	layer = ABOVE_MOB_LAYER
	obj_integrity = 500
	var/obj/machinery/armour_plating_nanorepair_well/apnw //parent device
	var/obj/structure/overmap/OM //parent ship
	var/armour_repair_amount = 0 //amount of quadrant armour to be repaired
	var/structure_repair_amount = 0 //amount of obj_integrity to be repaired
	var/armour_allocation = 0 //allocation of resources to armour for this APNP
	var/structure_allocation = 0 ///allocation of resource to structure for this APNP
	var/online = TRUE //Are we running?
	var/stress_shutdown = FALSE //Has this APNP been overtaxed?
	var/last_restart = 0 //Time since last forced system restart
	var/quadrant = null //Which armour quadrant we are assigned to
	var/apnw_id = null //The ID by which we identify our parent device - These should match the parent device and follow the formula: 1 - Main Ship, 2 - Secondary Ship, 3 - Syndie PvP Ship
	var/list/repair_records = list() //Graphs again
	var/repair_records_length = 300
	var/repair_records_interval = 10
	var/repair_records_next_interval = 0

/obj/machinery/armour_plating_nanorepair_pump/forward_port //this is a preset for mapping
	quadrant = "forward_port"

/obj/machinery/armour_plating_nanorepair_pump/aft_port //this is a preset for mapping
	quadrant = "aft_port"

/obj/machinery/armour_plating_nanorepair_pump/aft_starboard //this is a preset for mapping
	quadrant = "aft_starboard"

/obj/machinery/armour_plating_nanorepair_pump/forward_starboard //this is a preset for mapping
	quadrant = "forward_starboard"

/obj/machinery/armour_plating_nanorepair_pump/Initialize(mapload)
	.=..()
	OM = get_overmap()
	addtimer(CALLBACK(src, PROC_REF(handle_linking)), 30 SECONDS)

	repair_records["armour"] = list()
	repair_records["structure"] = list()

/obj/machinery/armour_plating_nanorepair_pump/examine(mob/user)
	.=..()
	if(quadrant)
		. += "<span class='notice'>This APNP is aligned to [quadrant]</span>"
	if(online)
		. += "<span class='notice'>It has a maintenance panel that appears to be welded shut</span>"
	if(!online)
		. += "<span class='notice'>The maintenance panel is open</span>"
	if(stress_shutdown)
		. += "<span class='warning'>The system overload lights are flashing</span>"

/obj/machinery/armour_plating_nanorepair_pump/process(delta_time)
	if(!OM)
		OM = get_overmap()
	if(online && is_operational && !stress_shutdown)
		idle_power_usage = 0 //reset power use
		var/weight_class = OM.mass
		if(weight_class >= MASS_TITAN)
			weight_class = 90 //Because someone changed how mass classes work //Undoing this because a repair rate of .13% is aweful. maths out instead to .5% per pump per secondish
		if(weight_class >= MASS_LARGE)
			weight_class = 50  //Copying above because a repair rate of .19% Feels aweful as an engineer. maths out to .5% per pump per secondish
		if(armour_allocation)
			if(OM.armour_quadrants[quadrant]["current_armour"] < OM.armour_quadrants[quadrant]["max_armour"]) //Armour Check
				var/armour_integrity = (OM.armour_quadrants[quadrant]["current_armour"] / OM.armour_quadrants[quadrant]["max_armour"]) * 100
				if(armour_integrity < 15)
					armour_integrity = 15
				armour_repair_amount = delta_time * ((382 * NUM_E **(0.0764 * armour_integrity))/(50 + NUM_E ** (0.0764 * armour_integrity)) ** 2 ) * (apnw.repair_efficiency * (armour_allocation / 100)) * 3 //Don't ask
				if(apnw.repair_resources >= (armour_repair_amount * weight_class))
					OM.armour_quadrants[quadrant]["current_armour"] += armour_repair_amount
					if(OM.armour_quadrants[quadrant]["current_armour"] > OM.armour_quadrants[quadrant]["max_armour"])
						OM.armour_quadrants[quadrant]["current_armour"] = OM.armour_quadrants[quadrant]["max_armour"]
					apnw.repair_resources -= (armour_repair_amount * weight_class)
					idle_power_usage += armour_repair_amount * 100
		if(structure_allocation)
			if(OM.obj_integrity < OM.max_integrity) //Structure Check
				if(OM.structure_crit_no_return) //If we have crossed the point of no return, halt repairs
					return
				structure_repair_amount = delta_time * ((2 + (weight_class / 10)) * apnw.repair_efficiency * structure_allocation) / 200
				if(apnw.repair_resources >= (structure_repair_amount * weight_class) * 1.5)
					//message_admins("repaired [structure_repair_amount]") // Admeme message for mathing help
					OM.obj_integrity += structure_repair_amount
					if(OM.obj_integrity > OM.max_integrity)
						OM.obj_integrity = OM.max_integrity
					apnw.repair_resources -= (structure_repair_amount * weight_class) * 1.5
					idle_power_usage += structure_repair_amount * 100

					if(OM.structure_crit) //Checking to see if we can exist SS Crit
						if(OM.obj_integrity >= OM.max_integrity * 0.2) //You need to repair a good chunk of her HP before you're getting outta this fucko.
							OM.stop_relay(channel=CHANNEL_SHIP_FX)
							priority_announce("Ship structural integrity restored to acceptable levels. ","Automated announcement ([apnw])")
							OM.structure_crit = FALSE

	else
		armour_repair_amount = 0
		structure_repair_amount = 0
		idle_power_usage = initial(idle_power_usage)
	update_icon() //temp

	if(world.time >= repair_records_next_interval)
		repair_records_next_interval = world.time + repair_records_interval

		var/list/armour = repair_records["armour"]
		armour += armour_repair_amount
		if(armour.len > repair_records_length)
			armour.Cut(1, 2)

		var/list/structure = repair_records["structure"]
		structure += structure_repair_amount
		if(structure.len > repair_records_length)
			structure.Cut(1, 2)

/obj/machinery/armour_plating_nanorepair_pump/proc/handle_linking()
	if(apnw_id) //If mappers set an ID)
		for(var/obj/machinery/armour_plating_nanorepair_well/W in GLOB.machines)
			if(W.apnw_id == apnw_id && W.z == z)
				apnw = W

/obj/machinery/armour_plating_nanorepair_pump/multitool_act(mob/user, obj/item/tool)
	. = TRUE
	if(!multitool_check_buffer(user, tool))
		return
	var/obj/item/multitool/M = tool
	if(!isnull(M.buffer) && istype(M.buffer, /obj/machinery/armour_plating_nanorepair_well))
		apnw?.apnp -= src
		apnw = M.buffer
		apnw.apnp += src
		M.buffer = null
	quadrant = input(user, "Direct nano-repair pump to which quadrant?", "[name]") as null|anything in list("forward_port", "forward_starboard", "aft_port", "aft_starboard")
	playsound(src, 'sound/items/flashlight_on.ogg', 100, TRUE)
	to_chat(user, "<span class='notice'>Buffer transfered</span>")
	return

/obj/machinery/armour_plating_nanorepair_pump/welder_act(mob/user, obj/item/tool)
	. = FALSE
	if(online)
		to_chat(user, "<span class='notice'>You start to unseal the maintenance panel cover...</span>")
		if(tool.use_tool(src, user, 40, volume=100))
			to_chat(user, "<span class='notice'>You unseal and remove the maintenance panel cover</span>")
			online = FALSE
			update_icon()
			return TRUE
	if(!online)
		to_chat(user, "<span class='notice'>You start to replace and seal the maintenance panel cover...</span>")
		if(tool.use_tool(src, user, 40, volume=100))
			to_chat(user, "<span class='notice'>You replace the maintenance panel cover and seal it</span>")
			online = TRUE
			update_icon()
			return TRUE

/obj/machinery/armour_plating_nanorepair_pump/wrench_act(mob/user, obj/item/tool)
	. = FALSE
	if(!online && stress_shutdown)
		to_chat(user, "<span class='notice'>You start to purge and restart the pump...</span>")
		if(tool.use_tool(src, user, 100, volume=100))
			to_chat(user, "<span class='notice'>You restart the pump</span>")
			stress_shutdown = FALSE
			last_restart = world.time
			update_icon()
			return TRUE

/obj/machinery/armour_plating_nanorepair_pump/Destroy()
	. = ..()
	apnw.apnp -= src


/obj/machinery/armour_plating_nanorepair_pump/update_icon()
	cut_overlays()
	if(!online)
		icon_state = "pump_maint"
		set_light(0)
	if(stress_shutdown)
		add_overlay("stressed")
		light_color = LIGHT_COLOR_RED
		set_light(1)
	if(online)
		icon_state = "pump"
		var/repair_total = armour_repair_amount + structure_repair_amount
		if(repair_total > 0)
			add_overlay("active")
			light_color = LIGHT_COLOR_CYAN
			set_light(1)

/obj/machinery/armour_plating_nanorepair_pump/attack_hand(mob/living/carbon/user)
	.=..()
	if(!apnw)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked well</span>")
		return
	ui_interact(user)

/obj/machinery/armour_plating_nanorepair_pump/attack_ai(mob/user)
	.=..()
	if(!apnw)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked well</span>")
		return
	ui_interact(user)

/obj/machinery/armour_plating_nanorepair_pump/attack_robot(mob/user)
	.=..()
	if(!apnw)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked well</span>")
		return
	ui_interact(user)

/obj/machinery/armour_plating_nanorepair_pump/attack_ghost(mob/user)
	.=..()
	if(!apnw)
		to_chat(user, "<span class='warning'>Unable to detect linked well</span>")
		return
	ui_interact(user)

/obj/machinery/armour_plating_nanorepair_pump/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArmourPlatingNanorepairPump")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/armour_plating_nanorepair_pump/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(!(in_range(src, usr) || IsAdminGhost(usr)))
		return
	var/adjust = text2num(params["adjust"])
	if(action == "armour_allocation")
		if(isnum(adjust))
			armour_allocation = CLAMP(adjust, 0, 100 - structure_allocation)
			return TRUE
	if(action == "structure_allocation")
		if(isnum(adjust))
			structure_allocation = CLAMP(adjust, 0, 100 - armour_allocation)
			return TRUE

/obj/machinery/armour_plating_nanorepair_pump/ui_data(mob/user)
	var/list/data = list()
	data["armour_allocation"] = armour_allocation
	data["structure_allocation"] = structure_allocation
	data["armour_repair_amount"] = armour_repair_amount
	data["structure_repair_amount"] = structure_repair_amount
	data["repair_records"] = repair_records
	data["quadrant"] = quadrant
	return data

/obj/item/circuitboard/machine/armour_plating_nanorepair_pump
	name = "Armour Plating Nano-repair Pump (Machine Board)"
	build_path = /obj/machinery/armour_plating_nanorepair_pump
	req_components = list(
		/obj/item/stock_parts/manipulator = 10,
		/obj/item/stock_parts/scanning_module = 5,
		/obj/item/stock_parts/capacitor = 5,
		/obj/item/stock_parts/micro_laser = 6)
