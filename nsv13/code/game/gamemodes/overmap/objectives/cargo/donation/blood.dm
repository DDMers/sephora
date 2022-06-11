/datum/overmap_objective/cargo/donation/blood
	name = "Donate blood types"
	desc = "Donate 1 or more blood types"
	var/list/possible_blood_types = list(
		"O-",
		"O+",
		"B-",
		"B+",
		"A-",
		"A+",
		"L",
		// We don't have enough ethereal or oozling players to donate blood if the ship does not spawn with any
		// "LE",
		// "OZ",
	)
	crate_name = "Blood Packs crate"

/datum/overmap_objective/cargo/donation/blood/New()
	..()
	var/picked = pick( possible_blood_types )
	var/datum/freight_type/single/reagent/blood/C = new( item_name = ( picked + " blood" ), blood_type = picked )
	freight_type_group = new( list( C ) )

