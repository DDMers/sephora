/obj/machinery/atmospherics/components/unary/plasma_loader
	name = "phoron gas regulator"
	desc = "The gas regulator that pumps gaseous phoron into the Phoron Caster"
	icon = 'nsv13/icons/obj/machinery/reactor_parts.dmi'
	icon_state = "plasma_condenser"
	pixel_y = 5 //So it lines up with layer 3 piping
	layer = OBJ_LAYER
	density = TRUE
	dir = WEST
	initialize_directions = WEST
	pipe_flags = PIPING_ONE_PER_TURF
	active_power_usage = 200
	var/obj/machinery/ship_weapon/plasma_caster/linked_gun
	var/non_phoron = FALSE
	var/heretical_gases = list(
		GAS_CO2,
		GAS_BZ,
		GAS_O2,
		GAS_N2,
		GAS_H2O,
		GAS_HYPERNOB,
		GAS_NITROUS,
		GAS_TRITIUM,
		GAS_NITRYL,
		GAS_STIMULUM,
		GAS_PLUOXIUM,
		GAS_CONSTRICTED_PLASMA,
		GAS_NUCLEIUM,
	)

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

/obj/machinery/atmospherics/components/unary/plasma_loader/update_icon()
	cut_overlays()
	if(panel_open)
		icon_state = "plasma_condenser_screw"
	else if(on)
		icon_state = "plasma_condenser_active"
	else
		icon_state = "plasma_condenser"

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
	var/datum/gas_mixture/environment = loc.return_air()

	if(air1.get_moles(GAS_PLASMA) > 5 && linked_gun.plasma_mole_amount < linked_gun.plasma_fire_moles)
		air1.adjust_moles(GAS_PLASMA, -5)
		linked_gun.plasma_mole_amount += 5
	for(var/gas in heretical_gases)
		if(air1.get_moles(gas))
			var/air1_pressure = air1.return_pressure()

			var/transfer_moles = air1_pressure*environment.return_volume()/(air1.return_temperature() * R_IDEAL_GAS_EQUATION)
			loc.assume_air_moles(air1, transfer_moles)
			air_update_turf()

			non_phoron = TRUE //Stop putting suggestive variables in my code BOBBANZ1!

	if(non_phoron)
		say("Non-Phoron gas detected! Venting gas!") //BURN THEM ALL
		on = !on
		update_icon()
		non_phoron = FALSE
	update_parents()
