//NSV13 Custom Grenades

/obj/item/grenade/chem_grenade/armor_destruction
	name = "Starlight Armaments- Armor Deterioration Grenade Mk3"
	desc = "SAAD Grenades are certified non-lethal. WARNING: Do not use near vital equipment or machinery."
	icon_state= "armor_destruction"
	stage = GRENADE_READY

/obj/item/grenade/chem_grenade/armor_destruction/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/glass/beaker/large/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/large/B2 = new(src)

	B1.reagents.add_reagent(/datum/reagent/fluorosurfactant, 30)
	B1.reagents.add_reagent(/datum/reagent/toxin/acid, 20)
	B1.reagents.add_reagent(/datum/reagent/uranium/radium, 25)
	B1.reagents.add_reagent(/datum/reagent/stable_plasma, 25)
	B2.reagents.add_reagent(/datum/reagent/water, 30)
	B2.reagents.add_reagent(/datum/reagent/carbon, 25)
	B2.reagents.add_reagent(/datum/reagent/toxin/acid, 45)

	beakers += B1
	beakers += B2
