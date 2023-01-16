/obj/machinery/ship_weapon/plasma_caster
	name = "\improper Magnetic Phoron 'Vintergatan' Acceleration Caster"
	icon = 'nsv13/icons/obj/railgun.dmi' //Temp Sprite
	icon_state = "OBC" //Temp Sprite
	desc = "Retrieve the lamp, Torch, for the Dominion, and the Light!"
	anchored = TRUE

	density = TRUE
	safety = FALSE //Set to true when we have a working UI for the weapon

	bound_width = 128
	bound_height = 32
	ammo_type = /obj/item/stack/sheet/mineral/plasma/twenty
	circuit = /obj/item/circuitboard/machine/plasma_caster

	fire_mode = FIRE_MODE_PHORON

	auto_load = TRUE
	semi_auto = TRUE
	maintainable = TRUE
	max_ammo = 1
	feeding_sound = 'nsv13/sound/effects/ship/freespace2/m_load.wav' //TEMP, CHANGE LATER
	fed_sound = null //TEMP, CHANGE LATER
	chamber_sound = null //TEMP, CHANGE LATER

	load_delay = 20
	unload_delay = 20
	fire_animation_length = 10 SECONDS //Maybe? We'll see how I feel about a long firing animations.

	feed_delay = 0
	chamber_delay_rapid = 0
	chamber_delay = 0
	bang = FALSE

	var/obj/machinery/atmospherics/components/unary/plasma_loader/loader
	var/plasma_fire_moles = 250 //TEMPORARY PROBABLY
	var/plasma_mole_amount = 0 //How much plasma gas is in the gun
	var/alignment = 100 //Stealing this from hybrid railguns

/obj/machinery/ship_weapon/plasma_caster/Initialize(mapload)
	. = ..()
	loader = locate(/obj/machinery/atmospherics/components/unary/plasma_loader) in orange(1, src)
	loader.linked_gun = src

/obj/machinery/ship_weapon/plasma_caster/can_fire(shots = weapon_type.burst_size)
	if((state < STATE_CHAMBERED) || !chambered)
		return FALSE
	if(state >= STATE_FIRING)
		return FALSE
	if(ammo?.len < shots) //Do we have ammo?
		return FALSE
	if(maintainable && malfunction) //Do we need maintenance?
		return FALSE
	if(plasma_mole_amount < plasma_fire_moles) //Is there enough Plasma Gas to fire?
		return FALSE
	if(alignment < 90)
		if(prob(25))
			misfire()
			return FALSE
	else
		return TRUE

/obj/machinery/ship_weapon/plasma_caster/proc/misfire()
	if(prob(25))
		do_sparks(4, FALSE, src)
	atmos_spawn_air("plasma=[plasma_mole_amount]")

/obj/machinery/ship_weapon/plasma_caster/after_fire()
	alignment -= rand(5,60)
	..()

/obj/machinery/ship_weapon/plasma_caster/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlasmaGun")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/ship_weapon/plasma_caster/ui_data(mob/user)
	. = ..()
	var/list/data = list()
	data["alignment"] = alignment
	data["plasma_moles"] = plasma_mole_amount
	data["plasma_moles_max"] = plasma_fire_moles
	data["safety"] = safety
	data["loaded"] = (state > STATE_LOADED) ? TRUE : FALSE
	return data

/obj/machinery/ship_weapon/plasma_caster/ui_act(action, params)
    if(..())
        return
    var/adjust = text2num(params["adjust"])
    switch(action)
        if("capacitor_current_charge_rate")
            //capacitor_current_charge_rate = adjust
            active_power_usage = adjust
        if("toggle_load")
            if(state == STATE_LOADED)
                feed()
            else
                unload()
        if("chamber")
            chamber()
        if("toggle_safety")
            toggle_safety()
        if("switch_type")
            //if(switching)
            //    to_chat(usr, "<span class='notice'>Error: Unable to comply, action already in process.</span>")
            //    return
            if(ammo.len == 0)
                to_chat(usr, "<span class='notice'>Action queued: Cycling ordnance chamber configuration.</span>")
            //    switching = TRUE
                playsound(src, 'nsv13/sound/effects/ship/mac_hold.ogg', 100)
            //    addtimer(CALLBACK(src, .proc/switch_munition), 10 SECONDS)
            else
                to_chat(usr, "<span class='notice'>Error: Unable to alter selected ordnance type, eject loaded munitions.</span>")
    return

/obj/machinery/atmospherics/components/unary/plasma_loader
	name = "phoron gas regulator"
	desc = "The gas regulator that pumps gaseous phoron into the Plasma Caster"
	icon = 'nsv13/icons/obj/machinery/reactor_parts.dmi' //Temp Sprite
	icon_state = "constrictor" //Temp Sprite
	pixel_y = 5 //So it lines up with layer 3 piping
	layer = OBJ_LAYER
	density = FALSE //Change to True when done testing
	dir = WEST
	initialize_directions = WEST
	pipe_flags = PIPING_ONE_PER_TURF
	active_power_usage = 200
	var/obj/machinery/ship_weapon/plasma_caster/linked_gun

/obj/machinery/atmospherics/components/unary/plasma_loader/on_construction()
	var/obj/item/circuitboard/machine/thermomachine/board = circuit
	if(board)
		piping_layer = board.pipe_layer
	..(dir, piping_layer)

/obj/machinery/atmospherics/components/unary/plasma_loader/attack_hand(mob/user)
	. = ..()
	if(panel_open)
		to_chat(user, "<span class='notice'>You must turn close the panel on [src] before turning it on.</span>")
		return
	to_chat(user, "<span class='notice'>You press [src]'s power button.</span>")
	on = !on
	update_icon()

//TEMPORARY
/obj/machinery/atmospherics/components/unary/plasma_loader/update_icon()
	cut_overlays()
	if(panel_open)
		icon_state = "constrictor_screw"
	else if(on)
		icon_state = "constrictor_active"
	else
		icon_state = "constrictor"

/obj/machinery/atmospherics/components/unary/plasma_loader/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation,ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS )

/obj/machinery/atmospherics/components/unary/plasma_loader/process_atmos()
	..()
	if(!on)
		return
	if(!linked_gun)
		return

	var/datum/gas_mixture/air1 = airs[1]
	if(air1.get_moles(GAS_PLASMA) > 5 && linked_gun.plasma_mole_amount < linked_gun.plasma_fire_moles)
		air1.adjust_moles(GAS_PLASMA, -5)
		linked_gun.plasma_mole_amount += 5

	update_parents()

/obj/item/circuitboard/machine/plasma_loader
	name = "Phoron Gas Regulator (Machine Board)"
	build_path = /obj/machinery/atmospherics/components/unary/plasma_loader
	var/pipe_layer = PIPING_LAYER_DEFAULT
	req_components = list(
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/manipulator = 1)


/obj/item/circuitboard/machine/plasma_caster
	name = "circuit board (plasma caster)"
	desc = "My faithful...stand firm!"
	req_components = list(
		/obj/item/stack/sheet/mineral/titanium = 50,
		/obj/item/stack/sheet/iron = 100,
		/obj/item/stack/sheet/mineral/uranium = 20,
		/obj/item/stock_parts/manipulator = 10,
		/obj/item/stock_parts/capacitor = 10,
		/obj/item/stock_parts/matter_bin = 10,
		/obj/item/assembly/igniter = 1,
		/obj/item/ship_weapon/parts/firing_electronics = 1
	)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	build_path = /obj/machinery/ship_weapon/plasma_caster

/datum/ship_weapon/plasma_caster
	name = "MPAC"
	burst_size = 1
	fire_delay = 1 SECONDS //Change to 180 SECONDS when done testing
	range_modifier = 10 //Check what this changes
	default_projectile_type = /obj/item/projectile/bullet/plasma_caster
	select_alert = "<span class='notice'>Charging magnetic accelerator...</span>"
	failure_alert = "<span class='warning'>Magnetic Accelerator not ready!</span>"
	overmap_firing_sounds = list('nsv13/sound/effects/ship/broadside.ogg') //Make custom sound, thgwop
	overmap_select_sound = 'nsv13/sound/effects/ship/mac_load_unjam.ogg' //Make custom sound, charging maybe?
	weapon_class = WEAPON_CLASS_HEAVY
	ai_fire_delay = 180 SECONDS
	allowed_roles = OVERMAP_USER_ROLE_GUNNER

/obj/item/projectile/bullet/plasma_caster
	name = "plasma ball"
	icon = 'nsv13/icons/obj/projectiles_nsv.dmi'
	icon_state = "plasma_ball" //Really bad test sprite, animate and globulate later
	homing = TRUE
	homing_turn_speed = 60
	damage = 150
	obj_integrity = 500
	flag = "overmap_heavy"
	speed = 40
	projectile_piercing = ALL

//For FIRE proc, make animation play FIRST, prob with sleep proc
