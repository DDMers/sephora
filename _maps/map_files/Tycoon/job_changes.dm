MAP_REMOVE_JOB(virologist) //This job is being phased out of NSV

/datum/job/pilot/New()
	..()
	MAP_JOB_CHECK
	total_positions = 7
	spawn_positions = 7

#undef JOB_MODIFICATION_MAP_NAME
