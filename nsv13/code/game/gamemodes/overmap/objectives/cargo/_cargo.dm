
// If you're writing new cargo objectives please perform these test cases:
// Objective approves when supplying all and only items requested
// Objective rejects when supplying items requested and any additional trash
// For objectives with multiple cargo item types or targets greater than 1: objective rejects when supplying only some of items requested
// For objectives that send prepackaged items, and the objective is written to automatically fail on tamper: objective fails on comms console
// For objectives that send prepackaged items: objective approves when supplying items that have been removed from its original cargo crate

/datum/overmap_objective/cargo
	name = "cargo objective"
	// crate_name appears as a crate name when stations return requisition forms to players.
	// crate_name should be named similarly to cargo supply console crate names
	var/crate_name = "Approved Shipment"
	binary = TRUE
	extension_supported = FALSE // Players won't enjoy being handed a cargo job after beating up fleets. Review this if we decide to refactor missions later

	// Variables target and tally are automatically handled by the freight_type datum
	// Please set your target and tally amounts when setting up the freight_type datum
	target = 0
	tally = 0

	var/destination = null // For knowing who wants what by looking at this objective datum

	// On proc pick_station, pick_same_destination attempts to find a station that is already expecting cargo. This avoids situations where players are trekking halfway across the universe to deliver two separate items
	// Set to FALSE if you always want random stations to be picked
	// If you want to ensure your gamemode assigns its destinations correctly with pick_same_destination TRUE and using random_objectives, either choose only objectives with pick_same_destination TRUE, manually set all cargo objectives pick_same_destination to TRUE, or do not use variable random_objectives! When cherrypicking objectives with both pick_same_destination TRUE and FALSE, preorder your cargo missions in list objectives (not random_objectives) by pick_same_destination FALSE first, pick_same_destination TRUE last. This ensures these objectives have applicable stations to pick from. I'm not responsible for destination inconsistency for not following these instructions
	// TLDR station destinations get funky when a gamemode uses random_objectives to store multiple cargo objectives with pick_same_destination set to TRUE and FALSE, due to how random_objectives randomly selects its objectives
	var/pick_same_destination = TRUE

	// Setting send_to_station_pickup_point to TRUE will delay calling deliver_package until the players navigate to the station pickukp point and request the pickup. This is performed through the station trader menu after clicking the DRADIS blip
	// This means the package will not be delievered at roundstart!
	var/send_to_station_pickup_point = FALSE

	var/obj/structure/overmap/pickup_destination = null

	// Cargo objectives handle the station's requisitioned item in a special datum so we can control how to check contents
	var/datum/freight_type/group/freight_type_group = null
	var/datum/freight_type_check/last_freight_type_check = null // admin/coder in-round debugging. In the last shipment, displays all contents that the station approved/rejected for cargo objectives
	var/roundstart_packages_handled = FALSE
	var/delivered_package = FALSE

/datum/overmap_objective/cargo/instance()
	get_target()
	pick_station()
	if ( !roundstart_packages_handled ) // Don't call roundstart setup handling again, even if additional objectives are requested
		roundstart_deliver_package()
		roundstart_packages_handled = TRUE
	update_brief()

/datum/overmap_objective/cargo/proc/get_target()
	if ( freight_type_group )
		target = freight_type_group.get_target()
	else
		message_admins( "BUG: A cargo objective was assigned with no delivery item types set! Automatically marking as completed" )
		brief = "Succeed"
		status = 1

/datum/overmap_objective/cargo/proc/pick_station()
	// Pick a random existing station to give this objective to
	var/list/ntstations = list()
	var/list/ntstations_expecting_cargo = list()
	for ( var/trader in SSstar_system.traders )
		var/datum/trader/T = trader
		if ( T.faction_type == FACTION_ID_NT )
			var/obj/structure/overmap/S = T.current_location

			if ( S?.current_system.name != SSovermap_mode.mode.starting_system ) // No transfer objectives to same-system stations on roundstart
				ntstations += S

				if ( length( S.expecting_cargo ) )
					ntstations_expecting_cargo += S

	var/obj/structure/overmap/S
	if ( pick_same_destination && length( ntstations_expecting_cargo ) )
		S = pick( ntstations_expecting_cargo )
	else
		S = pick( ntstations )

	// Assign this objective directly to the station, so the station can track it
	destination = S
	S.add_objective( src )

/datum/overmap_objective/cargo/proc/roundstart_deliver_package()
	if ( send_to_station_pickup_point )
		pick_station_pickup_point()
		return TRUE

	deliver_package()

/datum/overmap_objective/cargo/proc/deliver_package() // Called when picking up prepackaged crates at station pickup points
	if ( !delivered_package ) // Do not resend prepackaged contents
		if ( !freight_type_group.deliver_package() )
			message_admins( "BUG: A cargo objective failed to deliver a prepackaged item to the ship! Automatically marking the objective as completed." )
			status = 1
		delivered_package = TRUE
		SSovermap_mode.update_reminder(objective=TRUE) // Picking up objective cargo resets the timer

/datum/overmap_objective/cargo/proc/pick_station_pickup_point()
	// Pick a random existing station to give the prepackaged wooden crate to
	// This proc is called in place of deliver_package if send_to_station_pickup_point is TRUE

	var/list/ntstations = list()
	for ( var/trader in SSstar_system.traders )
		var/datum/trader/T = trader
		if ( T.faction_type == FACTION_ID_NT )
			var/obj/structure/overmap/S = T.current_location

			if ( !length( S.expecting_cargo ) ) // No transfer objectives to stations that are also expecting cargo, for now
				ntstations += S

	var/obj/structure/overmap/S = pick( ntstations )

	// Assign this objective directly to the station, so the station can track it
	pickup_destination = S
	S.add_holding_cargo( src )

/datum/overmap_objective/cargo/proc/update_brief()
	if ( freight_type_group )
		// var/list/segments = list()
		// for( var/datum/freight_type/type in freight_types )
		// 	segments += type.get_brief_segment()

		var/obj/structure/overmap/S = destination
		brief = "Complete supply request form #[rand(1000)] by delivering its contents to station [S] in system [S.current_system]"

/datum/overmap_objective/cargo/donation/update_brief()
	if ( freight_type_group )
		// var/list/segments = list()
		// for( var/datum/freight_type/type in freight_types )
		// 	segments += type.get_brief_segment()

		var/obj/structure/overmap/S = destination
		brief = "Complete supply request form #[rand(1000)] by delivering its contents to station [S] in system [S.current_system]"

/datum/overmap_objective/cargo/transfer/update_brief()
	if ( freight_type_group )
		// var/list/segments = list()
		// for( var/datum/freight_type/type in freight_types )
		// 	segments += type.get_brief_segment()

		var/obj/structure/overmap/S = destination
		brief = "Complete supply request form #[rand(1000)] by delivering its contents to station [S] in system [S.current_system]"

/datum/freight_type_check
	// At the start of a check, the raw container and its contents go here
	var/obj/container = null
	var/list/untracked_contents = list()

	// At the end of a check, untracked contents are filtered into approved contents and a global status is set in this datum
	var/list/approved_contents = list()
	var/group_status = TRUE

/datum/overmap_objective/cargo/proc/check_cargo( var/obj/shipment )
	if ( freight_type_group )
		// var/all_accounted_for = TRUE

		// Cargo objectives with multiple freight types need to be checked individually,
		// then the entire container needs checked for non-objective related trash.
		// Individual freight_type datums cannot check for non-objective trash because they do not have the full context of other freight_types in the same list

		var/list/allContents = list()
		for ( var/atom/a in shipment.GetAllContents() )
			if( !is_type_in_typecache( a.type, GLOB.blacklisted_paperwork_itemtypes ) )
				allContents += a

		last_freight_type_check = new()
		last_freight_type_check.container = shipment
		last_freight_type_check.untracked_contents = allContents
		freight_type_group.check_contents( last_freight_type_check )

		// for( var/datum/freight_type/freight_type in freight_types )
		// 	var/list/item_results = freight_type.check_contents( shipment )
		// 	if ( item_results )
		// 		for ( var/atom/i in item_results )
		// 			last_check_cargo_items_accepted += i
		// 			allContents -= i
		// 	else
		// 		// There are missing items in this freight type, we're not going to bother checking the rest
		// 		all_accounted_for = FALSE
		// 		break

		// If there are additional trash items that were not requested, we won't mark this shipment as an objective completion
		// This prevents a scenario where the crew piles all their objective related cargo into a freight torpedo, completes 2 out of 3 applicable objectives, and can't get the incomplete shipment back for objective #3
		if ( last_freight_type_check.group_status && !length( last_freight_type_check.untracked_contents ) )
			tally = target // Target is set when the freight_type is assigned
			status = 1
			return TRUE
