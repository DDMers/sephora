/obj/item/ship_weapon/ammunition/gauss //Medium sized slugs to be loaded into a gauss gun.
	name = "\improper M4 NTRS 300mm teflon coated tungsten round"
	desc = "A large slug designed to be magnetically accelerated via a gauss gun. These rounds are lighter than those fired out of railguns, but are still extremely heavy duty."
	icon_state = "gauss"
	lefthand_file = 'nsv13/icons/mob/inhands/weapons/bombs_lefthand.dmi'
	righthand_file = 'nsv13/icons/mob/inhands/weapons/bombs_righthand.dmi'
	icon = 'nsv13/icons/obj/munitions.dmi'
	w_class = 4
	projectile_type = /obj/item/projectile/bullet/gauss_slug

/obj/item/circuitboard/machine/gauss_dispenser
	name = "\improper Gauss ammunition dispenser (Machine Board)"
	build_path = /obj/machinery/gauss_dispenser
	req_components = list(
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/ship_weapon/parts/loading_tray = 1)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF

/obj/item/circuitboard/machine/gauss_dispenser/Initialize(mapload)
	. = ..()
	GLOB.critical_muni_items += src

/obj/item/circuitboard/machine/gauss_dispenser/Destroy(force=FALSE)
	if(!force)
		return QDEL_HINT_LETMELIVE
	GLOB.critical_muni_items -= src
	return ..()

/obj/machinery/gauss_dispenser
	name = "\improper Gauss ammunition dispenser"
	desc = "A machine which can delve deep into the ship's ammunition stores and dispense whatever it finds."
	icon = 'nsv13/icons/obj/munitions.dmi'
	icon_state = "gauss_dispenser"
	req_one_access = ACCESS_MUNITIONS
	circuit = /obj/item/circuitboard/machine/gauss_dispenser
	pixel_y = 26
	var/dispense_amount = 12 //Fully fills one gauss gun.
	var/active = TRUE
	var/progress = 0 SECONDS
	var/progress_rate = 1 SECONDS
	var/goal = 45 SECONDS
	var/ready = FALSE

/obj/machinery/gauss_dispenser/RefreshParts()
	progress_rate = 0 SECONDS
	for(var/obj/item/stock_parts/S in component_parts)
		progress_rate += S.rating SECONDS

/obj/machinery/gauss_dispenser/process()
	cut_overlays()
	if(machine_stat & NOPOWER)
		progress = 0 SECONDS
		return PROCESS_KILL
	progress += progress_rate
	if(progress >= goal)
		add_overlay("gauss_dispenser_ready")
		playsound(src, 'nsv13/sound/effects/ship/freespace2/computer/escape.wav', 100, FALSE)
		ready = TRUE
		progress = 0
		return PROCESS_KILL
	else
		add_overlay("gauss_dispenser_active")

/obj/machinery/gauss_dispenser/attack_hand(mob/user)
	if(!allowed(user))
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Access denied</span>")
		return
	ui_interact(user)

/obj/machinery/gauss_dispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GaussDispenser")
		ui.open()
		ui.set_autoupdate(TRUE) // progress bar

/obj/machinery/gauss_dispenser/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	switch(action)
		if("toggle_power")
			active = !active
			ready = FALSE
			progress = 0
			check_active(active)
		if("dispense")
			if(!ready)
				return FALSE
			flick("gauss_dispenser_dispense", src)
			playsound(src, 'nsv13/sound/effects/ship/mac_load.ogg', 100, 1)
			for(var/I = 0, I < dispense_amount, I++)
				new /obj/item/ship_weapon/ammunition/gauss(get_turf(src))
			cut_overlays()
			ready = FALSE
			use_power = 50
			START_PROCESSING(SSmachines, src)

/obj/machinery/gauss_dispenser/proc/check_active(state)
	if(state)
		use_power = 50 //Takes some power
		START_PROCESSING(SSmachines, src)
	else
		use_power = 0
		cut_overlays()
		STOP_PROCESSING(SSmachines, src)

/obj/machinery/gauss_dispenser/screwdriver_act(mob/user, obj/item/tool)
	var/icon_state_open = "gauss_dispenser_open"
	var/icon_state_closed = initial(icon_state)
	. = default_deconstruction_screwdriver(user, icon_state_open, icon_state_closed, tool)

/obj/machinery/gauss_dispenser/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/I)
	. = ..()
	check_active(!panel_open)

/obj/machinery/gauss_dispenser/ui_data(mob/user)
	var/list/data = list()
	data["powered"] = active
	data["progress"] = progress
	data["goal"] = goal
	data["ready"] = ready
	return data
