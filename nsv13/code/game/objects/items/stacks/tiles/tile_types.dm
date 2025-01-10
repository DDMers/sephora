/obj/item/stack/tile/glass
	name = "glass tile"
	icon = 'nsv13/icons/obj/tiles.dmi'
	singular_name = "glass floor tile"
	desc = "The glass you walk on."
	icon_state = "glass_tile"
	turf_type = /turf/open/floor/glass
	materials = list(/datum/material/glass=500)

/obj/item/stack/tile/glass/reinforced
	name = "reinforced glass tile"
	singular_name = "reinforced glass tile"
	desc = "The glass you walk on."
	icon_state = "rglass_tile"
	turf_type = /turf/open/floor/glass/reinforced
	materials = list(/datum/material/glass=500, /datum/material/iron=250)


//durasteel tiles
/obj/item/stack/tile/durasteel
	name = "durasteel floor tile"
	singular_name = "durasteel floor tile"
	desc = "A durasteel tile. Those could work as a pretty decent throwing weapon."
	icon = 'nsv13/icons/obj/custom_tiles.dmi'
	icon_state = "durasteel_tile"
	force = 6
	materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT*0.05, /datum/material/silver = MINERAL_MATERIAL_AMOUNT*0.0375, /datum/material/titanium = MINERAL_MATERIAL_AMOUNT*0.1625)
	throwforce = 10
	flags_1 = CONDUCT_1
	turf_type = /turf/open/floor/durasteel
	mineralType = "durasteel"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 70, "stamina" = 0)
	resistance_flags = FIRE_PROOF
	merge_type = /obj/item/stack/tile/durasteel
	var/catwalk_type = null
	var/list/tilelist = list( \
	"durasteel_tile", \
	"durasteel_tile_alt", \
	"riveted_tile", \
	"padded_tile", \
	"eris_techfloor_tile", \
	"eris_techfloor_alt_tile", \
	"lino_tile", \
	"techfloor_tile", \
	"techfloor_grid_tile", \
	"monotile_steel", \
	"monotile_dark", \
	"monotile_light", \
	"monofloor_tile" \
	)
	var/list/tiletypes = list( \
	"durasteel_tile" = /turf/open/floor/durasteel, \
	"durasteel_tile_alt" = /turf/open/floor/durasteel/alt, \
	"riveted_tile" = /turf/open/floor/durasteel/riveted, \
	"padded_tile" = /turf/open/floor/durasteel/padded, \
	"eris_techfloor_tile" = /turf/open/floor/durasteel/eris_techfloor, \
	"eris_techfloor_alt_tile" = /turf/open/floor/durasteel/eris_techfloor_alt, \
	"lino_tile" = /turf/open/floor/durasteel/lino, \
	"techfloor_tile" = /turf/open/floor/durasteel/techfloor, \
	"techfloor_grid_tile" = /turf/open/floor/durasteel/techfloor_grid, \
	"monotile_steel" = /turf/open/floor/monotile/steel, \
	"monotile_dark" = /turf/open/floor/monotile/dark, \
	"monotile_light" = /turf/open/floor/monotile/light, \
	"monofloor_tile" = /turf/open/floor/monofloor \
	)
	var/list/catwalktypes = list( \
	"monotile_steel" = /obj/structure/lattice/catwalk/over/ship, \
	"monotile_dark" = /obj/structure/lattice/catwalk/over/ship/dark, \
	"monotile_light" = /obj/structure/lattice/catwalk/over/ship/light, \
	)

/obj/item/stack/tile/durasteel/Initialize(mapload, amount)
	. = ..()
	for(var/option in tilelist) //Just hardcoded for now!
		tilelist[option] = image(icon = 'nsv13/icons/obj/custom_tiles.dmi', icon_state = option)

/obj/item/stack/tile/durasteel/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Ctrl-click to change the tile type.</span>"
	if(catwalk_type)
		. += "<span class='notice'>There are attachment points for <i>rods</i>.</span>"

/obj/item/stack/tile/durasteel/CtrlClick(mob/user)
	if((istype(user) && user.canUseTopic(src, BE_CLOSE, ismonkey(user))) && !is_cyborg && user.is_holding(src)) //Only activate when in your hand
		var/choice = show_radial_menu(user, user, tilelist)
		if(choice)
			icon_state = choice
			turf_type = tiletypes[icon_state] //it JUST works
			catwalk_type = catwalktypes[icon_state]
	return ..()

/obj/item/stack/tile/durasteel/attackby(obj/item/W, mob/user, params)//plated catwalk construction
	add_fingerprint(user)
	if(istype(W, /obj/item/stack/rods))
		if(!catwalk_type)
			to_chat(user, "<span class='warning'>You can't make a plated catwalk with this variant of tile!</span>")
			return
		var/turf/T = get_turf(usr)
		if(locate(/obj/structure/lattice/catwalk) in T)
			to_chat(user, "<span class='warning'>There is already a catwalk here!</span>")
			return
		if(!isfloorturf(T))
			to_chat(user, "<span class='warning'>You can only build a plated catwalk on a floor!</span>")
			return
		var/obj/item/stack/rods/V = W
		if (V.get_amount() >= 2 && get_amount() >= 1)
			new catwalk_type(T)
			V.use(2)
			use(1)
		else
			to_chat(user, "<span class='warning'>You need two rods and one tile to make a plated catwalk!</span>")
			return
	else
		return ..()
/obj/item/stack/tile/durasteel/alt
	icon_state = "durasteel_tile_alt"
	turf_type = /turf/open/floor/durasteel/alt

/obj/item/stack/tile/durasteel/riveted
	icon_state = "riveted_tile"
	turf_type = /turf/open/floor/durasteel/riveted

/obj/item/stack/tile/durasteel/padded
	icon_state = "padded_tile"
	turf_type = /turf/open/floor/durasteel/padded

/obj/item/stack/tile/durasteel/eris_techfloor
	icon_state = "eris_techfloor_tile"
	turf_type = /turf/open/floor/durasteel/eris_techfloor

/obj/item/stack/tile/durasteel/eris_techfloor_alt
	icon_state = "eris_techfloor_alt_tile"
	turf_type = /turf/open/floor/durasteel/eris_techfloor_alt

/obj/item/stack/tile/durasteel/lino
	icon_state = "lino_tile"
	turf_type = /turf/open/floor/durasteel/lino

/obj/item/stack/tile/durasteel/techfloor
	icon_state = "techfloor_tile"
	turf_type = /turf/open/floor/durasteel/techfloor

/obj/item/stack/tile/durasteel/techfloor_grid
	icon_state = "techfloor_grid_tile"
	turf_type = /turf/open/floor/durasteel/techfloor_grid

/obj/item/stack/tile/durasteel/mono_steel
	icon_state = "monotile_steel"
	turf_type = /turf/open/floor/monotile/steel
	catwalk_type = /obj/structure/lattice/catwalk/over/ship

/obj/item/stack/tile/durasteel/mono_dark
	icon_state = "monotile_dark"
	turf_type = /turf/open/floor/monotile/dark
	catwalk_type = /obj/structure/lattice/catwalk/over/ship/dark

/obj/item/stack/tile/durasteel/mono_light
	icon_state = "monotile_light"
	turf_type = /turf/open/floor/monotile/light
	catwalk_type = /obj/structure/lattice/catwalk/over/ship/light

/obj/item/stack/tile/durasteel/monofloor
	icon_state = "monofloor_tile"
	turf_type = /turf/open/floor/monofloor
//carpet

/obj/item/stack/tile/carpet/ship
	name = "nanoweave carpet tile"
	singular_name = "nanoweave carpet tile"
	desc = "A regular nanoweave carpet tile"
	icon = 'nsv13/icons/turf/dark_carpet.dmi'
	icon_state = "dark_carpet_tile"
	resistance_flags = FLAMMABLE
	materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT*0.05, /datum/material/silver = MINERAL_MATERIAL_AMOUNT*0.0375, /datum/material/titanium = MINERAL_MATERIAL_AMOUNT*0.1625)
	turf_type = /turf/open/floor/carpet/ship

/obj/item/stack/tile/carpet/ship/blue
	name = "nanoweave carpet tile (blue)"
	icon = 'nsv13/icons/turf/blue_carpet.dmi'
	icon_state = "blue_carpet_tile"
	turf_type = /turf/open/floor/carpet/ship/blue

/obj/item/stack/tile/carpet/ship/orange_carpet
	name = "nanoweave carpet tile (orange)"
	icon = 'nsv13/icons/turf/orange_carpet.dmi'
	icon_state = "orange_carpet_tile"
	turf_type = /turf/open/floor/carpet/ship/orange_carpet

/obj/item/stack/tile/carpet/ship/purple_carpet
	name = "nanoweave carpet tile (purple)"
	icon = 'nsv13/icons/turf/purple_carpet.dmi'
	icon_state = "purple_carpet_tile"
	turf_type = /turf/open/floor/carpet/ship/purple_carpet

/obj/item/stack/tile/carpet/ship/beige_carpet
	name = "nanoweave carpet tile (beige)"
	icon = 'nsv13/icons/turf/beige_carpet.dmi'
	icon_state = "beige_carpet_tile"
	turf_type = /turf/open/floor/carpet/ship/beige_carpet

/obj/item/stack/tile/carpet/ship/red_carpet
	name = "nanoweave carpet tile (red)"
	icon = 'nsv13/icons/turf/beige_carpet.dmi'
	icon_state = "red_carpet_tile"
	turf_type = /turf/open/floor/carpet/ship/red_carpet
