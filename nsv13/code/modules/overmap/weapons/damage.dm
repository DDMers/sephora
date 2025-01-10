/**

Damage behaviour for overmap ships

Seen here:
Superstructure crit
Repairs
Bullet reactions

*/

/**
 * Shakes the view of every mob within this overmap that has a client and is not protected by dampeners.
 */
/obj/structure/overmap/proc/shake_everyone(severity)
	for(var/mob/M in mobs_in_ship)
		if(M.client)
			shake_with_inertia(M, severity, 1)

/obj/structure/overmap/bullet_act(obj/item/projectile/P)
	if(istype(P, /obj/item/projectile/beam/overmap/aiming_beam))
		return
	if(shields)
		var/shield_result = shields.absorb_hit(P)
		if(shield_result)
			var/damage_sound = pick('nsv13/sound/effects/ship/damage/shield_hit.ogg', 'nsv13/sound/effects/ship/damage/shield_hit2.ogg')
			if(!impact_sound_cooldown)
				new /obj/effect/temp_visual/overmap_shield_hit(src, src)
				relay(damage_sound)
				if(P.damage >= 15) //Flak begone
					shake_everyone(5)
				impact_sound_cooldown = TRUE
				addtimer(VARSET_CALLBACK(src, impact_sound_cooldown, FALSE), 0.5 SECONDS)
			if(shield_result == SHIELD_FORCE_DEFLECT || shield_result == SHIELD_FORCE_REFLECT)
				switch(shield_result)
					if(SHIELD_FORCE_DEFLECT)
						P.setAngle((P.Angle + rand(25, 50) + (prob(50) ? 0 : 285)) % 360)
					if(SHIELD_FORCE_REFLECT)
						P.setAngle((P.Angle + rand(160, 200)) % 360)
					else

				P.faction = null //We go off the rails.
				P.homing_target = null
				P.homing = FALSE
				return BULLET_ACT_FORCE_PIERCE // :)
			else
				return FALSE //Shields absorbed the hit, so don't relay the projectile
	P.spec_overmap_hit(src)
	var/relayed_type = P.relay_projectile_type ? P.relay_projectile_type : P.type
	relay_damage(relayed_type)
	if(!use_armour_quadrants)
		return ..()
	else
		playsound(src, P.hitsound, 50, 1)
		visible_message("<span class='danger'>[src] is hit by \a [P]!</span>", null, null, COMBAT_MESSAGE_RANGE)
		if(!QDELETED(src)) //Bullet on_hit effect might have already destroyed this object
			//var/datum/vector2d/point_of_collision = src.physics2d?.collider2d.get_collision_point(P.physics2d?.collider2d)//Get the collision point, see if the armour quadrants need to absorb this hit.
			take_quadrant_hit(run_obj_armor(P.damage, P.damage_type, P.flag, null, P.armour_penetration), quadrant_impact(P)) //This looks horrible, but trust me, it isn't! Probably!. Armour_quadrant.dm for more info

/**
 * Used to relay a projectile impacting an overmap onto an overmap's interior zlevels.
 * * proj_type = The type of the projectile to create.
 */
/obj/structure/overmap/proc/relay_damage(proj_type)
	if(!length(occupying_levels))
		return
	var/datum/space_level/SL = pick(occupying_levels)
	var/theZ = SL.z_value
	var/startside = pick(GLOB.cardinals)
	var/turf/pickedstart = spaceDebrisStartLoc(startside, theZ)
	var/turf/pickedgoal = locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), theZ)
	var/obj/item/projectile/proj = new proj_type(pickedstart)
	proj.starting = pickedstart
	proj.firer = null
	proj.def_zone = "chest"
	proj.original = pickedgoal
	spawn()
		proj.fire(get_angle(pickedstart,pickedgoal))
		proj.set_pixel_speed(4)

/obj/structure/overmap/small_craft/relay_damage(proj_type)
	return

/obj/structure/overmap/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, bypasses_shields = FALSE, nsv_damagesound = TRUE)
	var/blocked = FALSE
	var/damage_sound = pick(GLOB.overmap_impact_sounds)
	if(!bypasses_shields && shields && shields.absorb_hit(damage_amount))
		blocked = TRUE
		damage_sound = pick('nsv13/sound/effects/ship/damage/shield_hit.ogg', 'nsv13/sound/effects/ship/damage/shield_hit2.ogg')
		if(!impact_sound_cooldown)
			add_overlay(new /obj/effect/temp_visual/overmap_shield_hit(get_turf(src), src))
	if(nsv_damagesound && !impact_sound_cooldown && damage_sound)
		relay(damage_sound)
		if(damage_amount >= 15) //Flak begone
			shake_everyone(5)
		impact_sound_cooldown = TRUE
		addtimer(VARSET_CALLBACK(src, impact_sound_cooldown, FALSE), 1 SECONDS)
	if(blocked)
		return FALSE
	if(CHECK_BITFIELD(overmap_deletion_traits, DAMAGE_STARTS_COUNTDOWN) && !(CHECK_BITFIELD(overmap_deletion_traits, DAMAGE_DELETES_UNOCCUPIED) && !has_occupants())) //Code for handling "superstructure crit" countdown
		if(obj_integrity <= damage_amount || structure_crit) //Superstructure crit! They would explode otherwise, unable to withstand the hit.
			SEND_SIGNAL(src, COMSIG_ATOM_DAMAGE_ACT, damage_amount) //Sending the comsig here because we do not call parent in this case.
			obj_integrity = 10 //Automatically set them to 10 HP, so that the hit isn't totally ignored. Say if we have a nuke dealing 1800 DMG (the ship's full health) this stops them from not taking damage from it, as it's more DMG than we can handle.
			handle_crit(damage_amount)
			return FALSE
	update_icon()
	return ..()

/**
 * Checks if the overmap contains any `/living`, non-animal, mobs.
 * Also considers Fighters occupants if the proper flag is enabled on src.
 * * Returns TRUE / FALSE.
 */
/obj/structure/overmap/proc/has_occupants()
	if(length(mobs_in_ship))
		for(var/mob/M in mobs_in_ship) // Hopefully we don't have to do this super often but I didn't want one list of people who have to hear noises and announcements and another list of people who matter for this
			if(istype(M, /mob/living) && !istype(M, /mob/living/simple_animal))
				return TRUE
	if(length(overmaps_in_ship))
		if(CHECK_BITFIELD(overmap_deletion_traits, FIGHTERS_ARE_OCCUPANTS))
			return TRUE
		for(var/obj/structure/overmap/OM as() in overmaps_in_ship)
			if(length(OM.mobs_in_ship))
				return TRUE
	return FALSE

/obj/structure/overmap/proc/is_player_ship() //Should this ship be considered a player ship? This doesnt count fighters because they need to actually die.
	if(length(occupying_levels) || role == MAIN_OVERMAP)
		return TRUE
	return FALSE

/**
 * A proc to allow ships to enter superstructure crit, this means the player ship can't die, but its insides can get torn to shreds.
 * * When not in critical, triggers the structure crit state for a ship.
 * * Additionally, causes internal damage when called, proportional to the `damage_amount` passed.
 */
/obj/structure/overmap/proc/handle_crit(damage_amount)
	if(!structure_crit)
		structure_crit = TRUE
		structure_crit_init = world.time
		structure_crit_alert = 0 //RESET
	if(explosion_cooldown)
		return
	explosion_cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, explosion_cooldown, FALSE), 5 SECONDS)
	var/area/target = null
	if(role == MAIN_OVERMAP)
		var/name = pick(GLOB.teleportlocs) //Time to kill everyone
		target = GLOB.teleportlocs[name]
	else if(length(linked_areas))
		target = pick(linked_areas)

	if(target)
		var/turf/T = pick(get_area_turfs(target))
		new /obj/effect/temp_visual/explosion_telegraph(T, damage_amount)

///Handles the announcements for structure critical.
/obj/structure/overmap/proc/handle_critical_failure_part_1()
	var/ss_crit_timer = world.time - structure_crit_init
	switch(ss_crit_timer)
		if(0 to 12 SECONDS)
			if(structure_crit_alert == 0)
				priority_announce("Warning. Ship superstructure integrity critical. Total structural failure will occur in T - 15 minutes.  The ship will reach an irreparable state in T - 10 minutes.","Automated announcement ([src])", "null")
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_15.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
				structure_crit_alert ++
		if(12 SECONDS to 5 MINUTES)
			if(structure_crit_alert == 1)
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_alarm_15.ogg', message=null, loop=TRUE, channel=CHANNEL_SHIP_FX)
				structure_crit_alert ++
		if(5 MINUTES to 5.2 MINUTES)
			if(structure_crit_alert == 2)
				stop_relay(channel=CHANNEL_SHIP_FX)
				priority_announce("Warning. Total structural integrity failure will occur in T-10 minutes. The ship will reach an irreparable state in T - 5 minutes.","Automated announcement ([src])", "null")
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_10.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
				structure_crit_alert ++
		if(5.2 MINUTES to 9 MINUTES)
			if(structure_crit_alert == 3)
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_alarm_10.ogg', message=null, loop=TRUE, channel=CHANNEL_SHIP_FX)
				structure_crit_alert ++
		if(9 MINUTES to 9.1 MINUTES)
			if(structure_crit_alert == 4)
				stop_relay(channel=CHANNEL_SHIP_FX)
				priority_announce("DANGER. The ship will reach an irreparable state in T-1 minute.","Automated announcement ([src])", "null")
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_6.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
				structure_crit_alert ++
		if(9.1 MINUTES to 10 MINUTES)
			if(structure_crit_alert == 5)
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_alarm_10.ogg', message=null, loop=TRUE, channel=CHANNEL_SHIP_FX)
				structure_crit_alert ++
		if(10 MINUTES to 10.1 MINUTES)
			if(structure_crit_alert == 6)
				structure_crit_no_return = TRUE //Better launch those escape pods pronto
				stop_relay(channel=CHANNEL_SHIP_FX)
				priority_announce("DANGER. The window for repairing the ship's superstructure has now expired. The ship will detonate in T - 5 minutes.","Automated announcement ([src])","null")
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_5.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
				structure_crit_alert ++
		if(10.1 MINUTES to 14.5 MINUTES)
			if(structure_crit_alert == 7)
				relay('nsv13/sound/effects/ship/sscrit/hullcrit_alarm_5.ogg', message=null, loop=TRUE, channel=CHANNEL_SHIP_FX)
				structure_crit_alert ++
		if(14.5 MINUTES to 15 MINUTES)
			if(structure_crit_alert == 8)
				relay('nsv13/sound/effects/ship/sscrit/countdown.ogg', message=null, loop=FALSE, channel=CHANNEL_IMPORTANT_SHIP_ALERT)
				structure_crit_alert ++
		if(15 MINUTES to INFINITY)
			if(structure_crit_alert == 9)
				message_admins("Critical Structure Failure Occurred in [src.name]")
				handle_critical_failure_part_2()
				structure_crit_alert ++

///Detonates the ship, and ends the round if it was a main overmap.
/obj/structure/overmap/proc/handle_critical_failure_part_2()
	if(role == MAIN_OVERMAP)
		for(var/M in mobs_in_ship)
			if(!locate(M) in operators)
				if(isliving(M))
					start_piloting(M, OVERMAP_USER_ROLE_OBSERVER) //Make sure everyone sees the ship is exploding
				else
					if(istype(M, /mob/dead/observer))
						var/mob/dead/observer/D = M
						D.ManualFollow(src)

		sleep(10)
		STOP_PROCESSING(SSphysics_processing, src) //Reject player input
		src.SpinAnimation(1000, 1) //Drift
		var/michael_bay = rand(5,8) //How many explosions we're going to see (lens flares cost extra)
		for(var/I = 0, I < michael_bay, I++)
			var/obj/effect/temp_visual/nuke_impact/MB = new /obj/effect/temp_visual/nuke_impact(get_turf(src))
			MB.pixel_x = rand(-120, 20)
			MB.pixel_y = rand(-160, 20)
			sleep(rand(5, 20))
		sleep(20)
		qdel(src) //kaboom goes the main ship, end of round
		sleep(20)
		//flick an awesome cinematic screen here - WYSI
		SSticker.mode.check_finished(TRUE)
		SSticker.force_ending = TRUE
	else
		STOP_PROCESSING(SSphysics_processing, src)
		src.SpinAnimation(1000, 1)
		var/michael_bay = rand(5,8)
		for(var/I = 0, I < michael_bay, I++)
			var/obj/effect/temp_visual/nuke_impact/MB = new /obj/effect/temp_visual/nuke_impact(get_turf(src))
			MB.pixel_x = rand(-120, 20)
			MB.pixel_y = rand(-160, 20)
			sleep(rand(5, 20))
		sleep(20)
		qdel(src) //we didn't want miners anyway

/**
 * Repairs structure damage.
 * * amount = amount of structure integrity to restore.
 */
/obj/structure/overmap/proc/try_repair(amount)
	if(amount < 0) //Underflow
		return FALSE
	var/withrepair = obj_integrity+amount
	if(withrepair > max_integrity) //No overheal
		obj_integrity = max_integrity
	else
		obj_integrity += amount
	if(structure_crit)
		if(obj_integrity >= max_integrity * 0.2) //You need to repair a good chunk of her HP before you're getting outta this fucko.
			if(structure_crit_no_return) //Too late.
				return
			stop_relay(channel=CHANNEL_SHIP_FX)
			priority_announce("Ship structural integrity restored to acceptable levels. ","Automated announcement ([src])")
			structure_crit = FALSE


/obj/effect/temp_visual/explosion_telegraph
	name = "Explosion imminent!"
	icon = 'nsv13/icons/overmap/effects.dmi'
	icon_state = "target"
	duration = 6 SECONDS
	randomdir = 0
	light_color = LIGHT_COLOR_ORANGE
	layer = ABOVE_MOB_LAYER
	var/damage_amount = 1

/obj/effect/temp_visual/explosion_telegraph/New(loc, damage_amount)
	. = ..()

/obj/effect/temp_visual/explosion_telegraph/Initialize(mapload)
	. = ..()
	set_light(4)
	for(var/mob/M in orange(src, 3))
		if(isliving(M) && (M.client?.prefs.toggles & PREFTOGGLE_SOUND_AMBIENCE) && M.can_hear_ambience())
			to_chat(M, "<span class='userdanger'>You hear a loud creak coming from above you. Take cover!</span>")
			SEND_SOUND(M, pick('nsv13/sound/ambience/ship_damage/creak5.ogg','nsv13/sound/ambience/ship_damage/creak6.ogg'))

/obj/effect/temp_visual/explosion_telegraph/Destroy()
	var/turf/T = get_turf(src)
	var/damage_level = ((damage_amount <= 20) ? 1 : ((damage_amount <= 75) ? 2 : ((damage_amount <= 150) ? 3 : 4)))
	explosion(T,damage_level == 4 ? 2 : 0,round(damage_level*1.75),round(damage_level*2.25))
	return ..()
