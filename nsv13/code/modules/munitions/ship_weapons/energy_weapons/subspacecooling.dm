/obj/machinery/cooling
	name = "subspace cooling unit"
	desc = "A cooling unit that dumps the massive amounts of heat energy weapons generate into subspace."
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"
	circuit = /obj/item/circuitboard/machine/cooling
	bound_width = 32
	pixel_x = -32
	pixel_y = -32
	idle_power_usage =  2000
	var/obj/machinery/ship_weapon/energy/parent
	var/function = "heat"
	var/on = FALSE

/obj/item/circuitboard/machine/cooling
	name = "subspace cooling unit circuit board"
	icon = 'icons/obj/module.dmi'
	icon_state = "command"
	materials = list(/datum/material/glass=1000)
	w_class = WEIGHT_CLASS_SMALL

/obj/item/circuitboard/machine/cooling/storage
	name = "subspace heatsink unit circuit board"
	icon = 'icons/obj/module.dmi'
	icon_state = "command"
	materials = list(/datum/material/glass=1000)
	w_class = WEIGHT_CLASS_SMALL

/obj/machinery/cooling/Initialize(mapload)
	.= ..()
	parent = locate(/obj/machinery/ship_weapon/energy) in orange(1, src)

/obj/machinery/cooling/process(delta_time)
	.= ..()
	if(!on)
		return
	if(!parent)
		return
	if(parent.[function] > 0)
		parent.[function] = max(parent.[function]-50, 0)
	update_icon()


/obj/machinery/cooling/attack_hand(mob/user)
	. = ..()
	if(panel_open)
		to_chat(user, "<span class='notice'>You must turn close the panel on [src] before turning it on.</span>")
		return
	to_chat(user, "<span class='notice'>You press [src]'s power button.</span>")
	on = !on
	update_icon()

/*/obj/machinery/cooling/update_icon()
	cut_overlays()
	if(panel_open)
		icon_state = "plasma_condenser_screw"
	else if(on)
		icon_state = "plasma_condenser_active"
	else
		icon_state = "plasma_condenser"


/obj/machinery/cooling/multitool_act(mob/living/user, obj/item/I)
		if(!multitool_check_buffer(user, I))
			return
		var/obj/item/multitool/P = I

		if(istype(P.buffer, /obj/machinery/ship_weapon/energy))
			if(get_area(P.buffer) != get_area(src))
				to_chat(user, "<font color = #666633>-% Cannot link machines across power zones. %-</font color>")
				return
			to_chat(user, "<font color = #666633>-% Successfully linked [P.buffer] with [src] %-</font color>")
			parent = P.buffer
			parent.console = src
		return

*/

/obj/machinery/cooling/storage
	name = "subspace heatsink unit"
	desc = "A cooling unit that stores the massive amounts of heat energy weapons generate in subspace."
	icon_state = "smes"
	circuit = /obj/item/circuitboard/machine/cooling/storage
	function = "max_heat"


