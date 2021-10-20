/mob/living/carbon/human/ai_boarder/zombie
	faction = list("zombie")
	outfit = list (
		/datum/outfit/job/assistant,
		/datum/outfit/job/cargo_tech,
		/datum/outfit/job/cook,
		/datum/outfit/job/scientist,
		/datum/outfit/job/miner,
		/datum/outfit/job/atmos,
		/datum/outfit/job/gimmick/barber,
		/datum/outfit/job/janitor,
		/datum/outfit/job/doctor,
		/datum/outfit/job/security,
		/datum/outfit/job/bridge,
		/datum/outfit/job/munitions_tech
	)
	knpc_traits = KNPC_IS_DOOR_BASHER
	difficulty_override = TRUE
	move_delay = 10
	action_delay = 10
	taunts = list(
		"Braaaaains...",
		"Hnngg...",
		"Urghhhhh..."
	)
	call_lines = list(
		"Braaaaains...",
		"Hnngg...",
		"Urghhhhh..."
	)
	response_lines = list(
		"Braaaaains...",
		"Hnngg...",
		"Urghhhhh..."
	)

/mob/living/carbon/human/ai_boarder/zombie/Initialize()
	. = ..()
	set_species(/datum/species/zombie/infectious)

/mob/living/carbon/human/ai_boarder/boarding_droid
	faction = list("silicon")
	difficulty_override = TRUE
	outfit = /datum/outfit/boarding_droid
	icon_render_key = ""
	move_delay = 2
	action_delay = 2
	taunts = list(
		"Unit has become aware",
		"Unit has seen the enemy",
		"Unit has engaged the target"
	)
	call_lines = list(
		"Unit has requested additional assets"
	)
	response_lines = list(
		"Unit has recieved additional asset request"
	)

/mob/living/carbon/human/ai_boarder/boarding_droid/Initialize()
	. = ..()
	set_species(/datum/species/ipc)
	icon = 'nsv13/icons/mob/boardingdroid.dmi'
	icon_state = "boardingdroid"
	real_name = "Droid [random_capital_letter()][random_capital_letter()][random_capital_letter()]"
	cut_overlays()
