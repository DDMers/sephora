// Don't change this to anything lower than 260 or else it'll conflict with the spooldown sound loop
/// Minimuim time between FTL jumps in deciseconds
#define FTL_COOLDOWN 260

/// Maximum link distance between pylons and the core
#define MAX_PYLON_DISTANCE 10

/obj/machinery/computer/ship/ftl_core
	name = "\improper Thirring Drive manifold"
	desc = "The Lense-Thirring Precession Drive, an advanced method of FTL propulsion that utilizes exotic energy to twist space around the ship. Exotic energy must be supplied via drive pylons."
	icon = 'nsv13/icons/obj/machinery/FTL_drive.dmi'
	icon_state = "core_idle"
	pixel_x = -64
	bound_x = -64
	bound_height = 128
	bound_width = 160
	appearance_flags = PIXEL_SCALE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	icon_screen = null
	icon_keyboard = null
	req_access = list(ACCESS_ENGINE_EQUIP)
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	var/tier = 1 // increased tiers increase jump range
	var/faction = "nanotrasen"
	var/link_id = "default"
	var/list/pylons = list() //connected pylons
	var/min_pylons = 1 // min active pylons required to spool drive
	var/active = FALSE // Whether or not we should be charging
	var/progress = 0 // charge progress, 0 to req_charge
	var/can_cancel_jump = TRUE //Defaults to true. TODO: Make emagging disable this
	var/req_charge = 100
	var/cooldown = FALSE
	var/charge_rate = 1 // how much charge is given by each pylon per second
	var/obj/item/radio/radio //For engineering alerts.
	var/radio_key = /obj/item/encryptionkey/headset_eng
	var/radio_channel = "Engineering"
	var/max_range = 30000
	var/jump_speed_factor = 1.5 //How quickly do we jump? Larger is faster.
	var/jump_speed_pylon = 1 // Adds this value onto jump_speed_factor for every active pylon
	var/ftl_startup_time = 32.3 SECONDS // How long does it take to iniate the jump.
	var/ftl_loop = 'nsv13/sound/effects/ship/FTL_loop.ogg'
	var/ftl_start = 'nsv13/sound/effects/ship/FTL_long_thirring.ogg'
	var/ftl_exit = 'nsv13/sound/effects/ship/freespace2/warp_close.wav'
	var/datum/looping_sound/advanced/ftl_drive/soundloop
	var/auto_spool_capable = TRUE // whether the drive is capable of auto spooling or not
	var/auto_spool_enabled = FALSE // whether the drive is set to auto spool or not
	var/lockout = FALSE //Used for our end round shenanigains

	var/ftl_state = FTL_STATE_IDLE

	///world.time until which an user can confirm the emergency jump triggered by Nav.
	var/await_emergency_ftl_confirm = 0

/obj/machinery/computer/ship/ftl_core/Initialize(mapload)
	. = ..()
	add_overlay("screen")
	radio = new(src)
	radio.keyslot = new radio_key
	radio.listening = 0
	radio.recalculateChannels()
	soundloop = new(src, FALSE, FALSE, CHANNEL_FTL_MANIFOLD, TRUE)
	STOP_PROCESSING(SSmachines, src)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/ship/ftl_core/LateInitialize()
	. = ..()
	has_overmap()
	get_pylons()

/obj/machinery/computer/ship/ftl_core/Destroy()
	QDEL_NULL(soundloop)
	QDEL_NULL(radio)
	linked?.ftl_drive = null
	pylons = null
	return ..()

/obj/machinery/computer/ship/ftl_core/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, "<span class='warning'>This equipment should be preserved, it will be a useful resource to our masters in the future. Aborting.</span>")
	S.LoseTarget()
	return FALSE

/// Links with available pylons and returns number of connections
/obj/machinery/computer/ship/ftl_core/proc/get_pylons()
	var/obj/structure/overmap/OMcache = get_overmap()
	if(length(pylons))
		for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
			P.ftl_drive = null
		pylons.len = 0
	for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P in GLOB.machines)
		if(length(pylons) == 4) // No more than 4 pylons
			break
		if(P.get_overmap() == OMcache && get_dist(src, P) <= MAX_PYLON_DISTANCE && link_id == P.link_id && P.is_operational)
			pylons += P
			P.ftl_drive = src

	return length(pylons)

/// Returns the amount of *active* pylons connected to the drive
/obj/machinery/computer/ship/ftl_core/proc/get_active_pylons()
	. = 0
	for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
		if(P.pylon_state != PYLON_STATE_ACTIVE)
			continue
		.++

/obj/machinery/computer/ship/ftl_core/proc/check_pylons()
	if(!length(pylons) && get_pylons() < min_pylons)
		return FALSE
	return TRUE

/obj/machinery/computer/ship/ftl_core/proc/spoolup()
	if(!is_operational || !anchored)
		visible_message("FTL core is damaged or unpowered, startup procedure cancelled.")
		return
	if(cooldown)
		say("FTL core temperature beyond safety limits, please wait for cooldown cycle to complete.")
		return
	if(progress || ftl_state != FTL_STATE_IDLE)
		say("FTL manifold is already active.")
		return
	if(!check_pylons())
		say("You must construct additional pylons.")
		return
	var/active_pylons = 0
	for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
		if(P.pylon_state != PYLON_STATE_ACTIVE)
			continue
		active_pylons++
		if(min_pylons > active_pylons)
			continue
		visible_message("<span class='info'>Core fuel cycle starting.</span>")
		active = TRUE
		START_PROCESSING(SSmachines, src)
		soundloop.start()
		playsound(src, 'nsv13/sound/voice/ftl_spoolup.wav', 100, FALSE)
		radio.talk_into(src, "FTL spoolup initiated.", radio_channel)
		icon_state = "core_active"
		use_power = 500
		return TRUE

	visible_message("<span class='warning'>Insufficient active drive pylons.</span>")


/obj/machinery/computer/ship/ftl_core/process(delta_time)
	if(!active || !is_operational || !anchored || !length(pylons))
		depower()
		return
	if(ftl_state == FTL_STATE_JUMPING)
		return
	var/active_charge = FALSE
	for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
		if(P.pylon_state == PYLON_STATE_ACTIVE)
			progress = min(progress + round(charge_rate * delta_time, 0.1), req_charge)
			active_charge = TRUE
			if(prob(30))
				discharge_pylon(P)
	if(!active_charge && progress > 0)
		progress = min(progress - 1, 0)
		if(progress < req_charge && ftl_state == FTL_STATE_READY)
			cancel_ftl()
	if(ftl_state != FTL_STATE_READY && progress >= req_charge)
		ready_ftl()

/// Visual effect
/obj/machinery/computer/ship/ftl_core/proc/discharge_pylon(atom/P)
	set waitfor = FALSE
	playsound(P, 'nsv13/sound/machines/FTL/FTL_pylon_discharge.ogg', 120, TRUE, 2, 4.5)
	var/atom/target
	if(length(pylons) > 1)
		target = pick(pylons - P)
	else
		target = locate(x + rand(-1, 1), y + 1, z) // Offset to make it hit the "ring" of the sprite, not the console
	sleep(20)
	P.Beam(target, "lightning[rand(1, 12)]")
	playsound(P, 'sound/magic/lightningshock.ogg', 50, 1, 1)

/obj/machinery/computer/ship/ftl_core/attackby(obj/item/I, mob/user)
	. = ..()
	if(istype(I, /obj/item/ftl_slipstream_chip))
		var/obj/item/ftl_slipstream_chip/FI = I
		if(FI.tier > tier)
			playsound(src, 'sound/machines/terminal_insert_disc.ogg', 100, 0)
			to_chat(user, "<span class='notice'>You slot [I] into [src], updating its vector calculation systems.</span>")
			tier = FI.tier
			qdel(FI)
			upgrade()
		else
			to_chat(user, "<span class='notice'>\The [src] has already been upgraded to a higher tier than [FI] can offer.</span>")

/obj/machinery/computer/ship/ftl_core/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == "tier")
		upgrade()

/obj/machinery/computer/ship/ftl_core/proc/upgrade()
	switch(tier)
		if(2)
			name = "upgraded [initial(name)]"
			max_range = initial(max_range) * 2
			jump_speed_factor = 2

		if(3) //Admin only, for now
			name = "advanced [initial(name)]"
			auto_spool_capable = TRUE
			jump_speed_factor = 5
			max_range = initial(max_range) * 3

///Requests emergency FTL, needs manual confirm at the machine itself.
/obj/machinery/computer/ship/ftl_core/proc/request_emergency_ftl_confirm()
	if(await_emergency_ftl_confirm - world.time > 0)
		return
	if(!linked.ftl_safety_override)
		return
	await_emergency_ftl_confirm = world.time + 15 SECONDS
	say("Emergency FTL request signal received from Navigation system. Manual confirmation required.")
	radio.talk_into(src, "Emergency FTL request signal received from Navigation system. Manual confirmation required.", radio_channel)

/*
Preset classes of FTL drive with pre-programmed behaviours
*/

/obj/machinery/computer/ship/ftl_core/preset/Initialize(mapload)
	. = ..()
	upgrade()

/obj/machinery/computer/ship/ftl_core/preset/upgraded
	tier = 2

/obj/machinery/computer/ship/ftl_core/preset/super
	tier = 3

/obj/machinery/computer/ship/ftl_core/syndicate
	name = "syndicate FTL core"
	radio_key = /obj/item/encryptionkey/syndicate
	radio_channel = "Syndicate"
	faction = "syndicate"
	req_access = list(ACCESS_SYNDICATE)

/obj/machinery/computer/ship/ftl_core/mining
	name = "mining FTL core"
	radio_key = /obj/item/encryptionkey/headset_mining
	radio_channel = "Supply"
	req_access = null
	req_one_access_txt = "31;48"

/obj/machinery/computer/ship/ftl_core/set_position(obj/structure/overmap/OM)
	OM.ftl_drive = src

/obj/machinery/computer/ship/ftl_core/attack_hand(mob/user)
	if(!has_overmap())
		to_chat(user, "<span class='warning'>\The [src] can't connect to the ship!<span/>")
		return
	if(!allowed(user))
		var/sound/S = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, S, 100, 1)
		to_chat(user, "<span class='warning'>Access denied.</span>")
		return
	ui_interact(user)

/obj/machinery/computer/ship/ftl_core/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "FTLComputerModular")
	ui.open()
	ui.set_autoupdate(TRUE)

/obj/machinery/computer/ship/ftl_core/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(. || !has_overmap())
		return
	playsound(src, 'nsv13/sound/effects/computer/scroll_start.ogg', 100, 1)
	var/obj/machinery/atmospherics/components/binary/drive_pylon/P = locate(params["id"])
	switch(action)
		if("pylon_power")
			if(!P)
				return
			switch(P.pylon_state)
				if(PYLON_STATE_OFFLINE)
					if(P.try_enable()) // enables it if it passes
						visible_message("<span class='notice'>Pylon power cycle starting.</span>")
					else
						visible_message("<span class='warning'>Pylon power cycle failed, Power source missing.</span>")
				if(PYLON_STATE_SHUTDOWN)
					visible_message("<span class='warning'>Please wait for pylon power cycle to complete before reactivating.</span>")
				else
					P.set_state(PYLON_STATE_SHUTDOWN)
					. = TRUE
		if("toggle_shield")
			if(!P)
				return
			P.toggle_shield()
		if("find_pylons")
			get_pylons()
			. = TRUE

		if("toggle_power")
			if(active)
				depower()
			else
				spoolup()
			. = TRUE
		if("toggle_autospool")
			if(!auto_spool_capable)
				return
			auto_spool_enabled = !auto_spool_enabled
			. = TRUE
		if("emergency_jump")
			. = TRUE
			if(!linked.ftl_safety_override)
				return
			if(world.time < linked.next_emergency_jump)
				say("Failsafe Capacitor still recharging. Emergency transition unavailable.")
				await_emergency_ftl_confirm = 0
				return
			if(world.time > await_emergency_ftl_confirm)
				return
			if(progress / req_charge < 0.25)
				say("FTL not sufficiently spooled for emergency transition. 25% of full charge required.")
				await_emergency_ftl_confirm = 0
				return
			await_emergency_ftl_confirm = 0
			linked.emergency_jump()

/obj/machinery/computer/ship/ftl_core/ui_data(mob/user)
	var/list/data = list()
	data["powered"] = ftl_state != FTL_STATE_IDLE // Yes, we could pass ftl_state into just one data point but then defines break
	data["progress"] = progress
	data["goal"] = req_charge
	data["ready"] = ftl_state == FTL_STATE_READY
	data["jumping"] = ftl_state == FTL_STATE_JUMPING
	var/list/all_pylon_info = list()
	var/count = 0
	for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
		count++
		var/list/pylon_info = list()
		pylon_info["name"] = "Pylon [index2greek(count)]"
		pylon_info["id"] = "\ref[P]"
		pylon_info["status"] = P.pylon_state
		pylon_info["gyro"] = round(P.gyro_speed / P.req_gyro_speed, 0.01)
		pylon_info["capacitor"] = round(P.capacitor / P.req_capacitor, 0.01)
		pylon_info["draw"] = display_power(P.power_draw)
		pylon_info["nucleium"] = round(P.get_nucleium_use() / 2, 0.01) //Converted into mol / second, SSmachines runs every 2 seconds.
		pylon_info["shielded"] = P.shielded
		all_pylon_info[++all_pylon_info.len] = pylon_info // Unfortunately, this is currently the best way to embed lists
	data["pylons"] = all_pylon_info
	data["can_auto_spool"] = auto_spool_capable
	data["auto_spool_enabled"] = auto_spool_enabled
	data["await_emergency_ftl_confirm"] = (await_emergency_ftl_confirm > world.time && linked.ftl_safety_override)
	return data

/obj/machinery/computer/ship/ftl_core/proc/jump(datum/star_system/target_system, force=FALSE, misjump = FALSE)
	ftl_state = FTL_STATE_JUMPING
	if(!target_system)
		radio.talk_into(src, "ERROR. Specified star_system no longer exists.", radio_channel)
		return
	linked.begin_jump(target_system, force, misjump)
	playsound(src, 'nsv13/sound/voice/ftl_start.wav', 100, FALSE)
	radio.talk_into(src, "Initiating FTL translation.", radio_channel)
	playsound(src, 'nsv13/sound/effects/ship/freespace2/computer/escape.wav', 100, 1)
	visible_message("<span class='notice'>Initiating FTL jump.</span>")

/// Begins a jump regardless of whether we have enough fuel or power. Should only be used for debugging and round events
/obj/machinery/computer/ship/ftl_core/proc/force_jump(datum/star_system/target_system)
	use_power = 0
	progress = 0
	icon_state = "core_active"
	jump(target_system, TRUE)

/obj/machinery/computer/ship/ftl_core/proc/ready_ftl()
	playsound(src, 'nsv13/sound/voice/ftl_ready.wav', 100, FALSE)
	radio.talk_into(src, "FTL fuel cycle complete. Ready to commence FTL translation.", radio_channel)
	playsound(src, 'nsv13/sound/effects/ship/freespace2/computer/escape.wav', 100, 1)
	ftl_state = FTL_STATE_READY

/obj/machinery/computer/ship/ftl_core/proc/cancel_ftl()
	ftl_state = FTL_STATE_SPOOLING
	playsound(src, 'nsv13/sound/voice/ftl_cancelled.wav', 100, FALSE)
	radio.talk_into(src, "FTL translation cancelled.", radio_channel)

/obj/machinery/computer/ship/ftl_core/update_icon()
	return //Override computer updates

/obj/machinery/computer/ship/ftl_core/proc/depower(shutdown_pylons = TRUE)
	use_power = 50
	active = FALSE
	ftl_state = FTL_STATE_IDLE
	icon_state = "core_idle"
	if(progress <= 0)
		return FALSE
	progress = 0
	soundloop.interrupt()
	jump_speed_pylon = initial(jump_speed_pylon)
	if(shutdown_pylons && !auto_spool_enabled)
		for(var/obj/machinery/atmospherics/components/binary/drive_pylon/P as() in pylons)
			if(P.pylon_state == PYLON_STATE_OFFLINE || P.pylon_state == PYLON_STATE_SHUTDOWN)
				continue
			P.set_state(PYLON_STATE_SHUTDOWN)
	cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(post_cooldown), auto_spool_enabled), FTL_COOLDOWN)
	STOP_PROCESSING(SSmachines, src)
	return TRUE

/// Handles auto-spooling and cooldown resetting, called after cooldown duration
/obj/machinery/computer/ship/ftl_core/proc/post_cooldown(spool)
	cooldown = FALSE
	if(spool)
		active = TRUE
		spoolup()

/obj/machinery/computer/ship/ftl_core/proc/get_jump_speed()
	return jump_speed_factor * (jump_speed_pylon * get_active_pylons())

#undef FTL_COOLDOWN
#undef MAX_PYLON_DISTANCE
