//Time to talk about relationships 😳😳😳
#define RELATIONSHIP_ALLIES 200
#define RELATIONSHIP_NEUTRAL 100
#define RELATIONSHIP_DISTRUST 50
#define RELATIONSHIP_ENEMIES 0
#define RELATIONSHIP_HATRED -100 //Very hard pit to dig yourself out from.

/datum/faction
	var/name = "Faction superclass"
	var/desc = "Description not set."
	var/list/relationships = list() //Dictionary, K=faction reference, V=reputation score with that faction.
	var/id = null
	//Presets if you want a faction to start off pre-aligned with another either negatively or positively. It's up to you to make this make sense! You can have a one-directional hatred if you want.
	var/list/preset_enemies = list()
	var/list/preset_allies = list()
	var/tickets = 0 //How many victory tickets has this faction accrued? Factions other than NT can win!
	var/list/fleet_types = list()
	var/list/randomspawn_only_fleet_types = list()	//These fleets only get spawned randomly, not by say, missions.
	var/list/elite_fleet_types = list() //These fleets are only spawned if the difficulty is high enough.
	var/elite_difficulty_threshold = 3 //The minimum difficulty for elite fleets to spawn for this faction.
	var/next_fleet_spawn = 0 //Factions spawn fleets more frequently when they're doing well with tickets.
	var/fleet_spawn_rate = 10 MINUTES //By default, 1 / 5 minutes.
	var/spawn_rate_jitter = 3 MINUTES
	var/minimum_spawn_interval = 5 MINUTES

/**
Procs for handling factions winning / losing
*/
/datum/faction/proc/victory()
	if(istype(SSticker.mode, /datum/game_mode/pvp))
		var/datum/game_mode/pvp/mode = SSticker.mode
		mode.winner = src //This should allow the mode to finish up by itself
		mode.check_finished()
	return FALSE

/datum/faction/proc/check_status(id)
	var/datum/faction/F = SSstar_system.faction_by_id(id)
	return relationships[F]

/*
Set up relationships.
*/
/datum/faction/proc/setup_relationships()
	for(var/datum/faction/F in SSstar_system.factions)
		relationships[F] = RELATIONSHIP_NEUTRAL
	if(!preset_allies.len)
		return
	for(var/id in preset_allies)
		var/datum/faction/F = SSstar_system.faction_by_id(id)
		if(!F || F == src)
			continue
		relationships[F] = RELATIONSHIP_ALLIES
	if(!preset_enemies.len)
		return
	for(var/id in preset_enemies)
		var/datum/faction/F = SSstar_system.faction_by_id(id)
		if(!F || F == src)
			continue
		relationships[F] = RELATIONSHIP_HATRED

/datum/faction/proc/lose_influence(value)
	tickets -= value
	for(var/datum/faction/F in relationships)
		if(relationships[F] <= RELATIONSHIP_ENEMIES)
			F.gain_influence(value)

/datum/faction/proc/gain_influence(value)
	tickets += value

/datum/faction/proc/send_fleet(datum/star_system/override=null, custom_difficulty=null, force=FALSE)
	if(!fleet_types || !force && (world.time < next_fleet_spawn))
		return
	next_fleet_spawn = world.time + max(fleet_spawn_rate + rand(-spawn_rate_jitter, spawn_rate_jitter), minimum_spawn_interval)
	var/datum/star_system/current_system //Dont spawn enemies where theyre currently at
	var/obj/structure/overmap/main_ship = SSstar_system.find_main_overmap()
	if(main_ship)
		current_system = SSstar_system.ships[main_ship]["current_system"]
	var/list/possible_spawns = list()
	for(var/datum/star_system/starsys in SSstar_system.neutral_zone_systems) //Neutral zone to prevent overcrowding the Syndicate and friendly sectors
		if(starsys != current_system && !starsys.hidden && (lowertext(starsys.alignment) == lowertext(src.name) || starsys.alignment == "unaligned" || starsys.alignment == "uncharted")) //Find one of our base systems and try to send a fleet out from there.
			possible_spawns += starsys
	if(!possible_spawns.len && !override)
		message_admins("Failed to spawn a [name] fleet because that faction doesn't own a single system :(")
		return
	var/datum/star_system/starsys
	if(override)
		starsys = override
	else
		starsys = pick(possible_spawns)
	starsys.mission_sector = TRUE //set this sector to be the active mission
	starsys.spawn_asteroids() //refresh asteroids in the system
	var/list/possible_types = list()
	possible_types += fleet_types
	if(!force)
		possible_types += randomspawn_only_fleet_types
	if(custom_difficulty >= elite_difficulty_threshold || SSovermap_mode.mode.difficulty >= elite_difficulty_threshold)
		possible_types += elite_fleet_types
	var/fleet_type = pickweight(possible_types)
	var/datum/fleet/F = new fleet_type
	F.current_system = starsys
	starsys.fleets += F
	if(custom_difficulty)
		F.size = custom_difficulty
	F.assemble(starsys)
	if(!F.hide_movements && !starsys.hidden)
		if((F.alignment == "nanotrasen") || (F.alignment == "solgov"))
			mini_announce("A White Rapids fleet has been assigned to [starsys]", "White Rapids Fleet Command")
		else
			mini_announce("Typhoon drive signatures detected in [starsys]", "White Rapids EAS")
	F.faction = src
	if(!force && id == FACTION_ID_SYNDICATE && !SSstar_system.neutral_zone_systems.Find(F.current_system))	//If it isn't forced, it got spawned by the midround processing. If we didn't already spawn in the neutral zone, we head to a random system there and occupy it.
		var/list/possible_occupation_targets = list()
		for(var/datum/star_system/S in SSstar_system.neutral_zone_systems)
			if(S.alignment == "syndicate")
				continue
			if(S.hidden)
				continue	//Shhh
			possible_occupation_targets += S
		if(possible_occupation_targets.len)
			F.goal_system = pick(possible_occupation_targets)

	message_admins("DEBUG: [src] spawned a [F] in [starsys][F.goal_system ? " heading towards [F.goal_system]" : ""].")
	return

//The beginning and the end.
/datum/faction/nanotrasen
	name = "Nanotrasen"
	desc = "Nanotrasen systems is a conglomerate of sub-contractors and other companies."
	preset_allies = list(FACTION_ID_SOLGOV, FACTION_ID_UNATHI)
	preset_enemies = list(FACTION_ID_SYNDICATE, FACTION_ID_PIRATES)
	fleet_types = list(/datum/fleet/nanotrasen/light = 1)
	elite_fleet_types = list(/datum/fleet/nanotrasen = 1)
	fleet_spawn_rate = 40 MINUTES
	id = FACTION_ID_NT

/datum/faction/nanotrasen/victory()
	. = ..()
	for(var/datum/star_system/SS in SSstar_system.systems)
		if(SS.name == "Outpost 45")
			SS.hidden = FALSE
	for(var/client/C in GLOB.clients)
		if(!C.mob || !SSmapping.level_trait(C.mob.z, ZTRAIT_BOARDABLE))
			continue
		C.give_award(/datum/award/achievement/misc/crew_competent)
	priority_announce("Attention [station_name()]. You have completed your assigned patrol and are now eligible for a crew transfer. \
	Your navigational computers have been programmed with the coordinates of the nearest starbase where you may claim your allotted shore leave. \
	You are under no obligation to remain in this sector, and you have been taken off of active patrol status. If you wish to continue with exploratory missions or other activities you are free to do so.", "Naval Command")
	tickets = 0

/datum/faction/syndicate
	name = "Syndicate"
	desc = "The Abassi Syndicate are a collection of former Nanotrasen colonists who rebelled against their 'oppression' and formed their own government."
	preset_allies = list(FACTION_ID_PIRATES) //Yar HAR it's me, captain PLASMASALT
	preset_enemies = list(FACTION_ID_NT)
	fleet_types = list(/datum/fleet/neutral = 5, /datum/fleet/boarding = 5, /datum/fleet/wolfpack = 5, /datum/fleet/conflagration = 5)
	randomspawn_only_fleet_types = list(/datum/fleet/interdiction/light = 1)
	elite_fleet_types = list(/datum/fleet/wolfpack/elite = 2, /datum/fleet/elite = 2)
	fleet_spawn_rate = 30 MINUTES
	id = FACTION_ID_SYNDICATE

/datum/faction/syndicate/victory()
	. = ..()
	priority_announce("Attention [station_name()]. Our presence in this sector has been severely diminished due to your incompetence. Return to base immediately for disciplinary action.", "Naval Command")
	for(var/datum/star_system/SS in SSstar_system.systems) //This is trash but I don't wanna fix it right now.
		if(SS.name == "Outpost 45")
			SS.hidden = FALSE
	tickets = 0
	SSovermap_mode.objective_reminder_stacks = 0
	SSovermap_mode.next_objective_reminder = world.time + 10 HOURS

/datum/faction/pirate
	name = "Tortuga Raiders"
	desc = "The Tortuga raiders terrorise independent colonies and are widely recognised as 'free birds'."
	preset_allies = list(FACTION_ID_SYNDICATE) //Yar HAR it's me, captain PLASMASALT
	preset_enemies = list(FACTION_ID_NT)
	fleet_types = list(/datum/fleet/pirate/scout = 1, /datum/fleet/pirate/raiding = 1)
	id = FACTION_ID_PIRATES
