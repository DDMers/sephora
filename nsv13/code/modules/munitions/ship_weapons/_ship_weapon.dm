/**
 *	Ship-to-ship weapons
 *	To add a weapon type:
 *	Define a FIRE_MODE in nsv13/_DEFINES/overmap.dm
 *	Up the size of weapon_types and weapons in nsv13/code/modules/overmap/weapons.dm
 *	Add weapon specifics as a datum in nsv13/code/datums/weapon_types.dm
 *	Add a new datum of your type to weapon_types in nsv13/code/modules/overmap/overmap.dm Initialize()
 *	Subclass this
 *	Make firing_mode in the subclass equal to that define
 *	Set weapon_type in the subclass to a new datum of the kind you just created
 *	Define an ammo_type or magazine_type so you can load the weapon
 */
/obj/machinery/ship_weapon //CREDIT TO CM FOR THE SPRITES!
	name = "A ship weapon"
	desc = "Don't use this, use the subtypes"
	icon = 'nsv13/icons/obj/railgun.dmi'
	icon_state = "OBC"
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER

	var/obj/structure/overmap/linked = null
	var/obj/machinery/computer/ship/munitions_computer/linked_computer
	var/obj/weapon_overlay/overlay = null
	var/list/icon_state_list

	// Icons, sounds, and timing for the states
	var/load_sound = 'nsv13/sound/effects/ship/mac_load.ogg'
	var/mag_load_sound = 'sound/weapons/autoguninsert.ogg'
	var/load_delay = 20

	var/unload_sound = 'nsv13/sound/effects/ship/freespace2/crane_short.ogg'
	var/mag_unload_sound = 'sound/weapons/autoguninsert.ogg'
	var/unload_delay = 10

	var/feeding_sound = 'nsv13/sound/effects/ship/freespace2/crane_short.ogg'
	var/fed_sound = 'nsv13/sound/effects/ship/reload.ogg'
	var/feed_delay = 20

	var/chamber_sound = 'nsv13/sound/weapons/railgun/ready.ogg'
	var/chamber_delay_rapid = 2
	var/chamber_delay = 10

	var/firing_sound = 'nsv13/sound/effects/ship/tri_mount_fire.ogg'
	var/fire_animation_length = 5
	var/fire_mode

	var/malfunction_sound = 'sound/effects/alert.ogg'


	//Various traits that probably won't change
	var/maintainable = TRUE //Does the weapon require maintenance?
	var/bang = TRUE //Is firing loud?
	var/bang_range = 8
	var/broadside = FALSE //Does the weapon only fire to the sides?
	var/auto_load = FALSE //Does the weapon feed and chamber the round once we load it?
	var/semi_auto = FALSE //Does the weapon re-chamber for us after firing?

	var/ammo_type = null
	var/magazine_type = null
	var/max_ammo = 1

	var/datum/ship_weapon/weapon_type = null

	// Things that change while we're operating
	var/maint_req = 0 //Number of times a weapon can fire until a maintenance cycle is required. This will countdown to 0.
	var/malfunction = FALSE
	var/maint_state = MSTATE_CLOSED
	var/safety = TRUE //Can only fire when safeties are off
	var/loading = FALSE
	var/state = STATE_NOTLOADED

	var/obj/item/ammo_box/magazine/magazine //Magazine if we have one
	var/obj/chambered //Chambered round if we have one. Extrapolate ammo type from this
	var/list/ammo = list() //All loaded ammo
	//energy weapon vars used to be here, they aren't anymore

/**
 * Constructor for /obj/machinery/ship_weapon
 * Attempts to link the weapon to an overmap ship.
 * If the weapon requires maintenance, generates initial maintenance countdown.
 * Caches icon state list for sanity checking when updating icons.
 */
/obj/machinery/ship_weapon/Initialize(mapload)
	. = ..()
	PostInitialize()
	addtimer(CALLBACK(src, PROC_REF(get_ship)), 15 SECONDS) //This takes a minute to load...

/**
*
*	Late initialize'd these weapons as they're dependant on areas + overmaps being initialized first. This way, they're initialized after everything else in the game.
*
*/

/obj/machinery/ship_weapon/proc/PostInitialize()
	if(maintainable)
		maint_req = rand(20,25) //Setting initial number of cycles until maintenance is required
		create_reagents(50)
	icon_state_list = icon_states(icon)


/**
 * Destructor for /obj/machinery/ship_weapon
 * Try to unlink from a munitions computer, so it can re-link to other things
 */
/obj/machinery/ship_weapon/Destroy(force=FALSE)
	var/obj/item/circuitboard/C = circuit
	if(C)
		component_parts?.Remove(C)
		circuit = null
		if(force)
			qdel(C, force)
		else
			C.forceMove(loc)
	if(component_parts && component_parts.len)
		for(var/obj/P in component_parts)
			component_parts.Remove(P)
			if(force)
				qdel(P, force)
			else
				P.forceMove(loc)
	. = ..()
	if(linked_computer)
		linked_computer.SW = null

/**
 * Tries to link the ship to an overmap by finding the overmap linked it the area we are in.
 */
/obj/machinery/ship_weapon/proc/get_ship(error_log=TRUE)
	linked = get_overmap()
	if(linked)
		set_position(linked)
	else
		message_admins("[z] not linked to an overmap - [src] will not be linked.")

/**
 * Adds the weapon to the overmap ship's list of weapons of this type
 */
/obj/machinery/ship_weapon/proc/set_position(obj/structure/overmap/OM) //Use this to tell your ship what weapon category this belongs in
	OM.add_weapon(src)

/**
 * If we're not already linked to an overmap ship, try again.
 * If we can accept it as ammunition, try to load it.
 * If we're in maintenance and it holds reagents, try to use it as lubricant.
 */
/obj/machinery/ship_weapon/attackby(obj/item/I, mob/user)
	if(!linked)
		get_ship()
	if(islist(ammo_type))
		for(var/at in ammo_type)
			if(istype(I, at))
				load(I, user)
				return TRUE

	if(ammo_type && istype(I, ammo_type))
		load(I, user)
		return TRUE
	else if(magazine_type && istype(I, magazine_type))
		load_magazine(I, user)
		return TRUE
	else if(istype(I, /obj/item/reagent_containers))
		oil(I, user)
		return TRUE
	return ..()

/**
 * Store ID in multitool buffer for linking to munitions consoles
 */
/obj/machinery/ship_weapon/multitool_act(mob/living/user, obj/item/I)
	if(!multitool_check_buffer(user, I))
		return
	var/obj/item/multitool/P = I
	P.buffer = src
	to_chat(user, "<span class='notice'>-% Successfully stored [REF(P.buffer)] [P.buffer.name] in buffer %-</span>")
	return TRUE

/**
 * Unload magazine or just-loaded rounds.
 */
/obj/machinery/ship_weapon/attack_hand(mob/user)
	. = ..()
	if(magazine)
		unload_magazine(user)
	else if(state == STATE_LOADED) //Only if we just put it in, if it's in the chamber they need to use the computer
		unload()

/**
 * If we can accept it as ammo, try to load it.
 */
/obj/machinery/ship_weapon/MouseDrop_T(obj/item/A, mob/user)
	. = ..()
	if(!isliving(user))
		return FALSE
	if(islist(ammo_type))
		for(var/at in ammo_type)
			if(istype(A, at))
				load(A, user)
				return TRUE
	if(ammo_type && istype(A, ammo_type))
		load(A, user)

/**
 * Transitions from STATE_NOTLOADED to STATE_LOADED.
 *
 * Try to load a single round (obj/A).
 * Returns true if loaded successfully, false otherwise.
 */
/obj/machinery/ship_weapon/proc/load(obj/A, mob/user)
	set waitfor = FALSE
	if(length(ammo) < max_ammo) //Room for one more?
		if(!loading) //Not already loading a round?
			if(user)
				to_chat(user, "<span class='notice'>You start to load [A] into [src]...</span>")
			loading = TRUE
			if(!user || do_after(user, load_delay, target = src))
				if(!isturf(A.loc) && !ismob(A.loc)) //Fix double-loading torpedos
					if(user)
						loading = FALSE
						to_chat(user, "<span class='warning'>The ammunition has to be next to the weapon!</span>")
					return FALSE
				loading = FALSE
				A.forceMove(src)
				ammo += A
				if(load_sound)
					playsound(src, load_sound, 100, 1)
				state = STATE_LOADED
				if(user)
					to_chat(user, "<span class='notice'>You load [A] into [src].</span>")
				if(auto_load) //If we're automatic, get ready to fire
					feed()
					chamber()
				loading = FALSE
				return TRUE
			loading = FALSE
		else if(user)
			to_chat(user, "<span class='notice'>You're already loading a round into [src]!.</span>")
	else if(user)
		to_chat(user, "<span class='warning'>[src] is already fully loaded!</span>")

	return FALSE

/**
*Get the ammo / max ammo values for tactical consoles.

*/
/obj/machinery/ship_weapon/proc/get_max_ammo()
	return max_ammo

/obj/machinery/ship_weapon/proc/get_ammo()
	return length(ammo)

/**
 * Transitions from STATE_NOTLOADED to STATE_LOADED.
 *
 * Try to load a magazine (obj/A).
 * Returns true if loaded successfully, false otherwise.
 */
/obj/machinery/ship_weapon/proc/load_magazine(obj/A, mob/user)
	if(loading)
		to_chat(user, "<span class='warning'>You can't do that right now.</span>")
		return FALSE
	if(magazine_type && istype(A, magazine_type))
		to_chat(user, "<span class='notice'>You start to load [A] into [src].</span>")
		loading = TRUE
		if(do_after(user, load_delay, target = src))
			if ( !user_has_payload( A, user ) )
				loading = FALSE
				return FALSE
			if(mag_load_sound)
				playsound(src, mag_load_sound, 100, 1)

			if(magazine) //If one's already loaded, swap it out
				user.put_in_hands(magazine)
				magazine = null

			A.forceMove(src)
			magazine = A
			ammo = magazine.stored_ammo //Lets us handle magazines and single rounds the same way
			state = STATE_LOADED
			to_chat(user, "<span class='notice'>You load [A] into [src].</span>")

			if(auto_load) //If we're automatic, get ready to fire
				feed()
				chamber()
			loading = FALSE
			return TRUE
		loading = FALSE
	else
		to_chat(user, "<span class='warning'>You can't load [A] into [src]!</span>")

	return FALSE

/obj/machinery/ship_weapon/proc/user_has_payload(obj/item/A, mob/user) // Searches humans and borgs for gunpowder before depositing
	if ( !user )
		return FALSE

	// Prove you're not human
	if ( istype( user, /mob/living/silicon/robot ) )
		// Give me your hands
		var/obj/item/borg/apparatus/munitions/hands = locate( /obj/item/borg/apparatus/munitions ) in user.contents
		if ( !hands?.stored )
			return FALSE

	return TRUE

/**
 * If we're not magazine-fed, eject round(s) from the weapon.
 * Transitions to STATE_NOTLOADED from higher states.
 */
/obj/machinery/ship_weapon/proc/unload()
	set waitfor = FALSE
	if((state >= STATE_LOADED) && !magazine)
		if(state >= STATE_FED) //Animate properly and make sure we clear any chambered rounds
			unfeed()

		if(unload_sound)
			playsound(src, unload_sound, 100, 1)
		sleep(unload_delay)

		if(ammo[1])
			var/atom/movable/AM = ammo[1]
			AM.forceMove(get_turf(src))
			ammo -= AM
		state = STATE_NOTLOADED
		icon_state = initial(icon_state)

		//If we have more ammo, spit those out too
		if(length(ammo))
			for(var/atom/movable/AM as() in ammo)
				AM.forceMove(get_turf(src))
			ammo.len = 0
	//end if((state >= STATE_LOADED) && !magazine)

/**
 * If we are magazine-fed, unload the magazine.
 * Transitions to STATE_NOTLOADED from higher states.
 */
/obj/machinery/ship_weapon/proc/unload_magazine(mob/user)
	if((state >= STATE_LOADED) && magazine)
		to_chat(user, "<span class='notice'>You start to unload [magazine] from [src].</span>")
		if(state >= STATE_FED)
			unfeed() //Animate properly and make sure we clear any chambered rounds
		if(do_after(user, unload_delay, target = src))
			user.put_in_hands(magazine)
			magazine = null
			if(mag_unload_sound)
				playsound(src, mag_unload_sound, 100, 1)
			state = STATE_NOTLOADED

/**
 * Once the user has insert a round into the gun, we can start moving through the cycle of firing.
 * Primarily an animation and sound effect step - closes the breech/tray.
 * Transitions from STATE_LOADED to STATE_FED
 */
/obj/machinery/ship_weapon/proc/feed()
	if(state == STATE_LOADED)
		state = STATE_FEEDING
		flick("[initial(icon_state)]_loading",src)
		if(feeding_sound)
			playsound(src, feeding_sound, 100, 1)
		sleep(feed_delay)
		if("[initial(icon_state)]_loaded" in icon_state_list)
			icon_state = "[initial(icon_state)]_loaded"
		if(fed_sound)
			playsound(src, fed_sound, 100, 1)
		state = STATE_FED
/**
 * Gets ammunition ready to take out.
 * Primarily an animation and sound effect step - opens the breech/tray.
 * Transitions to STATE_LOADED from higher states.
 */
/obj/machinery/ship_weapon/proc/unfeed()
	if(state >= STATE_FED && length(ammo))
		if(state == STATE_CHAMBERED) //If chambered, unchamber first
			unchamber()
		flick("[initial(icon_state)]_unloading",src)
		state = STATE_LOADED

//Toggle the safety. Mostly used to

/obj/machinery/ship_weapon/proc/toggle_safety()
	safety = !safety
	update()

/obj/machinery/ship_weapon/proc/update()
	if(weapon_type) // Who would've thought creating a weapon with no weapon_type would break everything!
		if(!safety && chambered)
			weapon_type.weapons["loaded"] |= src //OR to avoid duplicating refs
		else
			weapon_type.weapons["loaded"] -= src

/obj/machinery/ship_weapon/proc/lazyload()
	if(magazine_type)
		magazine = new magazine_type(src)
		ammo = magazine.stored_ammo //Lets us handle magazines and single rounds the same way
	else
		var/ammoType = (islist(ammo_type)) ? ammo_type[1] : ammo_type
		for(var/I = 0, I < max_ammo, I++)
			var/atom/BB = new ammoType(src)
			ammo += BB
	safety = FALSE
	chambered = ammo[1]
	if(chamber_sound) //This got super annoying on gauss guns, so i've made it only work for the initial "ready to fire" warning.
		playsound(src, chamber_sound, 100, 1)
	state = STATE_CHAMBERED
	maint_req = 20
	malfunction = FALSE
	update()

/**
 * Chambers the next round in ammo so that we're ready to fire.
 * Rapidfire is used for when you want to reload rapidly. This is done for the railgun autoloader so that you can "volley" shots quickly.
 * Transitions from STATE_FED to STATE_CHAMBERED.
 */
/obj/machinery/ship_weapon/proc/chamber(rapidfire = FALSE)
	if((state == STATE_FED) && length(ammo))
		state = STATE_CHAMBERING
		flick("[initial(icon_state)]_chambering",src)
		if(rapidfire)
			sleep(chamber_delay_rapid)
		else
			sleep(chamber_delay)
		if("[initial(icon_state)]_chambered" in icon_state_list)
			icon_state = "[initial(icon_state)]_chambered"
		chambered = ammo[1]
		if(chamber_sound && !rapidfire) //This got super annoying on gauss guns, so i've made it only work for the initial "ready to fire" warning.
			playsound(src, chamber_sound, 100, 1)
		state = STATE_CHAMBERED
	update()

/**
 * Unchambers a chambered round.
 * Very important, sets chambered to null so we can't shoot things that aren't inside the weapon anymore.
 * Transitions from STATE_CHAMBERED to STATE_FED.
 */
/obj/machinery/ship_weapon/proc/unchamber()
	if(state == STATE_CHAMBERED)
		state = STATE_CHAMBERING // Technically unchambering, but it accomplishes the same purpose without needless defines
		flick("[initial(icon_state)]_chambering",src)
		sleep(chamber_delay)
		if("[initial(icon_state)]_loaded" in icon_state_list)
			icon_state = "[initial(icon_state)]_loaded"
		if(fed_sound)
			playsound(src, fed_sound, 100, 1)
		chambered = null
		state = STATE_FED

/**
 * Checks if the weapon is able to fire the given number of shots.
 * Need to have a round in the chamber, not already be shooting, not be in maintenance, not be malfunctioning, and have enough shots in our ammo pool. Also checks if the direction of a broadside gun is correct.
 */
/obj/machinery/ship_weapon/proc/can_fire(atom/target, shots = weapon_type.burst_size)
	if((state < STATE_CHAMBERED) || !chambered) //Do we have a round ready to fire
		return FALSE
	if (maint_state > MSTATE_UNSCREWED) //Are we in maintenance?
		return FALSE //Checks for states after UNSCREWED so we can add buttons under the panel
	if(state >= STATE_FIRING) //Are we in the process of shooting already?
		return FALSE
	if(maintainable && malfunction) //Do we need maintenance?
		return FALSE
	if(safety) // Is the safety on?
		return FALSE
	if(length(ammo) < shots) //Do we have enough ammo?
		return FALSE
	if(broadside && target)
		return dir == angle2dir_ship(overmap_angle(linked, target) - linked.angle) ? TRUE : FALSE
	else
		return TRUE

/**
 * Fires the weapon a given number of times at a given target.
 * Verifies that we are ready to fire this many shots, then does that.
 * Transitions from STATE_CHAMBERED to STATE_FIRING, then transitions
 *   from STATE_FIRING to STATE_NOTLOADED if no more ammo,
 *   from STATE_FED if not semi-auto and have ammo
 *   from STATE_CHAMBERED if semi-auto and have ammo.
 * Returns projectile if successfully fired, FALSE otherwise.
 */
/obj/machinery/ship_weapon/proc/fire(atom/target, shots = weapon_type.burst_size, manual = TRUE)
	//Fun fact: set [waitfor, etc] is special, and is inherited by child procs even if they do not call parent!
	set waitfor = FALSE //As to not hold up any feedback messages.
	if(can_fire(target, shots))
		if(manual)
			linked.last_fired = overlay

		for(var/i = 0, i < shots, i++)
			state = STATE_FIRING
			do_animation()
			overmap_fire(target)

			ammo -= chambered
			local_fire()
			if(!istype(chambered, /obj/item/ship_weapon/ammunition/torpedo/freight)) // Don't qdel freight torpedoes, these are being moved to the stations for additional checks
				qdel(chambered)
			chambered = null

			if(length(ammo))
				state = STATE_FED
			else
				state = STATE_NOTLOADED

			if(semi_auto)
				chamber(rapidfire = TRUE)
			after_fire()
			. = TRUE //waitfor = FALSE early return returns the current . value at the time of sleeping, so this makes it return the correct value for burst fire weapons.
			if(shots > 1)
				sleep(weapon_type.burst_fire_delay)
		return TRUE
	return FALSE

/obj/machinery/ship_weapon/energy/fire(atom/target, shots = weapon_type.burst_size, manual = TRUE)
	if(can_fire(target, shots))
		if(manual)
			linked.last_fired = overlay
		for(var/i = 0, i < shots, i++)
			do_animation()
			local_fire()
			overmap_fire(target)
			charge -= charge_per_shot
			heat += heat_per_shot
			after_fire()
			. = TRUE
			if(shots > 1)
				sleep(weapon_type.burst_fire_delay)
		return TRUE
	return FALSE

/**
 * Handles firing animations and sounds around the mapped weapon
 */
/obj/machinery/ship_weapon/proc/local_fire()
	if(firing_sound)
		playsound(src, firing_sound, 100, 1)
	if(bang)
		for(var/mob/living/M in get_hearers_in_view(bang_range, src)) //Burst unprotected eardrums
			if(M.stat != DEAD && M.get_ear_protection() < 1) //checks for protection - why was this not here before???
				M.soundbang_act(1,200,10,15)

/**
 * Handles firing animations and sounds on the overmap.
 */
/obj/machinery/ship_weapon/proc/overmap_fire(atom/target)

	if(weapon_type?.overmap_firing_sounds)
		overmap_sound()

	if(overlay)
		overlay.do_animation()
	if( weapon_type )
		animate_projectile(target)

/obj/machinery/ship_weapon/proc/overmap_sound()
	var/sound/chosen = pick(weapon_type.overmap_firing_sounds)
	linked.relay_to_nearby(chosen)

/**
 * Animates an overmap projectile matching whatever we're shooting.
 */
/obj/machinery/ship_weapon/proc/animate_projectile(atom/target)
	return linked.fire_projectile(weapon_type.default_projectile_type, target, lateral=weapon_type.lateral)

/**
 * Updates maintenance counter after firing if applicable.
 */
/obj/machinery/ship_weapon/proc/after_fire()
	//Count down towards maintenance
	if(maintainable)
		if(maint_req > 0)
			maint_req --
		else
			weapon_malfunction()
	update()

/**
 * Handles firing animation for the mapped weapon.
 */
/obj/machinery/ship_weapon/proc/do_animation()
	set waitfor = FALSE
	flick("[initial(icon_state)]_firing",src)
	sleep(fire_animation_length)
	flick("[initial(icon_state)]_unloading",src)
	sleep(fire_animation_length)
	icon_state = initial(icon_state)
