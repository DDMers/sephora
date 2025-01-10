/*SKYNET 2 AI by Kmc2000
"Because SKYNET 1 wasn't good enough."
This implements fleet movement for AIs through the use of very basic "utility score" AI programming.
How this works:
Instead of a traditional decision tree like we used back in SKYNET 1, Skynet 2 uses utility scoring, a technique similar to GOAP.
Instead of giving the AI a preset, flat list of decisions to make, the AI will now make decisions "on the fly" based on what task is most important to it at the time.
-This can vary! And can be anything you want. Maybe you're making a asteroid slinger ship, and you want to ensure that it has an asteroid to fling at someone BEFORE attacking an enemy ship. In this case, you'd just say that the "get asteroid" goal is more important to the AI than the "search and destroy" goal. (Though be sure to lock it to that specific ship via traits!)
This code uses singleton datums to give AI orders.
Workflow:
AIs like score, every few seconds, they'll run through all the subtypes of datum/ai_goal, which are stored in a global list. If it has a goal, and finds a higher priority task, it'll switch focus to whatever task we want it to.
Example:
Frame 1: Ai shoots ship, runs out of ammo
Frame 2: Ai ship's "search and destroy" goal is now a lower priority than its resupply goal, as it recognises that it's fresh out of ammo. It'll now go find a supply ship and get re-armed there.
Current task hierarchy (as of 10/02/2021)!
1: Repair and re-arm. If a ship becomes critically damaged, or runs out of bullets, it will rush to a supply ship to resupply (if available), and heal up.
2: (if you're a battleship): Defend the supply lines. Battleships stick close to the supply ships and keep them safe.
3: (Non-supply ships) Search and destroy: Attempt to find a target that's visible and within tracking range. - This is replaced with Swarm for fighters and bombers, which will somewhat cooperate while hunting down targets.
4: Patrol: Destroyers and Supply ships will slowly patrol the sector for hostile ships, with their escorts in tow. Supply ships run when they spot anything close, Destroyers engage.
5: (All ships) Defend the supply lines: If AIs cannot find a suitable target, they'll flock back to the main fleet and protect the tankers. More nimble attack squadrons will blade off in wings and attack the enemy if they get too close, with the battleships staying behind to protect their charges.
Adding tasks is easy! Just define a datum for it.
*/

/datum/fleet
	var/name = "Syndicate Invasion Fleet"//Todo: randomize this name
	//Ai fleet type enum. Add your new one here. Use a define, or text if youre lazy.
	var/list/taskforces = list("fighters" = list(), "destroyers" = list(), "battleships" = list(), "supply" = list())
	var/list/fighter_types = list(/obj/structure/overmap/syndicate/ai/fighter, /obj/structure/overmap/syndicate/ai/bomber)
	var/list/destroyer_types = list(/obj/structure/overmap/syndicate/ai, /obj/structure/overmap/syndicate/ai/destroyer, /obj/structure/overmap/syndicate/ai/destroyer/flak, /obj/structure/overmap/syndicate/ai/cruiser, /obj/structure/overmap/syndicate/ai/mako_flak, /obj/structure/overmap/syndicate/ai/mako_carrier)
	var/list/battleship_types = list(/obj/structure/overmap/syndicate/ai, /obj/structure/overmap/syndicate/ai/destroyer, /obj/structure/overmap/syndicate/ai/destroyer/flak, /obj/structure/overmap/syndicate/ai/cruiser, /obj/structure/overmap/syndicate/ai/mako_flak, /obj/structure/overmap/syndicate/ai/mako_carrier)
	var/list/supply_types = list(/obj/structure/overmap/syndicate/ai/carrier)
	var/list/all_ships = list()
	var/list/lances = list()
	var/obj/structure/overmap/default_ghost_ship = /obj/structure/overmap/syndicate/ai

	var/size = FLEET_DIFFICULTY_MEDIUM //How big is this fleet anyway?
	var/applied_size	//How big is this fleet ACTUALLY after modifications applied by.. well. everything.
	var/threat_elevation_allowed = TRUE	//Does the threat elevation system apply to this fleet? This acts independantly to the base difficulty pop scaling.
	var/can_reinforce = TRUE	//Can this fleet gain new ships after a while out of combat has passed?

	var/allow_difficulty_scaling = TRUE	//Set this to false if the fleet is supposed to have a constant difficulty as opposed to scaling with pop.
	var/list/audio_cues = list() //Does this fight come with a theme tune? Takes youtube / media links so that we don't have to store a bunch of copyrighted music on the box.
	var/instantiated = FALSE //If we're not instantiated, moving all the ships is a piece of cake, if we are however, we do some extra steps to FTL them all.
	var/datum/star_system/current_system = null //Where are we?
	var/datum/star_system/goal_system = null //Where are we looking to go?
	var/list/plotted_course = FALSE
	var/list/navigation_spec_alignments = list()	//If for some reason you have a fleet that is supposed to navigate smart, but also isn't allowed (or even only allowed) some alignment types, use this.
	var/navigation_spec_alignment_type = ALIGNMENT_BLACKLIST	//ALIGNMENT_BLACKLIST: Do not use systems with these alignments | ALIGNMENT_WHITELIST: Only use systems with these alignments.
	var/navigation_uses_wormholes = TRUE	//If for some reason you want a fleet type that can't use wormholes (in navigation!!, it'll still use them for random wandering), be my guest, and just set this to FALSE
	var/allow_hidden_systems = FALSE	//Set this to true if you want to allow the fleet to plot courses using hidden systems.
	var/hide_movements = FALSE
	var/alignment = "syndicate"
	var/list/taunts = list("Unidentified vessel, you have entered our airspace. Leave immediately or be destroyed", "Identify yourselves immediately or be destroyed", "Unidentified vessel, leave immediately. You are entering Syndicate territory.", "Hold it right there. Prepare to be boarded, Captain.", "Nanotrasen vessel, surrender immediately or face unnecessary casualties.", "All Nanotrasen crewmen, please prepare for immediate evisceration.", "Unidentified vessel, transmit your credentials now or- Wait a second, that’s the ship we’re looking for! Deploy fighters!", "Nanotrasen? You’ve just made my day, all crafts prepare to engage.", "Unknown vessel, failure to contact Syndicate control on frequency 0.4 is a suspected act of aggression. Prepare for engagement.")
	var/list/greetings = list("IFF confirmed, good to see you", "Allied vessel, IFF confirmed.")
	var/list/recently_visited = list()
	var/fleet_trait = FLEET_TRAIT_INVASION
	var/last_encounter_time = 0
	var/datum/faction/faction = null
	var/faction_id = FACTION_ID_SYNDICATE
	var/reward = 100 //Reward for defeating this fleet, is credited to this faction's enemies.

	var/initial_move_delay = 10 MINUTES
	var/minimum_random_move_delay = 5 MINUTES
	var/maximum_random_move_delay = 10 MINUTES
	var/combat_move_delay = 10 MINUTES

	var/list/shared_targets = list()

/datum/fleet/proc/start_reporting(target, reporter)
	//message_admins("[reporter] started reporting [target] to fleet")
	if(!shared_targets)
		shared_targets = list()
	if(!shared_targets[target])
		shared_targets[target] = list(reporter)
	else
		shared_targets[target] |= reporter

/datum/fleet/proc/stop_reporting(target, reporter)
	//message_admins("[reporter] stopped reporting [target] to fleet")
	if(!shared_targets || !shared_targets[target])
		return
	shared_targets[target] -= reporter
	if(!length(shared_targets[target]))
		shared_targets -= target

/datum/fleet/proc/is_reporting_target(target, reporter)
	return ((shared_targets?[target]) && (reporter in shared_targets[target]))

/datum/fleet/proc/stop_reporting_all(reporter)
	if(!length(shared_targets))
		return
	for(var/target in shared_targets)
		stop_reporting(target, reporter)

//BFS search algo. Entirely unused for now.
/datum/fleet/proc/bfs(datum/star_system/target)
	if(!current_system)
		return //No pathfinding from /NULL/
	if(!target)
		target = SSstar_system.system_by_id("Sol")
	var/list/path = list()
	//Firstly, let's BFS from the target system to get what we actually need to go through.
	var/list/queue = list()
	var/list/visited = list()

	var/list/ourQueue = list()
	var/list/ourVisited = list()

	visited[target] = TRUE
	queue += target

	ourVisited[current_system] = TRUE
	ourQueue += current_system

	while(queue.len)
		var/datum/star_system/SS = queue[1]
		queue.Cut(1,2)
		for(var/_name in SS.adjacency_list)
			var/datum/star_system/sys = SSstar_system.system_by_id(_name)
			if(!visited[sys])
				visited[sys] = TRUE
				queue += sys
				path += sys

	for(var/X in path)
		message_admins(X)

	return target

/datum/fleet/proc/try_threat_elevation_reinforce()
	if(!current_system)
		return	//Which admin did this?
	if(current_system.occupying_z)
		return	//Loaded z - abort
	if(current_system.check_conflict_status())
		return //Bonking in progress - abort
	if(world.time < last_encounter_time + TE_REINFORCEMENT_DELAY)
		return
	if(allow_difficulty_scaling)
		//Account for pre-round spawned fleets.
		if(SSovermap_mode?.mode)
			applied_size = SSovermap_mode.mode.difficulty
		else
			applied_size = 1 //Lets assume a low number of players
	else
		applied_size = size
	applied_size = max(applied_size, FLEET_DIFFICULTY_EASY)
	if(threat_elevation_allowed)
		applied_size += round(SSovermap_mode.threat_elevation / TE_POINTS_PER_FLEET_SIZE)	//Threat level modifies danger
	if(length(destroyer_types))
		for(var/i = length(taskforces["destroyers"]); i < max(round(applied_size/2), 1); i++)
			var/shipType = pick(destroyer_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "destroyers")
	if(length(battleship_types))
		for(var/i = length(taskforces["battleships"]); i < max(round(applied_size/4), 1); i++)
			var/shipType = pick(battleship_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "battleships")
	if(length(supply_types))
		for(var/i = length(taskforces["supply"]); i < max(round(applied_size/4), 1); i++)
			var/shipType = pick(supply_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "supply")

/datum/fleet/proc/move(datum/star_system/target, force=FALSE)
	if(can_reinforce)
		try_threat_elevation_reinforce()
	var/course_picked_target = FALSE
	if(!target)
		if(goal_system)
			if(current_system == goal_system)
				if(!force)
					addtimer(CALLBACK(src, PROC_REF(move)), rand(minimum_random_move_delay, maximum_random_move_delay))
				return //We already arrived at our goal, time to chill here unless it changes.
			if(!plotted_course || !plotted_course.len)	//Route len should ONLY be empty if we already arrived.
				navigate_to(goal_system)
		if(!plotted_course || !plotted_course.len)	//When route is still FALSE after this. there is no way to our goal, so we just pick a random system instead. If it was just a empty list, we are AT our goal instead, though that should early return earlier.
			var/list/potential = list()
			var/list/fallback = list()
			//Pick a movement target based on our fleet trait.
			for(var/_name in current_system.adjacency_list)
				var/datum/star_system/sys = SSstar_system.system_by_id(_name)
				if(sys.hidden)
					continue
				switch(fleet_trait)
					if(FLEET_TRAIT_DEFENSE)
						return FALSE //These boss fleets do not move.
					if(FLEET_TRAIT_NEUTRAL_ZONE) //These fleets live in the neutral zone
						if(sys.alignment != "unaligned" || "uncharted")
							continue
					if(FLEET_TRAIT_BORDER_PATROL)
						if(sys.owner != alignment)
							continue
					if(FLEET_TRAIT_INVASION)
						if(sys.alignment == alignment)
							continue
						if(sys.alignment == "unaligned")
							fallback += sys
							continue
				potential += sys
			if(!potential.len)
				potential = fallback //Nowhere else to go.
			if(!potential.len)	//Welp, we are stuck here for now.
				if(!force)
					addtimer(CALLBACK(src, PROC_REF(move)), rand(minimum_random_move_delay, maximum_random_move_delay))
				return FALSE
			target = pick(potential)
		else
			target = plotted_course[1]	//This shouldn't be able to reach this point with an empty route, so it *should* be safe.
			course_picked_target = TRUE
	if(!force)
		addtimer(CALLBACK(src, PROC_REF(move)), rand(minimum_random_move_delay, maximum_random_move_delay))
		//Precondition: We're allowed to go to this system.
		if(!course_picked_target)
			switch(fleet_trait)
				if(FLEET_TRAIT_DEFENSE)
					return FALSE //These boss fleets do not move.
				if(FLEET_TRAIT_BORDER_PATROL)
					if(target.owner != alignment) //Patrol systems we control
						return FALSE
				if(FLEET_TRAIT_INVASION)
					if(target.alignment == alignment)
						return FALSE
				if(FLEET_TRAIT_NEUTRAL_ZONE)
					if(target.owner == alignment) //Can still patrol systems that are occupied
						return FALSE

		if(world.time < last_encounter_time + combat_move_delay) //So that fleets don't leave mid combat.
			return FALSE

		if(SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CHECK_INTERDICT, pick(all_ships)) & BEING_INTERDICTED)	//Hypothesis: All ships within a fleet should have the same faction.
			return FALSE

	current_system.fleets -= src
	if(current_system.fleets?.len)
		var/datum/fleet/F = pick(current_system.fleets)
		current_system.alignment = F.alignment
		current_system.mission_sector = FALSE
		for(var/datum/fleet/FF in current_system.fleets)
			if(FF.alignment != current_system.owner && !FF.federation_check())
				current_system.mission_sector = TRUE
	else
		current_system.alignment = current_system.owner
		current_system.mission_sector = FALSE
	if(instantiated)//If the fleet was "instantiated", that means it's already been encountered, and we need to track the states of all the ships in it.
		for(var/obj/structure/overmap/OM in all_ships)
			SSstar_system.move_existing_object(OM, target)
	target.fleets += src
	shared_targets = list() // We just got here and don't know where anything is
	current_system = target
	target.alignment = alignment //We're occupying it
	if(target.fleets?.len)
		for(var/datum/fleet/F as() in target.fleets)
			if(alignment != target.owner && !federation_check(target))
				current_system.mission_sector = TRUE
	if(!hide_movements && !current_system.hidden)
		if((alignment == "syndicate") || (alignment == "pirate"))
			mini_announce("Typhoon drive signatures detected in [current_system]", "White Rapids EAS")
	for(var/obj/structure/overmap/OM in current_system.system_contents)
		//Boarding ships don't want to go to brasil
		if(OM.mobs_in_ship?.len && OM.reserved_z)
			encounter(OM)

	if(current_system.check_conflict_status())
		if(!SSstar_system.contested_systems.Find(current_system))
			SSstar_system.contested_systems.Add(current_system)
	if(course_picked_target)
		plotted_course -= target
	else if(plotted_course && plotted_course.len)	//We jumped. but didn't follow our course! Recalculate!
		navigate_to(goal_system)
	return TRUE

/datum/fleet/interdiction/move(datum/star_system/target, force=FALSE)
	if(!target && hunted_ship)
		goal_system = hunted_ship.current_system
	. = ..()
	if(.)
		navigate_to(goal_system)	//Anytime we successfully move we recalculate the route, since players like moving around alot.

/datum/fleet/interdiction/New()
	. = ..()
	hunted_ship = SSstar_system.find_main_overmap()

/datum/fleet/earthbuster/New()
	. = ..()
	goal_system = SSstar_system.system_by_id("Sol")


//Clear a ship from this fleet.
/datum/fleet/proc/remove_ship(obj/structure/overmap/OM)
	all_ships -= OM
	last_encounter_time = world.time
	for(var/V in taskforces)	//Very cursed but it works!
		var/list/L = taskforces["[V]"]
		if(!L)
			continue
		for(var/obj/structure/overmap/OOM in L)	//I'm gonna OOM
			if(OOM == OM)
				L.Remove(OM)
				break	//Ships should exist once in a each taskforce, unless something is very wrong in there.
	if(!all_ships.len) //We've been defeated!
		defeat()

/datum/fleet/proc/defeat()
	var/datum/star_system/player_system = SSstar_system.find_main_overmap().current_system
	var/datum/star_system/mining_system = SSstar_system.find_main_miner()?.current_system
	var/message = "\A [name] has been defeated [(current_system && !current_system.hidden) ? "during combat in the [current_system.name] system" : "in battle"]."
	if(alignment == "nanotrasen" || current_system == player_system || current_system == mining_system)
		minor_announce(message, "White Rapids Fleet Command")
	else
		mini_announce(message, "White Rapids Fleet Command")
	current_system.fleets -= src
	if(current_system.fleets && current_system.fleets.len)
		var/datum/fleet/F = pick(current_system.fleets)
		current_system.alignment = F.alignment
		current_system.mission_sector = FALSE
		for(var/datum/fleet/FF in current_system.fleets)
			if(FF.alignment != current_system.owner && !federation_check())
				current_system.mission_sector = TRUE
	else
		current_system.alignment = current_system.owner
		current_system.mission_sector = FALSE
	var/player_caused = FALSE
	for(var/obj/structure/overmap/OOM in current_system.system_contents)
		if(QDELETED(OOM) || QDELING(OOM))
			continue
		if(!length(OOM.mobs_in_ship))
			continue
		player_caused = TRUE
		SEND_SIGNAL(OOM, COMSIG_SHIP_KILLED_FLEET)
		for(var/mob/M in OOM.mobs_in_ship)
			if(M.client)
				var/client/C = M.client
				C.tgui_panel?.stop_music()
	if(player_caused)	//Only modify influence if players caused this, otherwise someone else claimed the kill and it doesn't modify influence for the purpose of Patrol completion.
		faction = SSstar_system.faction_by_id(faction_id)
		faction?.lose_influence(reward)
		if(alignment != "nanotrasen")
			SSovermap_mode.modify_threat_elevation(TE_FLEET_THREAT_DYNAMIC ? (TE_FLEET_KILL_THREAT * applied_size ) : TE_FLEET_KILL_THREAT)
	QDEL_NULL(src)

/datum/fleet/solgov/earth/defeat()
	. = ..() //If you lose sol...game over man, game over.
	priority_announce("SolGov command do you read?! Requesting immediate assistance, we have a foothold situation, repeat, a foothold sit##----///", "White Rapids Fleet Command")
	SSticker.mode.check_finished(TRUE)
	SSticker.force_ending = TRUE

/obj/structure/overmap/proc/force_jump(where)
	if(!where)
		return
	var/datum/star_system/SS = SSstar_system.system_by_id(where)
	if(!SS)
		return
	var/datum/star_system/curr = SSstar_system.ships[src]["current_system"]
	curr?.remove_ship(src)
	jump_end(SS)

/obj/structure/overmap/proc/try_hail(mob/living/user, var/obj/structure/overmap/source_ship)
	if(!isliving(user))
		return FALSE
	if(!source_ship)
		return FALSE
	var/text = stripped_input(user, "What do you want to say?", "Hailing")
	if(text)
		source_ship.hail(text, name, user.name, TRUE) // Let the crew on the source ship know an Outbound message was sent
		hail(text, source_ship.name, user.name)

/obj/structure/overmap/proc/try_deliver( mob/living/user, var/obj/machinery/computer/ship/dradis/minor/cargo/console )
	if( !isliving(user) )
		return FALSE
	if( !allowed(user) ) //Only cargo auth'd personnel can make purchases.
		to_chat(user, "<span class='warning'>Warning: You cannot open a communications channel without appropriate requisitions access registered to your ID card.</span>")
		return FALSE

	if (!console?.linked_launcher)
		to_chat(user, "<span class='warning'>[console] has no cargo launcher attached! Use a multitool with a cargo launcher stored on its buffer to connect it.</span>")
		if ( console && console.linked )
			try_hail( user, console.linked )
		return FALSE

	var/obj/machinery/ship_weapon/torpedo_launcher/cargo/launcher = console.linked_launcher
	if ( !launcher.chambered )
		to_chat(user, "<span class='warning'>[launcher] has no freight torpedoes loaded!</span>")
		if ( console.linked )
			try_hail( user, console.linked )
		return FALSE

	if ( launcher.safety ) //cannot fire with safety on
		to_chat(user, "<span class='warning'>[launcher] has its safeties on!</span")
		if ( console.linked )
			try_hail( user, console.linked )
		return FALSE

	for(var/a in launcher.chambered.GetAllContents())
		if(is_type_in_typecache(a, GLOB.blacklisted_cargo_types))
			if ( !istype( a, /mob/living/simple_animal ) ) // Allow the transfer of specimens specifically for cargo missions
				to_chat(user, "<span class='warning'>[launcher] Cargo Shuttle Brand lifeform checker blinks an error, \
					for safety reasons it cannot transport hazardous organisms, human remains, classified nuclear weaponry, \
					homing beacons or machinery housing any form of artificial intelligence.")
				return FALSE

	var/choice = input("Transfer cargo to [src]?", "Confirm delivery", "No") in list("Yes", "No")
	if(!choice || choice == "No")
		if ( console.linked )
			try_hail( user, console.linked )
		return FALSE

	var/obj/item/ship_weapon/ammunition/torpedo/freight/shipment = launcher.chambered
	var/success = receive_cargo( user, console, shipment )

	if ( success )
		// Fire the torpedo away to unload the launcher.
		// Without a weapon_type the projectile will not be animated
		launcher.fire( src, shots = 1 )
		// Because it doesn't have a weapon_type to store the overmap_firing_sounds we'll bodge it here
		user?.get_overmap()?.relay( pick( list(
			'nsv13/sound/effects/ship/freespace2/m_shrike.wav',
			'nsv13/sound/effects/ship/freespace2/m_stiletto.wav',
			'nsv13/sound/effects/ship/freespace2/m_tsunami.wav',
			'nsv13/sound/effects/ship/freespace2/m_wasp.wav'
		) ) )
		return TRUE

/obj/structure/overmap/proc/add_objective( objective )
	if ( objective )
		expecting_cargo += objective
		essential = TRUE
		nodamage = TRUE

/obj/structure/overmap/proc/add_holding_cargo( objective )
	if ( objective )
		holding_cargo += objective
		essential = TRUE
		nodamage = TRUE

/obj/structure/overmap/proc/deliver_package(var/mob/living/user, var/datum/overmap_objective/cargo/O)
	if ( !O?.delivered_package )
		var/obj/structure/overmap/MO = SSstar_system.find_main_overmap()
		SEND_SOUND(user, 'nsv13/sound/effects/ship/freespace2/computer/textdraw.wav')
		MO.hail( pick( list(
			"Message received, we are delivering your package for transfer now.",
			"Understood, delivering the cargo.",
			"The package is enroute, make sure it arrives intact to the destination.",
			"Understood, the package is enroute. Is there anything else you needed?",
		) ), src)

		O.deliver_package()
		holding_cargo -= O

/obj/structure/overmap/proc/check_objectives( var/datum/freight_delivery_receipt/receipt )
	if ( !length( expecting_cargo ) )
		reject_unexpected_shipment( receipt )
		return FALSE

	for ( var/datum/overmap_objective/cargo/request in expecting_cargo ) // Only validate this station's cargo related objectives
		if ( request.status != 0 )
			continue

		var/datum/overmap_objective/cargo/objective = request
		var/allCargoPresent = objective.check_cargo( receipt.shipment ) // check_cargo will automatically check for additional trash

		if ( allCargoPresent )
			// Bag it, tag it, store it. Accessible for admin debugging later if needed
			// Able to check off multiple objectives through the loop if crew are piling everything into one torpedo
			receipt.completed_objectives += objective
			expecting_cargo -= request

			// Break from the loop if there are multiple cargo missions requesting the same type of item. No double dipping!
			break

	if ( length( receipt.completed_objectives ) )
		// If multiple objectives were completed, only hail once
		received_cargo += receipt
		approve_shipment( receipt )
		return TRUE
	else
		// If no objectives were completed, reject it and dispose of the receipt
		reject_incomplete_shipment( receipt )
		return FALSE

/obj/structure/overmap/proc/make_paperwork( var/datum/freight_delivery_receipt/receipt, var/approval )
	// Cargo DRADIS automatically synthesizes and attaches the requisition form to the cargo torp
	var/obj/item/paper/paper = new /obj/item/paper()
	var/final_paper_text = "<h2>[receipt.vessel] Shipping Manifest</h2><hr/>"

	if ( length( receipt.completed_objectives ) == 1 )
		var/datum/overmap_objective/cargo/objective = receipt.completed_objectives[ 1 ]
		final_paper_text += "Order: #[GLOB.round_id]-[objective.objective_number]<br/> \
			Destination: [src]<br/> \
			Item: [objective.crate_name]<br/>"
	else
		final_paper_text += "Order: N/A<br/> \
			Destination: [src]<br/> \
			Item: Unregistered Shipment<br/>"

	final_paper_text += "Contents:<br/><ul>"

	if ( istype( receipt.shipment, /obj/item/ship_weapon/ammunition/torpedo/freight ) )
		var/obj/item/ship_weapon/ammunition/torpedo/freight/shipment = receipt.shipment

		// Reveal all contents of the torpedo tube
		for ( var/atom/item in shipment.GetAllContents() )
			// Remove redundant objects that would otherwise always appear on the list
			if ( !is_type_in_typecache( item.type, GLOB.blacklisted_paperwork_itemtypes ) )
				final_paper_text += "<li>[item]</li>"
	else
		final_paper_text += "<li>miscellaneous unpackaged objects</li>"

	final_paper_text += "</ul><h4>Stamp below to confirm receipt of goods:</h4>"

	//paper.stamped = list()
	//paper.stamps = list()
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)

	// Extremely cheap stamp code because the only way to add stamps is through tgui
	if ( approval )
		paper.add_stamp(sheet.icon_class_name("stamp-ok"), 1, 1, 0, "stamp-ok")
		//paper.stamped += "stamp-ok"
		//paper.stamps = list( list(sheet.icon_class_name("stamp-ok"), 1, 1, 0) )
	else
		paper.add_stamp(sheet.icon_class_name("stamp-deny"), 1, 1, 0, "stamp-deny")
		//paper.stamped += "stamp-deny"
		//paper.stamps = list( list(sheet.icon_class_name("stamp-deny"), 1, 1, 0) )

	paper.add_raw_text(final_paper_text)
	paper.update_appearance()
	return paper

/obj/structure/overmap/proc/return_approved_form( var/datum/freight_delivery_receipt/receipt )
	if(receipt?.vessel)
		var/obj/structure/overmap/vessel = receipt.vessel

		// Paperwork! Stations should always stamp their requisition forms as accepted and return to sender
		var/obj/item/paper/requisition_form = make_paperwork( receipt, TRUE )

		vessel.send_supplypod( requisition_form, src, TRUE )

/obj/structure/overmap/proc/reject_unexpected_shipment( var/datum/freight_delivery_receipt/receipt )
	if(receipt?.vessel)
		if ( returns_rejected_cargo )
			SEND_SOUND(receipt.courier, 'nsv13/sound/effects/ship/freespace2/computer/textdraw.wav')
			receipt.vessel.hail( pick( list(
				"We're not expecting any shipments at this time. Please give us some time to arrange the return shipment.",
				"We're not expecting any shipments, please don't send us your trash.",
				"This cargo isn't registered on our supply requests. We will return it as soon as we can.",
				"We haven't asked for any cargo like this. Take your business elsewhere.",
			) ), src)
			addtimer(CALLBACK(src, PROC_REF(return_shipment), receipt), speed_cargo_return)
		else
			SEND_SOUND(receipt.courier, 'nsv13/sound/effects/ship/freespace2/computer/textdraw.wav')
			receipt.vessel.hail( pick( list(
				"We're not expecting any shipments at this time. We hope you weren't attached to this.",
				"We're not expecting any shipments, but our assistants could make use of this.",
				"This cargo isn't registered on our supply requests. We won't be returning this.",
				"We haven't asked for any cargo like this. Take your unwanted business elsewhere.",
			) ), src)

/obj/structure/overmap/proc/reject_incomplete_shipment( var/datum/freight_delivery_receipt/receipt )
	if(receipt?.vessel)
		// Won't check for returns_rejected_cargo if the station is actually expecting cargo, but the torp they receive is incorrect
		SEND_SOUND(receipt.courier, 'nsv13/sound/effects/ship/freespace2/computer/textdraw.wav')
		receipt.vessel.hail( pick( list(
			"Some of the cargo contents are missing. We're sending the crates back, please double check your crates and try again.",
			"We're not expecting this kind of shipment. We will return it as soon as we can.",
			"This cargo isn't matching on our supply requests, please review the attached contents manifest and resend the contents.",
			"We haven't asked for any cargo like this. Take your business elsewhere if you won't complete the job.",
		) ), src)
		addtimer(CALLBACK(src, PROC_REF(return_shipment), receipt), speed_cargo_return)

/obj/structure/overmap/proc/approve_shipment( var/datum/freight_delivery_receipt/receipt )
	if(receipt?.vessel)
		SEND_SOUND(receipt.courier, 'nsv13/sound/effects/ship/freespace2/computer/textdraw.wav')
		receipt.vessel.hail( "Thank you for delivering this cargo. We have marked the supply request as received.", src)
		addtimer(CALLBACK(src, PROC_REF(return_approved_form), receipt), speed_cargo_return)
		SSovermap_mode.update_reminder(objective=TRUE) // Completing any valid delivery resets the timer

/obj/structure/overmap/proc/return_shipment( var/datum/freight_delivery_receipt/receipt )
	if(receipt?.vessel)
		if ( istype( receipt.shipment, /obj/item/ship_weapon/ammunition/torpedo/freight ) )
			var/obj/item/ship_weapon/ammunition/torpedo/freight/F = receipt.shipment
			F.contents += make_paperwork( receipt, FALSE )

		var/obj/structure/overmap/vessel = receipt.vessel
		vessel.send_supplypod( receipt.shipment, src, TRUE )

/obj/structure/overmap/proc/receive_cargo( mob/living/user, var/obj/machinery/computer/ship/dradis/minor/cargo/console, var/obj/item/ship_weapon/ammunition/torpedo/freight/shipment )
	if ( !console.linked )
		return FALSE

	var/obj/structure/overmap/courier = console.linked
	if ( courier.faction != src.faction )
		// Make an exception for syndicate stations specifically, for adminbussing
		if ( !istype( src, /obj/structure/overmap/trader ) )
			return FALSE

		var/obj/structure/overmap/trader/T = src
		if ( !T.inhabited_trader )
			// We're not allowing syndicate to hitscan the player ship with boarders at this time
			to_chat(user, "<span class='warning'>The cargo launcher IFF checker blinks an error, recipient faction is unmatched!</span>")
			return FALSE

	var/datum/freight_delivery_receipt/receipt = new /datum/freight_delivery_receipt()
	receipt.courier = user
	receipt.vessel = console.linked
	receipt.shipment = shipment
	receipts += receipt

	if ( SSovermap_mode.mode.debug_mode )
		speed_cargo_check = 1 SECONDS
		speed_cargo_return = 1 SECONDS

	to_chat(user, "<span class='notice'>The cargo has been sent to [src] and should be received shortly.</span>")
	addtimer(CALLBACK(src, PROC_REF(check_objectives), receipt), speed_cargo_check)

	src.send_supplypod( shipment, courier, TRUE )
	return TRUE

/obj/structure/overmap/proc/hail(var/text, var/ship_name, var/player_name, var/outbound = FALSE)
	if(!text)
		return
	if(!ship_name)
		return
	var/player_string = ""
	if(player_name && player_name != ship_name) // No sender means AI ship, or a ghost ship if the player and ship name are the same
		player_string = " (Sent by [player_name])"

	if(outbound)
		relay('nsv13/sound/effects/ship/freespace2/computer/textdraw.wav', "<h3>Outbound hail to: [ship_name][player_string]</h3><hr><span class='danger'>[text]</span><br>")
	else
		relay('nsv13/sound/effects/ship/freespace2/computer/textdraw.wav', "<h1>Incoming hail from: [ship_name][player_string]</h1><hr><span class='userdanger'>[text]</span><br>")

/proc/get_internet_sound(web_sound_input)
	if(!web_sound_input)
		return
	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		message_admins("<span class='boldwarning'>YT-DL not set up! Check your configs and that you've installed it.</span>")
		return
	if(istext(web_sound_input))
		var/web_sound_url = ""
		if(istext(web_sound_input))
			var/list/music_extra_data = list()
			if(length(web_sound_input))
				web_sound_input = trim(web_sound_input)
			if(findtext(web_sound_input, ":") && !findtext(web_sound_input, GLOB.is_http_protocol))
				message_admins("<span class='boldwarning'>Non-http(s) URIs are not allowed.</span>")
				message_admins("<span class='warning'>For youtube-dl shortcuts like ytsearch: please use the appropriate full url from the website.</span>")
				return
			var/shell_scrubbed_input = shell_url_scrub(web_sound_input)
			var/list/output = world.shelleo("[ytdl] --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_scrubbed_input]\"")
			var/errorlevel = output[SHELLEO_ERRORLEVEL]
			var/stdout = output[SHELLEO_STDOUT]
			var/stderr = output[SHELLEO_STDERR]
			if(!errorlevel)
				var/list/data
				try
					data = json_decode(stdout)
				catch(var/exception/e)
					message_admins("<span class='boldwarning'>Youtube-dl JSON parsing FAILED:</span>")
					message_admins("<span class='warning'>[e]: [stdout]</span>")
					return

				if (data["url"])
					web_sound_url = data["url"]
					music_extra_data["start"] = data["start_time"]
					music_extra_data["end"] = data["end_time"]
				else
					message_admins("<span class='boldwarning'>Youtube-dl URL retrieval FAILED:</span>")
					message_admins("<span class='warning'>[stderr]</span>")
			if(web_sound_url && !findtext(web_sound_url, GLOB.is_http_protocol))
				message_admins("<span class='boldwarning'>BLOCKED: Content URL not using http(s) protocol</span>")
				message_admins("<span class='warning'>The media provider returned a content URL that isn't using the HTTP or HTTPS protocol</span>")
				return
			return list(web_sound_url, music_extra_data)

/datum/fleet/proc/encounter(obj/structure/overmap/OM)
	set waitfor = FALSE

	if(OM.faction == alignment || federation_check(OM))
		OM.hail(pick(greetings), name)
	assemble(current_system)
	if(OM.faction != alignment && !federation_check(OM))
		if(OM.alpha >= 150) //Sensor cloaks my boy, sensor cloaks
			OM.hail(pick(taunts), name)
			last_encounter_time = world.time
			if(audio_cues?.len)
				OM.play_music(pick(audio_cues))

			//Ghost Ship Spawn Here
			if(SSovermap_mode.override_ghost_ships)
				message_admins("Failed to spawn ghost ship due to admin override.")
				return
			if(!prob(20))
				return

			var/player_check = get_active_player_count(alive_check = TRUE, afk_check = TRUE, human_check = TRUE)
			var/list/ship_list = list()
			if(player_check > 15) //Requires 15 active players for most ships
				ship_list += fighter_types
				ship_list += destroyer_types
				ship_list += battleship_types

			else if(player_check > 10) //10 for fighters
				ship_list += fighter_types

			else
				message_admins("Failed to spawn ghost ship due to insufficent players.")
				log_game("Failed to spawn ghost ship due to insufficent players.")
				return

			if(!length(ship_list))
				log_game("No valid [name] ship types found for [player_check] slayers. Using default ship type: [default_ghost_ship]")
				ship_list += default_ghost_ship
				return

			var/target_location = locate(rand(round(world.maxx/2) + 10, world.maxx - 39), rand(40, world.maxy - 39), OM.z)
			var/obj/structure/overmap/selected_ship = pick(ship_list)
			var/target_ghost
			var/list/mob/dead/observer/candidates = pollGhostCandidates("Do you wish to pilot a [initial(selected_ship.faction)] [initial(selected_ship.name)]?", ROLE_GHOSTSHIP, /datum/role_preference/midround_ghost/ghost_ship, 20 SECONDS, POLL_IGNORE_GHOSTSHIP)
			if(LAZYLEN(candidates))
				var/mob/dead/observer/C = pick(candidates)
				target_ghost = C
				var/obj/structure/overmap/GS = new selected_ship(target_location)
				GS.ghost_ship(target_ghost)


///Pass in a youtube link, have it played ONLY on that overmap. This should be called by code or admins only.
/obj/structure/overmap/proc/play_music(url)
	set waitfor = FALSE //Don't hold up the jump
	if(!istext(url))
		return FALSE
	var/list/result = get_internet_sound(url)
	if(!result || !islist(result))
		return
	var/web_sound_url = result[1] //this is cringe but it works
	var/music_extra_data = result[2]
	if(web_sound_url)
		for(var/mob/M in mobs_in_ship)
			if(M.client)
				var/client/C = M.client
				C.tgui_panel?.stop_music()
				C.tgui_panel?.play_music(web_sound_url, music_extra_data)

//Syndicate Fleets

/datum/fleet/neutral
	name = "\improper Syndicate scout fleet"
	fleet_trait = FLEET_TRAIT_NEUTRAL_ZONE

/datum/fleet/border
	name = "\improper Syndicate border defense force"
	supply_types = list(/obj/structure/overmap/syndicate/ai/carrier, /obj/structure/overmap/syndicate/ai/carrier/elite)
	fleet_trait = FLEET_TRAIT_BORDER_PATROL
	hide_movements = TRUE
	size = FLEET_DIFFICULTY_HARD //Border patrol is stronger

/datum/fleet/boarding
	name = "\improper Syndicate commando taskforce"
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/assault_cruiser/boarding_frigate)
	taunts = list("Attention: This is an automated message. All non-Syndicate vessels prepare to be boarded for security clearance.")
	fleet_trait = FLEET_TRAIT_NEUTRAL_ZONE

/datum/fleet/wolfpack
	name = "\improper unidentified Syndicate fleet"
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/submarine)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/cruiser, /obj/structure/overmap/syndicate/ai/cruiser/elite, /obj/structure/overmap/syndicate/ai/mako_flak, /obj/structure/overmap/syndicate/ai/destroyer, /obj/structure/overmap/syndicate/ai/submarine/elite)
	audio_cues = list()
	hide_movements = TRUE
	taunts = list("....", "*static*")
	fleet_trait = FLEET_TRAIT_NEUTRAL_ZONE

/datum/fleet/wolfpack/elite
	name = "\improper unidentified Syndicate taskforce"
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/submarine, /obj/structure/overmap/syndicate/ai/submarine/elite)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/submarine/elite, /obj/structure/overmap/syndicate/ai/cruiser/elite)
	taunts = list(".....", "*loud microphone feedback*", "You've got nowhere to run, and nowhere to hide...")

/datum/fleet/conflagration
	name = "\improper Syndicate conflagration deterrent"
	taunts = list("Enemy ship, surrender now. This vessel is armed with hellfire weapons and eager to test them.")
	audio_cues = list()
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/conflagration, /obj/structure/overmap/syndicate/ai/conflagration/elite)
	size = FLEET_DIFFICULTY_EASY
	fleet_trait = FLEET_TRAIT_NEUTRAL_ZONE

/datum/fleet/elite
	name = "\improper elite Syndicate taskforce"
	taunts = list("Enemy ship, surrender immediately or face destruction.", "Excellent, a worthwhile target. Arm all batteries.")
	supply_types = list(/obj/structure/overmap/syndicate/ai/carrier/elite)
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/destroyer/elite, /obj/structure/overmap/syndicate/ai/submarine/elite)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/cruiser/elite)

//Space Pirate Fleets
/datum/fleet/pirate
	name = "\proper Tortuga Raiders Fleet"
	fighter_types = null
	destroyer_types = list(/obj/structure/overmap/spacepirate/ai)
	battleship_types = list(/obj/structure/overmap/spacepirate/ai/nt_missile, /obj/structure/overmap/spacepirate/ai/syndie_gunboat)
	default_ghost_ship = /obj/structure/overmap/spacepirate/ai
	supply_types = null
	alignment = "pirate"
	faction_id = FACTION_ID_PIRATES
	reward = 35

/datum/fleet/pirate/scout
	name = "\improper Tortuga Raiders scout fleet"
	audio_cues = list()
	taunts = list("Yar har! Fresh meat", "Unfurl the mainsails! We've got company", "Die landlubbers!")
	size = FLEET_DIFFICULTY_MEDIUM
	fleet_trait = FLEET_TRAIT_DEFENSE

/datum/fleet/pirate/raiding
	name = "\improper Tortuga Raiders raiding fleet"
	destroyer_types = list(/obj/structure/overmap/spacepirate/ai, /obj/structure/overmap/spacepirate/ai/boarding)
	audio_cues = list()
	taunts = list("Avast! A fine hold of loot sails our way", "Prepare the boarding crews, they've got enough loot for us all!")
	size = FLEET_DIFFICULTY_MEDIUM

/datum/fleet/pirate/tortuga
	name = "\improper Tortuga Raiders holding fleet"
	supply_types = list(/obj/structure/overmap/spacepirate/ai/dreadnought)
	audio_cues = list()
	taunts = list("These are our waters you are sailing, prepare to surrender!", "Bold of you to fly Nanotrasen colours in this system, your last mistake.")
	size = FLEET_DIFFICULTY_VERY_HARD
	fleet_trait = FLEET_TRAIT_DEFENSE
	reward = 100	//Difficult pirate fleet, so default reward.

/datum/fleet/pirate/tortuga/defeat()
	if(!current_system)
		return ..()
	for(var/obj/structure/overmap/survivor in current_system.system_contents)
		if(survivor.ai_controlled)
			continue
		for(var/mob/living/victorious_mob in survivor.mobs_in_ship)
			if(!victorious_mob.client)
				continue
			victorious_mob.client.give_award(/datum/award/achievement/misc/pirate_exterminator, victorious_mob)
	return ..()


//Boss battles.

/datum/fleet/rubicon //Crossing the rubicon, are we?
	name = "\proper Rubicon Crossing"
	size = FLEET_DIFFICULTY_VERY_HARD
	allow_difficulty_scaling = FALSE
	battleship_types = list(/obj/structure/overmap/syndicate/ai/kadesh)	//:)
	audio_cues = list()
	taunts = list("Better crews have tried to cross the Rubicon, you will die like they did.", "Defense force, stand ready!", "Nanotrasen filth. Munitions, ready the guns. We’ll scrub the galaxy clean of you vermin.", "This shift just gets better and better. I’ll have your Captain’s head on my wall.")
	fleet_trait = FLEET_TRAIT_DEFENSE

/datum/fleet/earthbuster
	name = "\proper Syndicate Armada" //Fleet spawned if the players are too inactive. Set course...FOR EARTH.
	destroyer_types = list(/obj/structure/overmap/syndicate/ai, /obj/structure/overmap/syndicate/ai/conflagration, /obj/structure/overmap/syndicate/ai/assault_cruiser, /obj/structure/overmap/syndicate/ai/gunboat, /obj/structure/overmap/syndicate/ai/submarine, /obj/structure/overmap/syndicate/ai/assault_cruiser/boarding_frigate)
	size = FLEET_DIFFICULTY_INSANE
	allow_difficulty_scaling = FALSE
	taunts = list("We're coming for Sol, and you can't stop us. All batteries fire at will.", "Lay down your arms now, you're outnumbered.", "All hands, assume assault formation. Begin bombardment.")
	audio_cues = list()

/datum/fleet/interdiction	//Pretty strong fleet with unerring hunting senses, Adminspawn for now.
	name = "\improper Syndicate interdiction fleet"	//These fun guys can and will hunt the player ship down, no matter how far away they are.
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/conflagration, /obj/structure/overmap/syndicate/ai/assault_cruiser, /obj/structure/overmap/syndicate/ai/assault_cruiser/boarding_frigate)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/kadesh)
	size = FLEET_DIFFICULTY_HARD
	taunts = list("We have come to end your meagre existance. Prepare to die.", "Hostile entering weapons range. Fire at will.", "You have been a thorn in our side for quite a while. Time to end this.", "That is a nice ship you have there. Nothing a few hellfire missiles cannot fix.")
	audio_cues = list()
	var/obj/structure/overmap/hunted_ship
	initial_move_delay = 5 MINUTES
	minimum_random_move_delay = 2 MINUTES	//These are quite a bunch faster than your usual fleets. Good luck running. It won't save you.
	maximum_random_move_delay = 4 MINUTES
	combat_move_delay = 6 MINUTES

/datum/fleet/interdiction/stealth	//More fun for badmins
	name = "\improper unidentified Syndicate heavy fleet"
	hide_movements = TRUE
	destroyer_types = list(/obj/structure/overmap/syndicate/ai/submarine, /obj/structure/overmap/syndicate/ai/conflagration, /obj/structure/overmap/syndicate/ai/assault_cruiser)

/datum/fleet/interdiction/light	//The syndicate can spawn these randomly (though rare). Be caareful! But, at least they aren't that scary.
	name = "\improper Syndicate light interdiction fleet"
	battleship_types = list(/obj/structure/overmap/syndicate/ai/cruiser)
	size = FLEET_DIFFICULTY_MEDIUM	//Don't let this fool you though, they are still somewhat dangerous and will hunt you down.
	initial_move_delay = 12 MINUTES

/datum/fleet/dolos
	name = "\proper Dolos Welcoming Party" //Don't do it czanek, don't fucking do it!
	size = FLEET_DIFFICULTY_WHAT_ARE_YOU_DOING
	allow_difficulty_scaling = FALSE
	audio_cues = list()
	taunts = list("Don't think we didn't learn from your last attempt.", "We shall not fail again", "Your outdated MAC weapons are no match for us. Prepare to be destroyed.")
	fleet_trait = FLEET_TRAIT_DEFENSE
	destroyer_types = list(/obj/structure/overmap/syndicate/ai, /obj/structure/overmap/syndicate/ai/destroyer/elite, /obj/structure/overmap/syndicate/ai/destroyer/flak, /obj/structure/overmap/syndicate/ai/cruiser/elite, /obj/structure/overmap/syndicate/ai/mako_flak, /obj/structure/overmap/syndicate/ai/mako_carrier)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/cruiser/elite, /obj/structure/overmap/syndicate/ai/conflagration/elite)
	supply_types = list(/obj/structure/overmap/syndicate/ai/carrier/elite)

/datum/fleet/remnant
	name = "\proper The Remnant"
	size = FLEET_DIFFICULTY_WHAT_ARE_YOU_DOING
	allow_difficulty_scaling = FALSE
	audio_cues = list()
	taunts = list("<pre>\[DECRYPTION FAILURE]</pre>")
	fleet_trait = FLEET_TRAIT_DEFENSE
	destroyer_types = list(/obj/structure/overmap/syndicate/ai, /obj/structure/overmap/syndicate/ai/destroyer/elite, /obj/structure/overmap/syndicate/ai/destroyer/flak, /obj/structure/overmap/syndicate/ai/cruiser/elite, /obj/structure/overmap/syndicate/ai/mako_flak, /obj/structure/overmap/syndicate/ai/mako_carrier)
	battleship_types = list(/obj/structure/overmap/syndicate/ai/cruiser/elite, /obj/structure/overmap/syndicate/ai/conflagration/elite)
	supply_types = list(/obj/structure/overmap/syndicate/ai/carrier/elite)

/datum/fleet/unknown_ship
	name = "\improper unknown Syndicate ship class"
	size = 1
	allow_difficulty_scaling = FALSE
	battleship_types = list(/obj/structure/overmap/syndicate/ai/battleship)
	audio_cues = list()
	taunts = list("Your assault on Rubicon only served to distract you from the real threat. It's time to end this war in one swift blow.")
	fleet_trait = FLEET_TRAIT_DEFENSE

/datum/fleet/syndicate/fistofsol_boss
	name = "SSV Fist of Sol"
	faction = FACTION_ID_SYNDICATE
	size = 1
	allow_difficulty_scaling = FALSE
	battleship_types = list(/obj/structure/overmap/syndicate/ai/fistofsol)
	supply_types = list(/obj/structure/overmap/syndicate/ai/carrier/elite)
	taunts = list("What a pleasure that we should meet again. I hope you won't disappoint!")
	fleet_trait = FLEET_TRAIT_DEFENSE

/datum/fleet/hostile/alicorn_boss
	name = "\proper SGV Alicorn"
	size = 1
	hide_movements = TRUE
	allow_difficulty_scaling = FALSE
	fighter_types = list(/obj/structure/overmap/hostile/ai/fighter)
	supply_types = list(/obj/structure/overmap/hostile/ai/alicorn)
	taunts = list("A powerful ship, a powerful gun, powerful ammunition. The graceful slaughter of a billion lives to save billions more, you'll be the first of many.")
	fleet_trait = FLEET_TRAIT_DEFENSE


//Nanotrasen fleets

/datum/fleet/nanotrasen
	name = "\improper Nanotrasen heavy combat fleet"
	fighter_types = list(/obj/structure/overmap/nanotrasen/ai/fighter)
	destroyer_types = list(/obj/structure/overmap/nanotrasen/ai, /obj/structure/overmap/nanotrasen/frigate/ai)
	battleship_types = list(/obj/structure/overmap/nanotrasen/patrol_cruiser/ai, /obj/structure/overmap/nanotrasen/heavy_cruiser/ai, /obj/structure/overmap/nanotrasen/battlecruiser/ai)
	supply_types = list(/obj/structure/overmap/nanotrasen/carrier/ai)
	default_ghost_ship = /obj/structure/overmap/nanotrasen/ai
	alignment = "nanotrasen"
	hide_movements = TRUE //Friendly fleets just move around as you'd expect.
	faction_id = FACTION_ID_NT
	taunts = list("Syndicate vessel, stand down or be destroyed", "You are encroaching on our airspace, prepare to be destroyed", "Unidentified vessel, your existence will be forfeit in accordance with the peacekeeper act.")
	can_reinforce = FALSE
	threat_elevation_allowed = FALSE	//Sorry EDF, nothing personal.

/datum/fleet/nanotrasen/light
	name = "\improper Nanotrasen light fleet"
	battleship_types = list(/obj/structure/overmap/nanotrasen/patrol_cruiser/ai)

/datum/fleet/nanotrasen/border
	name = "\proper Concord Border Enforcement Unit"
	taunts = list("You have violated the law. Stand down your weapons and prepare to be boarded.", "Hostile vessel. Stand down immediately or be destroyed.")
	size = FLEET_DIFFICULTY_EASY
	fleet_trait = FLEET_TRAIT_BORDER_PATROL

/datum/fleet/nanotrasen/border/defense
	name = "\proper 501st 'Crais' Fist' Expeditionary Force"
	taunts = list("You have violated the law. Stand down your weapons and prepare to be boarded.", "Hostile vessel. Stand down immediately or be destroyed.")
	size = FLEET_DIFFICULTY_EASY
	fleet_trait = FLEET_TRAIT_DEFENSE

//Solgov

/datum/fleet/solgov
	name = "\improper Solgov light exploratory fleet"
	fighter_types = list(/obj/structure/overmap/nanotrasen/solgov/ai/fighter)
	destroyer_types = list(/obj/structure/overmap/nanotrasen/solgov/ai)
	battleship_types = list(/obj/structure/overmap/nanotrasen/solgov/aetherwhisp/ai)
	supply_types = list(/obj/structure/overmap/nanotrasen/solgov/carrier/ai)
	alignment = "solgov"
	hide_movements = TRUE //They're "friendly" alright....
	faction_id = FACTION_ID_NT
	taunts = list("You are encroaching on our airspace, prepare to be destroyed", "You have entered SolGov secure airspace. Prepare to be destroyed", "You are in violation of the SolGov non-aggression agreement. Leave this airspace immediately.")
	size = FLEET_DIFFICULTY_EASY
	greetings = list("Allied vessel. You will be scanned for compliance with the peacekeeper act in 30 seconds. We thank you for your compliance.")
	var/scan_delay = 30 SECONDS
	var/scanning = FALSE

/datum/fleet/solgov/earth
	name = "\proper Earth Defense Force"
	taunts = list("You're foolish to venture this deep into Solgov space! Main batteries stand ready.", "All hands, set condition 1 throughout the fleet, enemy vessel approaching.", "Defense force, stand ready!", "We shall protect our homeland!")
	size = FLEET_DIFFICULTY_HARD
	allow_difficulty_scaling = FALSE
	audio_cues = list()
	fleet_trait = FLEET_TRAIT_DEFENSE

/datum/fleet/solgov/assemble(datum/star_system/SS, difficulty)
	. = ..()
	if(!scanning)
		addtimer(CALLBACK(src, PROC_REF(scan)), scan_delay)
		scanning = TRUE

/datum/fleet/solgov/proc/scan()
	scanning = FALSE
	if(!current_system)
		return FALSE
	for(var/obj/structure/overmap/OM in current_system.system_contents)
		OM.relay('nsv13/sound/effects/ship/solgov_scan.ogg')
	sleep(5 SECONDS)
	for(var/obj/structure/overmap/shield_scan_target in current_system.system_contents)
		if(istype(shield_scan_target, /obj/structure/overmap/nanotrasen/solgov))
			continue //We don't scan our own boys.
		//Ruh roh.... (Persona non gratas do not need to be scanned again.)
		if((shield_scan_target.faction != shield_scan_target.name) && shield_scan_target.shields && shield_scan_target.shields.active && length(shield_scan_target.occupying_levels))
			shield_scan_target.hail("Scans have detected that you are in posession of prohibited technology. \n Your IFF signature has been marked as 'persona non grata'. \n In accordance with SGC-reg #10124, your ship and lives are now forfeit. Evacuate all civilian personnel immediately and surrender yourselves.", name)
			shield_scan_target.relay_to_nearby('nsv13/sound/effects/ship/solgov_scan_alert.ogg', ignore_self=FALSE)
			shield_scan_target.faction = shield_scan_target.name
			grant_oopsie_achievement(shield_scan_target)

/datum/fleet/solgov/proc/grant_oopsie_achievement(obj/structure/overmap/fugitive)
	for(var/mob/living/traitor in fugitive.mobs_in_ship)
		if(!traitor.client)
			continue
		traitor.client.give_award(/datum/award/achievement/misc/illegal_technology, traitor)

/datum/fleet/solgov/interdiction
	name = "\improper Solgov hunter fleet"
	destroyer_types = list(/obj/structure/overmap/nanotrasen/solgov/ai/interdictor)
	var/list/traitor_taunts = list("Rogue vessel, reset your identification codes immediately or be destroyed.", "The penalty for defection is death.", "Your crew is charged with treason and breach of contract. Lethal force is authorized.")
	size = FLEET_DIFFICULTY_INSANE
	var/players_fired_upon = FALSE
	var/obj/structure/overmap/hunted_ship

/datum/fleet/solgov/interdiction/New()
	. = ..()
	hunted_ship = SSstar_system.find_main_overmap()

/datum/fleet/solgov/interdiction/move(datum/star_system/target, force=FALSE)
	// If we're going home just delete us actually
	// Don't let the players game the ability to make solgov show up
	if(!hunted_ship && goal_system)
		qdel(src)
		return
	if(!target && hunted_ship)
		goal_system = hunted_ship.current_system
	. = ..()
	if(.)
		navigate_to(goal_system)	//Anytime we successfully move we recalculate the route, since players like moving around alot.

/datum/fleet/solgov/interdiction/assemble(datum/star_system/SS, difficulty)
	. = ..()
	for(var/obj/structure/overmap/OM as() in all_ships)
		RegisterSignal(OM, COMSIG_ATOM_BULLET_ACT, PROC_REF(check_bullet))

/datum/fleet/solgov/interdiction/encounter(obj/structure/overmap/OM)
	// Same as parent but detects if the player ship is hostile and uses different taunts
	if(OM.faction == alignment || federation_check(OM))
		OM.hail(pick(greetings), name)
	assemble(current_system)
	if(OM.faction != alignment && !federation_check(OM))
		if(OM.alpha >= 150)
			if(OM == SSstar_system.find_main_overmap())
				OM.hail(pick(traitor_taunts), name)
				RegisterSignal(OM, COMSIG_SHIP_BOARDED, PROC_REF(handle_iff_change))
			else
				OM.hail(pick(taunts), name)
			last_encounter_time = world.time
			if(audio_cues?.len)
				OM.play_music(pick(audio_cues))

/datum/fleet/solgov/interdiction/proc/check_bullet(obj/structure/overmap/source, obj/item/projectile/P)
	if(P.overmap_firer?.role == MAIN_OVERMAP)
		players_fired_upon = TRUE
		for(var/obj/structure/overmap/OM as() in all_ships)
			UnregisterSignal(OM, COMSIG_ATOM_BULLET_ACT)

/datum/fleet/solgov/interdiction/proc/handle_iff_change(obj/structure/overmap/source)
	switch(source.faction)
		if("nanotrasen")
			if(!players_fired_upon)
				hunted_ship = null
				goal_system = SSstar_system.system_by_id("Sol")
				if(current_system == source.current_system)
					source.hail("Don't let it happen again.", name)
			else if(current_system == source.current_system)
				source.hail("... That's not going to cut it anymore.", name)
		if("syndicate")
			// Anger
			hunted_ship = source
			goal_system = null

/datum/fleet/proc/federation_check(checked = current_system) //Lazy way to check if you're in the federation; for alignments.
	if(istype(checked, /datum/star_system))
		var/datum/star_system/S = checked
		if(S.owner == "solgov" && alignment == "nanotrasen")
			return TRUE
		if(S.owner == "nanotrasen" && alignment == "solgov")
			return TRUE
	if(istype(checked, /datum/fleet))
		var/datum/fleet/F = checked
		if(F.alignment == "solgov" && alignment == "nanotrasen")
			return TRUE
		if(F.alignment == "nanotrasen" && alignment == "solgov")
			return TRUE
	if(istype(checked, /obj/structure/overmap))
		var/obj/structure/overmap/O = checked
		if(O.faction == "solgov" && alignment == "nanotrasen")
			return TRUE
		if(O.faction == "nanotrasen" && alignment == "solgov")
			return TRUE
	return FALSE

/datum/fleet/New()
	. = ..()
	if(allow_difficulty_scaling)
		//Account for pre-round spawned fleets.
		if(SSovermap_mode?.mode)
			applied_size = SSovermap_mode.mode.difficulty
		else
			applied_size = 1 //Lets assume a low number of players
	else
		applied_size = size
	applied_size = CLAMP(applied_size, FLEET_DIFFICULTY_EASY, INFINITY)
	faction = SSstar_system.faction_by_id(faction_id)
	reward *= applied_size //Bigger fleet = larger reward
	if(istype(SSticker.mode, /datum/game_mode/pvp)) //Disables notoriety during Galactic Conquest.
		threat_elevation_allowed = FALSE
	if(SSovermap_mode && threat_elevation_allowed)
		applied_size += round(SSovermap_mode.threat_elevation / TE_POINTS_PER_FLEET_SIZE)	//Threat level modifies danger
	if(current_system)
		current_system.alignment = alignment
		if(current_system.alignment != current_system.owner && !federation_check())
			current_system.mission_sector = TRUE
		assemble(current_system)
	addtimer(CALLBACK(src, PROC_REF(move)), initial_move_delay)

/datum/fleet/proc/add_ship(var/obj/structure/overmap/member, role as text)
	if(!istype(member) || !role)
		return
	taskforces[role] += member
	member.fleet = src
	member.current_system = current_system
	if(alignment != "nanotrasen" && alignment != "solgov") //NT, SGC or whatever don't count as enemies that NT hire you to kill.
		current_system.enemies_in_system += member
	all_ships += member
	RegisterSignal(member, COMSIG_PARENT_QDELETING , /datum/fleet/proc/remove_ship, member)
	RegisterSignal(member, COMSIG_SHIP_BOARDED , /datum/fleet/proc/remove_ship, member)

	if(current_system.occupying_z)
		current_system.add_ship(member)
	else
		LAZYADD(current_system.system_contents, member)
		current_system.contents_positions[member] = list("x" = rand(15, 240), "y" = rand(15, 240)) //If the system isn't loaded, just give them randomized positions.
		STOP_PROCESSING(SSphysics_processing, member)
		if(member.physics2d)
			STOP_PROCESSING(SSphysics_processing, member.physics2d)

//A fleet has entered a system. Assemble the fleet so that it lives in this system now.
/datum/fleet/proc/assemble(datum/star_system/SS, difficulty=applied_size)
	if(!SS)
		return
	if(SS.occupying_z && instantiated)
		for(var/obj/structure/overmap/unbox in all_ships)
			if(SS.occupying_z != unbox.z)	//If we have ships 'stored' in nullspace or somewhere else, get them all into our system.
				SS.add_ship(unbox)
				START_PROCESSING(SSphysics_processing, unbox) //And let's restart its processing since it's likely stopped if they were in nullspace.
				if(unbox.physics2d)
					START_PROCESSING(SSphysics_processing, unbox.physics2d) //Respawn this ship's collider so it can start colliding once more
		return
	if(instantiated)
		return
	SS.alignment = alignment
	if(SS.alignment != SS.owner && !federation_check(SS))
		SS.mission_sector = TRUE
	current_system = SS	//It should already have a system but lets be safe and move it.
	instantiated = TRUE
	/*Fleet comp! Let's use medium as an example:
	6 total
	3 destroyers (1/2 of the fleet size)
	2 battleships (1/4th of the fleet)
	2 supply ships (1/4th of the fleet)
	*/
	//This may look lazy, but it's easier than storing all this info in one massive dict. Deal with it!
	if(destroyer_types?.len)
		for(var/I=0; I<max(round(difficulty/2), 1);I++)
			var/shipType = pick(destroyer_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "destroyers")
	if(battleship_types?.len)
		for(var/I=0; I<max(round(difficulty/4), 1);I++)
			var/shipType = pick(battleship_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "battleships")
	if(supply_types?.len)
		for(var/I=0; I<max(round(difficulty/4), 1);I++)
			var/shipType = pick(supply_types)
			var/obj/structure/overmap/member = new shipType()
			add_ship(member, "supply")
	if(SS.check_conflict_status())
		if(!SSstar_system.contested_systems.Find(SS))
			SSstar_system.contested_systems.Add(SS)
	return TRUE

/datum/ai_goal
	var/name = "Placeholder goal" //Please keep these human readable for debugging!
	var/score = 0
	var/required_ai_flags = NONE //Set this if you want this task to only be achievable by certain types of ship. This is a bitfield.

//Method to get the score of a certain action. This can change the "base" score if the score of a specific action goes up, to encourage skynet to go for that one instead.
//@param OM - If you want this score to be affected by the stats of an overmap.
/datum/ai_goal/proc/check_score(obj/structure/overmap/OM)
	if(!istype(OM) || !OM.ai_controlled)
		return 0 //0 Score, in other terms, the AI will ignore this task completely.
	if(!CHECK_MULTIPLE_BITFIELDS(OM.ai_flags, required_ai_flags))
		return 0
	return (score > 0 ? score : TRUE) //Children sometimes NEED this true value to run their own checks.

//Delete the AI's last orders, tell the AI ship what to do.
/datum/ai_goal/proc/assume(obj/structure/overmap/OM)
	if(OM.current_goal)
		OM.current_goal = null
	action(OM)

//What happens when the AI ship physically assumes this goal? This is the method you'll want to override to make the AI ship do things!
/datum/ai_goal/proc/action(obj/structure/overmap/OM)
	OM.current_goal = src

/datum/ai_goal/rearm
	name = "Re-arm at supply ship"
	score = 0

//If the ship in question is low health, or low on ammo, it will attempt to re-arm and repair at a supply ship. If there are no supply ships, then we'll ignore this one.

/datum/ai_goal/rearm/check_score(obj/structure/overmap/OM)
	if(!..() || !OM.fleet) //If it's not an overmap, or it's not linked to a fleet.
		return 0
	var/list/L = OM.fleet.taskforces["supply"] //I don't know why we have to do it this way, but dreamchecker is forcing us to.
	if(!L.len)
		return 0 //Can't resupply if there's no supply station/ship. Carry on fighting!
	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY) && L.len == 1)	//We are the only supply ship left, no resupplying for us.
		return 0
	if(OM.obj_integrity < OM.max_integrity/3)
		return AI_SCORE_SUPERPRIORITY
	if(OM.shots_left < initial(OM.shots_left)/3)
		return AI_SCORE_PRIORITY
	return 0

/datum/ai_goal/rearm/action(obj/structure/overmap/OM)
	..()
	if(OM.current_lance)
		var/datum/lance/L = OM.current_lance
		if(L.lance_target && L.last_finder == OM)
			L.lance_target = null	//Clear our relayed target if we fly to resupply to make it a bit easier on the players.
			L.last_finder = null
	var/obj/structure/overmap/supplyPost = null
	var/list/orig_resupply_points = OM.fleet.taskforces["supply"]
	var/list/resupply_points = orig_resupply_points.Copy()
	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))
		resupply_points.Remove(src)
	for(var/obj/structure/overmap/supply in resupply_points)
		supplyPost = supply
		break
	if(supplyPost) //Neat, we've found a supply post. Autobots roll out.
		if(overmap_dist(OM, supplyPost) <= AI_PDC_RANGE)
			OM.brakes = TRUE
			OM.move_mode = null
		else
			OM.move_toward(supplyPost)

/datum/ai_goal/seek
	name = "Search and destroy"
	score = AI_SCORE_DEFAULT

/datum/ai_goal/seek/check_score(obj/structure/overmap/OM)
	if(!OM.fleet && !OM.current_lance) //If this is a rogue / lone AI. This should be their only objective.
		return AI_SCORE_MAXIMUM
	if(!..()) //If it's not an overmap, or it's not linked to a fleet.
		return 0
	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))
		return 0	//Carriers don't hunt you down, they just patrol. The dirty work is reserved for their escorts.
	if(QDELETED(OM.last_target) || !OM.fleet?.is_reporting_target(OM.last_target, OM))
		OM.seek_new_target()
	if(OM.last_target) //If we can't find a target, then don't bother hunter-killering.
		return score
	else
		return AI_SCORE_VERY_LOW_PRIORITY //Just so that there's a "default" behaviour to avoid issues.

/datum/ai_goal/seek/action(obj/structure/overmap/OM)
	..()
	if(OM.last_target)
		if(overmap_dist(OM, OM.last_target) <= 10)
			OM.circle_around(OM.last_target)
		else
			OM.move_toward(OM.last_target)
	else
		OM.send_radar_pulse() //Send a pong when we're actively hunting.
		OM.seek_new_target()
		OM.move_toward(null) //Just fly around in a straight line, I guess.

/*
Ships with this goal create a a lance, but are not exactly bound to it. They'll fly off on their own if they find a closeby target, but if they have none they'll try assisting with their lance target.
*/
/datum/ai_goal/swarm
	name = "Join a lance and subsequently search & swarm targets."
	score = AI_SCORE_DEFAULT + AI_SCORE_VERY_LOW_PRIORITY	//This is a tiiiny bit better of a goal than normal ones.
	required_ai_flags = AI_FLAG_SWARMER

/datum/ai_goal/swarm/check_score(obj/structure/overmap/OM)
	if(!..())
		return 0
	if(!OM.fleet && !OM.current_lance)
		return 0
	if(OM.current_lance)
		return AI_SCORE_PRIORITY
	return score

/datum/ai_goal/swarm/action(obj/structure/overmap/OM)
	..()
	if(!OM.current_lance)	//If we aren't in a lance already: Handle that.
		if(!OM.fleet)
			return
		for(var/datum/lance/L in OM.fleet.lances)
			if(L.member_count < L.maximum_members)
				L.add_member(OM)
				break
		if(!OM.current_lance)	//we didn't find a lance to join, make our own
			new /datum/lance(OM, OM.fleet)
	if(!OM.current_lance)
		return	//Something that shouldn't have happened happened.

	var/datum/lance/L = OM.current_lance
	if(QDELETED(OM.last_target) || !OM.fleet?.is_reporting_target(OM.last_target, OM))
		OM.send_radar_pulse()
		OM.seek_new_target()

	if(QDELETED(OM.last_target))	//We didn't find a target
		if(L.lance_target)
			if(L.last_finder == OM)
				L.lance_target = null
				L.last_finder = null
				regroup_swarm(OM, L)
				return
			else
				OM.add_enemy(L.lance_target)
				OM.last_target = L.lance_target
		else	//No targets anywhere we could grab, regroup or float, depending on if you are the leader.
			regroup_swarm(OM, L)
			return
	//If we get to here, we should have a target
	if(!L.lance_target)	//Relay target
		L.lance_target = OM.last_target
		L.last_finder = OM

	else if(L.last_finder == OM && OM.last_target != L.lance_target)	//We switched targets, relay this too.
		L.lance_target = OM.last_target

	if(overmap_dist(OM, OM.last_target) <= 4)	//Strafe Flyby (and / or ram) them.
		OM.desired_angle = overmap_angle(OM, OM.last_target)
		OM.move_mode = null
	else
		OM.move_toward(OM.last_target)

/*
If leader: Return to a bigger ship and wait around it.
If not leader: Return to leader.
Staging point priorities are supply ships > battleships > destroyers > just float
*/
/datum/ai_goal/swarm/proc/regroup_swarm(var/obj/structure/overmap/OM, var/datum/lance/L)
	var/obj/structure/overmap/movement_target
	if(OM == L.lance_leader)
		movement_target = find_staging_point(OM)
	else
		movement_target = L.lance_leader

	if(!movement_target)
		OM.move_toward(null)	//Just drift I guess?
	else
		if(overmap_dist(OM, movement_target) <= 8)
			OM.brakes = TRUE
			OM.move_mode = null
			OM.desired_angle = movement_target.angle //Style points
		else
			OM.move_toward(movement_target)
/*
Seek a ship thich we'll station ourselves around
*/
/datum/ai_goal/swarm/proc/find_staging_point(var/obj/structure/overmap/OM)
	var/list/L	//We need this
	if(!OM.fleet)
		return
	L = OM.fleet.taskforces["supply"]
	if(L.len)
		return L[1]	//gives us a consistant target.
	L = OM.fleet.taskforces["battleships"]
	if(L.len)
		return L[1]
	L = OM.fleet.taskforces["destroyers"]
	if(L.len)
		return L[1]

/datum/ai_goal/kamikaze
	name = "Ram Target at fullspeed like a fly bumping against a closed window."
	score = AI_SCORE_SUPERCRITICAL
	required_ai_flags = AI_FLAG_SWARMER

/datum/ai_goal/kamikaze/check_score(obj/structure/overmap/OM)
	if(!..())
		return 0
	if(OM.fleet)
		var/list/L = OM.fleet.taskforces["supply"]
		if(L.len)
			return 0
	if(OM.shots_left)
		return 0	//Gotta have run dry.

	if(QDELETED(OM.last_target))
		return 0

	return score

/datum/ai_goal/kamikaze/action(obj/structure/overmap/OM)
	..()
	OM.move_toward(OM.last_target, ram_target = TRUE)

//Boarding! Boarders love to board your ships.
/datum/ai_goal/board
	name = "Board target"
	score = AI_SCORE_HIGH_PRIORITY
	required_ai_flags = AI_FLAG_BOARDER

/datum/ai_goal/board/check_score(obj/structure/overmap/OM)
	if(!..())
		return 0
	if(QDELETED(OM.last_target) || !OM.fleet?.is_reporting_target(OM.last_target, OM))
		OM.seek_new_target(max_weight_class=null, min_weight_class=null, interior_check=TRUE)
	if(OM.last_target) //If we can't find a target, then don't bother hunter-killering.
		return score
	else
		return AI_SCORE_VERY_LOW_PRIORITY //Just so that there's a "default" behaviour to avoid issues.

/datum/ai_goal/board/action(obj/structure/overmap/OM)
	..()
	if(OM.last_target)
		OM.move_toward(OM.last_target)
		if(overmap_dist(OM.last_target, OM) <= 8)
			var/obj/structure/overmap/foo = OM.last_target
			if(istype(foo))
				OM.desired_angle = foo.angle //Pull up parallel beside it for style points.
		if(OM.can_board(OM.last_target))
			OM.try_board(OM.last_target)
			return FALSE
	else
		OM.move_toward(null) //Just fly around in a straight line, I guess.

/datum/ai_goal/defend
	name = "Protect supply lines"
	score = AI_SCORE_LOW_PRIORITY

/datum/ai_goal/defend/action(obj/structure/overmap/OM)
	..()
	if(prob(5))	//Sometimes ping, but not that often.
		OM.send_radar_pulse()
	if(!OM.defense_target || QDELETED(OM.defense_target))
		var/list/supplyline = OM.fleet.taskforces["supply"]
		OM.defense_target = supplyline?.len ? pick(OM.fleet.taskforces["supply"]) : OM

	if(OM.defense_target.last_target && overmap_dist(OM.defense_target, OM.defense_target.last_target) < OM.defense_target.max_weapon_range * 1.5)	//Enemy close to our defense target, prioritize.
		defensively_engage(OM, OM.defense_target.last_target)
		return
	if(OM.last_target && (overmap_dist(OM, OM.defense_target) <= OM.max_weapon_range * 2 || overmap_dist(OM.last_target, OM.defense_target) <= OM.max_weapon_range * 2))	//If we have a target and they're somewhat close to our defense target: Engage them.
		defensively_engage(OM, OM.last_target)
		return

	guard(OM, OM.defense_target) //Otherwise: Fly to the defense target and vibe there.

//Proc for flying close to a target, then copying its angle. Usually used to defend, probably useful elsewhere.
/datum/ai_goal/proc/guard(obj/structure/overmap/OM, obj/structure/overmap/to_guard)
	if(overmap_dist(OM, to_guard) <= AI_PDC_RANGE)
		OM.brakes = TRUE
		OM.move_mode = null
		OM.desired_angle = to_guard.angle //Turn and face boys!
	else
		OM.move_toward(to_guard)

//Proc for flying towards a target till pretty close, then orbiting said target. Usually used to engage enemies.
/datum/ai_goal/proc/defensively_engage(obj/structure/overmap/OM, obj/structure/overmap/to_engage)
	if(overmap_dist(OM, to_engage) <= 10)
		OM.circle_around(to_engage)
	else
		OM.move_toward(to_engage)
		OM.send_radar_pulse()

//Battleships love to stick to supply ships like glue. This becomes the default behaviour if the AIs cannot find any targets.
/datum/ai_goal/defend/check_score(obj/structure/overmap/OM)
	if(!..() || !OM.fleet) //If it's not an overmap, or it's not linked to a fleet.
		return score
	var/list/supplyline = OM.fleet.taskforces["supply"]
	if(!supplyline || !supplyline.len)
		return 0	//If there is nothing to defend, lets hunt the guys that destroyed our supply line instead.
	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))
		return 0	//Can't defend ourselves

	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_BATTLESHIP))
		if(OM.obj_integrity < OM.max_integrity/3 || OM.shots_left < initial(OM.shots_left)/3)
			return AI_SCORE_PRIORITY - 1	//If we are out of ammo, prioritize rearming over chasing.
		return AI_SCORE_CRITICAL
	return score //If you've got nothing better to do, come group with the main fleet.

//Goal used entirely for supply ships, signalling them to run away! Most ships use the "repair and re-arm" goal instead of this one.
/datum/ai_goal/retreat
	name = "Maintain safe distance from enemies"

//Supply ships are timid, and will always try to run.
/datum/ai_goal/retreat/check_score(obj/structure/overmap/OM)
	if(!..() || !OM.fleet) //If it's not an overmap, or it's not linked to a fleet.
		return 0
	if(!CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))
		return 0
	if( OM.last_target)
		OM.fleet.stop_reporting(OM.last_target, src)
	OM.last_target = null
	OM.seek_new_target(max_distance = OM.max_tracking_range)	//Supply ships will only start running if an enemy actually comes close.
	if(OM.last_target)
		return AI_SCORE_CRITICAL
	return AI_SCORE_VERY_LOW_PRIORITY

//Supply ships are sheepish, and like to run away. Otherwise, they patrol the sector until they find enemies, in which case they run and let their escorts handle the rest.

/datum/ai_goal/retreat/action(obj/structure/overmap/OM)
	..()
	OM.brakes = TRUE
	var/obj/structure/overmap/foo = OM.last_target
	if(!foo || !istype(foo) || overmap_dist(OM, foo) > OM.max_weapon_range) //You can run on for a long time, run on for a long time, run on for a long time, sooner or later gonna cut you down
		return //Just drift aimlessly, let the fleet form up with it.
	OM.move_away_from(foo) //Turn the opposite direction and run.

//Patrol goal in case there is no target.
/datum/ai_goal/patrol
	name = "Patrol system"
	score = AI_SCORE_DEFAULT

/datum/ai_goal/patrol/check_score(obj/structure/overmap/OM)
	if(!..())
		return 0
	if(!OM.last_target || !OM.fleet?.is_reporting_target(OM.last_target, OM))
		OM.seek_new_target()
	if(OM.last_target)
		if(overmap_dist(OM, OM.last_target) < OM.max_tracking_range)
			OM.patrol_target = null	//Clear our destination if we are getting close to the enemy. Otherwise we resume patrol to our old destination.
			return 0
		if(!CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))	//Supply ships only stop patrolling to run away (which when needed still has higher score
			return 0
	if(CHECK_BITFIELD(OM.ai_flags, AI_FLAG_SUPPLY))
		if(OM.resupplying)
			return 0
		return AI_SCORE_HIGH_PRIORITY	//Supply ships like slowly patrolling the sector.
	return score

/datum/ai_goal/patrol/action(obj/structure/overmap/OM)
	..()
	if(prob(8))	//Ping every now and then, so things can't sneak up on you.
		OM.send_radar_pulse()
	if(OM.patrol_target && overmap_dist(OM, OM.patrol_target) <= 8)
		OM.patrol_target = null	//You have arrived at your destination.
		if(OM.mines_left >= 1) //Deploy a mine if you have one, this should spread them out nicely
			OM.deploy_mine()
	if(!OM.patrol_target || OM.patrol_target.z != OM.z)
		var/min_x = max(OM.x - 50, 15)
		var/max_x = min(OM.x + 50, 240)
		var/min_y = max(OM.y - 50, 15)
		var/max_y = min(OM.y + 50, 240)
		var/x_target = rand(min_x, max_x)
		var/y_target = rand(min_y, max_y)
		OM.patrol_target = locate(x_target, y_target, OM.z)
	if(!OM.patrol_target)
		return	//Somehow, there still is no target. Well, return it is.

	OM.move_toward(OM.patrol_target)





//Goal used for anti-fighter craft, encouraging them to attempt to lock on to smaller ships.
/datum/ai_goal/seek/flyswatter
	name = "Hunt down fighters"
	required_ai_flags = AI_FLAG_ANTI_FIGHTER
	score = AI_SCORE_PRIORITY

//Kill the fighters
/datum/ai_goal/seek/flyswatter/check_score(obj/structure/overmap/OM)
	if(!..())
		return 0
	var/obj/structure/overmap/target = OM.last_target
	if(!OM.last_target || !istype(target) || QDELETED(OM.last_target) || target.mass > MASS_TINY || !OM.fleet?.is_reporting_target(OM.last_target, OM))
		OM.seek_new_target(max_weight_class=MASS_TINY)
	if(OM.last_target) //If we can't find a target, then don't bother hunter-killering.
		return score
	else
		return 0 //Default back to the "hunt down ships" behaviour.

/datum/ai_goal/stationary
	name = "Remain in place and defend against attackers"
	required_ai_flags = AI_FLAG_STATIONARY
	score = AI_SCORE_MAXIMUM + 1	//Stations do nothing else. Maximum++ to avoid conflict with Seek and Destroy.

/datum/ai_goal/stationary/action(obj/structure/overmap/OM)
	..()
	if(!OM.last_target)
		OM.seek_new_target()
	OM.brakes = TRUE


/obj/structure/overmap/proc/choose_goal()
	//Populate the list of valid goals, if we don't already have them
	if(!GLOB.ai_goals.len)
		for(var/x in (subtypesof(/datum/ai_goal) - typesof(/datum/ai_goal/human)))
			var/datum/ai_goal/newGoal = new x
			GLOB.ai_goals += newGoal
	var/best_score = 0
	var/datum/ai_goal/chosen = null
	for(var/datum/ai_goal/goal in GLOB.ai_goals)
		var/newScore = goal.check_score(src)
		if(newScore > best_score)
			best_score = newScore
			chosen = goal
	if(!chosen)
		return //Uh..yeah..whoops?
	if(chosen == current_goal)
		chosen.action(src)
		return
	chosen.assume(src)

//Basic inherited stuff that we need goes here:

/obj/structure/overmap
	var/ai_controlled = FALSE //Set this to true to let the computer fly your ship.
	var/ai_behaviour = null // Determines if the AI ship shoots you first, or if you have to shoot them.
	var/list/enemies = list() //Things that have attacked us
	var/max_weapon_range = 50
	var/max_tracking_range = 50//50, 100 when pinging - Range that AI ships can hunt you down in. The amounts to almost half the Z-level.
	var/obj/structure/overmap/defense_target = null
	var/ai_can_launch_fighters = FALSE //AI variable. Allows your ai ships to spawn fighter craft
	var/list/ai_fighter_type = list()
	var/ai_flags = AI_FLAG_DESTROYER
	///Overmap bitflags
	var/overmap_flags = NONE

	var/list/holding_cargo = list() // list of objective datums. This station has cargo to deliver to the players as part of a courier objective
	var/list/expecting_cargo = list() // list of objective datums. This station is expecting cargo delivered to them by the players as a part of a courier objective
	var/list/received_cargo = list() // list of typically freight torps. This station has received cargo
	var/list/receipts = list() // All cargo delivery attempts made to this station
	var/essential = FALSE // AI targeting will ignore essential stations to preserve ammo. At least I hope, there's a thousand places AI last_target is updated
	var/nodamage = FALSE // Mob immunity equivalent for stations, used for mission critical targets. Separate var if mission critical stations need to be essential but not immortal
	var/supply_pod_type = /obj/structure/closet/supplypod/centcompod
	var/returns_rejected_cargo = TRUE // AI ships will return cargo that does not match their expected shipments
	var/speed_cargo_check = 30 SECONDS // Time it takes for a ship to respond to a shipment
	var/speed_cargo_return = 30 SECONDS // Time it takes for a ship to return shipment results (approved paperwork, rejected shipment)

	var/last_decision = 0
	var/decision_delay = 2 SECONDS
	var/move_mode = 0
	var/next_boarding_attempt = 0
	var/mine_cooldown = 0

	var/reloading_torpedoes = FALSE
	var/reloading_missiles = FALSE
	var/static/list/warcrime_blacklist = typecacheof(list(/obj/structure/overmap/small_craft/escapepod, /obj/structure/overmap/asteroid, /obj/structure/overmap/trader/independent))//Ok. I'm not THAT mean...yet. (Hello karmic, it's me karmic 2) Hello Karmic this is Bokkie being extremely lazy (TODO: make the unaligned faction excluded from targeting)

	//Fleet organisation
	var/shots_left = 15 //Number of arbitrary shots an AI can fire with its heavy weapons before it has to resupply with a supply ship.
	var/light_shots_left = 300
	var/mines_left = 0
	var/resupply_range = 15
	var/resupplying = 0	//Are we resupplying things right now? If yes, how many?
	var/can_resupply = FALSE //Can this ship resupply other ships?
	var/obj/structure/overmap/resupply_target = null
	var/datum/fleet/fleet = null
	var/datum/current_lance = null	//Some ships can assign themselves to a lance, which will act together.
	var/turf/patrol_target = null
	var/datum/ai_goal/current_goal = null
	var/obj/structure/overmap/squad_lead = null
	var/obj/structure/overmap/last_overmap = null
	var/switchsound_cooldown = 0

/obj/structure/overmap/proc/ai_fire(atom/target)
	if(istype(target, /obj/structure/overmap))
		add_enemy(target)
		var/target_range = overmap_dist(src,target)
		var/new_firemode = FIRE_MODE_GAUSS
		if(target_range > max_weapon_range) //Our max range is the maximum possible range we can engage in. This is to stop you getting hunted from outside of your view range.
			if(fleet)
				fleet.stop_reporting(target, src)
			last_target = null
			return
		var/best_distance = INFINITY //Start off infinitely high, as we have not selected a distance yet.
		var/uses_main_shot = FALSE //Will this shot count as depleting "shots left"? Heavy weapons eat ammo, PDCs do not.
		//So! now we pick a weapon.. We start off with PDCs, which have an effective range of "5". On ships with gauss, gauss will be chosen 90% of the time over PDCs, because you can fire off a PDC salvo anyway.
		//Heavy weapons take ammo, stuff like PDC and gauss do NOT for AI ships. We make decisions on the fly as to which gun we get to shoot. If we've run out of ammo, we have to resort to PDCs only.
		for(var/I = FIRE_MODE_ANTI_AIR; I <= MAX_POSSIBLE_FIREMODE; I++) //We should ALWAYS default to PDCs.
			var/datum/ship_weapon/SW = weapon_types[I]
			if(!SW)
				continue
			var/distance = target_range - SW.range_modifier //How close to the effective range of the given weapon are we?
			if(distance < best_distance)
				if(!SW.valid_target(src, target))
					continue
				if(SW.next_firetime > world.time)
					continue
				if(SW.weapon_class > WEAPON_CLASS_LIGHT)
					if(shots_left <= 0)
						if(!ai_resupply_scheduled)
							ai_resupply_scheduled = TRUE
							addtimer(CALLBACK(src, PROC_REF(ai_self_resupply)), ai_resupply_time)
						continue //If we are out of shots. Continue.
				else if(light_shots_left <= 0)
					spawn(150)
						light_shots_left = initial(light_shots_left) // make them reload like real people, sort of
					continue
				var/arc = overmap_angle(src, target)
				if(SW.firing_arc && arc > SW.firing_arc) //So AIs don't fire their railguns into nothing.
					continue
				if(SW.weapon_class > WEAPON_CLASS_LIGHT)
					uses_main_shot = TRUE
				else
					uses_main_shot = FALSE
				new_firemode = I
				best_distance = distance
		if(!weapon_types[new_firemode]) //I have no physical idea how this even happened, but ok. Sure. If you must. If you REALLY must. We can do this, Sarah. We still gonna do this? It's been 5 years since the divorce, can't you just let go?
			new_firemode = FIRE_MODE_GAUSS
		if(new_firemode != FIRE_MODE_GAUSS && current_system) //If we're not on PDCs, let's fire off some PDC salvos while we're busy shooting people. This is still affected by weapon cooldowns so that they lay off on their target a bit.
			var/datum/ship_weapon/SW = weapon_types[FIRE_MODE_GAUSS]
			if(SW)
				for(var/obj/structure/overmap/ship in current_system.system_contents)
					if(warcrime_blacklist[ship.type])
						continue
					if(!ship || QDELETED(ship) || ship == src || overmap_dist(src, ship) > max_weapon_range || ship.faction == src.faction || ship.z != z)
						continue
					if(fire_weapon(ship, FIRE_MODE_GAUSS, ai_aim=TRUE))
						SW.next_firetime += SW.ai_fire_delay
					break
		fire_mode = new_firemode
		if(uses_main_shot) //Don't penalise them for weapons that are designed to be spammed.
			shots_left --
		else
			light_shots_left --

		if(fire_weapon(target, new_firemode, ai_aim=TRUE))
			var/datum/ship_weapon/SW = weapon_types[new_firemode]
			SW.next_firetime += SW.ai_fire_delay
		handle_cloak(CLOAK_TEMPORARY_LOSS)

/**
 * # `ai_elite_fire(atom/target)`
 * This proc is a slightly more advanced form of the normal 'fire' proc.
 * Most menacing trait is that this allows AI elites to effectively broadside every single of their guns thats off cooldown. (if they have ammo)
*/
/obj/structure/overmap/proc/ai_elite_fire(atom/target)
	if(!istype(target, /obj/structure/overmap))
		return
	add_enemy(target)
	var/target_range = overmap_dist(src,target)
	if(target_range > max_weapon_range) //Our max range is the maximum possible range we can engage in. This is to stop you getting hunted from outside of your view range.
		if(fleet)
			fleet.stop_reporting(target, src)
		last_target = null
		return
	var/did_fire = FALSE
	var/ammo_use = 0

	for(var/iter = FIRE_MODE_ANTI_AIR, iter <= MAX_POSSIBLE_FIREMODE, iter++)
		if(iter == FIRE_MODE_AMS || iter == FIRE_MODE_FLAK)
			continue	//These act independantly
		var/will_use_ammo = FALSE
		var/datum/ship_weapon/SW = weapon_types[iter]
		if(!SW)
			continue
		if(!SW.next_firetime)
			SW.next_firetime = world.time
		else if(SW.next_firetime > world.time)
			continue
		if(!SW.valid_target(src, target, TRUE))
			continue
		if(SW.weapon_class > WEAPON_CLASS_LIGHT)
			if((shots_left - ammo_use) <= 0)
				if(!ai_resupply_scheduled)
					ai_resupply_scheduled = TRUE
					addtimer(CALLBACK(src, PROC_REF(ai_self_resupply)), ai_resupply_time)
				continue //If we are out of shots. Continue.
			will_use_ammo = TRUE
		var/arc = overmap_angle(src, target)
		if(SW.firing_arc && arc > SW.firing_arc) //So AIs don't fire their railguns into nothing.
			continue
		fire_weapon(target, iter, ai_aim=TRUE)
		if(will_use_ammo)
			ammo_use++
		did_fire = TRUE
		SW.next_firetime = world.time + SW.fire_delay + SW.ai_fire_delay

	if(did_fire)
		shots_left -= ammo_use
		handle_cloak(CLOAK_TEMPORARY_LOSS)

// Not as good as a carrier, but something
/obj/structure/overmap/proc/ai_self_resupply()
	ai_resupply_scheduled = FALSE
	missiles = round(CLAMP(missiles + initial(missiles)/4, 1, initial(missiles)/4))
	torpedoes = round(CLAMP(torpedoes + initial(torpedoes)/4, 1, initial(torpedoes)/4))
	shots_left = round(CLAMP(shots_left + initial(shots_left)/2, 1, initial(shots_left)/4))
/**
* Given target ship and projectile speed, calculate aim point for intercept
* See: https://stackoverflow.com/a/3487761
* If they're literally moving faster than a bullet just aim right at them
*/
/obj/structure/overmap/proc/calculate_intercept(obj/structure/overmap/target, obj/item/projectile/P, miss_chance=5, max_miss_distance=5)
	if(!target || !istype(target) || !target.velocity || !P || !istype(P))
		return target
	var/turf/my_center = get_center()
	var/turf/their_center = target.get_center()
	if(!my_center || !their_center)
		return target

	var/dx = their_center.x - my_center.x
	var/dy = their_center.y - my_center.y
	var/tvx = target.velocity.a
	var/tvy = target.velocity.e
	var/projectilespeed = 32 / P.speed

	var/a = tvx * tvx + tvy * tvy - (projectilespeed * projectilespeed)
	var/b = 2 * (tvx * dx + tvy * dy)
	var/c = dx * dx + dy * dy
	var/list/solutions = SolveQuadratic(a, b, c)
	if(!solutions.len)
		return their_center
	var/time = 0
	if(solutions.len > 1)
		// If both are valid take the smaller time
		if((solutions[1] > 0) && (solutions[2] > 0))
			time = min(solutions[1], solutions[2])
		else if(solutions[1] > 0)
			time = solutions[1]
		else if(solutions[2] > 0)
			time = solutions[2]
		else
			return their_center

	var/targetx = their_center.x + target.velocity.a * time
	var/targety = their_center.y + target.velocity.e * time
	var/turf/newtarget = locate(targetx, targety, target.z)

	return newtarget

/**
*
*
* Proc override to handle AI ship specific requirements such as spawning a pilot, making it move away, and calling its ai behaviour action.
*
*/

/obj/structure/overmap/proc/ai_process() //For ai ships, this allows for target acquisition, tactics etc.
	set waitfor = FALSE
	handle_autonomous_targeting()
	SSstar_system.update_pos(src)
	if(!ai_controlled)
		return
	if(!z)	//Lets only fully stop processing on AI ships that get to nullspace with their processing still running, to not accidentally fuck up stuff.
		STOP_PROCESSING(SSphysics_processing, src)
		if(physics2d)
			STOP_PROCESSING(SSphysics_processing, physics2d)
		return
	if(disruption && prob(min(99, disruption)))
		return	//Timeout.
	choose_goal()
	if(!pilot) //AI ships need a pilot so that they aren't hit by their own bullets. Projectiles.dm's can_hit needs a mob to be the firer, so here we are.
		pilot = new /mob/living(get_turf(src))
		pilot.overmap_ship = src
		pilot.name = "Dummy AI pilot"
		pilot.mouse_opacity = FALSE
		pilot.alpha = FALSE
		pilot.forceMove(src)
		gunner = pilot
	if(last_target) //Have we got a target?
		var/obj/structure/overmap/OM = last_target
		if(overmap_dist(last_target, src) > max(max_tracking_range, OM.sensor_profile) || istype(OM) && OM.is_sensor_visible(src) < SENSOR_VISIBILITY_TARGETABLE) //Out of range - Give up the chase
			if(istype(OM) && CHECK_BITFIELD(ai_flags, AI_FLAG_DESTROYER) && OM.z == z)
				patrol_target = get_turf(last_target)	//Destroyers are wary and will actively investigate when their target exits their sensor range. You might be able to use this to your advantage though!
			if(fleet)
				fleet.stop_reporting(last_target, src)
			if(!fleet?.shared_targets?[last_target])
				last_target = null
		else //They're in our tracking range. Let's hunt them down.
			if(overmap_dist(last_target, src) <= max_weapon_range) //Theyre within weapon range.  Calculate a path to them and fire.
				if(CHECK_BITFIELD(ai_flags, AI_FLAG_ELITE))
					ai_elite_fire(last_target)
				else
					ai_fire(last_target) //Fire already handles things like being out of range, so we're good
	if(move_mode)
		user_thrust_dir = move_mode
	if(can_resupply)
		if(resupply_target && !QDELETED(resupply_target) && overmap_dist(src, resupply_target) <= resupply_range)
			new /obj/effect/temp_visual/heal(get_turf(resupply_target))
			return
		var/list/maybe_resupply = current_system.system_contents.Copy()
		shuffle(maybe_resupply)	//Lets not have a fixed resupply list that can cause things to be wonky.
		for(var/obj/structure/overmap/OM in maybe_resupply)
			if(OM.z != z || OM == src || OM.faction != faction || overmap_dist(src, OM) > resupply_range) //No self healing
				continue
			if(OM.obj_integrity >= OM.max_integrity && OM.shots_left >= initial(OM.shots_left) && OM.missiles >= initial(OM.missiles) && OM.torpedoes >= initial(OM.torpedoes)) //No need to resupply this ship at all.
				continue
			resupply_target = OM
			addtimer(CALLBACK(src, PROC_REF(resupply)), 5 SECONDS)	//Resupply comperatively fast, but not instant. Repairs take longer.
			resupplying++
			break
//Method to allow a supply ship to resupply other AIs.

/obj/structure/overmap/proc/resupply()
	resupplying--
	if(!resupply_target || QDELETED(resupply_target) || overmap_dist(src, resupply_target) > resupply_range)
		resupply_target = null
		return
	var/missileStock = initial(resupply_target.missiles)
	if(missileStock > 0)
		resupply_target.missiles = missileStock
	var/torpStock = initial(resupply_target.torpedoes)
	if(torpStock > 0)
		resupply_target.torpedoes = torpStock
	resupply_target.shots_left = initial(resupply_target.shots_left)
	resupply_target.try_repair(resupply_target.max_integrity  * 0.1)
	resupply_target = null

/obj/structure/overmap/proc/can_board(obj/structure/overmap/ship)
	if(!length(ship.occupying_levels))
		return FALSE
	if(overmap_dist(ship, src) > 8)
		return FALSE
	if(next_boarding_time <= world.time || next_boarding_attempt <= world.time)
		return TRUE
	return FALSE

/obj/structure/overmap/proc/try_board(obj/structure/overmap/ship)
	if(overmap_dist(ship, src) > 8)
		return FALSE
	next_boarding_attempt = world.time + 5 MINUTES //We very rarely try to board.
	if(next_boarding_time <= world.time)
		next_boarding_time = world.time + 30 MINUTES
		ship.spawn_boarders(null, src.faction)
		return TRUE
	return FALSE

/obj/structure/overmap/proc/add_enemy(atom/target)
	if(!istype(target, /obj/structure/overmap)) //Don't know why it wouldn't be..but yeah
		return
	var/obj/structure/overmap/OM = target
	if(OM.faction == faction)
		return
	if ( OM.essential )
		return
	last_target = target
	if(ai_can_launch_fighters) //Found a new enemy? Release the hounds
		ai_can_launch_fighters = FALSE
		var/cancelled = FALSE
		if(ai_fighter_type.len)
			for(var/i = 0, i < rand(2,3), i++)
				var/ai_fighter = pick(ai_fighter_type)
				var/turf/launch_turf = get_turf(pick(orange(3, src)))
				if(!launch_turf)
					cancelled = TRUE
					if(!i)
						ai_can_launch_fighters = TRUE
					else
						addtimer(VARSET_CALLBACK(src, ai_can_launch_fighters, TRUE), (1 + i) MINUTES)
					break
				var/obj/structure/overmap/newFighter = new ai_fighter(launch_turf)
				newFighter.last_target = last_target
				if(CHECK_BITFIELD(ai_flags, AI_FLAG_ELITE))
					newFighter.ai_flags |= AI_FLAG_ELITE	//:)
				if(current_system)
					current_system.system_contents += newFighter
					newFighter.current_system = current_system
				if(fleet)
					newFighter.fleet = fleet
					fleet.taskforces["fighters"] += newFighter //Lets our fighters come back to the mothership to fuel up every so often.
					fleet.all_ships += newFighter
					fleet.RegisterSignal(newFighter, COMSIG_PARENT_QDELETING , /datum/fleet/proc/remove_ship, newFighter)

				relay_to_nearby('nsv13/sound/effects/ship/fighter_launch_short.ogg')
		if(!cancelled)
			addtimer(VARSET_CALLBACK(src, ai_can_launch_fighters, TRUE), 3 MINUTES)
	if(OM in enemies) //If target's in enemies, return
		return
	enemies += target
	if(OM.role == MAIN_OVERMAP)
		if(GLOB.security_level < SEC_LEVEL_RED)	//Lets not pull them out of Zebra / Delta
			set_security_level(SEC_LEVEL_RED) //Action stations when the ship is under attack, if it's the main overmap.
		SSovermap_mode.update_reminder()
	if(OM.tactical)
		var/sound = pick('nsv13/sound/effects/computer/alarm.ogg','nsv13/sound/effects/computer/alarm_3.ogg','nsv13/sound/effects/computer/alarm_4.ogg')
		var/message = "<span class='warning'>DANGER: [src] is now targeting [OM].</span>"
		OM.tactical.relay_sound(sound, message)
	else
		if(OM.dradis)
			playsound(OM.dradis, 'nsv13/sound/effects/fighters/being_locked.ogg', 100, FALSE)

//Pathfinding...sorta
/obj/structure/overmap/proc/move_toward(atom/target, ram_target = FALSE, ignore_all_collisions = FALSE)
	brakes = FALSE
	move_mode = NORTH
	enable_dampeners()
	if(!target || QDELETED(target))
		if(defense_target) //Maybe it's defending a ship, it'll still need to find its way home.
			target = defense_target
		else
			return
	desired_angle = overmap_angle(src, target)
	var/target_dist = overmap_dist(src, target)
	if(world.time >= next_maneuvre && (target_dist > 12 || ram_target || ignore_all_collisions))
		var/angular_difference = desired_angle - angle
		switch(angular_difference)
			if(-15 to 15)
				boost(NORTH)	//ZOOOM
			if(-180 to -45)
				boost(WEST)
			if(-INFINITY to -180)
				boost(EAST)
			if(45 to 180)
				boost(EAST)
			if(180 to INFINITY)
				boost(WEST)
	if(ignore_all_collisions)
		return	//FULL SPEED AHEAD!
	//Raycasting! Should finally give the AI ships their driver's license....
	for(var/turf/T in getline(src, target))
		var/dist = overmap_dist(get_turf(src), T)
		if(dist >= 8) //ignore collisions this far away, no need to dodge that.
			break
		var/obj/structure/overmap/blocked = null
		//This is...inefficient, but unavoidable without some equally expensive vector math.
		for(var/obj/structure/overmap/OM in current_system.system_contents)
			if(OM == src) //:sigh: this one tripped me up
				continue
			if(OM == target && ram_target)
				continue
			if(overmap_dist(get_turf(OM), T) <= 5 && OM.mass > MASS_TINY) //Who cares about fighters anyway!
				blocked = OM
				break
		if(blocked) //Time to do some evasive. Determine the object's direction to evade in the opposite direction.
			if(blocked.velocity.a > 0)
				move_mode = EAST //The ship should still drift forward / backwards, but in this case let's not accelerate into an asteroid shall we...
				disable_dampeners()
			if(blocked.velocity.a <= 0)
				move_mode = WEST
				disable_dampeners()
			return


	//If the AI is going to be blocked in its path, it'll need to dodge very slightly

/obj/structure/overmap/proc/move_away_from(atom/target)
	brakes = FALSE
	move_mode = NORTH
	if(!target || QDELETED(target))
		return
	desired_angle =	overmap_angle(src, target) - 180
	if(mines_left >= 1) //if we have mines, we should try to discourage anyone from following
		deploy_mine()

/obj/structure/overmap/proc/circle_around(atom/target)
	brakes = FALSE
	move_mode = NORTH
	if(!target)
		return
	var/relative_angle = overmap_angle(src, target)
	var/option1 = relative_angle + 90
	var/option2 = relative_angle - 90
	if(option2 < 0)
		option2 = 360 + option2
	option1 = option1 % 360
	var/actual_angle_positive = angle + 180	//Ew, math.
	var/option1_difference = 180 - abs(abs(actual_angle_positive - option1) - 180)
	var/option2_difference = 180 - abs(abs(actual_angle_positive - option2) - 180)
	if(option1_difference < option2_difference)	//Basically, we circle the target the way we need to waste less time turning towards.
		desired_angle = option1 - 180
	else
		desired_angle = option2 - 180

	//Uncomment the next line if you want some insight on the decision making or if you are localtesting why this isn't working. Do not have this uncommented if you don't want adminchat spam.
	//message_admins("Circling target. relative angle: [relative_angle], option 1: [option1] | [option1 - 180] | [option1_difference], option 2: [option2] | [option2 - 180] | [option2_difference]. Choice: [desired_angle]")

//Method that will get you a new target, based on basic params.
/obj/structure/overmap/proc/seek_new_target(max_weight_class=null, min_weight_class=null, interior_check=FALSE, max_distance)
	var/list/shiplist = current_system?.system_contents.Copy()	//We need to Copy() so shuffle doesn't make the global list messier
	if(!shiplist || !shiplist.len)
		return FALSE
	shuffle(shiplist)	//Because we go through this list from first to last, shuffling will make the way we select targets appear more random.
	for(var/obj/structure/overmap/ship in shiplist)
		if(warcrime_blacklist[ship.type])
			continue
		if(!ship || QDELETED(ship) || ship == src || overmap_dist(src, ship) > max(max_tracking_range, ship.sensor_profile) || ship.faction == faction || ship.z != z || ship.is_sensor_visible(src) < SENSOR_VISIBILITY_TARGETABLE)
			continue
		if ( ship.essential )
			continue
		if(max_distance && overmap_dist(src, ship) > max_distance)
			continue
		if(max_weight_class && ship.mass > max_weight_class)
			continue
		if(min_weight_class && ship.mass < min_weight_class)
			continue
		if(interior_check && !length(ship.occupying_levels)) //So that boarders don't waste their time and try commit to boarding other AIs...yet.
			continue
		add_enemy(ship)
		last_target = ship
		if(fleet)
			fleet.start_reporting(ship, src)
		return TRUE
	if(!last_target && length(fleet?.shared_targets))
		last_target = pick(fleet.shared_targets)
		add_enemy(last_target)
		return TRUE
	return FALSE

///Make this ship drop a mine.
/obj/structure/overmap/proc/deploy_mine()
	if(mines_left <= 0)
		return //why are we here
	if(mine_cooldown > world.time) //Don't drop them all at once now
		return
	mine_cooldown = world.time + 6 SECONDS
	mines_left--
	new /obj/structure/space_mine(get_center(),faction,current_system)

/client/proc/instance_overmap_menu() //Creates a verb for admins to open up the ui
	set name = "Instance Overmap"
	set desc = "Load a ship midround."
	set category = "Adminbus"

	if(IsAdminAdvancedProcCall())
		return FALSE

	var/list/choices = flist("_maps/map_files/Instanced/")
	var/ship_file = file("_maps/map_files/Instanced/"+input(usr, "What ship would you like to load?","Ship Instancing", null) as null|anything in choices)
	if(!ship_file)
		return
	if(instance_ship_from_json(ship_file))
		message_admins("[key_name(src)] has instanced a copy of [ship_file]!")
	else
		message_admins("Failed to instance a copy of [ship_file]!")

/proc/instance_ship_from_json(ship_file)
	if(!ship_file)
		message_admins("Error loading ship, null file passed in.")
		return
	if(!isfile(ship_file))
		message_admins("Error loading ship from JSON. Check that the file exists.")
		return
	var/list/json = json_decode(file2text(ship_file))
	if(!json)
		return
	var/shipName = json["map_name"]
	var/shipType = text2path(json["ship_type"])
	var/mapPath = json["map_path"]
	var/mapFile = json["map_file"]
	var/list/traits = json["traits"]
	if (istext(mapFile))
		if (!fexists("_maps/[mapPath]/[mapFile]"))
			log_world("Map file ([mapPath]/[mapFile]) does not exist!")
			return
	else if (islist(mapFile))
		for (var/file in mapFile)
			if (!fexists("_maps/[mapPath]/[file]"))
				log_world("Map file ([mapPath]/[file]) does not exist!")
				return
	var/obj/structure/overmap/OM = instance_overmap(shipType, mapPath, mapFile, traits, ZTRAITS_BOARDABLE_SHIP, TRUE)
	if(OM)
		OM.name = shipName
	return OM
