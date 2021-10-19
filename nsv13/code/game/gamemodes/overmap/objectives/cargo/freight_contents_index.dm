
// Stores freight torpedo contents and its prepackaged status data 

/datum/freight_contents_index 
	// Keep a total count of the actual type we're checking 
	var/list/atoms_amount = list()
	// Return these items that contain the amount in the list above 
	var/list/atoms_list = list()

/datum/freight_contents_index/proc/add_amount( var/atom/a, var/amount, var/type )
	if ( !type ) 
		if ( a?.type )
			type = a.type 

	if ( !atoms_amount[ type ] ) 
		atoms_amount[ type ] = 0
		atoms_list[ type ] = list()
	atoms_amount[ type ] += amount 
	atoms_list[ type ] += a 

/datum/freight_contents_index/proc/get_all() 
	message_admins( "freight_contents_index get_all" )
	// Compile a list of all items from atoms_list types and their lists 
	var/list/allAtoms = list() 
	for ( var/types in atoms_list ) 
		message_admins( types )
		for ( var/atom/a in atoms_list[ types ] ) 
			message_admins( a )
			allAtoms += a 
	
	message_admins( "freight_contents_index final_check" )
	message_admins( english_list( allAtoms ) )
	if ( length( allAtoms ) )
		return allAtoms

/datum/freight_contents_index/proc/get_amount( var/type, var/amount, var/allow_subtypes ) 
	if ( atoms_amount[ type ] && atoms_amount[ type ] >= amount )
		return atoms_list[ type ]

	if ( allow_subtypes && ispath( type ) )
		// Object subtype leniency 
		// If a parent type of an object is requested like a plain cake or a base fighter_component object, allow its subtypes to be submitted as well 
		for ( var/subtype in subtypesof( type ) )
			if ( atoms_amount[ subtype ] && atoms_amount[ subtype ] >= amount )
				return atoms_list[ subtype ]

/datum/freight_contents_index/proc/get_all_if_successful( var/type, var/amount, var/allow_subtypes ) 
	message_admins( "freight_contents_index get_all_if_successful" )
	// Runs get_amount by default. If successful, marks all filtered contents in atoms_list as not trash for objectives with ignore_inner_contents 
	var/list/valid_atoms = get_amount( type, amount, allow_subtypes ) 
	message_admins( "freight_contents_index valid_atoms [ english_list( valid_atoms ) ]" )
	if ( valid_atoms && length( valid_atoms ) )
		return get_all()
