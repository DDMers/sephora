// Old, simplified magic FTL computers.
// Mappers should use modular drives instead where possible
// Kept in the game for the sake of compatability and smaller ships.

/obj/machinery/computer/ship/ftl_computer
	name = "\improper Seegson FTL drive computer"
	desc = "A supercomputer which is capable of calculating incalculably complex vectors which are interpreted into a simplified 4-dimensional course through which ships are able to travel. It takes some time to spool up between uses"
	icon = 'nsv13/goonstation/icons/ftlcomp.dmi'
	icon_state = "ftl_off"
	bound_height = 96
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	icon_screen = null
	icon_keyboard = null
	req_access = list(ACCESS_ENGINE_EQUIP)
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	var/tier = 1
	var/faction = "nanotrasen" //For ship tracking. The tracking feature of the FTL compy is entirely so that antagonists can hunt the NT ships down
	var/jump_speed_factor = 3.5 //How quickly do we jump? Larger is faster.
	var/ftl_state = FTL_STATE_IDLE //Mr Gaeta, spool up the FTLs.
	var/obj/item/radio/radio //For engineering alerts.
	var/radio_key = /obj/item/encryptionkey/headset_eng
	var/radio_channel = "Engineering"
	var/active = FALSE
	var/progress = 0 SECONDS
	var/progress_rate = 1 SECONDS
	var/spoolup_time = 45 SECONDS //Make sure this is always longer than the ftl_startup_time, or you can seriously bug the ship out with cancel jump spam.
	var/screen = 1
	var/can_cancel_jump = TRUE //Defaults to true. TODO: Make emagging disable this
	var/max_range = 30000 //max jump range. This is _very_ long distance
	var/list/tracking = list() //What ships are we tracking, if any? Used for antag FTLs so they can always find you.
	var/ftl_loop = 'nsv13/sound/effects/ship/FTL_loop.ogg'
	var/ftl_start = 'nsv13/sound/effects/ship/FTL_long.ogg'
	var/ftl_exit = 'nsv13/sound/effects/ship/freespace2/warp_close.wav'
	var/ftl_startup_time = 30 SECONDS
	var/auto_spool_enabled = FALSE //For lazy admins
	var/lockout = FALSE //Used for our end round shenanigains

	///world.time until which an user can confirm the emergency jump triggered by Nav.
	var/await_emergency_ftl_confirm = 0

/obj/machinery/computer/ship/ftl_computer/attackby(obj/item/I, mob/user) //Allows you to upgrade dradis consoles to show asteroids, as well as revealing more valuable ones.
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
			to_chat(user, "<span class='notice'>[src] has already been upgraded to a higher tier than [FI] can offer.</span>")

/obj/machinery/computer/ship/ftl_computer/swarmer_act(mob/living/simple_animal/hostile/swarmer/S)
	to_chat(S, "<span class='warning'>This equipment should be preserved, it will be a useful resource to our masters in the future. Aborting.</span>")
	S.LoseTarget()
	return FALSE

/obj/machinery/computer/ship/ftl_computer/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == "tier")
		upgrade()

/obj/machinery/computer/ship/ftl_computer/proc/upgrade()
	switch(tier)
		if(1)
			return
		if(2)
			name = "quantum slipstream drive computer"
			desc = "A supercomputer using absolutely cutting edge wormhole research. It is able to project a streamlined field of constrained wormhole particles to cut through bluespace cleanly. This drive eliminates the lengthy FTL charge up process, and can see a ship jump almost instantaneously, after it generates a suitable wormhole."
			ftl_loop = 'nsv13/sound/effects/ship/slipstream.ogg'
			ftl_start = 'nsv13/sound/effects/ship/slipstream_start.ogg'
			ftl_startup_time = 6 SECONDS
			spoolup_time = 30 SECONDS
			jump_speed_factor = 5

		if(3) //Admin only so I can test things more easily, or maybe dropped from an EXTREMELY RARE, copyright free ruin.
			name = "warp drive computer"
			desc = "A computer that is impossibly advanced for this time period. It uses unknown technology harvested by unknown means to accelerate a starship to unheard of speeds. Ardata operatives have as yet been unable to ascertain how it functions, but field testing shows that this eliminates the need for spooling entirely in favour of distorting space."
			ftl_loop = 'nsv13/sound/effects/ship/warp_loop.ogg'
			ftl_start = 'nsv13/sound/effects/ship/warp.ogg'
			ftl_exit = 'nsv13/sound/effects/ship/warp_exit.ogg'
			ftl_startup_time = 5 SECONDS
			spoolup_time = 10 SECONDS
			auto_spool_enabled = TRUE
			jump_speed_factor = 10

	max_range = initial(max_range) * 2
/*
Preset classes of FTL drive with pre-programmed behaviours
*/

/obj/machinery/computer/ship/ftl_computer/preset/Initialize(mapload)
	. = ..()
	upgrade()

/obj/machinery/computer/ship/ftl_computer/preset/slipstream
	tier = 2

/obj/machinery/computer/ship/ftl_computer/preset/warp
	tier = 3

/obj/machinery/computer/ship/ftl_computer/syndicate
	name = "\improper Syndicate FTL computer"
//	jump_speed_factor = 2 //Twice as fast as NT's shit so they can hunt the ship down or get ahead of them to set up an ambush of raptors
	radio_key = /obj/item/encryptionkey/syndicate
	radio_channel = "Syndicate"
	faction = "syndicate"
	req_access = list(ACCESS_SYNDICATE)

/obj/machinery/computer/ship/ftl_computer/mining
	name = "mining FTL computer"
	radio_key = /obj/item/encryptionkey/headset_mining
	radio_channel = "Supply"
	req_access = null
	req_one_access_txt = "31;48"

/obj/machinery/computer/ship/ftl_computer/Initialize(mapload)
	. = ..()
	start_monitoring(get_overmap()) //I'm a lazy hack that can't actually be assed to deal with an if statement in react right now.

/obj/machinery/computer/ship/ftl_computer/syndicate/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/ship/ftl_computer/syndicate/LateInitialize(mapload)
	. = ..()
	for(var/obj/structure/overmap/OM as() in GLOB.overmap_objects) //Needs to go through global list due to filtering for any ship with importants not just the one main ship.
		if(OM.role > NORMAL_OVERMAP && OM.faction != faction)
			start_monitoring(OM)

//Tell the FTL computer to start tracking a ship, regardless of how far apart you both are.
/obj/machinery/computer/ship/ftl_computer/proc/start_monitoring(obj/structure/overmap/OM)
	tracking[OM] = list("ship" = OM, "name" = OM.name, "current_system" = OM.starting_system, "target_system" = null)
	RegisterSignal(OM, COMSIG_FTL_STATE_CHANGE, PROC_REF(announce_jump))

/*
A way for syndies to track where the player ship is going in advance, so they can get ahead of them and hunt them down.
*/

/obj/machinery/computer/ship/ftl_computer/proc/announce_jump()
	radio.talk_into(src, "TRACKING: FTL signature detected. Tracking information updated.",radio_channel)
	for(var/list/L in tracking)
		var/obj/structure/overmap/target = L["ship"]
		var/datum/star_system/target_system = SSstar_system.ships[target]["target_system"]
		var/datum/star_system/current_system = SSstar_system.ships[target]["current_system"]
		tracking[target] = list("name" = target.name, "current_system" = current_system.name, "target_system" = target_system.name)

/obj/machinery/computer/ship/ftl_computer/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(has_overmap)), 5 SECONDS)
	STOP_PROCESSING(SSmachines, src)

/obj/machinery/computer/ship/ftl_computer/process()
	if(!is_operational)
		depower()
		return
	if(progress < spoolup_time)
		icon_state = "ftl_charging"
		use_power = 500 //Eats up a fuckload of power as it takes 2 minutes to spool up.
		progress += progress_rate
		ftl_state = FTL_STATE_SPOOLING
		return
	else
		ready_ftl()
		use_power = 300 //Keeping the FTL spooled requires a fair bit of power
		return PROCESS_KILL

/obj/machinery/computer/ship/ftl_computer/has_overmap()
	. = ..()
	if(linked)
		linked.ftl_drive = src

/obj/machinery/computer/ship/ftl_computer/attack_hand(mob/user)
	if(!has_overmap())
		return
	if(!allowed(user))
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Access denied</span>")
		return
	ui_interact(user)

/obj/machinery/computer/ship/ftl_computer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FTLComputer")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/ship/ftl_computer/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(!has_overmap())
		return
	playsound(src, 'nsv13/sound/effects/computer/scroll_start.ogg', 100, 1)
	switch(action)
		if("toggle_power")
			active = !active
			ftl_state = FTL_STATE_IDLE
			progress = 0
			check_active(active)
		if("show_tracking")
			screen = 2
		if("go_back")
			screen = 1
		if("jump")
			if(ftl_state != FTL_STATE_READY)
				visible_message("<span class='warning'>[icon2html(src, viewers(src))] Unable to comply. FTL vector calculation still in progress. 'Blind' FTL jumps are prohibited by the system administrative policy.</span>")
				return
			var/target_name = params["target"]
			for(var/datum/star_system/S in SSstar_system.systems)
				if(S.visitable && S.name == target_name)
					jump(S)
					check_active(FALSE)
					break
		if("emergency_jump")
			. = TRUE
			if(!linked.ftl_safety_override)
				return
			if(world.time > await_emergency_ftl_confirm)
				return
			if(world.time < linked.next_emergency_jump)
				say("Failsafe Capacitor still recharging. Emergency transition unavailable.")
				await_emergency_ftl_confirm = 0
				return
			if(progress / spoolup_time < 0.25)
				say("FTL not sufficiently spooled for emergency transition. 25% of full charge required.")
				await_emergency_ftl_confirm = 0
				return
			await_emergency_ftl_confirm = 0
			linked.emergency_jump()

/obj/machinery/computer/ship/ftl_computer/ui_data(mob/user)
	var/list/data = list()
	data["powered"] = active
	data["progress"] = progress
	data["goal"] = spoolup_time
	data["ready"] = (ftl_state == FTL_STATE_READY) ? TRUE : FALSE
	data["mode"] = screen
	data["systems"] = list()
	var/list/ships = list()
	for(var/X in tracking)
		var/list/ship_info = list()
		ship_info["name"] = tracking[X]["name"]
		ship_info["current_system"] = tracking[X]["current_system"]
		ship_info["target_system"] = tracking[X]["target_system"]
		ships[++ships.len] = ship_info
	data["tracking"] = ships
	for(var/datum/star_system/S in SSstar_system.systems)
		if(S.visitable && S != linked.current_system)
			data["systems"] += list(list("name" = S.name, "distance" = "2 minutes"))
	data["await_emergency_ftl_confirm"] = (await_emergency_ftl_confirm > world.time && linked.ftl_safety_override)
	return data

/obj/machinery/computer/ship/ftl_computer/proc/check_active(state)
	if(state)
		spoolup()
		START_PROCESSING(SSmachines, src)
	else
		depower()
		STOP_PROCESSING(SSmachines, src)

/obj/machinery/computer/ship/ftl_computer/proc/jump(datum/star_system/target_system, force=FALSE, misjump = FALSE)
	if(!target_system)
		radio.talk_into(src, "ERROR. Specified star_system no longer exists.", radio_channel)
		return
	linked?.begin_jump(target_system, force, misjump)
	playsound(src, 'nsv13/sound/voice/ftl_start.wav', 100, FALSE)
	radio.talk_into(src, "Initiating FTL translation.", radio_channel)
	playsound(src, 'nsv13/sound/effects/ship/freespace2/computer/escape.wav', 100, 1)
	visible_message("<span class='notice'>Initiating FTL jump.</span>")
	ftl_state = FTL_STATE_JUMPING

/// Begins a jump regardless of whether we have enough fuel or power. Should only be used for debugging and round events
/obj/machinery/computer/ship/ftl_computer/proc/force_jump(datum/star_system/target_system)
	ftl_state = FTL_STATE_READY //force it all to be ready
	use_power = 0
	progress = 0
	jump(target_system, TRUE)

/obj/machinery/computer/ship/ftl_computer/proc/ready_ftl()
	ftl_state = FTL_STATE_READY
	icon_state = "ftl_ready"
	playsound(src, 'nsv13/sound/voice/ftl_ready.wav', 100, FALSE)
	radio.talk_into(src, "FTL vectors calculated. Ready to commence FTL translation.", radio_channel)
	playsound(src, 'nsv13/sound/effects/ship/freespace2/computer/escape.wav', 100, 1)

/obj/machinery/computer/ship/ftl_computer/proc/spoolup()
	if(ftl_state == FTL_STATE_IDLE)
		playsound(src, 'nsv13/sound/effects/computer/hum3.ogg', 100, 1)
		playsound(src, 'nsv13/sound/voice/ftl_spoolup.wav', 100, FALSE)
		radio.talk_into(src, "FTL spoolup initiated.", radio_channel)
		icon_state = "ftl_charging"
		ftl_state = FTL_STATE_SPOOLING

/obj/machinery/computer/ship/ftl_computer/proc/cancel_ftl()
	if(depower())
		playsound(src, 'nsv13/sound/voice/ftl_cancelled.wav', 100, FALSE)
		radio.talk_into(src, "FTL translation cancelled.", radio_channel)
		return TRUE
	return FALSE


/obj/machinery/computer/ship/ftl_computer/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.listening = 0
	radio.recalculateChannels()

/obj/machinery/computer/ship/ftl_computer/update_icon()
	return //Override computer updates

/obj/machinery/computer/ship/ftl_computer/proc/depower()
	if(ftl_state > FTL_STATE_IDLE)
		var/list/timers = active_timers
		active_timers = null
		for(var/thing in timers)
			var/datum/timedevent/timer = thing
			if (timer.spent)
				continue
			qdel(timer)
		active = FALSE
		icon_state = "ftl_off"
		ftl_state = FTL_STATE_IDLE
		progress = 0
		use_power = 0
		if(auto_spool_enabled)
			active = TRUE
			spoolup()
			if(!(datum_flags & DF_ISPROCESSING))
				START_PROCESSING(SSmachines, src)
		else if(datum_flags & DF_ISPROCESSING)
			STOP_PROCESSING(SSmachines, src)
		return TRUE
	return FALSE

/obj/machinery/computer/ship/ftl_computer/proc/get_jump_speed()
	return jump_speed_factor

///Requests emergency FTL, needs manual confirm at the machine itself.
/obj/machinery/computer/ship/ftl_computer/proc/request_emergency_ftl_confirm()
	if(await_emergency_ftl_confirm - world.time > 0)
		return
	if(!linked.ftl_safety_override)
		return
	await_emergency_ftl_confirm = world.time + 15 SECONDS
	say("Emergency FTL request signal received from Navigation system. Manual confirmation required.")
	radio.talk_into(src, "Emergency FTL request signal received from Navigation system. Manual confirmation required.", radio_channel)
