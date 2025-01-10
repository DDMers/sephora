//Handles camera stuff for all generic overmap interaction
/client
	perspective = EYE_PERSPECTIVE //Use this perspective or else shit will break! (sometimes screen will turn black)

/client/proc/AdjustView()
	if(mob.overmap_ship)
		pixel_x = mob.overmap_ship.pixel_x
		pixel_y = mob.overmap_ship.pixel_y
		eye = mob.overmap_ship
	else
		pixel_x = 0
		pixel_y = 0
		eye = mob

/obj/structure/overmap/proc/gauss_test()
	var/mob/living/carbon/human/M = new(src)
	start_piloting(M, "gauss_gunner")

/obj/structure/overmap/proc/start_piloting(mob/living/carbon/user, position)
	if(!position || user.overmap_ship == src || LAZYFIND(operators, user))
		return FALSE
	if(position & OVERMAP_USER_ROLE_PILOT)
		if(pilot)
			to_chat(pilot, "<span class='warning'>[user] has kicked you off the ship controls!</span>")
			stop_piloting(pilot)
		pilot = user
		LAZYOR(user.mousemove_intercept_objects, src)
	if(position & OVERMAP_USER_ROLE_GUNNER)
		if(gunner)
			to_chat(gunner, "<span class='warning'>[user] has kicked you off the ship controls!</span>")
			stop_piloting(gunner)
		gunner = user
	observe_ship(user)
	dradis?.attack_hand(user)
	if(position & (OVERMAP_USER_ROLE_PILOT | OVERMAP_USER_ROLE_GUNNER))
		user.add_verb(overmap_verbs) //Add the ship panel verbs
	if(mass < MASS_MEDIUM)
		return TRUE
	user.client.overmap_zoomout = (mass <= MASS_MEDIUM) ? 5 : 10 //Automatically zooms you out a fair bit so you can see what's even going on.
	user.client.rescale_view(user.client.overmap_zoomout, 0, ((40*2)+1)-15)
	return TRUE

// Handles actually "observing" the ship.
/obj/structure/overmap/proc/observe_ship(mob/living/carbon/user)
	if(user.overmap_ship == src || LAZYFIND(operators, user))
		return FALSE
	user.set_focus(src)
	LAZYADD(operators,user)
	CreateEye(user)
	user.overmap_ship = src
	user.click_intercept = src

/obj/structure/overmap/proc/stop_piloting(mob/living/M)
	LAZYREMOVE(operators,M)
	M.remove_verb(overmap_verbs)
	M.overmap_ship = null
	if(M.click_intercept == src)
		M.click_intercept = null
	if(pilot && M == pilot)
		LAZYREMOVE(M.mousemove_intercept_objects, src)
		pilot = null
		keyboard_delta_angle_left = 0
		keyboard_delta_angle_right = 0
		if(helm)
			playsound(helm, 'nsv13/sound/effects/computer/hum.ogg', 100, 1)
	if(gunner && M == gunner)
		if(tactical)
			playsound(tactical, 'nsv13/sound/effects/computer/hum.ogg', 100, 1)
		gunner = null
		target_lock = null
	if(LAZYFIND(gauss_gunners, M))
		var/datum/component/overmap_gunning/C = M.GetComponent(/datum/component/overmap_gunning)
		C.end_gunning()
	if(M.client)
		M.client.view_size.resetToDefault()
		M.client.overmap_zoomout = 0
		for(var/V in M.actions) //Reset action buttons to stop the screen from staying large
			var/datum/action/A = V
			var/atom/movable/screen/movable/action_button/B = A.button
			B.moved = FALSE
		M.update_action_buttons(TRUE)
	var/mob/camera/ai_eye/remote/overmap_observer/eyeobj = M.remote_control
	M.cancel_camera()
	if(M.client) //Reset px, y
		M.client.pixel_x = 0
		M.client.pixel_y = 0

	if(istype(M, /mob/living/silicon/ai))
		var/mob/living/silicon/ai/hal = M
		hal.view_core()
		hal.remote_control = null
		qdel(eyeobj)
		qdel(eyeobj?.off_action)
		qdel(M.remote_control)
		return

	qdel(eyeobj)
	qdel(eyeobj?.off_action)
	qdel(M.remote_control)
	M.remote_control = null
	M.set_focus(M)
	M.cancel_camera()
	return TRUE

/obj/structure/overmap/proc/CreateEye(mob/user)
	if(!user.client)
		return
	if(isAI(user)) //view core nice and neatly resets their camera perspective, stops them tracking and so on.
		var/mob/living/silicon/ai/hal = user
		hal.view_core()
	user.update_sight()
	var/mob/camera/ai_eye/remote/overmap_observer/eyeobj = new(get_center())
	eyeobj.origin = src
	eyeobj.off_action = new
	eyeobj.off_action.remote_eye = eyeobj
	eyeobj.eye_user = user
	eyeobj.name = "[name] observer"
	eyeobj.off_action.target = user
	eyeobj.off_action.user = user
	eyeobj.off_action.ship = src
	eyeobj.off_action.Grant(user)
	eyeobj.setLoc(eyeobj.loc)
	eyeobj.RegisterSignal(src, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/mob/camera/ai_eye/remote/overmap_observer, update))
	user.reset_perspective(eyeobj)
	user.remote_control = eyeobj

/obj/structure/overmap/proc/remove_eye_control()
	return TRUE

//Now it's time to handle people observing the ship.
/mob/camera/ai_eye/remote/overmap_observer
	name = "Inactive Camera Eye"
	var/datum/action/innate/camera_off/overmap/off_action
	animate_movement = 0 //Stops glitching with overmap movement
	use_static = FALSE
	var/obj/structure/overmap/ship_target = null //Lets gunners lock on to their targets for accurate shooting.

/mob/camera/ai_eye/remote/overmap_observer/Destroy()
	UnregisterSignal(origin, COMSIG_MOVABLE_MOVED)
	if(ship_target)
		UnregisterSignal(ship_target, COMSIG_MOVABLE_MOVED)
		ship_target = null
	return ..()

/datum/action/innate/camera_off/overmap
	name = "Stop observing"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "camera_off"
	var/mob/camera/ai_eye/remote/overmap_observer/remote_eye
	var/mob/living/user
	var/obj/structure/overmap/ship = null

/datum/action/innate/camera_off/overmap/Activate()
	if(!target || !isliving(target))
		return
	if(!remote_eye?.origin)
		qdel(src)
		qdel(remote_eye)
	else if(ship.stop_piloting(target))
		qdel(remote_eye)
		qdel(src)

/mob/camera/ai_eye/remote/overmap_observer/relaymove(mob/user,direct)
	origin?.relaymove(user,direct) //Move the ship. Means our pilots don't fucking suffocate because space is C O L D
	return

/mob/camera/ai_eye/remote/overmap_observer/proc/set_override(state, obj/structure/overmap/override)
	if(state)
		track_target(override)
	else
		var/obj/structure/overmap/ship = origin
		to_chat(eye_user, "<span class='notice'>Target lock relinquished.</span>")
		ship.CreateEye(eye_user)
		QDEL_NULL(off_action)
		QDEL_NULL(src)

/mob/camera/ai_eye/remote/overmap_observer/proc/update()
	SIGNAL_HANDLER
	if(!eye_user.client)
		return
	var/obj/structure/overmap/ship = origin
	var/scan_range = (ship.dradis) ? ship.dradis.visual_range : SENSOR_RANGE_DEFAULT
	if(eye_user == ship.gunner && !(!ship_target || overmap_dist(ship, ship_target) > scan_range)) // No target or our target's out of range, go to origin
		ship = ship_target
	eye_user.client.pixel_x = ship.pixel_x
	eye_user.client.pixel_y = ship.pixel_y
	setLoc(ship.get_center())
	return TRUE

// Switches the camera to track a specific target. If no target is passed, we track our origin
/mob/camera/ai_eye/remote/overmap_observer/proc/track_target(obj/structure/overmap/target)
	if(ship_target)
		UnregisterSignal(ship_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	ship_target = target
	if(ship_target)
		RegisterSignal(ship_target, COMSIG_MOVABLE_MOVED, PROC_REF(update))
		RegisterSignal(ship_target, COMSIG_PARENT_QDELETING, PROC_REF(handle_target_qdel))
	update()
	return TRUE

/mob/camera/ai_eye/remote/overmap_observer/proc/handle_target_qdel()
	SIGNAL_HANDLER
	UnregisterSignal(ship_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	ship_target = null
