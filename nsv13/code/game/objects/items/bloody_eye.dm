/obj/item/reagent_containers/hypospray/bloody_eye
	name = "Bloody Eye Spray"
	desc = "This vial of Bloody Eye is equipped with a spray nozzle and a handy measuring ring to make sure the spray cone is just the right size."
	icon = 'nsv13/icons/obj/nsv13_syringe.dmi'
	item_state = "bloody"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	icon_state = "bloody"
	amount_per_transfer_from_this = 30
	volume = 30
	possible_transfer_amounts = list(30)
	resistance_flags = ACID_PROOF
	reagent_flags = OPENCONTAINER
	slot_flags = ITEM_SLOT_BELT
	list_reagents = list(/datum/reagent/drug/bloody_eye = 30)

/datum/reagent/drug/bloody_eye
	name = "Bloody Eye"
	description = "A powerful drug of Syndicate origin. Manufactured to give the user an incredibly exciting rush, typically exilerating the user into a state of rage-induced psychosis. Boosts physical strength and allows the user to ignore the effects of critical condition."
	reagent_state = LIQUID
	color = "#D92323"
	overdose_threshold = 5
	addiction_threshold = 5
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/drug/bloody_eye/on_mob_metabolize(mob/living/L)
	ADD_TRAIT(L,TRAIT_MONKEYLIKE,type)
	ADD_TRAIT(L,TRAIT_NOBREATH,type)
	ADD_TRAIT(L,TRAIT_NOCRITDAMAGE,type)
	ADD_TRAIT(L,TRAIT_RESISTLOWPRESSURE,type)
	ADD_TRAIT(L,TRAIT_RESISTHIGHPRESSURE,type)
	ADD_TRAIT(L,TRAIT_NOSOFTCRIT,type)
	ADD_TRAIT(L,TRAIT_NOHARDCRIT,type)
	ADD_TRAIT(L,TRAIT_NOBLOCK,type)
	ADD_TRAIT(L,TRAIT_STUNIMMUNE,type)
	ADD_TRAIT(L,TRAIT_SLEEPIMMUNE,type)
	ADD_TRAIT(L,TRAIT_IGNOREDAMAGESLOWDOWN,type)
	ADD_TRAIT(L,TRAIT_NOSTAMCRIT,type)
	ADD_TRAIT(L,TRAIT_NOLIMBDISABLE,type)
	..()
	if (L.client)
		SSmedals.UnlockMedal(MEDAL_APPLY_REAGENT_METH,L.client)

	L.add_movespeed_modifier(type, update=TRUE, priority=100, multiplicative_slowdown=-2, blacklisted_movetypes=(FLYING|FLOATING))

/datum/reagent/drug/bloody_eye/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L,TRAIT_MONKEYLIKE,type)
	REMOVE_TRAIT(L,TRAIT_NOBREATH,type)
	REMOVE_TRAIT(L,TRAIT_NOCRITDAMAGE,type)
	REMOVE_TRAIT(L,TRAIT_RESISTLOWPRESSURE,type)
	REMOVE_TRAIT(L,TRAIT_RESISTHIGHPRESSURE,type)
	REMOVE_TRAIT(L,TRAIT_NOSOFTCRIT,type)
	REMOVE_TRAIT(L,TRAIT_NOHARDCRIT,type)
	REMOVE_TRAIT(L,TRAIT_NOBLOCK,type)
	REMOVE_TRAIT(L,TRAIT_STUNIMMUNE,type)
	REMOVE_TRAIT(L,TRAIT_SLEEPIMMUNE,type)
	REMOVE_TRAIT(L,TRAIT_IGNOREDAMAGESLOWDOWN,type)
	REMOVE_TRAIT(L,TRAIT_NOSTAMCRIT,type)
	REMOVE_TRAIT(L,TRAIT_NOLIMBDISABLE,type)
	L.remove_movespeed_modifier(type)
	..()

/datum/reagent/drug/bloody_eye/on_mob_life(mob/living/carbon/M)
	var/high_message = pick("You see red.", "You feel like ripping out someone's throat.", "You feel like nothing could ever kill you.")
	if(prob(5))
		to_chat(M, "<span class='notice'>[high_message]</span>")
	M.AdjustStun(-40, FALSE)
	M.AdjustKnockdown(-40, FALSE)
	M.AdjustUnconscious(-40, FALSE)
	M.AdjustParalyzed(-40, FALSE)
	M.AdjustImmobilized(-40, FALSE)
	M.adjustStaminaLoss(-30, 0)
	M.Jitter(2)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
	M.overlay_fullscreen("brute", /atom/movable/screen/fullscreen/brute, 5)
	if(prob(5))
		M.emote(pick("scream", "laugh"))
	..()
	. = 1
	playsound("heart_beat.ogg")

/datum/reagent/drug/bloody_eye/overdose_start(mob/living/M)
	to_chat(M, "<span class='userdanger'>KILLKILLKILLKILLKILLKILLKILLKILL!</span>")
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "[type]_overdose", /datum/mood_event/overdose, name)

/datum/reagent/drug/bloody_eye/overdose_process(mob/living/M)
	if((M.mobility_flags & MOBILITY_MOVE) && !ismovableatom(M.loc))
		for(var/i in 1 to 4)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote("scream")
	if(prob(33))
		M.visible_message("<span class='danger'>[M]'s eyes are blood red!</span>")
		M.drop_all_held_items()
	..()
	M.adjustToxLoss(0.5, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, pick(0.1, 0.2, 0.3, 0.4, 0.5))
	. = 1

/datum/reagent/drug/bloody_eye/addiction_act_stage1(mob/living/M)
	M.Jitter(20)
	if(prob(20))
		M.emote(pick("scream","laugh"))
	..()

/datum/reagent/drug/bloody_eye/addiction_act_stage2(mob/living/M)
	M.Jitter(50)
	M.Dizzy(5)
	if(prob(30))
		M.emote(pick("scream","gasp","laugh"))
	..()

/datum/reagent/drug/bloody_eye/addiction_act_stage3(mob/living/M)
	if((M.mobility_flags & MOBILITY_MOVE) && !ismovableatom(M.loc))
		for(var/i = 0, i < 4, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(100)
	M.Dizzy(10)
	if(prob(40))
		M.emote(pick("scream","gasp"))
	..()

/datum/reagent/drug/bloody_eye/addiction_act_stage4(mob/living/carbon/human/M)
	if((M.mobility_flags & MOBILITY_MOVE) && !ismovableatom(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(150)
	M.Dizzy(15)
	M.adjustToxLoss(0.5, 0)
	if(prob(50))
		M.emote(pick("scream"))
	..()
	. = 1

/obj/item/reagent_containers/hypospray/bloody_eye/attack_paw(mob/user)
	return attack_hand(user)

/obj/item/reagent_containers/hypospray/bloody_eye/attack(mob/living/M, mob/user)
	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] is empty!</span>")
		return
	if(!iscarbon(M))
		return

	var/list/injected = list()
	for(var/datum/reagent/R in reagents.reagent_list)
		injected += R.name
	var/contained = english_list(injected)
	log_combat(user, M, "attempted to spray", src, "([contained])")

	if(reagents.total_volume && (ignore_flags || M.can_inject(user, 1))) // Ignore flag should be checked first or there will be an error message.
		to_chat(M, "<span class='warning'>Your eye is covered in a fine red mist!</span>")
		to_chat(user, "<span class='notice'>You spray [M]'s eye with [src].</span>")
		playsound(loc, 'sound/items/hypospray.ogg', 50, 1)

		var/fraction = min(amount_per_transfer_from_this/reagents.total_volume, 1)
		reagents.reaction(M, INJECT, fraction)
		if(M.reagents)
			var/trans = 0
			if(!infinite)
				trans = reagents.trans_to(M, amount_per_transfer_from_this, transfered_by = user)
			else
				trans = reagents.copy_to(M, amount_per_transfer_from_this)

			to_chat(user, "<span class='notice'>[trans] unit\s sprayed.  [reagents.total_volume] unit\s remaining in [src].</span>")


			log_combat(user, M, "sprayed", src, "([contained])")

/datum/uplink_item/dangerous/bloody_eye
	 name = "Bloody Eye Spray"
	 desc = "Spray into your eye or someone else's to go into a bloody thirsty rage. The Syndicate will not be held responsible for the actions taken by operatives of The Syndicate while they are under the influence of Bloody Eye."
	 item = /obj/item/reagent_containers/hypospray/bloody_eye
	 cost = 10
