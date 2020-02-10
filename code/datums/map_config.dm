//used for holding information about unique properties of maps
//feed it json files that match the datum layout
//defaults to box
//  -Cyberboss

/datum/map_config //NSV EDITED START
	// Metadata
	var/config_filename = "_maps/hammerhead.json"
	var/defaulted = TRUE  // set to FALSE by LoadConfig() succeeding
	// Config from maps.txt
	var/config_max_users = 0
	var/config_min_users = 0
	var/voteweight = 1
	var/votable = FALSE

	// Config actually from the JSON - should default to Hammerhead //NSV EDITS
	var/map_name = "NSV Hammerhead - DEFAULTED"
	var/map_link = "Hammerhead"
	var/map_path = "map_files/Hammerhead"
	var/map_file = "Hammerhead.dmm"

	var/traits = null
	var/space_ruin_levels = -1
	var/space_empty_levels = 1

	var/minetype = "nostromo"

	var/overmap = "overmap.dmm" //NSV13 Stuff with overmap code
	var/over_traits = list(
		list( ZTRAIT_ASTRAEUS = TRUE, ZTRAIT_STATION = FALSE),
		list( ZTRAIT_HYPERSPACE = TRUE, ZTRAIT_STATION = FALSE),
		list( ZTRAIT_CORVI = TRUE, ZTRAIT_STATION = FALSE))
	//NSV13 Stuff with overmap code

	var/allow_custom_shuttles = TRUE
	var/shuttles = list(
		"cargo" = "cargo_box",
		"ferry" = "ferry_fancy",
		"whiteship" = "whiteship_box",
		"emergency" = "emergency_box")

//NSV EDITED END

/proc/load_map_config(filename = "data/next_map.json", default_to_box, delete_after, error_if_missing = TRUE)
	var/datum/map_config/config = new
	if (default_to_box)
		return config
	if (!config.LoadConfig(filename, error_if_missing))
		qdel(config)
		config = new /datum/map_config  // Fall back to Box
	if (delete_after)
		fdel(filename)
	return config

#define CHECK_EXISTS(X) if(!istext(json[X])) { log_world("[##X] missing from json!"); return; }
/datum/map_config/proc/LoadConfig(filename, error_if_missing)
	if(!fexists(filename))
		if(error_if_missing)
			log_world("map_config not found: [filename]")
		return

	var/json = file(filename)
	if(!json)
		log_world("Could not open map_config: [filename]")
		return

	json = file2text(json)
	if(!json)
		log_world("map_config is not text: [filename]")
		return

	json = json_decode(json)
	if(!json)
		log_world("map_config is not json: [filename]")
		return

	config_filename = filename

	CHECK_EXISTS("map_name")
	map_name = json["map_name"]
	CHECK_EXISTS("map_path")
	map_path = json["map_path"]

	map_file = json["map_file"]
	// "map_file": "BoxStation.dmm"
	if (istext(map_file))
		if (!fexists("_maps/[map_path]/[map_file]"))
			log_world("Map file ([map_path]/[map_file]) does not exist!")
			return
	// "map_file": ["Lower.dmm", "Upper.dmm"]
	else if (islist(map_file))
		for (var/file in map_file)
			if (!fexists("_maps/[map_path]/[file]"))
				log_world("Map file ([map_path]/[file]) does not exist!")
				return
	else
		log_world("map_file missing from json!")
		return

	if (islist(json["shuttles"]))
		var/list/L = json["shuttles"]
		for(var/key in L)
			var/value = L[key]
			shuttles[key] = value
	else if ("shuttles" in json)
		log_world("map_config shuttles is not a list!")
		return

	traits = json["traits"]
	// "traits": [{"Linkage": "Cross"}, {"Space Ruins": true}]
	if (islist(traits))
		// "Station" is set by default, but it's assumed if you're setting
		// traits you want to customize which level is cross-linked
		for (var/level in traits)
			if (!(ZTRAIT_STATION in level))
				level += ZTRAITS_STATION
	// "traits": null or absent -> default
	else if (!isnull(traits))
		log_world("map_config traits is not a list!")
		return

	var/temp = json["space_ruin_levels"]
	if (isnum(temp))
		space_ruin_levels = temp
	else if (!isnull(temp))
		log_world("map_config space_ruin_levels is not a number!")
		return

	temp = json["space_empty_levels"]
	if (isnum(temp))
		space_empty_levels = temp
	else if (!isnull(temp))
		log_world("map_config space_empty_levels is not a number!")
		return

	if ("minetype" in json)
		minetype = json["minetype"]

	allow_custom_shuttles = json["allow_custom_shuttles"] != FALSE

	overmap = json["overmap"]
	if (istext(overmap))
		if (!fexists("_maps/[map_path]/[overmap]"))
			log_world("Map file ([map_path]/[overmap]) does not exist!")
			return
	// BECAUSE I NEED TO MODULARISE THIS AND MOVE IT OUT- Jalleo (I should stop shouting at myself) [Shout at me if I dont do this]

	else if (islist(overmap))
		for (var/file in overmap)
			if (!fexists("_maps/[map_path]/[file]"))
				log_world("Map file ([map_path]/[file]) does not exist!")
				return

	over_traits = json["over_traits"]
	if (islist(over_traits))
		// "overmap" is set by default, but it's assumed if you're setting
		// traits you want to customize which level is cross-linked
		for (var/level in over_traits)
			if (!(ZTRAITS_OVERMAP in level))
				level += ZTRAITS_OVERMAP
	// "traits": null or absent -> default
	else if (!isnull(traits))
		log_world("map_config over_traits is not a list!")
		return

	if("map_link" in json)						// NSV Changes begin
		map_link = json["map_link"]
	else
		log_world("map_link missing from json!")	// NSV Changes end

	defaulted = FALSE
	return TRUE
#undef CHECK_EXISTS

/datum/map_config/proc/GetFullMapPaths()
	if (istext(map_file))
		return list("_maps/[map_path]/[map_file]")
	. = list()
	for (var/file in map_file)
		. += "_maps/[map_path]/[file]"

/datum/map_config/proc/is_votable()
	var/below_max = !(config_max_users) || GLOB.clients.len <= config_max_users
	var/above_min = !(config_min_users) || GLOB.clients.len >= config_min_users
	return votable && below_max && above_min

/datum/map_config/proc/MakeNextMap()
	return config_filename == "data/next_map.json" || fcopy(config_filename, "data/next_map.json")
