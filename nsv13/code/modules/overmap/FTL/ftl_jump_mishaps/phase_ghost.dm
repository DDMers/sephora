/obj/effect/abstract/phase_ghost
	name = "?????"
	alpha = 0
	invisibility = INVISIBILITY_MAXIMUM
	resistance_flags = INDESTRUCTIBLE

///Links the echo to a existing thing.
/obj/effect/abstract/phase_ghost/proc/set_up(mob/living/clone)
	icon = clone.icon
	icon_state = clone.icon_state
	copy_overlays(clone, TRUE)
	addtimer(CALLBACK(src,  PROC_REF(appear)), rand(3, 6) MINUTES)

///Makes the echo visible, and sets it to disappear later.
/obj/effect/abstract/phase_ghost/proc/appear()
	invisibility = 0
	alpha = 100
	add_atom_colour("#77abff", FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, rand(13, 20) MINUTES)

/obj/effect/abstract/phase_ghost/Destroy(force)
	icon = null
	icon_state = null
	return ..()
