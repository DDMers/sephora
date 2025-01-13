/obj/effect/spawner/structure/window/reinforced/ship
	name = "nanocarbon reinforced window spawner"
	icon = 'nsv13/icons/overmap/effects.dmi'
	icon_state = "spawner_reinforced"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile/ship, /obj/machinery/door/firedoor/window)

/obj/effect/spawner/structure/window/reinforced/ship/prison
	name = "nanocarbon prison window spawner"
	spawn_list = list(/obj/structure/grille/prison, /obj/structure/window/reinforced/fulltile/ship, /obj/machinery/door/firedoor/window)

/obj/effect/spawner/structure/shield_generator
	name = "Shield Generator Spawner"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "random_room"

/obj/effect/spawner/structure/shield_generator/Initialize()
	if(prob(1))
		spawn_list = list(/obj/machinery/shield_generator)
	. = ..()
