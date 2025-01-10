/datum/game_mode/bloodling
	name = "bloodling"
	config_tag = "bloodling"
	report_type = "bloodling"
	role_preference = /datum/role_preference/antagonist/bloodling
	antag_datum = /datum/antagonist/bloodling
	false_report_weight = 10
	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list(JOB_NAME_SECURITYOFFICER, JOB_NAME_WARDEN, JOB_NAME_HEADOFSECURITY, JOB_NAME_CAPTAIN, JOB_NAME_BRIGPHYSICIAN)
	required_players = 20
	required_enemies = 2 //Requires at LEAST 1 to play the master. Anything over 1 means how many thralls it should start with.
	recommended_enemies = 2
	reroll_friendly = 1

	announce_span = "green"
	announce_text = "While adrift through space, the ship has picked up an unwelcome visitor...\n\
	<span class='green'>Bloodling Thralls</span>: Accomplish the objectives assigned to you.\n\
	<span class='notice'>Crew</span>: Root out and eliminate the alien menace."

	title_icon = "bloodling"
	var/mob/living/simple_animal/bloodling/master = null

	var/const/bloodling_amount = 2 //hard limit on bloodlings if scaling is turned off
	var/list/bloodlings = list()

/datum/game_mode/bloodling/pre_setup()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Midshipman" //Nsv13 - Crayon eaters

	if(CONFIG_GET(flag/protect_heads_from_antagonist))
		restricted_jobs += GLOB.command_positions

	var/num_bloodlings = bloodling_amount

	master = spawn_bloodling()
	if(!master)
		setup_error = "Map error! No suitable vent networks / Xeno spawn waypoints found!"
		return 0

	if(antag_candidates.len>0)
		for(var/i = 0, i < num_bloodlings, i++)
			if(!antag_candidates.len)
				break
			var/datum/mind/bloodling = antag_pick(antag_candidates, ROLE_BLOODLING)
			antag_candidates -= bloodling
			bloodlings += bloodling
			bloodling.special_role = ROLE_BLOODLING
			bloodling.restricted_roles = restricted_jobs
		return 1
	else
		setup_error = "Not enough bloodling candidates"
		return 0

/datum/game_mode/bloodling/post_setup()
	var/datum/mind/theMaster = null //A230-385
	for(var/datum/mind/bloodling in bloodlings)
		if(!theMaster)
			theMaster = bloodling
			if(theMaster.current)
				qdel(theMaster.current)
			master.key = theMaster.key
			master.mind.add_antag_datum(new /datum/antagonist/bloodling)
			log_game("[key_name(master.mind)] has been selected as a bloodling master")
			continue

		bloodling.add_antag_datum(new /datum/antagonist/changeling/bloodling_thrall)
		log_game("[key_name(bloodling)] has been selected as a bloodling thrall")
	return ..()

/datum/game_mode/bloodling/check_win()
	. = ..()
	var/datum/component/bloodling/B = master?.GetComponent(/datum/component/bloodling)
	return (master && master.health > 0 && istype(master, /mob/living/simple_animal/hostile/eldritch/armsy/prime/bloodling_ascended)) && B?.biomass >= B?.final_form_biomass

/**
Helper proc to spawn the lil' blood alien creature in a vent! Adapted from alien_infestation.dm
*/
/proc/spawn_bloodling()
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		if(QDELETED(temp_vent))
			continue
		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
			var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
			if(!temp_vent_parent)
				continue//no parent vent
			//Stops Aliens getting stuck in small networks.
			//See: Security, Virology
			if(temp_vent_parent.other_atmos_machines.len > 20)
				vents += temp_vent

	//Okay, fallback.
	if(!vents.len)
		if(!GLOB.xeno_spawn.len)
			return FALSE //Okay, what the fuck even. Fix your shitty map!
		vents = GLOB.xeno_spawn

	var/obj/vent = pick_n_take(vents)

	var/mob/living/simple_animal/bloodling/habibi = new(vent.loc)
	return habibi


/datum/game_mode/bloodling/make_antag_chance(mob/living/carbon/human/character) //Assigns bloodling to latejoiners
	if(master) //There's already a master
		return
	if(bloodlings.len < bloodling_amount)
		if(!QDELETED(character) && character.client?.should_include_for_role(
			banning_key = initial(antag_datum.banning_key),
			role_preference_key = role_preference,
			req_hours = initial(antag_datum.required_living_playtime),
		))
			if(!(character.job in restricted_jobs))					if(!(character.job in restricted_jobs))
				if(!master) //Make him the master
					master = spawn_bloodling()
					if(!master)
						return FALSE //yeah okay your shit map doesn't support bloodling RIP
					master.key = character.client.ckey
					bloodlings += master.mind
					qdel(character) //Bye!
				//Otherwise, make him a new thrall...
				character.mind.add_antag_datum(/datum/antagonist/changeling/bloodling_thrall)


/datum/game_mode/bloodling/generate_report()
	return "The Gorlex Marauders have announced the successful raid and destruction of Central Command containment ship #S-[rand(1111, 9999)]. This ship housed only a single prisoner - \
			codenamed \"Thing\", and it was highly adaptive and extremely dangerous. We have reason to believe that the Thing has allied with the Syndicate, and you should note that likelihood \
			of the Thing being sent to a station in this sector is highly likely. It may be in the guise of any crew member. Trust nobody - suspect everybody. Do not announce this to the crew, \
			as paranoia may spread and inhibit workplace efficiency."

//////////////////////////////////////////
//Checks to see if someone is bloodling//
//////////////////////////////////////////
/proc/is_bloodling(mob/M)
	return M?.mind?.has_antag_datum(/datum/antagonist/bloodling) || M?.mind?.has_antag_datum(/datum/antagonist/changeling/bloodling_thrall) || M.GetComponent(/datum/component/bloodling)

/datum/game_mode/bloodling/generate_credit_text()
	var/list/round_credits = list()

	round_credits += "<center><h1>The Master:</h1>"

	if(master && master.client)
		round_credits += "<center><h2>[master.client.ckey]!</h2>"

	round_credits += "<center><h1>Its evil minions:</h1>"

	for(var/datum/mind/M in bloodlings)
		if(M.key)
			round_credits += "<center><h2>[M.key] as [M.name]</h2>"
	round_credits += "<br>"
	round_credits += ..()
	return round_credits
