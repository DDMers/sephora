#define isdwarf(A) (is_species(A, /datum/species/dwarf))

GLOBAL_LIST_INIT(dwarf_first, world.file2list("strings/names/dwarf_first.txt"))
GLOBAL_LIST_INIT(dwarf_last, world.file2list("strings/names/dwarf_last.txt"))

/datum/species/dwarf //not to be confused with the genetic manlets, they also can grab real good due to short stocky body.
	name = "Dwarf"
	id = "dwarf"
	default_color = "FFFFFF"
	species_traits = list(EYECOLOR,HAIR,FACEHAIR,LIPS,TRAIT_STRONG_GRABBER,NO_UNDERWEAR)
	mutant_bodyparts = list("tail_human", "ears", "wings")
	default_features = list("mcolor" = "FFF", "tail_human" = "None", "ears" = "None", "wings" = "None")
	limbs_id = "dwarf"
	offset_features = list(OFFSET_UNIFORM = list(0,0), OFFSET_ID = list(0,0), OFFSET_GLOVES = list(0,0), OFFSET_GLASSES = list(0,0), OFFSET_EARS = list(0,0), OFFSET_SHOES = list(0,0), OFFSET_S_STORE = list(0,0), OFFSET_FACEMASK = list(0,0), OFFSET_HEAD = list(0,0), OFFSET_HAIR = list(0,-4), OFFSET_FACE = list(0,-3), OFFSET_BELT = list(0,0), OFFSET_BACK = list(0,0), OFFSET_SUIT = list(0,0), OFFSET_NECK = list(0,0))
	use_skintones = 1
	damage_overlay_type = "monkey" //fits surprisngly well, so why add more icons?
	skinned_type = /obj/item/stack/sheet/animalhide/human
	liked_food = ALCOHOL | MEAT | DAIRY //Dwarves like alcohol, meat, and dairy products.
	disliked_food = JUNKFOOD | FRIED //Dwarves hate foods that have no nutrition other than alcohol.
	brutemod = 0.9 //Take slightly less damage than a human.
	burnmod = 0.9 //Less laser damage too.
	coldmod = 0.85 //Handle cold better too.
	heatmod = 0.85 //Of course heat also.
	speedmod = 1 //Slower than a human.
	punchdamagelow = 2 // Their min roll is 1 higher than a base human
	punchdamagehigh = 14 //They do more damage and have a higher chance to stunpunch cause of the greater cap.
	mutanteyes = /obj/item/organ/eyes/night_vision //And they have night vision.

/mob/living/carbon/human/species/dwarf
	race = /datum/species/dwarf

/datum/species/dwarf/qualifies_for_rank(rank, list/features)
	return TRUE	//I don't think dwarves would be barred from holding rank, reliable industrious people.

/datum/species/dwarf/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	var/dwarf_hair = pick("Dwarf Beard", "Very Long Beard", "Full Beard")
	var/mob/living/carbon/human/H = C
	H.facial_hair_style = dwarf_hair
	H.update_hair()

/datum/species/dwarf/random_name(gender,unique,lastname)
	return dwarf_name() 

//Dwarf Names
/proc/dwarf_name()
	return "[pick(GLOB.dwarf_first)] [pick(GLOB.dwarf_last)]"