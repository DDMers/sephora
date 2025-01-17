//Subsystem to control overmap events and the greater gameworld
SUBSYSTEM_DEF(star_system)
	name = "star_system"
	wait = 10
	init_order = INIT_ORDER_STARSYSTEM

	var/last_combat_enter = 0 //Last time an AI controlled ship attacked the players
	var/list/systems = list()
	var/list/traders = list()
	var/bounty_pool = 0 //Bounties pool to be delivered for destroying syndicate ships
	var/list/enemy_types = list()
	var/list/enemy_blacklist = list(/obj/structure/overmap/syndicate/ai/fistofsol, /obj/structure/overmap/syndicate/ai/battleship)
	var/list/ships = list() //2-d array. Format: list("ship" = ship, "x" = 0, "y" = 0, "current_system" = null, "target_system" = null, "transit_time" = 0)
	//Starmap 2
	var/list/factions = list() //List of all factions in play on this starmap, instantiated on init.
	var/list/neutral_zone_systems = list()
	var/list/all_missions = list()
	var/time_limit = FALSE //Do we want to end the round after a specific time? Mostly used for galconquest.
	var/datum/star_system/return_system //Which system should we jump to at the end of the round?

	var/enable_npc_combat = TRUE	//If you are running an event and don't want fleets to shoot eachother, set this to false.
	var/next_combat_cycle = 0
	var/list/contested_systems = list()	//A maintained list containing all systems that have fleets of opposing factions in them. Fleets add a system to it if they arrive in a system with a hostile fleet, handle_combat removes a system if there is no more conflict.

	var/obj/structure/overmap/main_overmap = null //The main overmap
	var/obj/structure/overmap/mining_ship = null //The mining ship
	var/saving = FALSE

	///Kind of cursed list that tracks which of our overmap interiors have been initialized yet.
	var/list/overmap_interior_queue = list() //Ratvar save me from this.
	///Are we already busy?
	var/initing_interior = FALSE

/datum/controller/subsystem/star_system/fire() //Overmap combat events control system, adds weight to combat events over time spent out of combat
	handle_interior_inits() //Cursed. I don't like this.
	if(time_limit && world.time >= time_limit)
		var/datum/faction/winner = get_winner()
		if(istype(SSticker.mode, /datum/game_mode/pvp))
			var/datum/game_mode/pvp/mode = SSticker.mode
			mode.winner = winner //This should allow the mode to finish up by itself
			mode.check_finished()
		else
			SSticker.force_ending = 1
		return

	if(enable_npc_combat)
		if(world.time >= next_combat_cycle)
			for(var/datum/star_system/SS in contested_systems)
				SS.handle_combat()
			next_combat_cycle = world.time + COMBAT_CYCLE_INTERVAL

	for(var/datum/faction/F in factions)
		F.send_fleet() //Try send a fleet out from each faction.

/datum/controller/subsystem/star_system/Initialize(start_timeofday)
	instantiate_systems()
	. = ..()
	return_system = system_by_id(SSmapping.config.return_system)
	enemy_types = subtypesof(/obj/structure/overmap/syndicate/ai)
	for(var/type in enemy_blacklist)
		enemy_types -= type
	for(var/instance in subtypesof(/datum/faction))
		var/datum/faction/F = new instance
		factions += F
	for(var/datum/faction/F in factions)
		F.setup_relationships() //Set up faction relationships AFTER they're all initialised to avoid errors.

	for(var/datum/star_system/S in systems)	//Setup the neutral zone for easier access - Bit of overhead but better than having to search for sector 2 systems everytime we want a new neutral zone occupier)
		if(S.sector != SECTOR_NEUTRAL)
			continue
		neutral_zone_systems += S

/datum/controller/subsystem/star_system/Shutdown()
	if(CONFIG_GET(flag/starmap_persistence_enabled))
		saving = TRUE
		save()
		saving = FALSE
	. = ..()

///Absolutely cursed proc handling ship interior init queues.
/datum/controller/subsystem/star_system/proc/handle_interior_inits()
	set waitfor = FALSE
	if(initing_interior)
		return
	if(SSatoms.initialized_changed)
		return
	if(!length(overmap_interior_queue))
		return
	initing_interior = TRUE
	var/obj/structure/overmap/shipinterior_candidate = overmap_interior_queue[1]
	shipinterior_candidate.instance_interior()
	SEND_SIGNAL(shipinterior_candidate, COMSIG_INTERIOR_DONE_LOADING)
	overmap_interior_queue -= shipinterior_candidate
	initing_interior = FALSE

/datum/controller/subsystem/star_system/proc/queue_for_interior_load(obj/structure/overmap/to_interior_load)
	overmap_interior_queue += to_interior_load

/**
Returns a faction datum by its name (case insensitive!)
*/
/datum/controller/subsystem/star_system/proc/faction_by_name(name)
	RETURN_TYPE(/datum/faction)
	if(!name)
		return //Stop wasting my time.
	for(var/datum/faction/F as() in factions)
		if(lowertext(F.name) == lowertext(name))
			return F

/datum/controller/subsystem/star_system/proc/faction_by_id(id)
	RETURN_TYPE(/datum/faction)
	if(!id)
		return //Stop wasting my time.
	for(var/datum/faction/F as() in factions)
		if(F.id == id)
			return F

/datum/controller/subsystem/star_system/proc/add_blacklist(what)
	enemy_blacklist += what
	if(locate(what) in enemy_types)
		enemy_types -= what

/datum/controller/subsystem/star_system/proc/instantiate_systems(_source_path = SSmapping.config.starmap_path)
	message_admins("Loading starsystem from [_source_path]...")
	var/list/_systems = list()
	//Read the file in...
	//If we can't find starmap.json, load in the default instead. This should usually be for local servers
	if(!fexists(_source_path))
		log_game("Unable to find [_source_path]. Loading default instead. This is normal for local servers")
		_source_path = "config/starmap/starmap_default.json"
	try
		_systems += json_decode(rustg_file_read(file(_source_path)))
	catch(var/exception/ex)
		//Fallback: Load the hardcoded systems and report an error.
		instantiate_systems_backup()
		log_game("Unable to load starmap from: [_source_path]. (Defaulting...): [ex]")

	for(var/i = 1; i <= _systems.len; i++)
		//Try instancing this system from JSON, jump out if anything goes wrong.
		var/list/sys_info = _systems[i]
		try{
			//Fields that must be present are accessed unsafely. The rest is fine if null.
			var/datum/star_system/next = new /datum/star_system(
				//Required props, you must fill these out, or it's an invalid map.
				name = sys_info["name"],
				desc = sys_info["desc"],
				x = sys_info["x"],
				y = sys_info["y"],
				alignment = sys_info["alignment"],
				owner = sys_info["owner"],
				hidden = sys_info["hidden"],
				sector = sys_info["sector"],
				adjacency_list = json_decode(sys_info["adjacency_list"]) || list(),
				//Optional props. Recommended, but can be left blank.
				threat_level = LAZYACCESS(sys_info, "threat_level") || THREAT_LEVEL_NONE,
				is_capital = LAZYACCESS(sys_info, "is_capital") || FALSE,
				fleet_type = LAZYACCESS(sys_info, "fleet_type") || null,
				parallax_property = LAZYACCESS(sys_info, "parallax_property") || null,
				visitable = LAZYACCESS(sys_info, "visitable") || TRUE,
				is_hypergate = LAZYACCESS(sys_info,"is_hypergate") || FALSE,
				preset_trader = (LAZYACCESS(sys_info,"preset_trader")) ? text2path(sys_info["preset_trader"]) : null,
				system_traits = LAZYACCESS(sys_info,"system_traits") ? sys_info["system_traits"] : NONE,
				system_type = (LAZYACCESS(sys_info,"system_type") && sys_info["system_type"] != "null" && sys_info["system_type"] != null) ? json_decode(sys_info["system_type"]) : list(),
				audio_cues = (LAZYACCESS(sys_info,"audio_cues") && sys_info["audio_cues"] != "null" && sys_info["audio_cues"] != null) ? json_decode(sys_info["audio_cues"]) : list(),
				wormhole_connections = (LAZYACCESS(sys_info,"wormhole_connections") && sys_info["wormhole_connections"] != "null" && sys_info["wormhole_connections"] != null) ? json_decode(sys_info["wormhole_connections"]) : list(),
				startup_proc = LAZYACCESS(sys_info,"startup_proc") || null
				//Future implementation ideas: We can cache system_contents. I'm not dealing with that now though.
			)
			systems += next
		}
		catch(var/exception/e){ //Please avoid using trycatch, you CANNOT debug try-catch. It's doesn't RUNTIME TRACK trycatch. Breakpoints do not trigger in trycatch. Fix runtimes or failure proof the system instead so nobody has to manually tear apart the trycatch while debugging.
			message_admins("WARNING: Invalid star system in json: [sys_info["name"]] ([e]). Skipping...")
			continue
		}
	message_admins("Successfully loaded starmap layout from [_source_path]")


/datum/controller/subsystem/star_system/proc/instantiate_systems_backup()
	for(var/instance in subtypesof(/datum/star_system))
		var/datum/star_system/S = new instance
		if(S.name)
			systems += S
	if(saving)
		return

/**
<summary>Save the current starmap layout to a json file. Used for persistence.</summary>
<param></param>
*/

/datum/controller/subsystem/star_system/proc/save(_destination_path = SSmapping.config.starmap_path)
	// No :)
	_destination_path = sanitize_filepath(_destination_path)
	var/list/directory = splittext(_destination_path, "/")
	if((directory[1] != "config") || (directory[2] != "starmap"))
		CRASH("ERR: Starmaps can only be saved to the config directory!")
	if(!findtext(directory[directory.len], ".json"))
		CRASH("ERR: Starmaps can only be written to JSON.")

	message_admins("Saving current starsystem layout...")
	var/json_file = null
	//Read the file in...
	try
		json_file = file(_destination_path)
	catch(var/exception/ex)
		message_admins("WARNING: Unable to open [_destination_path]: [ex]")
		return 1
	var/list/file_data = list()
	for(var/datum/star_system/S in systems)
		if(S == null || istype(S, /datum/star_system/random))
			continue
		var/list/adjusted_adjacency_list = S.initial_adjacencies.Copy() //Don't copy adjacency changes from wormholes or badmins
		/*var/list/adjusted_wormhole_connections = S.wormhole_connections.Copy() Not saving this right now, since wormholes spawn randomly
		for(var/system_name in adjusted_wormhole_connections)
			var/datum/star_system/SS = system_by_id(system_name)
			if(istype(SS, /datum/star_system/random))
				adjusted_wormhole_connections.Remove(system_name) */
		var/list/entry = list(
			//Fluff.
			"name"=S.name,
			"desc"=S.desc,
			"threat_level"=S.threat_level,
			//General system props
			"alignment" = S.alignment,
			"owner" = S.owner,
			"hidden"=initial(S.hidden),
			"system_type" = json_encode(S.system_type),
			"system_traits"=isnum(S.system_traits) ? S.system_traits : NONE,
			"is_capital"=S.is_capital,
			"adjacency_list"=json_encode(adjusted_adjacency_list),
			"wormhole_connections"=/*json_encode(S.wormhole_connections)*/json_encode(list()), //If you want to to have mapped wormholes stay, copy how I do adjacency lists or tell me. Do not initial and do not preserve random ones like it would if I just fixed the saving. -Delta
			"fleet_type" = S.fleet_type,
			//Coords, props.
			"x" = S.x,
			"y" = S.y,
			"parallax_property"=S.parallax_property,
			"visitable"=S.visitable,
			"sector"=S.sector,
			"is_hypergate"=S.is_hypergate,
			"preset_trader"=S.preset_trader,
			"audio_cues" = json_encode(S.audio_cues),
			"startup_proc" = S.startup_proc
		)
		file_data[++file_data.len] = entry
	//Attempt to write to the file...
	try
		listclearnulls(file_data)
		fdel(json_file)
		var/list/to_save = file_data
		WRITE_FILE(json_file, json_encode(to_save))
		message_admins("Successfully saved current starmap to: [_destination_path]")
		return 0
	catch(var/exception/e)
		message_admins("WARNING: Unable to save [_destination_path]: [e]")
		return 1

///////SPAWN SYSTEM///////

/datum/controller/subsystem/star_system/proc/find_main_overmap() //Find the main ship
	RETURN_TYPE(/obj/structure/overmap)
	if(main_overmap)
		return main_overmap
	for(var/obj/structure/overmap/OM in GLOB.overmap_objects) //We shouldn't have to do this, but fallback
		if(OM.role == MAIN_OVERMAP)
			return OM

/datum/controller/subsystem/star_system/proc/find_main_miner() //Find the mining ship
	RETURN_TYPE(/obj/structure/overmap)
	if(mining_ship)
		return mining_ship
	for(var/obj/structure/overmap/OM in GLOB.overmap_objects) //We shouldn't have to do this, but fallback
		if(OM.role == MAIN_MINING_SHIP)
			return OM

/datum/controller/subsystem/star_system/proc/system_by_id(id)
	RETURN_TYPE(/datum/star_system)
	for(var/datum/star_system/sys in systems)
		if(sys.name == id)
			return sys

///AVOID using this if possible, go by the objects current_system var if you can. Do not trust the weird ships[] list unless you HAVE to (e.g. you haven't set the system yet)
/datum/controller/subsystem/star_system/proc/find_system(obj/O) //Used to determine what system a ship is currently in. Famously used to determine the starter system that you've put the ship in.
	var/datum/star_system/system
	if(isovermap(O))
		var/obj/structure/overmap/OM = O
		system = system_by_id(OM.starting_system)
		if(!ships[OM])
			return
		else if(!ships[OM]["current_system"])
			ships[OM]["current_system"] = system
		else
			system = ships[OM]["current_system"]
	else if(isanomaly(O))
		var/obj/effect/overmap_anomaly/AN = O
		system = AN.current_system
	return system

/datum/controller/subsystem/star_system/proc/spawn_ship(obj/structure/overmap/OM, datum/star_system/target_sys, center=FALSE)//Select Ship to Spawn and Location via Z-Trait
	if(target_sys.occupying_z)
		var/turf/destination = null
		if(center)
			destination = get_turf(locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), target_sys.occupying_z)) //Plop them bang in the center of the system as requested. This is usually saved for wormholes.
		else
			destination = get_turf(locate(rand(50, world.maxx), rand(50, world.maxy), target_sys.occupying_z)) //Spawn them somewhere in the system. I don't really care where.
		var/obj/structure/overmap/enemy = new OM(destination)
		target_sys.add_ship(enemy)
	else
		target_sys.enemy_queue += OM

/datum/controller/subsystem/star_system/proc/move_existing_object(obj/structure/overmap/OM, datum/star_system/target)
	if(QDELETED(OM))
		return
	var/datum/star_system/previous_system = OM.current_system
	target.system_contents += OM
	if(!target.occupying_z)
		STOP_PROCESSING(SSphysics_processing, OM)
		if(OM.physics2d)
			STOP_PROCESSING(SSphysics_processing, OM.physics2d)
		var/backupx = OM.x
		var/backupy = OM.y
		OM.moveToNullspace()
		if(backupx && backupy)
			target.contents_positions[OM] = list("x" = backupx, "y" = backupy) //Cache the ship's position so we can regenerate it later.
		else
			target.contents_positions[OM] = list("x" = rand(15, world.maxx - 15), "y" = rand(15, world.maxy - 15))
	else
		if(!OM.z)
			START_PROCESSING(SSphysics_processing, OM)
			if(OM.physics2d)
				START_PROCESSING(SSphysics_processing, OM.physics2d)
		target.add_ship(OM)
	if(OM.faction != "nanotrasen" && OM.faction != "solgov") //NT, SGC or whatever don't count as enemies that NT hire you to kill.
		previous_system?.enemies_in_system -= OM
		target.enemies_in_system += OM
	if(previous_system)
		previous_system.system_contents -= OM
		if(previous_system.contents_positions[OM]) //If we were loaded, but the system was not.
			previous_system.contents_positions -= OM
	OM.current_system = target

//Specific case for anomalies. They need to be spawned in for research to scan them.

/datum/controller/subsystem/star_system/proc/spawn_anomaly(anomaly_type, datum/star_system/target_sys, center=FALSE)
	RETURN_TYPE(/obj/structure/overmap)
	if(target_sys.occupying_z)
		spawn_ship(anomaly_type, target_sys, center)
		return
	var/turf/destination = null
	if(center)
		destination = get_turf(locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), 1))
	else
		destination = get_turf(locate(rand(50, world.maxx), rand(50, world.maxy), 1))
	var/obj/effect/overmap_anomaly/anomaly = new anomaly_type(destination)
	target_sys.contents_positions[anomaly] = list("x" = anomaly.x, "y" = anomaly.y) //Cache the ship's position so we can regenerate it later.
	target_sys.system_contents += anomaly
	anomaly.moveToNullspace() //Anything that's an NPC should be stored safely in nullspace until we return.
	anomaly.current_system = target_sys
	return anomaly

///////BOUNTIES//////

/datum/controller/subsystem/star_system/proc/bounty_payout()
	if(!bounty_pool) //No need to spam when there is no cashola payout
		return
	minor_announce("Bounty Payment Of [bounty_pool] Credits Processed", "Naval Command")
	var/split_bounty = bounty_pool / 2 //Split between our two accounts
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	D.adjust_money(split_bounty)
	var/datum/bank_account/DD = SSeconomy.get_dep_account(ACCOUNT_MUN)
	DD.adjust_money(split_bounty)
	bounty_pool = 0

/datum/controller/subsystem/star_system/proc/get_winner()
	var/highestTickets = 0
	var/datum/faction/winner = null
	for(var/X in factions)
		var/datum/faction/F = X
		if(F.tickets > highestTickets)
			winner = F
			highestTickets = F.tickets
	return winner

/datum/controller/subsystem/star_system/proc/add_ship(obj/structure/overmap/OM, turf/target, datum/star_system/system_override)
	ships[OM] = list("ship" = OM, "x" = 0, "y" = 0, "current_system" = system_by_id(OM.starting_system), "last_system" = system_by_id(OM.starting_system), "target_system" = null, "from_time" = 0, "to_time" = 0, "occupying_z" = OM.z)
	var/datum/star_system/curr
	if(!system_override)
		curr = ships[OM]["current_system"]
	else
		curr = system_override
	curr.add_ship(OM, target)

//Welcome to bracket hell.

//Updates the position of a given ship on the starmap

/datum/controller/subsystem/star_system/proc/update_pos(obj/structure/overmap/OM)
	if(!ships[OM])
		return FALSE
	var/datum/star_system/curr = ships[OM]["current_system"]
	var/datum/star_system/last = ships[OM]["last_system"]
	var/datum/star_system/targ = ships[OM]["target_system"]
	ships[OM]["x"] = (curr) ? curr.x : last.lerp_x(targ, get_transit_progress(OM))
	ships[OM]["y"] = (curr) ? curr.y : last.lerp_y(targ, get_transit_progress(OM))

/datum/controller/subsystem/star_system/proc/get_transit_progress(obj/structure/overmap/OM)
	var/list/info = ships[OM]
	if(info["current_system"])
		return FALSE
	return (world.time - info["from_time"])/(info["to_time"] - info["from_time"])

/datum/controller/subsystem/star_system/proc/dolos_visited(datum/star_system/source, obj/structure/overmap/entering)
	SIGNAL_HANDLER
	if(entering.ai_controlled)
		return
	for(var/mob/living/visitor in entering.mobs_in_ship)
		if(!visitor.client)
			continue
		INVOKE_ASYNC(visitor.client, TYPE_PROC_REF(/client, give_award), /datum/award/achievement/misc/crew_extremely_competent, visitor)

/datum/controller/subsystem/star_system/proc/abassi_visited(datum/star_system/source, obj/structure/overmap/entering)
	SIGNAL_HANDLER
	if(entering.ai_controlled)
		return
	for(var/mob/living/visitor in entering.mobs_in_ship)
		if(!visitor.client)
			continue
		INVOKE_ASYNC(visitor.client, TYPE_PROC_REF(/client, give_award), /datum/award/achievement/misc/crew_hypercompetent, visitor)

//////star_system DATUM///////

/datum/star_system
	var/name = null //Parent type, please ignore
	var/desc = null
	var/parallax_property = null //If you want things to appear in the background when you jump to this system, do this.
	var/level_trait = null //The Ztrait of the zlevel that this system leads to
	var/visitable = FALSE //Can you directly travel to this system? (You shouldnt be able to jump directly into hyperspace)
	var/list/enemies_in_system = list() //For mission completion.
	var/reward = 5000 //Small cash bonus when you clear a system, allows you to buy more ammo
	var/difficulty_budget = 2
	var/list/asteroids = list() //Keep track of how many asteroids are in system. Don't want to spam the system full of them
	var/mission_sector = FALSE
	var/objective_sector = FALSE
	var/threat_level = THREAT_LEVEL_NONE

	var/x = 0 //Maximum: 1000 for now
	var/y = 0 //Maximum: 1000 for now
	//Current list of valid alignments (from Map.scss in TGUI): null, whiterapids, solgov, nanotrasen, syndicate, unaligned, pirate, uncharted
	var/alignment = "unaligned"
	var/owner = "unaligned" //Same as alignment, but only changes when a system is definitively captured (for persistent starmaps)
	var/visited = FALSE
	var/hidden = FALSE //Secret systems
	var/list/system_type = null //Set this to pre-spawn systems as a specific type.
	var/event_chance = 0
	var/list/possible_events = list()
	var/list/active_missions = list()

	var/list/contents_positions = list()
	var/list/system_contents = list()
	var/list/enemy_queue = list()

	var/danger_level = 0
	var/system_traits = NONE
	var/is_capital = FALSE
	var/list/adjacency_list = list() //Which systems are near us, by name
	///List of adjacencies this system started with. Should never be edited. Cannot be initialed due to the json loading to system adjacencies.
	var/list/initial_adjacencies = list()
	var/occupying_z = 0 //What Z-level is this  currently stored on? This will always be a number, as Z-levels are "held" by ships.
	var/list/wormhole_connections = list() //Where did we dun go do the wormhole to honk
	var/fleet_type = null //Wanna start this system with a fleet in it?
	var/list/fleets = list() //Fleets that are stationed here.
	var/sector = 1 //What sector of space is this in?
	var/is_hypergate = FALSE //Used to clearly mark sector jump points on the map
	var/preset_trader = null
	var/datum/trader/trader = null
	var/list/audio_cues = null //if you want music to queue on system entry. Format: list of youtube or media URLS.
	var/already_announced_combat = FALSE
	var/startup_proc = null

/datum/star_system/proc/dist(datum/star_system/other)
	var/dx = other.x - x
	var/dy = other.y - y
	return sqrt((dx * dx) + (dy * dy))

/datum/star_system/proc/parse_startup_proc()
	switch(startup_proc)
		if("STARTUP_PROC_TYPE_BRASIL")
			addtimer(CALLBACK(src, PROC_REF(generate_badlands)), 5 SECONDS)
			return
		if("STARTUP_PROC_TYPE_BRASIL_LITE")
			addtimer(CALLBACK(src, PROC_REF(generate_litelands)), 5 SECONDS)
			return
		if("STARTUP_PROC_TYPE_DOLOS")
			addtimer(CALLBACK(src, PROC_REF(register_dolos_achievement)), 5 SECONDS)
			return
		if("STARTUP_PROC_TYPE_ABASSI")
			addtimer(CALLBACK(src, PROC_REF(register_abassi_achievement)), 5 SECONDS)
			return
	message_admins("WARNING: Invalid startup_proc declared for [name]! Review your defines (~L498, starsystem.dm), please.")
	return 1

/datum/star_system/vv_edit_var(var_name, var_value)
	var/list/banned_edits = list(NAMEOF(src, initial_adjacencies))
	if(var_name in banned_edits)
		return FALSE	//Don't you dare break the json.
	return ..()

/datum/star_system/New(name, desc, threat_level, alignment, owner, hidden, system_type, system_traits, is_capital, adjacency_list, wormhole_connections, fleet_type, x, y, parallax_property, visitable, sector, is_hypergate, preset_trader, audio_cues, startup_proc)
	. = ..()
	//Load props first.
	if(name)
		src.name = name
	if(desc)
		src.desc = desc
	if(threat_level)
		src.threat_level = threat_level
	if(alignment)
		src.alignment = alignment
	if(owner)
		src.owner = owner
	if(hidden)
		src.hidden = hidden
	if(system_type)
		src.system_type = system_type
	if(system_traits)
		src.system_traits = system_traits
	if(is_capital)
		src.is_capital = is_capital
	if(adjacency_list)
		var/list/cast_adjacency_list = adjacency_list
		src.adjacency_list = cast_adjacency_list
		src.initial_adjacencies = cast_adjacency_list.Copy()
	if(wormhole_connections)
		src.wormhole_connections = wormhole_connections
	if(fleet_type)
		src.fleet_type = fleet_type
	if(x)
		src.x = x
	if(y)
		src.y = y
	if(parallax_property)
		src.parallax_property = parallax_property
	if(visitable)
		src.visitable = visitable
	if(sector)
		src.sector = sector
	if(is_hypergate)
		src.is_hypergate = is_hypergate
	if(preset_trader)
		src.preset_trader = preset_trader
	if(audio_cues)
		src.audio_cues = audio_cues
	if(startup_proc)
		src.startup_proc = startup_proc
		parse_startup_proc()

	//Then set up.
	if(src.fleet_type)
		var/datum/fleet/fleet = new src.fleet_type(src)
		fleet.current_system = src
		src.fleets += fleet
		fleet.assemble(src)
	if(src.preset_trader)
		log_world("[src] has a preset trader")
		src.trader = new src.preset_trader
		//We need to instantiate the trader's shop now and give it info, so unfortunately these'll always load in.
		var/obj/structure/overmap/trader/station13 = SSstar_system.spawn_anomaly(src.trader.station_type, src, TRUE)
		station13.starting_system = src.name
		station13.current_system = src
		station13.set_trader(src.trader)
		src.trader.system = src
		// trader.generate_missions()
	if(!CHECK_BITFIELD(src.system_traits, STARSYSTEM_NO_ANOMALIES))
		addtimer(CALLBACK(src, PROC_REF(generate_anomaly)), 15 SECONDS)
	if(!CHECK_BITFIELD(src.system_traits, STARSYSTEM_NO_ASTEROIDS))
		addtimer(CALLBACK(src, PROC_REF(spawn_asteroids)), 15 SECONDS)

/datum/star_system/proc/create_wormhole()
	var/list/potential_systems = list()
	for(var/datum/star_system/P in SSstar_system.systems)
		if(!CHECK_BITFIELD(P.system_traits, STARSYSTEM_NO_WORMHOLE) && P != src) //Not ourselves or systems that we don't want wormholes to
			potential_systems += P

	var/datum/star_system/S = pick(potential_systems) //Pick a random system to put the wormhole in
	if(!(LAZYFIND(adjacency_list, S))) //Makes sure we're not already linked.
		adjacency_list += S.name
		wormhole_connections += S.name
		SSstar_system.spawn_anomaly(/obj/effect/overmap_anomaly/wormhole, src, center=TRUE)
		var/oneway = "One-way"
		if(!(LAZYFIND(S.adjacency_list, src)) && prob(30)) //Two-directional wormholes, AKA valid hyperlanes, are exceedingly rare.
			S.adjacency_list += name
			S.wormhole_connections += name
			oneway = "Two-way"
			SSstar_system.spawn_anomaly(/obj/effect/overmap_anomaly/wormhole, S, center=TRUE) //Wormholes are cool. Like Fezzes. Fezzes are cool.
		log_game("[oneway] wormhole created between [S] and [src]")

//Anomalies

/datum/star_system/proc/get_info()
	var/list/anomalies = list()
	for(var/obj/effect/overmap_anomaly/OA in system_contents)
		if(istype(OA))
			var/list/anomaly_info = list()
			anomaly_info["name"] = OA.name
			anomaly_info["desc"] = OA.desc
			anomaly_info["points"] = OA.research_points
			anomaly_info["scannable"] = !OA.scanned
			anomaly_info["anomaly_id"] = "\ref[OA]"
			anomalies[++anomalies.len] = anomaly_info
	return anomalies

/obj/effect/overmap_anomaly //Should not appear normally.
	name = "Tear in reality"
	desc = "Your mind is shattering just from looking at this."
	icon = 'nsv13/goonstation/icons/effects/explosions/electricity.dmi'
	icon_state = "rit-elec-aoe"
	bound_width = 64
	bound_height = 64
	var/datum/star_system/current_system
	var/research_points = 25000 //Glitches in spacetime are *really* interesting okay?
	var/scanned = FALSE
	var/specialist_research_type = null //Special techweb node unlocking.

/obj/effect/overmap_anomaly/Initialize(mapload, system)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	GLOB.overmap_anomalies += src
	if(system)
		current_system = system

/obj/effect/overmap_anomaly/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER

	if(istype(AM, /obj/item/projectile/bullet/torpedo/probe))
		SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, research_points*1.5) //more points for scanning up close.
		if(specialist_research_type)
			SSresearch.science_tech.add_point_type(specialist_research_type, research_points)
		research_points = 0
		scanned = TRUE
		minor_announce("Successfully received probe telemetry. Full astrological survey of [name] complete.", "WAYFARER subsystem")
		for(var/obj/structure/overmap/OM in GLOB.overmap_objects) //Has to go through global overmaps due to anomalies not referencing their system - probably something to change one day.
			if(OM && OM.z == z)
				OM.relay('nsv13/sound/effects/ship/FTL.ogg')
		qdel(AM)

/obj/effect/overmap_anomaly/wormhole
	name = "Wormhole"
	desc = "A huge tear in the fabric of space-time that can fling you to faraway places. A scan of this anomaly could advance the field of space-travel by years!"
	icon = 'nsv13/goonstation/icons/effects/overmap_anomalies/tearhuge.dmi'
	icon_state = "tear"
	research_points = 15000 //These things are really valuable and give you upgraded jumpdrive tech.
	bound_width = 64
	bound_height = 64
	pixel_x = -64
	pixel_y = -64
	specialist_research_type = TECHWEB_POINT_TYPE_WORMHOLE

#define OVERMAP_SINGULARITY_PROX_GRAVITY 2
#define OVERMAP_SINGULARITY_REDSHIFT_GRAV 3.5
#define OVERMAP_SINGULARITY_DANGER_GRAV 5
#define OVERMAP_SINGULARITY_DEATH_GRAV 40

/obj/effect/overmap_anomaly/singularity
	name = "Black hole"
	desc = "A peek into the void between worlds. These stellar demons consume everything in their path. Including you. Scanning this singularity could lead to groundbreaking discoveries in the field of quantum physics!"
	icon = 'nsv13/goonstation/icons/effects/overmap_anomalies/blackhole.dmi'
	icon_state = "blackhole"
	research_points = 20000 //These things are pretty damn valuable, for their risk of course.
	pixel_x = -64
	pixel_y = -64
	///Overmap objects currently being in range of the black hole
	var/list/affecting = list()
	///Assoc list that tracks which grav we already made the ship suffer
	var/list/grav_tracker = list()
	///Previous colors of overmaps before being discolored, to preserve fighters
	var/list/cached_colours = list()
	///Range closer than which things get a lot more dangerous.
	var/event_horizon_range = 15
	///Range closer than which starts discoloring everything into red
	var/redshift_range = 30
	///Total range of the black hole influence
	var/influence_range = 90 //Slightly less since it loops now.
	///Gravity pull when being close
	var/inner_pull_strength = 0.2 //Somewhat more since the vectors get correctly calced now.
	///Gravity pull while far away
	var/outer_pull_strength = 0.1

/obj/effect/overmap_anomaly/singularity/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/effect/overmap_anomaly/singularity/process()
	if(!z || !current_system) //Not in nullspace
		if(length(affecting))
			for(var/obj/structure/overmap/OM in affecting)
				stop_affecting(OM)
		return
	for(var/obj/structure/overmap/OM in current_system.system_contents) //This list is not exclusively overmaps so no as() calls.
		if(LAZYFIND(affecting, OM))
			continue
		if(OM.z != z)
			continue
		if(overmap_dist(src, OM) <= influence_range)
			affecting += OM
			grav_tracker[OM] = 0
			cached_colours[OM] = OM.color //So that say, a yellow fighter doesnt get its paint cleared by redshifting
			OM.relay(S='nsv13/sound/effects/ship/falling.ogg', message="<span class='warning'>You feel weighed down.</span>", loop=TRUE, channel=CHANNEL_HEARTBEAT)
			ADD_TRAIT(OM, TRAIT_NODAMPENERS, TRAIT_SOURCE_OVERMAP_BLACKHOLE)
			OM.disable_dampeners()
			RegisterSignal(OM, COMSIG_PARENT_QDELETING, PROC_REF(handle_affecting_del))
	for(var/obj/structure/overmap/OM as() in affecting)
		var/dist = overmap_dist(src, OM)
		if(dist > influence_range || !z || OM.z != z)
			stop_affecting(OM)
			continue
		var/grav_level = OVERMAP_SINGULARITY_PROX_GRAVITY
		if(dist <= redshift_range)
			var/redshift ="#[num2hex(130-dist,2)][num2hex(0,2)][num2hex(0,2)]"
			OM.color = redshift
			for(var/mob/M in OM.mobs_in_ship)
				M?.client?.color = redshift
			grav_level = OVERMAP_SINGULARITY_REDSHIFT_GRAV
			if(dist < event_horizon_range) //This var name kind of lies since the event horizon is actually at dist 2. I guess this is just the "it gets serious" distance.
				grav_level = OVERMAP_SINGULARITY_DANGER_GRAV
		else
			if(grav_tracker[OM] >= OVERMAP_SINGULARITY_REDSHIFT_GRAV)
				OM.color = cached_colours[OM] //Reset color, do not reset cache since we are still in proximity.
				for(var/mob/M in OM.mobs_in_ship)
					M?.client?.color = null
		if(dist <= 2)
			OM.current_system?.remove_ship(OM, is_ftl_jump = FALSE)
			for(var/area/crushed as() in OM.linked_areas)
				if(istype(crushed, /area/space))
					continue
				crushed.has_gravity = OVERMAP_SINGULARITY_DEATH_GRAV //You are dead.
			grant_death_achievement(OM)
			qdel(OM)
			continue
		if(grav_tracker[OM] != grav_level)
			for(var/area/crushed as() in OM.linked_areas)
				if(istype(crushed, /area/space))
					continue
				crushed.has_gravity = grav_level
				grav_tracker[OM] = grav_level
		dist = (dist > 0) ? dist : 1
		var/pull_strength = (dist > event_horizon_range) ? outer_pull_strength : inner_pull_strength
		var/succ_impulse = !OM.brakes ? pull_strength/dist*dist : (OM.forward_maxthrust / 10) + (pull_strength/dist*dist) //STOP RESISTING THE SUCC - is this meant to be inverse square? Missing a () in that case.. probably more 'fun' this way though since very low velocities get zerod - Delta.
		var/relative_angle = overmap_angle(OM, src) % 360
		var/x_succ = (succ_impulse * sin(relative_angle)) //I LOVE circle math I LOVE pi. (these two lines get the x and y component of the gravity vector)
		var/y_succ = (succ_impulse * cos(relative_angle))
		OM.velocity.a += x_succ
		OM.velocity.e += y_succ

/obj/effect/overmap_anomaly/singularity/proc/stop_affecting(obj/structure/overmap/OM = null)
	if(OM)
		affecting -= OM
		REMOVE_TRAIT(OM, TRAIT_NODAMPENERS, TRAIT_SOURCE_OVERMAP_BLACKHOLE)
		OM.stop_relay(CHANNEL_HEARTBEAT)
		OM.color = cached_colours[OM]
		cached_colours[OM] = null
		for(var/mob/M in OM.mobs_in_ship)
			M?.client?.color = null
		for(var/area/crushed as() in OM.linked_areas)
			if(istype(crushed, /area/space))
				continue
			crushed.has_gravity = initial(crushed.has_gravity)
		grav_tracker -= OM
		UnregisterSignal(OM, COMSIG_PARENT_QDELETING)

/obj/effect/overmap_anomaly/singularity/proc/handle_affecting_del(obj/structure/overmap/deleting)
	affecting -= deleting
	grav_tracker -= deleting
	cached_colours[deleting] = null
	UnregisterSignal(deleting, COMSIG_PARENT_QDELETING)

/obj/effect/overmap_anomaly/singularity/proc/grant_death_achievement(obj/structure/overmap/congratulations)
	for(var/mob/living/nice_job in congratulations.mobs_in_ship)
		if(!nice_job.client)
			continue
		nice_job.client.give_award(/datum/award/achievement/misc/blackhole_incident, nice_job)

#undef OVERMAP_SINGULARITY_PROX_GRAVITY
#undef OVERMAP_SINGULARITY_REDSHIFT_GRAV
#undef OVERMAP_SINGULARITY_DANGER_GRAV
#undef OVERMAP_SINGULARITY_DEATH_GRAV

/obj/effect/overmap_anomaly/wormhole/Initialize(mapload)
	. = ..()
	icon = pick('nsv13/goonstation/icons/effects/overmap_anomalies/tearhuge.dmi', 'nsv13/goonstation/icons/effects/overmap_anomalies/tearmed.dmi', 'nsv13/goonstation/icons/effects/overmap_anomalies/tearsmall.dmi')

/obj/effect/overmap_anomaly/safe
	name = "Placeholder"

/obj/effect/overmap_anomaly/safe/sun
	name = "Star"
	desc = "A huge ball of burning hydrogen that lights up space around it. Scanning its corona could yield useful information."
	icon = 'nsv13/goonstation/icons/effects/overmap_anomalies/stellarbodies.dmi'
	icon_state = "sun"
	research_points = 3000 //Pretty meagre, but a sustainable source of points.

/obj/effect/overmap_anomaly/safe/sun/red_giant
	name = "Red Giant"
	desc = "A large star that is nearing the end of its life. A scan of its stellar core could lead to useful conclusions."
	icon_state = "redgiant"
	research_points = 4000 //Somewhat more interesting than a sun.

//Space Weather

/datum/star_system/proc/apply_system_effects()
	event_chance = 15 //Very low chance of an event happening
	var/anomaly_type = null
	difficulty_budget = threat_level
	var/list/sys = system_type
	switch(sys["tag"])
		if("safe")
			possible_events = list(/datum/round_event_control/aurora_caelus)
		if("hazardous") //TODO: Make better anomalies spawn in hazardous systems scaling with threat level.
			possible_events = list(/datum/round_event_control/carp_migration, /datum/round_event_control/electrical_storm)
		if("wormhole")
			possible_events = list(/datum/round_event_control/wormholes, /datum/round_event/anomaly) //Wormhole systems are unstable in bluespace
			event_chance = 70 //Highly unstable region of space.
			create_wormhole()
			return
		/* Handled with boarders - replace me with something else
		if("pirate")
			possible_events = list(/datum/round_event_control/pirates) //Well what did you think was gonna happen when you jumped into a pirate system?
		*/
		if("radioactive")
			parallax_property = "radiation_cloud" //All credit goes to https://www.filterforge.com/filters/11427.html
			possible_events = list(/datum/round_event_control/radiation_storm/deadly, /datum/round_event_control/radioactive_sludge = 5)
			event_chance = 100 //Radioactive systems are just that: Radioactive
		if("nebula")
			parallax_property = "nebula-thick" //All credit goes to https://www.filterforge.com/filters/11427.html
		if("quasar")
			parallax_property = "quasar"
			possible_events = list(/datum/round_event_control/grey_tide, /datum/round_event_control/ion_storm, /datum/round_event_control/communications_blackout)
			event_chance = 100 //Quasars are screwy.
		if("accretiondisk")
			parallax_property = "accretiondisk_planet"
			possible_events = list(/datum/round_event_control/grey_tide, /datum/round_event_control/ion_storm, /datum/round_event_control/communications_blackout)
			event_chance = 70 //Black holes can fuck with you
		if("debris")
			parallax_property = "rocks"
			event_chance = 60 //Space rocks!
			possible_events = list(/datum/round_event_control/space_dust, /datum/round_event_control/meteor_wave)
		if("icefield")
			parallax_property = "icefield"
		if("demonstar")
			parallax_property = "demonstar_planet"
		if("supernova")
			parallax_property = "supernova_planet"
		if("gas")
			parallax_property = "gas"
		if("planet_earth")
			parallax_property = "planet_earth"
		if("ice_planet")
			parallax_property = "ice_planet"
		if("graveyard")
			parallax_property = "graveyard"
		if("blackhole")
			anomaly_type = /obj/effect/overmap_anomaly/singularity
			parallax_property = "pitchblack"
		if("blacksite") //this a special one!
			adjacency_list += SSstar_system.return_system.name //you're going to risa, damnit.
			SSstar_system.spawn_anomaly(/obj/effect/overmap_anomaly/wormhole, src, center=TRUE)
	if(alignment == "syndicate")
		spawn_enemies() //Syndicate systems are even more dangerous, and come pre-loaded with some Syndie ships.
		if(prob(20)) //Watch your step!
			spawn_mines("syndicate")
	if(alignment == "unaligned")
		if(prob(25))
			spawn_enemies()
		else if (prob(33))
			var/pickedF = pick(list(/datum/fleet/nanotrasen/light, /datum/fleet/nanotrasen)) //This should probably be a seperate proc to spawn friendlies
			var/datum/fleet/F = new pickedF
			F.current_system = src
			fleets += F
			F.assemble(src)
	if(!anomaly_type)
		anomaly_type = pick(subtypesof(/obj/effect/overmap_anomaly/safe))
	SSstar_system.spawn_anomaly(anomaly_type, src)

/datum/star_system/proc/generate_anomaly()
	if(prob(15)) //Low chance of spawning a wormhole twixt us and another system.
		create_wormhole()
	if(system_type) //Already have a preset system type. Apply its effects.
		apply_system_effects()
		return
	switch(threat_level)
		if(THREAT_LEVEL_NONE) //Threat level 0 denotes starter systems, so they just have "fluff" anomalies like gas clouds and whatever.
			system_type = pick(
				list(
					tag = "safe",
					label = "Empty space",
				),
				list(
					tag = "nebula",
					label = "Nebula",
				),
				list(
					tag = "gas",
					label = "Gas cloud",
				),
				list(
					tag = "icefield",
					label = "Ice field",
				),
				list(
					tag = "ice_planet",
					label = "Planetary system",
				),
			)
		if(THREAT_LEVEL_UNSAFE) //Unaligned and Syndicate systems have a chance to spawn threats. But nothing major.
			system_type = pick(
				list(
					tag = "debris",
					label = "Asteroid field",
				),
				list(
					tag = "pirate",
					label = "Debris",
				),
				list(
					tag = "nebula",
					label = "Nebula",
				),
				list(
					tag = "hazardous",
					label = "Untagged hazard",
				),
			)
		if(THREAT_LEVEL_DANGEROUS) //Extreme threat level. Time to break out the most round destroying anomalies.
			system_type = pick(
				list(
					tag = "quasar",
					label = "Quasar",
				),
				list(
					tag = "radioactive",
					label = "Radioactive",
				),
				list(
					tag = "blackhole",
					label = "Black hole",
				),
			)
	apply_system_effects()

/datum/star_system/proc/spawn_asteroids()
	for(var/I = 0; I <= rand(3, 6); I++)
		var/roid_type = pick(/obj/structure/overmap/asteroid, /obj/structure/overmap/asteroid/medium, /obj/structure/overmap/asteroid/large)
		SSstar_system.spawn_ship(roid_type, src)

/datum/star_system/proc/spawn_enemies(enemy_type, amount)
	if(!amount)
		amount = difficulty_budget
		if(amount <= 0)
			amount = 1 //Why else are you calling this?
	for(var/i = 0, i < amount, i++) //number of enemies is set via the star_system vars
		if(!enemy_type)
			enemy_type = pick(SSstar_system.enemy_types) //Spawn a random set of enemies.
		SSstar_system.spawn_ship(enemy_type, src)

/datum/star_system/proc/spawn_mines(faction, amount)
	if(!amount)
		amount = difficulty_budget*2
		if(amount <= 0)
			amount = 1 //Why else are you calling this?
	if(!faction) //Someone forgot to set their IFF
		faction = alignment
	if(!occupying_z) //We didn't get one
		for(var/i = 0, i < amount, i++)
			var/obj/structure/space_mine/M = new /obj/structure/space_mine(null, faction, src) //You are in nullspace now
			contents_positions[M] = list("x" = rand(5, world.maxx - 5),"y" = rand(5, world.maxy - 5))
	for(var/i = 0, i < amount, i++)
		new /obj/structure/space_mine(get_turf(locate(rand(5, world.maxx - 5), rand(5, world.maxy - 5), occupying_z)), faction, src) //random location in the system

/datum/star_system/proc/lerp_x(datum/star_system/other, t)
	return x + (t * (other.x - x))

/datum/star_system/proc/lerp_y(datum/star_system/other, t)
	return y + (t * (other.y - y))

/datum/star_system/staging
	name = "Staging"
	desc = "Used for round initialisation and admin event staging"
	hidden = TRUE
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_ASTEROIDS | STARSYSTEM_NO_WORMHOLE

/datum/star_system/staging/handle_combat() //disable the table top action
	return

//////star_system LIST (order of appearance)///////
// Only used as a fallback if the .json doesn't load right now.
/datum/star_system/sol
	name = "Sol"
	is_capital = TRUE
	x = 70
	y = 50
	fleet_type = /datum/fleet/solgov/earth
	alignment = "solgov"
	system_type = list(
		tag = "planet_earth",
		label = "Planetary system",
	)
	adjacency_list = list("Alpha Centauri", "Outpost 45", "Ross 154")
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_WORMHOLE

/datum/star_system/ross
	name = "Ross 154" //Hi mate my name's ross how's it going
	x = 80
	y = 45
	alignment = "nanotrasen"
	threat_level = THREAT_LEVEL_NONE
	adjacency_list = list("Sol", "Barnard's Star", "Alpha Centauri")

/datum/star_system/barnie
	name = "Barnard's Star"
	x = 75
	y = 60
	alignment = "nanotrasen"
	system_type = list(
		tag = "supernova",
		label = "Supernova",
	)
	threat_level = THREAT_LEVEL_NONE
	adjacency_list = list("Ross 154", "Sol")

/datum/star_system/acentauri
	name = "Alpha Centauri"
	x = 68
	y = 46
	alignment = "nanotrasen"
	threat_level = THREAT_LEVEL_NONE
	adjacency_list = list("Ross 154", "Sol", "Sirius")

/datum/star_system/sirius
	name = "Sirius"
	x = 50
	y = 35
	alignment = "nanotrasen"
	threat_level = THREAT_LEVEL_NONE
	adjacency_list = list("Alpha Centauri", "Wolf 359", "Sol")
	preset_trader = /datum/trader/minsky

/datum/star_system/wolf359
	name = "Wolf 359"
	x = 25
	y = 65
	alignment = "nanotrasen"
	adjacency_list = list("Sirius","Sol", "Wolf 359", "Lalande 21185")

//Sector translation point. Using the power of a demon star, the ship is able to enhance its effective FTL range.
/datum/star_system/lalande21185
	name = "Lalande 21185"
	x = 25
	y = 80
	system_type = list(
		tag = "demonstar",
		label = "Demon star",
	)
	alignment = "nanotrasen"
	fleet_type = /datum/fleet/nanotrasen/border
	adjacency_list = list("Wolf 359", "Feliciana", "Outpost 45")
	is_hypergate = TRUE

/datum/star_system/outpost
	name = "Outpost 45"
	hidden = TRUE //Initially hidden, unlocked when the players complete their patrol.
	mission_sector = TRUE
	x = 40
	y = 80
	alignment = "nanotrasen"
	adjacency_list = list("Lalande 21185")
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_ASTEROIDS | STARSYSTEM_NO_WORMHOLE | STARSYSTEM_END_ON_ENTER

//Sector 2: Neutral Zone.
/*
<summary>
Welcome to the neutral zone! Non corporate sanctioned traders with better gear and missions, but be wary of pirates!
</summary>
*/

//It's BACK
/datum/star_system/Feliciana
	name = "Feliciana"
	x = 10
	y = 70
	system_type = list(
		tag = "demonstar",
		label = "Demon star",
	)
	alignment = "nanotrasen"
	adjacency_list = list("Lalande 21185", "Corvi")
	sector = 2
	is_hypergate = TRUE

/datum/star_system/sector2
	name = "Corvi"
	parallax_property = "icefield"
	x = 10
	y = 60
	alignment = "unaligned"
	sector = 2
	adjacency_list = list("Feliciana", "Argo")

/datum/star_system/sector2/argo
	name = "Argo"
	x = 15
	y = 55
	alignment = "nanotrasen"
	adjacency_list = list("Corvi", "Ariel", "Ida")
	preset_trader = /datum/trader/czanekcorp

/datum/star_system/sector2/ariel
	name = "Ariel"
	x = 8
	y = 45
	alignment = "nanotrasen"
	adjacency_list = list("Corvi", "Argo", "Ida")

/datum/star_system/sector2/ida
	name = "Ida"
	x = 20
	y = 50
	alignment = "nanotrasen"
	adjacency_list = list("Ariel", "Argo", "Foothold")

/datum/star_system/sector2/foothold //The last bastion of civilisation.
	name = "Foothold"
	x = 30
	y = 40
	alignment = "nanotrasen"
	fleet_type = /datum/fleet/nanotrasen/border/defense //The foothold in the darkness
	adjacency_list = list("Ariel", "Argo", "The Badlands", "Ida", "Sion")
	preset_trader = /datum/trader/armsdealer
	desc = "The last bastion of civilisation before the endless uncharted wastes beyond."

/datum/star_system/sector2/sion
	name = "Sion"
	x = 27
	y = 25
	threat_level = THREAT_LEVEL_UNSAFE
	alignment = "unaligned"
	adjacency_list = list("Foothold", "Muir", "Beylix", "Sebacien")
	desc = "The inroad to several independent colonies long abandoned by SolGov. The Sion cluster houses criminals and opportunists alike."

/datum/star_system/sector2/muir
	name = "Muir"
	x = 25
	y = 30
	threat_level = THREAT_LEVEL_UNSAFE
	alignment = "unaligned"
	adjacency_list = list("Sion", "Sebacien")

/datum/star_system/sector2/beylix
	name = "Beylix"
	x = 34
	y = 22
	threat_level = THREAT_LEVEL_UNSAFE
	alignment = "unaligned"
	adjacency_list = list("Sion", "Muir", "Sebacien")

/datum/star_system/sector2/sebacien
	name = "Sebacien"
	x = 35
	y = 28
	threat_level = THREAT_LEVEL_UNSAFE
	alignment = "unaligned"
	adjacency_list = list("Sion", "Muir", "Beylix")

/datum/star_system/sector2/tortuga
	name = "Tortuga"
	x = 10
	y = 30
	alignment = "unaligned"
	system_type = list(
		tag = "pirate", //Guranteed piratical action!
		label = "Scrapyard",
	)
	threat_level = THREAT_LEVEL_UNSAFE
	wormhole_connections = list("Feliciana")
	adjacency_list = list()
	fleet_type = /datum/fleet/pirate/tortuga

/datum/star_system/sector2/rubicon
	name = "Rubicon"
	x = 140
	y = 60
	alignment = "syndicate"
	system_type = list(
		tag = "demonstar",
		label = "Demon star",
	)
	is_hypergate = TRUE
	threat_level = THREAT_LEVEL_UNSAFE
	fleet_type = /datum/fleet/rubicon
	adjacency_list = list("Romulus")
	desc = "Many have attempted to cross the Rubicon, many have failed. This system bridges many different sectors together, and is an inroad for the largely unknown Abassi ridge nebula."

/**
Random starsystem. Excluded from starmap saving, as they're generated at init.
*/
/datum/star_system/random
	name = "Unknown Sector"
	x = 0
	y = 0
	hidden = TRUE
	alignment = "uncharted"
	owner = "uncharted" //Currently this will say occupied whenever any fleet enters, change this.

//The badlands generates a rat run of random systems around it, so keep it well clear of civilisation
/datum/star_system/brasil
	name = "The Badlands"
	alignment = "uncharted"
	owner = "uncharted" //Ditto star_system/random
	x = 50
	y = 30
	sector = 2
	adjacency_list = list("Foothold")
	desc = "The beginning of a sector of uncharted space known as the Delphic expanse. Ships from many opposing factions all vye for control over this new territory."
	startup_proc = "STARTUP_PROC_TYPE_BRASIL"

#define NONRELAXATION_PENALTY 1.2 //Encourages the badlands generator to use jump line relaxation even if a + b >= c. Set this lower if you want Brazil's jumplines to be more direct, high values might be very wacky. 1.0 will give all of the systems a direct jumpline to rubiconnector. Values below 1 might be very wacky.
#define MAX_RANDOM_CONNECTION_LENGTH 30 //How long the random jump lines generated by this can be. Use higher values if there is few systems, or the sector may be very desolate of jump lines.
#define MIN_RANDOM_CONNECTION_LENGTH 0	//Same as above, but minimum instead. Default is 0, set it higher if you want more interconnectedness instead of it. Works well together with a high maximum.
#define RNGSYSTEM_MAX_CONNECTIONS 4 //A system has to have less than this amount of connections to gain new random jumplines. Note that this does not affect the tree-phase of the algorytm.
#define RANDOM_CONNECTION_BASE_CHANCE 40	//How high the probability for a system to gain a random jumpline is, provided it is valid and has valid partners. In percent.
#define RANDOM_CONNECTION_REPEAT_PENALTY 20	//By how much this probability decreases per random jump line added to the system. In percent.

/datum/star_system/proc/generate_badlands()
	var/list/generated = list()
	var/amount = rand(17, 25)
	var/toocloseconflict = 0
	message_admins("Generating Badlands with [amount] systems.")
	var/start_timeofday = REALTIMEOFDAY
	var/datum/star_system/rubicon = SSstar_system.system_by_id("Rubicon")
	if(!rubicon)
		message_admins("Error setting up Badlands - No Rubicon found!") //This should never happen unless admins do bad things.
		return

	for(var/I=0;I<amount,I++){
		var/datum/star_system/random/randy = new /datum/star_system/random()
		randy.system_type = pick(
			list(
				tag = "radioactive",
				label = "Radioactive",
			), 0.5;
			list(
				tag = "blackhole",
				label = "Blackhole",
			),
			list(
				tag = "quasar",
				label = "Quasar",
			), 0.75;
			list(
				tag = "accretiondisk",
				label = "Accretion disk",
			),
			list(
				tag = "nebula",
				label = "Nebula",
			),
			list(
				tag = "supernova",
				label = "Supernova",
			),
			list(
				tag = "debris",
				label = "Asteroid field",
			),
		)
		randy.apply_system_effects()
		randy.name = (randy.system_type[tag] != "nebula") ? "S-[rand(0,10000)]" : "N-[rand(0,10000)]"
		var/randy_valid = FALSE

		while(!randy_valid)
			randy.x = ((rand(1, 10)/10)+rand(1, 80)+20) // Buffer space for readability
			randy.y = ((rand(1, 10)/10)+rand(1, 50)+30) // Offset vertically for viewing 'pleasure'
			var/syscheck_pass = TRUE
			for(var/datum/star_system/S in (generated + rubicon + src))
				if(!syscheck_pass)
					break
				if(S.dist(randy) < 5)// Maybe this is enough?
					syscheck_pass = FALSE
					continue
				if(S.name == "Rubicon" && (S.dist(randy) < 7)) //Rubicon's text is too fat.
					syscheck_pass = FALSE
					continue
			if(syscheck_pass)
				randy_valid = TRUE
			else
				toocloseconflict++

		randy.sector = sector //Yeah do I even need to explain this?
		randy.hidden = FALSE
		generated += randy
		if(prob(10))
			//10 percent of systems have a trader for resupply.
			var/x = pick(typesof(/datum/trader)-/datum/trader)
			var/datum/trader/randytrader = new x
			var/obj/structure/overmap/trader/randystation = SSstar_system.spawn_anomaly(randytrader.station_type, randy)
			randystation.starting_system = randy.name
			randystation.current_system = randy
			randystation.set_trader(randytrader)
			randy.trader = randytrader
			// randytrader.generate_missions()

		else if(prob(10))
			var/x = pick(/datum/fleet/wolfpack, /datum/fleet/neutral, /datum/fleet/pirate/raiding, /datum/fleet/boarding, /datum/fleet/nanotrasen/light)
			var/datum/fleet/randyfleet = new x
			randyfleet.current_system = randy
			randyfleet.hide_movements = TRUE //Prevent the shot of spam this caused to R1497.
			randy.fleets += randyfleet
			randy.alignment = randyfleet.alignment
			randy.owner = randyfleet.alignment
			randyfleet.assemble(randy)

		SSstar_system.systems += randy
	}
	var/lowest_dist = 1000
	//Finally, let's play this drunken game of connect the dots.

	//First, we use the system closest to rubicon as a connector to it
	var/datum/star_system/rubiconnector = null
	for(var/datum/star_system/S in generated)
		if(S.dist(rubicon) < lowest_dist)
			lowest_dist = S.dist(rubicon)
			rubiconnector = S
	rubiconnector.adjacency_list += rubicon.name
	rubicon.adjacency_list += rubiconnector.name

	//We did it, we connected Rubicon. Now for the fun part: Connecting all of the systems, in a not-as-bad way. We'll use a tree for this, and then add some random connections to make it not as linear.
	generated += src //We want to get to rubicon from here!
	var/relax = 0	//Just a nice stat var
	var/random_jumpline_count = 0 //Another nice stat var
	var/systems[generated.len]
	var/distances[generated.len]
	var/parents[generated.len]	//This is what we will use later
	for(var/i = 1; i <= generated.len; i++)
		systems[i] = generated[i]
		parents[i] = rubiconnector
		if(generated[i] != rubiconnector)
			distances[i] = INFINITY
		else
			distances[i] = 0

	//Setup: Done. Dijkstra time.
	while(length(generated) > 0) //we have to go through this n times
		var/closest = null
		var/mindist = INFINITY
		for(var/datum/star_system/S in generated)	//Find the system with the smallest value in distances[].
			var/thisdist = distances[systems.Find(S)]
			if(!closest || mindist > thisdist)
				closest = systems.Find(S)
				mindist = thisdist //This is always the source node (rubiconnector) in the first run
		generated -= systems[closest]	//Remove it from the list.

		for(var/datum/star_system/S in generated)	//Try relaxing all other systems still in the list via it.
			var/datum/star_system/close = systems[closest]
			var/alternative = distances[closest] + close.dist(S)
			var/adj = systems.Find(S)
			if(alternative < distances[adj] * NONRELAXATION_PENALTY)	//Apply penalty to make the map more interconnected instead of all jump lines just going directly to the rubiconnector
				distances[adj] = alternative
				parents[adj] = systems[closest]
				relax++

	//Dijkstra: Done. We got parents for everyone, time to actually stitch them together.
	for(var/i = 1; i <= length(systems); i++)
		var/datum/star_system/S = systems[i]
		if(S == rubiconnector)
			continue	//Rubiconnector is the home node and would fuck with us if we did stuff with it here.
		var/datum/star_system/Connected = parents[i]
		S.adjacency_list += Connected.name
		Connected.adjacency_list += S.name

	//We got a nice tree! But this is looking far too clean, time to Brazilify this.
	for(var/datum/star_system/S as() in systems)
		var/bonus = 0
		var/list/valids = list()
		for(var/datum/star_system/candidate in systems)
			if(S == candidate)
				continue
			if(candidate.adjacency_list.Find(S.name) || S.adjacency_list.Find(candidate.name))
				continue
			if(S.dist(candidate) > MAX_RANDOM_CONNECTION_LENGTH || candidate.dist(S) < MIN_RANDOM_CONNECTION_LENGTH)
				continue
			if(candidate.adjacency_list.len >= RNGSYSTEM_MAX_CONNECTIONS)
				continue
			valids += candidate
		while(!prob(100 - RANDOM_CONNECTION_BASE_CHANCE + (bonus * RANDOM_CONNECTION_REPEAT_PENALTY))) //Lets not flood the map with random jumplanes, buuut create a good chunk of them
			if(!length(valids))
				break
			if(length(S.adjacency_list) >= RNGSYSTEM_MAX_CONNECTIONS)
				break
			var/datum/star_system/newconnection = pick(valids)
			newconnection.adjacency_list += S.name
			S.adjacency_list += newconnection.name
			valids -= newconnection
			random_jumpline_count++

	//Pick a random entrypoint system
	var/datum/star_system/inroute
	var/ir_rub = 0
	var/ir_othershit = 0
	while (!inroute)
		var/datum/star_system/picked = pick(systems)
		if(rubiconnector.name in picked.adjacency_list)
			ir_rub++
			continue // Skip
		if(picked.trader || picked.fleets.len)
			ir_othershit++
			continue
		var/datum/star_system/sol/solsys = SSstar_system.system_by_id("Sol")
		solsys.adjacency_list += picked.name
		picked.adjacency_list += solsys.name
		inroute = picked
		inroute.is_hypergate = TRUE

	var/time = (REALTIMEOFDAY - start_timeofday) / 10
	//There we go.
	message_admins("Badlands has been generated. T:[time]s CFS:[toocloseconflict]|[ir_rub]|[ir_othershit] Rubiconnector: [rubiconnector], Inroute system is [inroute]. Fun fact, jump lanes have been relaxed [relax] times by the algorithm and [random_jumpline_count] random connections have been created!")
	log_game("Badlands has been generated. T:[time]s CFS:[toocloseconflict]|[ir_rub]|[ir_othershit] Rubiconnector: [rubiconnector], Inroute system is [inroute]. Fun fact, jump lanes have been relaxed [relax] times by the algorithm and [random_jumpline_count] random connections have been created!")

/datum/star_system/proc/generate_litelands()
	var/list/generated = list()
	var/amount = rand(8, 15)
	var/toocloseconflict = 0
	message_admins("Generating Badlands Lite with [amount] systems.")
	var/start_timeofday = REALTIMEOFDAY
	var/datum/star_system/rubicon = SSstar_system.system_by_id(pick(list("Zalosi","Guriibuu")))
	if(!rubicon)
		message_admins("Error setting up Badlands Lite - No connector found!") //This should never happen unless admins do bad things.
		return

	for(var/I=0;I<amount,I++){
		var/datum/star_system/random/randy = new /datum/star_system/random()
		randy.system_type = pick(
			list(
				tag = "radioactive",
				label = "Radioactive",
			), 0.5;
			list(
				tag = "blackhole",
				label = "Blackhole",
			),
			list(
				tag = "quasar",
				label = "Quasar",
			), 0.75;
			list(
				tag = "accretiondisk",
				label = "Accretion disk",
			),
			list(
				tag = "nebula",
				label = "Nebula",
			),
			list(
				tag = "supernova",
				label = "Supernova",
			),
			list(
				tag = "debris",
				label = "Asteroid field",
			),
		)
		randy.apply_system_effects()
		randy.name = (randy.system_type[tag] != "nebula") ? "S-[rand(0,10000)]" : "N-[rand(0,10000)]"
		var/randy_valid = FALSE

		while(!randy_valid)
			randy.x = ((rand(1, 10)/10)+rand(-30, 15)+56)
			randy.y = ((rand(1, 10)/10)+rand(1, 30)+125)
			var/syscheck_pass = TRUE
			for(var/datum/star_system/S in (generated + rubicon + src))
				if(!syscheck_pass)
					break
				if(S.dist(randy) < 5)// Maybe this is enough?
					syscheck_pass = FALSE
					continue
			if(syscheck_pass)
				randy_valid = TRUE
			else
				toocloseconflict++

		randy.sector = sector //Yeah do I even need to explain this?
		randy.hidden = FALSE
		generated += randy
		if(prob(10))
			//10 percent of systems have a trader for resupply.
			var/x = pick(typesof(/datum/trader)-/datum/trader-/datum/trader/randy)
			var/datum/trader/randytrader = new x
			var/obj/structure/overmap/trader/randystation = SSstar_system.spawn_anomaly(randytrader.station_type, randy)
			randystation.starting_system = randy.name
			randystation.current_system = randy
			randystation.set_trader(randytrader)
			randy.trader = randytrader
			// randytrader.generate_missions()

		else if(prob(10))
			var/x = pick(/datum/fleet/wolfpack, /datum/fleet/neutral, /datum/fleet/pirate/raiding, /datum/fleet/boarding, /datum/fleet/nanotrasen/light)
			var/datum/fleet/randyfleet = new x
			randyfleet.current_system = randy
			randyfleet.hide_movements = TRUE //Prevent the shot of spam this caused to R1497.
			randy.fleets += randyfleet
			randy.alignment = randyfleet.alignment
			randy.owner = randyfleet.alignment
			randyfleet.assemble(randy)

		SSstar_system.systems += randy
	}
	var/lowest_dist = 1000
	//Finally, let's play this drunken game of connect the dots.

	//First, we use the system closest to rubicon as a connector to it
	var/datum/star_system/rubiconnector = null
	for(var/datum/star_system/S in generated)
		if(S.dist(rubicon) < lowest_dist)
			lowest_dist = S.dist(rubicon)
			rubiconnector = S
	rubiconnector.adjacency_list += rubicon.name
	rubicon.adjacency_list += rubiconnector.name

	//We did it, we connected Rubicon. Now for the fun part: Connecting all of the systems, in a not-as-bad way. We'll use a tree for this, and then add some random connections to make it not as linear.
	generated += src //We want to get to rubicon from here!
	var/relax = 0	//Just a nice stat var
	var/random_jumpline_count = 0 //Another nice stat var
	var/systems[generated.len]
	var/distances[generated.len]
	var/parents[generated.len]	//This is what we will use later
	for(var/i = 1; i <= generated.len; i++)
		systems[i] = generated[i]
		parents[i] = rubiconnector
		if(generated[i] != rubiconnector)
			distances[i] = INFINITY
		else
			distances[i] = 0

	//Setup: Done. Dijkstra time.
	while(length(generated) > 0) //we have to go through this n times
		var/closest = null
		var/mindist = INFINITY
		for(var/datum/star_system/S in generated)	//Find the system with the smallest value in distances[].
			var/thisdist = distances[systems.Find(S)]
			if(!closest || mindist > thisdist)
				closest = systems.Find(S)
				mindist = thisdist //This is always the source node (rubiconnector) in the first run
		generated -= systems[closest]	//Remove it from the list.

		for(var/datum/star_system/S in generated)	//Try relaxing all other systems still in the list via it.
			var/datum/star_system/close = systems[closest]
			var/alternative = distances[closest] + close.dist(S)
			var/adj = systems.Find(S)
			if(alternative < distances[adj] * NONRELAXATION_PENALTY)	//Apply penalty to make the map more interconnected instead of all jump lines just going directly to the rubiconnector
				distances[adj] = alternative
				parents[adj] = systems[closest]
				relax++

	//Dijkstra: Done. We got parents for everyone, time to actually stitch them together.
	for(var/i = 1; i <= length(systems); i++)
		var/datum/star_system/S = systems[i]
		if(S == rubiconnector)
			continue	//Rubiconnector is the home node and would fuck with us if we did stuff with it here.
		var/datum/star_system/Connected = parents[i]
		S.adjacency_list += Connected.name
		Connected.adjacency_list += S.name

	//We got a nice tree! But this is looking far too clean, time to Brazilify this.
	for(var/datum/star_system/S as() in systems)
		var/bonus = 0
		var/list/valids = list()
		for(var/datum/star_system/candidate in systems)
			if(S == candidate)
				continue
			if(candidate.adjacency_list.Find(S.name) || S.adjacency_list.Find(candidate.name))
				continue
			if(S.dist(candidate) > MAX_RANDOM_CONNECTION_LENGTH || candidate.dist(S) < MIN_RANDOM_CONNECTION_LENGTH)
				continue
			if(candidate.adjacency_list.len >= RNGSYSTEM_MAX_CONNECTIONS)
				continue
			valids += candidate
		while(!prob(100 - RANDOM_CONNECTION_BASE_CHANCE + (bonus * RANDOM_CONNECTION_REPEAT_PENALTY))) //Lets not flood the map with random jumplanes, buuut create a good chunk of them
			if(!length(valids))
				break
			if(length(S.adjacency_list) >= RNGSYSTEM_MAX_CONNECTIONS)
				break
			var/datum/star_system/newconnection = pick(valids)
			newconnection.adjacency_list += S.name
			S.adjacency_list += newconnection.name
			valids -= newconnection
			random_jumpline_count++

	//Pick a random entrypoint system
	var/datum/star_system/inroute
	var/ir_rub = 0
	var/ir_othershit = 0
	while (!inroute)
		var/datum/star_system/picked = pick(systems)
		if(rubiconnector.name in picked.adjacency_list)
			ir_rub++
			continue // Skip
		if(picked.trader || picked.fleets.len)
			ir_othershit++
			continue
		var/datum/star_system/sol/solsys = SSstar_system.system_by_id("Sol")
		solsys.adjacency_list += picked.name
		picked.adjacency_list += solsys.name
		inroute = picked
		inroute.is_hypergate = TRUE

	var/time = (REALTIMEOFDAY - start_timeofday) / 10
	//There we go.
	message_admins("Badlands Lite has been generated. T:[time]s CFS:[toocloseconflict]|[ir_rub]|[ir_othershit] Rubiconnector: [rubiconnector], Inroute system is [inroute]. Fun fact, jump lanes have been relaxed [relax] times by the algorithm and [random_jumpline_count] random connections have been created!")
	log_game("Badlands has been generated. T:[time]s CFS:[toocloseconflict]|[ir_rub]|[ir_othershit] Rubiconnector: [rubiconnector], Inroute system is [inroute]. Fun fact, jump lanes have been relaxed [relax] times by the algorithm and [random_jumpline_count] random connections have been created!")

#undef NONRELAXATION_PENALTY
#undef MAX_RANDOM_CONNECTION_LENGTH
#undef MIN_RANDOM_CONNECTION_LENGTH
#undef RNGSYSTEM_MAX_CONNECTIONS
#undef RANDOM_CONNECTION_BASE_CHANCE
#undef RANDOM_CONNECTION_REPEAT_PENALTY

/*
These are used to check if someone is visiting one of the special systems.
Handled this way and done on the starsystem controller so we do not conflict with other signals that rely on star systems registering a signal onto themselves.
*/

/datum/star_system/proc/register_dolos_achievement()
	SSstar_system.RegisterSignal(src, COMSIG_STAR_SYSTEM_AFTER_ENTER, TYPE_PROC_REF(/datum/controller/subsystem/star_system, dolos_visited))

/datum/star_system/proc/register_abassi_achievement()
	SSstar_system.RegisterSignal(src, COMSIG_STAR_SYSTEM_AFTER_ENTER, TYPE_PROC_REF(/datum/controller/subsystem/star_system, abassi_visited))

/*
<Summary>
Welcome to the endgame. This sector is the hardest you'll encounter in game and holds the Syndicate capital.
</Summary>
*/
/datum/star_system/sector4
	name = "Mediolanum"
	adjacency_list = list("Romulus", "Aeterna Victrix", "Demon's Maw")
	threat_level = THREAT_LEVEL_UNSAFE
	x = 100
	y = 50
	sector = 3

/datum/star_system/sector4/aeterna
	name = "Aeterna Victrix"
	adjacency_list = list("Mediolanum", "Deimos", "Romulus")
	x = 90
	y = 40

/datum/star_system/sector4/demon
	name = "Demon's Maw"
	adjacency_list = list("Aeterna Victrix", "Phobos", "Deimos", "Mediolanum")
	system_type = list(
		tag = "accretiondisk",
		label = "Accretion disk",
	)
	alignment = "uncharted"
	x = 100
	y = 60
	preset_trader = /datum/trader/armsdealer/syndicate

/datum/star_system/sector4/phobos
	name = "Phobos"
	system_type = list(
		tag = "nebula",
		label = "Nebula",
	)
	adjacency_list = list("Demon's Maw", "Deimos", "Dolos Remnants")
	fleet_type = /datum/fleet/border
	x = 120
	y = 70

/datum/star_system/sector4/deimos
	name = "Deimos"
	adjacency_list = list("Demon's Maw", "Dolos Remnants")
	x = 80
	y = 67

/datum/star_system/sector4/dolos
	name = "Dolos Remnants"
	x = 75
	y = 100
	alignment = "syndicate"
	system_type = list(
		tag = "graveyard",
		label = "Graveyard",
	)
	adjacency_list = list("Oasis Fidei", "Deimos", "Phobos") //No going back from here...
	threat_level = THREAT_LEVEL_DANGEROUS
	hidden = FALSE
	desc = "A place where giants fell. You feel nothing save for an odd sense of unease and an eerie silence."
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_WORMHOLE
	startup_proc = "STARTUP_PROC_TYPE_DOLOS"

/datum/star_system/sector4/abassi
	name = "Abassi"
	x = 85
	y = 120
	is_capital = TRUE
	alignment = "syndicate"
	system_type = list(
		tag = "demonstar",
		label = "Demon star",
	)
	adjacency_list = list("Dolos Remnants")
	threat_level = THREAT_LEVEL_DANGEROUS
	hidden = TRUE
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_WORMHOLE
	startup_proc = "STARTUP_PROC_TYPE_ABASSI"

/datum/star_system/sector4/laststand
	name = "Oasis Fidei" //oasis of faith
	x = 75
	y = 120
	alignment = "syndicate"
	system_type = list(
		tag = "radioactive",
		label = "Radioactive",
	)
	adjacency_list = list("Abassi") //No going back from here...
	threat_level = THREAT_LEVEL_DANGEROUS
	hidden = TRUE //In time, not now.
	fleet_type = /datum/fleet/remnant
	system_traits = STARSYSTEM_NO_ANOMALIES | STARSYSTEM_NO_WORMHOLE

/datum/star_system/romulus
	name = "Romulus"
	sector = 3
	x = 60
	y = 50
	alignment = "syndicate"
	system_type = list(
		tag = "demonstar",
		label = "Demon star",
	)
	is_hypergate = TRUE
	threat_level = THREAT_LEVEL_UNSAFE
	fleet_type = /datum/fleet/border
	adjacency_list = list("Rubicon", "Aeterna Victrix")

