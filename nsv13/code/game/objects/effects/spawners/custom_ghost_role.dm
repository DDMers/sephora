/obj/effect/mob_spawn/human/nsv13/syndicate_crew/
	name = "a syndicate soldier class stasis pod"
	desc = "Although this stasis pod looks medicinal, it seems as though it's meant to preserve something for a very long time. It has a name and Syndicate insignia on it."
	mob_name = "Syndicate Soldier"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	roundstart = FALSE
	death = FALSE
	flavour_text = "<b>You are a </b><span class='big bold'>Syndicate Soldier</span><b>, part of the crew of a Syndicate Space Vessel. Your objective is to protect your ship and its valuable assets such as prisoners or navigational data at all costs. Failure will not be accepted.</b>"
	assignedrole = "Syndicate Soldier"
	outfit = /datum/outfit/syndicate/sleeper/soldier

/obj/effect/mob_spawn/human/nsv13/syndicate_crew/pilot
	name = "a syndicate pilot class stasis pod"
	desc = "Although this stasis pod looks medicinal, it seems as though it's meant to preserve something for a very long time. It has as Officer's name and Syndicate insignia on it."
	mob_name = "Syndicate Pilot"
	flavour_text = "<b>You are a </b><span class='big bold'>Syndicate Pilot</span><b>, part of the crew of a Syndicate Space Vessel. Your objective is to fly and protect the bridge of the ship that you have been stationed on. Keep the navigational data from falling into enemy hands.</b>"
	assignedrole = "Syndicate Pilot"
	outfit = /datum/outfit/syndicate/sleeper/pilot

/obj/effect/mob_spawn/human/nsv13/syndicate_crew/Destroy()
	new/obj/structure/fluff/empty_sleeper/syndicate(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/nsv13/syndicate_crew/special(mob/living/new_spawn)
	new_spawn.fully_replace_character_name(null,random_unique_name(gender))

/obj/effect/mob_spawn/human/nsv13/syndicate_crew/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("A Syndicate Crewmember is about to thaw from cryo on \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE)

/obj/effect/mob_spawn/human/nsv13/nt_prisoner/
	name = "a prisoner stasis pod"
	desc = "Although this stasis pod looks medicinal, it seems as though it's meant to preserve something for a very long time. It has a prisoner's identification number and a Nanotrasen insignia on it. It seems like it's been ashed around quite a bit."
	mob_name = "NT Prisoner"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	roundstart = FALSE
	death = FALSE
	flavour_text = "<b>You are a </b><span class='big bold'>prisoner of the Syndicate</span><b>. You are a Nanotrasen employee captured by the syndicate. Your objective is to escape the ship you are on alive. Hopefully your extensive training will help you!</b><span class='big bold'><span class='danger'>THIS IS NOT AN ANTAGONIST ROLE!</span></span>"
	assignedrole = "NT Prisoner"
	outfit = /datum/outfit/sleeper/prisoner

/obj/effect/mob_spawn/human/nsv13/nt_prisoner/Destroy()
	new/obj/structure/fluff/empty_sleeper(get_turf(src))
	return ..()

/obj/effect/mob_spawn/human/nsv13/nt_prisoner/special(mob/living/new_spawn)
	new_spawn.fully_replace_character_name(null,random_unique_name(gender))

/obj/effect/mob_spawn/human/nsv13/nt_prisoner/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	if(A)
		notify_ghosts("An NT Prisoner is about to thaw from cryo on \the [A.name].", source = src, action=NOTIFY_ATTACK, flashwindow = FALSE, ignore_key = POLL_IGNORE_POSIBRAIN) //I don't know which POLL_IGNORE to use here
