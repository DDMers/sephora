
////// Magnetic Constrictors//////

/obj/machinery/atmospherics/components/binary/magnetic_constrictor //This heats the plasma up to acceptable levels for use in the reactor.
	name = "magnetic constrictor"
	desc = "A large magnet which is capable of pressurizing plasma into a more energetic state. It is able to self-regulate its plasma input valve, as long as plasma is supplied to it."
	icon = 'nsv13/icons/obj/machinery/reactor_parts.dmi'
	icon_state = "constrictor"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/magnetic_constrictor
	layer = OBJ_LAYER
	pipe_flags = PIPING_ONE_PER_TURF
	active_power_usage = 200
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT | INTERACT_MACHINE_ALLOW_SILICON
	var/emagged = FALSE
	var/constriction_rate = 0 //SSAtmos is 4x faster than SSMachines aka the reactor
	var/max_output_pressure = 0

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/on_construction()
	var/obj/item/circuitboard/machine/thermomachine/board = circuit
	if(board)
		piping_layer = board.pipe_layer
	..(dir, piping_layer)

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/RefreshParts()
	var/A
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		A += C.rating
	constriction_rate = 0.9 + (0.1 * A)
	var/B
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		B += M.rating
	max_output_pressure = 100 + (100 * B)

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/interact(mob/user)
	if(!can_interact(user))
		return
	to_chat(user, "<span class='notice'>You turn on \the [src].</span>")
	on = !on
	update_icon()

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/process_atmos()
	..()
	if(!on)
		return
	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/output_starting_pressure = air2.return_pressure()
	if(output_starting_pressure >= max_output_pressure)
		return
	var/plasma_moles = air1.get_moles(GAS_PLASMA)
	var/plasma_transfer_moles = min(constriction_rate, plasma_moles)
	var/plasma_temperature = air1.return_temperature()
	if(!plasma_moles)
		return

	var/plasma_threshold
	if(emagged) //Something's not right...
		plasma_transfer_moles -= 0.1
		if(plasma_transfer_moles > 0)
			var/turf/open/T = isopenturf(get_turf(src)) ? get_turf(src) : null
			if(T)
				plasma_threshold = TRUE
				T.air.adjust_moles_temp(GAS_CONSTRICTED_PLASMA, 0.1, plasma_temperature)
			else
				plasma_transfer_moles += 0.1
		else
			plasma_transfer_moles += 0.1

	air2.adjust_moles_temp(GAS_CONSTRICTED_PLASMA, plasma_transfer_moles, plasma_temperature)

	if(emagged && plasma_threshold) //Still remove the proper amount of plasma
		plasma_transfer_moles += 0.1
		plasma_threshold = FALSE

	air1.adjust_moles(GAS_PLASMA, -plasma_transfer_moles)
	update_parents()

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/crowbar_act(mob/user, obj/item/I)
	default_deconstruction_crowbar(I)
	return TRUE

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/screwdriver_act(mob/user, obj/item/I)
	if(..())
		return TRUE
	if(on)
		to_chat(user, "<span class='notice'>You must turn off [src] before opening the panel.</span>")
		return FALSE
	panel_open = !panel_open
	I.play_tool_sound(src)
	to_chat(user, "<span class='notice'>You [panel_open?"open":"close"] the panel on [src].</span>")
	update_icon()
	return TRUE

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/wrench_act(mob/user, obj/item/I)
	if(default_change_direction_wrench(user, I) && panel_open)
		I.play_tool_sound(src)
		var/obj/machinery/atmospherics/node1 = nodes[1]
		var/obj/machinery/atmospherics/node2 = nodes[2]
		if(node2)
			node2.disconnect(src)
			nodes[2] = null
			nullify_pipenet(parents[2])
		if(node1)
			node1.disconnect(src)
			nodes[1] = null
			nullify_pipenet(parents[1])

		set_init_directions()
		atmos_init()
		node1 = nodes[1]
		if(node1)
			node1.atmos_init()
			node1.add_member(src)
		node2 = nodes[2]
		if(node2)
			node2.atmos_init()
			node2.add_member(src)
		SSair.add_to_rebuild_queue(src)
		update_icon(TRUE)
	return TRUE

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/update_icon()
	cut_overlays()
	if(panel_open)
		icon_state = "constrictor_screw"
	else if(on)
		icon_state = "constrictor_active"
	else
		icon_state = "constrictor"
	pixel_y = 0
	pixel_x = 0
	PIPING_LAYER_SHIFT(src, piping_layer)

/obj/machinery/atmospherics/components/binary/magnetic_constrictor/emag_act(mob/user)
	obj_flags |= EMAGGED
	emagged = TRUE
	to_chat(user, "<span class='notice'>You overload [src]'s hydraulics.</span>")
	audible_message("<span class='warning'>\The [src] makes a mechanical sound.</span>")
	visible_message("<span class='warning'>Some bolts fall off \the [src]!</span>")
	log_combat(user, src, "emagged")

/obj/item/circuitboard/machine/magnetic_constrictor
	name = "Magnetic Constrictor (Machine Board)"
	build_path = /obj/machinery/atmospherics/components/binary/magnetic_constrictor
	var/pipe_layer = PIPING_LAYER_DEFAULT
	req_components = list(
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/manipulator = 1)

/obj/item/circuitboard/machine/magnetic_constrictor/multitool_act(mob/living/user, obj/item/I)
	. = ..()
	if(I.tool_behaviour == TOOL_MULTITOOL)
		pipe_layer = (pipe_layer >= PIPING_LAYER_MAX) ? PIPING_LAYER_MIN : (pipe_layer + 1)
		to_chat(user, "<span class='notice'>You change the circuitboard to layer [pipe_layer].</span>")

/datum/design/board/magnetic_constrictor
	name = "Machine Design (Magnetic Constrictor Board)"
	desc = "The circuit board for a Magnetic Constrictor."
	id = "mag_cons"
	build_path = /obj/item/circuitboard/machine/magnetic_constrictor
	category = list("Engineering Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING
