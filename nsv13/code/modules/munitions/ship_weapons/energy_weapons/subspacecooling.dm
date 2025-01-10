/obj/machinery/cooling
	name = "subspace unit"
	desc = "A subspace unit."
	icon = 'nsv13/icons/obj/subspace.dmi'
	icon_state = "cooler"
	bound_width = 32
	pixel_x = 0
	pixel_y = 0
	idle_power_usage =  2000
	var/obj/machinery/ship_weapon/energy/parent
	var/on = FALSE
	density = TRUE

/obj/machinery/cooling/cooler
	name = "subspace cooling unit"
	desc = "A cooling unit that dumps the massive amounts of heat energy weapons generate into subspace."
	circuit = /obj/item/circuitboard/machine/cooling



/obj/machinery/cooling/Destroy()
	if(parent)
		parent.cooling -= src
  . = ..()


/obj/machinery/cooling/attack_hand(mob/user)
	. = ..()
	if(panel_open)
		to_chat(user, "<span class='notice'>You must turn close the panel on [src] before turning it on.</span>")
		return
	to_chat(user, "<span class='notice'>You press [src]'s power button.</span>")
	on = !on
	update_icon()

/obj/machinery/cooling/examine()
	. = ..()
	if(on)
		. += "The power is on"

	if(!on)
		. += "The power is off"

	if(parent)
		. += "The thermal transcever is linked"

	if(!parent)
		. += "The thermal transcever is waiting for pairing"


/obj/machinery/cooling/update_icon()
	cut_overlays()
	if(panel_open)
//		icon_state = "smes-o"
	if(on && parent)
//		add_overlay("smes-op1")
	if(on)
//		add_overlay("smes-oc1")
	else
//		add_overlay("smes-op0")


/obj/machinery/cooling/multitool_act(mob/living/user, obj/item/multitool/I)
	if(!multitool_check_buffer(user, I))
		return
	var/obj/item/multitool/P = I

	if(istype(P.buffer, /obj/machinery/ship_weapon/energy))
		if(get_area(P.buffer) != get_area(src))
			to_chat(user, "<font color = #666633>-% Cannot link machines across power zones. %-</font color>")
			return

		if(parent)
			parent.cooling -= src
			parent = null
		parent = P.buffer
		.=TRUE
		parent.cooling |= src
		to_chat(user, "<font color = #666633>-% Successfully linked [P.buffer] with [src] %-</font color>")
		if(length(parent.cooling) >= 11)
			var/E = pick(parent.cooling)
			explosion(get_turf(E), 0, 1, 3, 5, flame_range = 4)
			return

		return


/obj/machinery/cooling/storage
	name = "subspace heatsink unit"
	desc = "A cooling unit that stores the massive amounts of heat energy weapons generate in subspace."
	icon_state = "storage"
	circuit = /obj/item/circuitboard/machine/cooling/storage


/obj/item/stock_parts/heatsink
	name = "heatsink"
	desc = "A heavy duty heatsink used in certain devices."
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "matter_bin"  //todo
	materials = list(/datum/material/bluespace=2000, /datum/material/copper=30000, /datum/material/iron=1000)
	w_class = WEIGHT_CLASS_BULKY
