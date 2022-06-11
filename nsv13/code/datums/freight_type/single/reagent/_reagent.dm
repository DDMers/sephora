// Reagent type cargo objectives

/datum/freight_type/single/reagent
	var/datum/reagent/reagent_type = null
	var/list/containers = list(
		/obj/item/reagent_containers
	)
	target = 30 // Standard volume of a bottle

/datum/freight_type/single/reagent/New( var/datum/reagent/medicine, target, item_name )
	message_admins( "/datum/freight_type/single/reagent/New: [src] ([src.type]) [ADMIN_VV(src)] - [item_type], [target], [item_name], [medicine] -" )
	..()
	if ( !reagent_type )
		if ( medicine )
			reagent_type = medicine

/datum/freight_type/single/reagent/set_item_name()
	if ( item_name ) // Don't overwrite it
		return TRUE

	if ( reagent_type )
		item_name = initial( reagent_type.name )
		return TRUE

/datum/freight_type/single/reagent/get_item_targets( var/datum/freight_type_check/freight_type_check )
	var/datum/freight_contents_index/index = new /datum/freight_contents_index()
	freight_contents_index = index

	for ( var/obj/item/reagent_containers/a in freight_type_check.container.GetAllContents() )
		if ( is_type_in_list( a, containers ) )
			var/datum/reagents/reagents = a.reagents
			for ( var/datum/reagent/R in reagents.reagent_list )
				if ( istype( R, reagent_type ) )
					if ( in_required_loc_or_is_required_loc( a ) )
						// Add to contents index for more checks
						index.add_amount( a, R.volume, R.type )

	return index.get_amount( reagent_type, target, TRUE )

/datum/freight_type/single/reagent/get_brief_segment()
	return "[item_name ? item_name : reagent_type] ([target] unit\s)"

/datum/freight_type/single/reagent/get_supply_request_form_segment()
	return "<span>Permissible reagent containers: most reagent containers</span><br>"
