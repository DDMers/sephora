/datum/component/storage/concrete/rped/quick_empty(mob/M)
	var/atom/A = parent
	if(!M.canUseStorage() || !A.Adjacent(M) || M.incapacitated())
		return
	if(check_locked(null, M, TRUE))
		return FALSE
	A.add_fingerprint(M)
	var/list/things = contents()
	var/lowest_rating = INFINITY
	for(var/obj/item/B in things)
		if(istype(B, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = B
			if(C.rating < lowest_rating)
				lowest_rating = C.rating
		else if(B.get_part_rating() < lowest_rating)
			lowest_rating = B.get_part_rating()
	for(var/obj/item/B in things)
		if(istype(B, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = B
			if(C.rating > lowest_rating)
				things.Remove(B)
		else if(B.get_part_rating() > lowest_rating)
			things.Remove(B)
	if(lowest_rating == INFINITY)
		to_chat(M, "<span class='notice'>There's no parts to dump out from [parent].</span>")
		return
	to_chat(M, "<span class='notice'>You start dumping out Tier/Cell rating [lowest_rating] parts from [parent].</span>")
	var/turf/T = get_turf(A)
	var/datum/progressbar/progress = new(M, length(things), T)
	while (do_after(M, 10, TRUE, T, FALSE, CALLBACK(src, .proc/mass_remove_from_storage, T, things, progress)))
		stoplag(1)
	qdel(progress)

/datum/component/storage/concrete/bluespace/rped/quick_empty(mob/M)
	var/atom/A = parent
	if(!M.canUseStorage() || !A.Adjacent(M) || M.incapacitated())
		return
	if(check_locked(null, M, TRUE))
		return FALSE
	A.add_fingerprint(M)
	var/list/things = contents()
	var/lowest_rating = INFINITY
	for(var/obj/item/B in things)
		if(istype(B, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = B
			if(C.rating < lowest_rating)
				lowest_rating = C.rating
		else if(B.get_part_rating() < lowest_rating)
			lowest_rating = B.get_part_rating()
	for(var/obj/item/B in things)
		if(istype(B, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = B
			if(C.rating > lowest_rating)
				things.Remove(B)
		else if(B.get_part_rating() > lowest_rating)
			things.Remove(B)
	if(lowest_rating == INFINITY)
		to_chat(M, "<span class='notice'>There's no parts to dump out from [parent].</span>")
		return
	to_chat(M, "<span class='notice'>You start dumping out Tier/Cell rating [lowest_rating] parts from [parent].</span>")
	var/turf/T = get_turf(A)
	var/datum/progressbar/progress = new(M, length(things), T)
	while (do_after(M, 10, TRUE, T, FALSE, CALLBACK(src, .proc/mass_remove_from_storage, T, things, progress)))
		stoplag(1)
	qdel(progress)
