// When validationg freight types, these common items will be ignored 
// This list is also used in ignoring common items for making paperwork 
GLOBAL_LIST_INIT( blacklisted_paperwork_itemtypes, typecacheof( list(
	/obj/item/ship_weapon/ammunition/torpedo/freight,
	/obj/structure/closet
	// /obj/item/storage
) ) )

// List of specifically defined freight types so the objective knows how to handle a specific item  
// If you're planning to deliver multiple different items to the same location, create one freight_type for each item and add these to the same objective 

/datum/freight_type
	// You'll want to use the /datum/freight_type/object type for defining a specific item 
	// This should be an initialized object so prepacked delivery objectives can verify the object is identical and untampered 
	// Some cargo types below will default to reagent/amount/credits validation in check_contents if an item is not provided 
	var/atom/item = null

	// target is an arbitrary number to track how many units have been delivered. 
	// target can be an amount of objects, a count of minerals, or a unit of reagents 
	var/target = 1 

	// tally is an arbitrary number that represents a percent of target 
	var/tally = 0 

	// Set to TRUE to automatically place this item in the ship's warehouse, for simpler transfer objectives 
	// If an item is provided in a prepackaged large wooden crate but the players open it, the players can either repackage or source a replacement to deliver 
	// item is a required field if prepackaged_item is true. 
	// overmap_objective is a required field if prepackaged_item is true. 
	var/send_prepackaged_item = FALSE 
	var/list/prepackaged_items = list()

	// If prepackaged mission critical items are tampered or destroyed, allow the crew to replace these items or transfer them in generic crates
	var/allow_replacements = TRUE 

	// Get the parent objective for this item type 
	var/datum/overmap_objective/cargo/overmap_objective = null
	
	// If mission critical items are prepackaged, includes additional supplies in case the crate is "accidentally" opened 
	// This packaging is not required for objective completion, and _cargo.dm will filter these items from completion checks. 
	// Attempting to replace prepackaging will flag the incoming freight torpedo as trash, and will not complete the objective.
	var/list/additional_prepackaging = list()
	
	var/last_freight_contents_index = null // vv debug 
	var/last_get_amount = null // vv debug 
	
	// Set to TRUE if we want whatever this item and whatever random items it contains 
	// freight_contents_index will pass the item contents in as valid freight 
	var/ignore_inner_contents = FALSE

/datum/freight_type/proc/check_contents( var/obj/container ) 
	// Stations call this proc, the freight_type datum handles the rest 
	// PLEASE do NOT put areas inside freight torps this WILL cause problems! 
	if ( send_prepackaged_item )
		return check_prepackaged_contents( container )
	return FALSE
	
// TODO add handling for stations begrudgingly accepting tampered cargo transfers 
// Due to the nature of objectives rewarding nothing but patrol completion there is no incentive for "bonus points" by leaving cargo untampered, unfortunately 
/datum/freight_type/proc/check_prepackaged_contents( var/obj/container )
	if ( !item ) // Something or someone forgot to define what the crew is delivering 
		return FALSE 

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/atom/a in container.GetAllContents() )
		if( !is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) || ( is_type_in_typecache( item, GLOB.blacklisted_paperwork_itemtypes ) && is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) ) )
			if ( LAZYFIND( prepackaged_items, a ) ) // Is this the item we're looking for? 
				// Add to contents index for more checks 
				index.add_amount( a, 1 )
				
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	message_admins( "final check" )
	message_admins( english_list( itemTargets ) )
	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/proc/get_brief_segment()
	return "nothing"

/datum/freight_type/proc/deliver_package() 
	if ( send_prepackaged_item )
		var/obj/structure/overmap/MO = SSstar_system.find_main_overmap()
		if(MO)
			var/obj/structure/closet/crate/large/freight_objective/C = new /obj/structure/closet/crate/large/freight_objective( src )
			for ( var/i = 0; i < target; i++ )
				// For transfer objectives expecting multiple items of the same type, clones the referenced item 
				var/atom/added_item = add_item_to_crate( C )
				if ( added_item ) 
					prepackaged_items += added_item 
			for ( var/atom/packaging in additional_prepackaging ) 
				C.contents += packaging
			C.overmap_objective = overmap_objective
			C.freight_type = src
			MO.send_supplypod( C, null, TRUE )
			return TRUE 
	else 
		return TRUE 

/datum/freight_type/proc/add_item_to_crate( var/obj/C )
	var/atom/newitem = DuplicateObject( item )
	C.contents += newitem
	return newitem

// Handheld item type objectives 

/datum/freight_type/object 
	target = 1

/datum/freight_type/object/New( var/obj/object, var/number )
	// Object should be initialized
	if ( object ) 
		item = object 

	if ( number )
		target = number

/datum/freight_type/object/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets 

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/atom/a in container.GetAllContents() )
		if( !is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) || ( is_type_in_typecache( item, GLOB.blacklisted_paperwork_itemtypes ) && is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) ) )
			if( istype( a, item.type ) )
				// Add to contents index for more checks 
				index.add_amount( a, 1 )
			
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/object/get_brief_segment() 
	return (target==1?"[item.name]":"[item.name] ([target] items)")

/datum/freight_type/object/credits
	target = 1
	var/credits = 10000

/datum/freight_type/object/credits/New( var/number )
	if ( number )
		credits = number
	
	var/obj/item/holochip/H = new /obj/item/holochip()
	H.credits = credits // Preset value for possible prepackage transfer objectives 
	H.name = "\improper [credits] credit transfer holochip" // Hopefully fixes cargo crate description fubar 
	item = H

/datum/freight_type/object/credits/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets  

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/obj/item/holochip/a in container.GetAllContents() )
		if( !is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) || ( is_type_in_typecache( item, GLOB.blacklisted_paperwork_itemtypes ) && is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) ) )
			if( istype( a, item.type ) || ( length( prepackaged_items ) && recursive_loc_check( a, item.type ) ) )
				// Add to contents index for more checks 
				index.add_amount( a, a.credits )
				
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/object/credits/get_brief_segment() 
	return "[credits] credit" + (target!=1?"s":"")

/datum/freight_type/object/mineral 
	target = 50

/datum/freight_type/object/mineral/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets 

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/obj/item/stack/a in container.GetAllContents() )
		if( !is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) || ( is_type_in_typecache( item, GLOB.blacklisted_paperwork_itemtypes ) && is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) ) )
			if( istype( a, item.type ) || ( length( prepackaged_items ) && recursive_loc_check( a, item.type ) ) )
				// Add to contents index for more checks 
				index.add_amount( a, a.amount )
				
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/object/mineral/get_brief_segment() 
	return "[item.name] ([target] sheet" + (target!=1?"s":"") + ")"

// Reagent type cargo objectives 

/datum/freight_type/reagent 
	var/datum/reagent/reagent = null
	var/list/containers = list( // We're not accepting chemicals in food 
		/obj/item/reagent_containers/spray,
		/obj/item/reagent_containers/glass,
		/obj/item/reagent_containers/chemtank
	)
	target = 30 // Standard volume of a bottle 

/datum/freight_type/reagent/New( var/datum/reagent/medicine, var/amount ) 
	if ( medicine )
		reagent = medicine 

	if ( amount ) 
		target = amount 

/datum/freight_type/reagent/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets 

	if ( istype( src, /datum/freight_type/reagent/blood ) ) // Run the actual blood type check please thank you 
		return FALSE

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()
	
	for ( var/obj/item/reagent_containers/a in container.GetAllContents() )
		if ( is_type_in_list( a, containers ) )
			var/datum/reagents/reagents = a.reagents
			for ( var/datum/reagent/R in reagents.reagent_list )
				if ( istype( R, reagent.type ) )
					// Add to contents index for more checks 
					index.add_amount( a, R.volume, R.type )
	
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/reagent/get_brief_segment() 
	return "[reagent.name ? reagent.name : reagent] ([target] unit" + (target!=1?"s":"") + ")"

/datum/freight_type/reagent/blood 
	reagent = new /datum/reagent/blood()
	var/blood_type = null
	containers = list(
		/obj/item/reagent_containers/blood
	)
	target = 200 // Standard volume of a blood pack 

/datum/freight_type/reagent/blood/New( var/type ) 
	if ( type )
		blood_type = type 

/datum/freight_type/reagent/blood/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets 

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/obj/item/reagent_containers/a in container.GetAllContents() )
		if ( is_type_in_list( a, containers ) )
			var/datum/reagents/reagents = a.reagents
			for ( var/datum/reagent/blood/R in reagents.reagent_list )
				if ( R.data[ "blood_type" ] == blood_type )
					// Add to contents index for more checks 
					index.add_amount( a, R.volume, blood_type )
					
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/reagent/blood/get_brief_segment() 
	return "blood type [blood_type] ([target] unit" + (target!=1?"s":"") + ")"

/datum/freight_type/specimen 
	var/reveal_specimen = FALSE // WIP 
	ignore_inner_contents = TRUE // Don't count equipment attached to mobs as trash 

/datum/freight_type/specimen/New( var/mob/living/simple_animal/object ) 
	if ( object ) 
		item = object 

	var/picked = get_random_food()
	additional_prepackaging += new picked()

/datum/freight_type/specimen/add_item_to_crate( var/obj/C )
	// DuplicateObject on a mob producing runtimes 
	var/mob/living/simple_animal/M = new item.type( C )
	// specimen = M
	M.AIStatus = AI_OFF
	return M

/datum/freight_type/specimen/check_contents( var/obj/container )
	var/list/prepackagedTargets = ..()
	if ( prepackagedTargets ) 
		return prepackagedTargets 
	
	if ( !allow_replacements )
		return FALSE 

	var/datum/freight_contents_index/index = new /datum/freight_contents_index()

	for ( var/atom/a in container.GetAllContents() )
		if( !is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) || ( is_type_in_typecache( item.type, GLOB.blacklisted_paperwork_itemtypes ) && is_type_in_typecache( a, GLOB.blacklisted_paperwork_itemtypes ) ) )
			if( istype( a, item.type ) || ( length( prepackaged_items ) && recursive_loc_check( a, item.type ) ) )
				// Add to contents index for more checks 
				index.add_amount( a, 1 )
	
	var/list/itemTargets = index.get_amount( item.type, target, TRUE )

	// Add wildcard contents from inner object contents found in the loop above. Otherwise check_cargo in the parent cargo objective thinks these inner wildcard contents are trash 
	if ( ignore_inner_contents )
		for ( var/atom/i in itemTargets ) 
			for ( var/atom/a in i.GetAllContents() ) 
				itemTargets += a 

	// Remove additional packaging from trash check 
	if ( additional_prepackaging )
		for ( var/atom/packaging in additional_prepackaging ) 
			itemTargets += packaging 

	last_freight_contents_index = index
	last_get_amount = itemTargets
	return itemTargets

/datum/freight_type/specimen/get_brief_segment() 
	if ( reveal_specimen )
		return (target==1?"[item.name] specimen":"[target] [item.name] specimens")
	else 
		return (target==1?"a secure specimen":"[target] secure specimens")
