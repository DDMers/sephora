/*

MASSIVE THANKS TO MONSTER860 FOR HELP WITH THIS. HE EXPLAINED PHYSICS AND MATH TO ME AND HELPED WRITE THIS.

*/

/obj/vehicle/sealed/car/realistic
	name = "Nissun Skyline GTR"
	desc = "DO YOU LIKE MY CAR?!"
	icon = 'nsv13/icons/obj/vehicles.dmi'
	icon_state = "tug"
	bound_width = 64
	bound_height = 64
	animate_movement = NO_STEPS // Override the inbuilt movement engine to avoid bouncing
	//Movement Variables
	movedelay = 0
	var/velocity_x = 0 // tiles per second.
	var/velocity_y = 0
	var/offset_x = 0 // like pixel_x/y but in tiles
	var/offset_y = 0
	var/angle = 0 // degrees, clockwise
	var/angular_velocity = 0 // degrees per second
	var/max_angular_acceleration = 180 // in degrees per second per second
	var/speed_limit = 7 //Stops ships from going too damn fast. This can be overridden by things like fighters launching from tubes, so it's not a const.
	var/last_thrust_forward = 0
	var/last_thrust_right = 0
	var/last_rotate = 0
	var/should_open_doors = FALSE //Should we open airlocks? This is off by default because it was HORRIBLE.

	var/user_thrust_dir = 0

	//Movement speed variables, configure these per car.
	var/max_acceleration = 5
	var/max_turnspeed = 15
	var/turnspeed = 15
	var/static_traction = 2 //How good are the tyres?. THis behaves somewhat like acceleration, but it shouldnt be more efficient than 9.8, which is the gravity on earth
	var/kinetic_traction = 1.25 //if you are moving sideways and the static traction wasnt enough to kill it, you skid and you will have less traction, but allowing you to drift. KINETIC IE moving traction

	var/bump_impulse = 0.6
	var/bounce_factor = 0.2 // how much of our velocity to keep on collision
	var/lateral_bounce_factor = 0.95 // mostly there to slow you down when you drive (pilot?) down a 2x2 corridor

	COOLDOWN_DECLARE(key_cooldown) // Anti-spam for keys
	var/brakes = FALSE //Helps you stop the tug
	var/last_slowprocess = 0
	var/last_squeak = 0
	var/datum/gas_mixture/cabin_air //Cabin air mix used for small ships like fighters (see overmap/fighters/fighters.dm)
	var/obj/machinery/portable_atmospherics/canister/internal_tank //Internal air tank reference. Used mostly in small ships. If you want to sabotage a fighter, load a plasma tank into its cockpit :)

/obj/vehicle/sealed/car/realistic

/obj/vehicle/sealed/car/realistic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	switch(severity)
		if(1)
			take_damage(30)
		if(2)
			take_damage(25)

/obj/vehicle/sealed/car/realistic/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)
	for(var/HPtype in default_hardpoints)
		var/obj/item/vehicle_hardpoint/HP = new HPtype(src)
		hardpoints[HP.type] = HP
		HP.on_insertion(src)
		update_icon()

/obj/vehicle/sealed/car/realistic/after_add_occupant(mob/M)
	. = ..()
	ui_interact(M)
	M.set_focus(src)

/obj/vehicle/sealed/car/realistic/after_remove_occupant(mob/M)
	M.set_focus(M)
	M?.client.AdjustView()

/obj/vehicle/sealed/car/realistic/proc/toggle_brakes()
	brakes = !brakes
	to_chat(usr, "<span class='notice'>You toggle the brakes [brakes ? "on" : "off"].")

/obj/effect/decal/cleanable/tyre_marks
	name = "Tyre tracks"
	desc = "The remnants of a vehicle skidding"
	icon = 'nsv13/icons/obj/vehicles.dmi'
	icon_state = "tyre_tracks"
	alpha = 10

/obj/effect/decal/cleanable/tyre_marks/Initialize(mapload, angle)
	. = ..()
	animate(src, alpha = 255, time = 1 SECONDS, easing = EASE_OUT)
	var/matrix/ntransform = new()
	ntransform.Turn(angle)
	transform = ntransform

/obj/vehicle/sealed/car/realistic/proc/slowprocess()
	return

/obj/vehicle/sealed/car/realistic/proc/can_move()
	return TRUE //Placeholder for everything but fighters. We can later extend this if / when we want to code in ship engines.

/obj/vehicle/sealed/car/realistic/driver_move(mob/user, direction)
	if(key_type && !is_key(inserted_key))
		if(COOLDOWN_FINISHED(src, key_cooldown))
			to_chat(user, "<span class='warning'>[src] has no key inserted!</span>")
			COOLDOWN_START(src, key_cooldown, 1 SECONDS)
		return FALSE
	if(world.time >= last_enginesound_time + engine_sound_length)
		last_enginesound_time = world.time
		playsound(src, engine_sound, 100, TRUE)
	user_thrust_dir = direction
	return TRUE

// The prices (tick drift) we'll pay for vroom
/obj/vehicle/sealed/car/realistic/process(delta_time)
	set waitfor = FALSE
	if(world.time > last_slowprocess + 1 SECONDS)
		last_slowprocess = world.time
		slowprocess()
	if(!canmove)
		velocity_x = 0
		velocity_y = 0
		return
	//Are we about to skid?
	var/pre_fx = cos(90 - angle)
	var/pre_fy = sin(90 - angle) //Forward vector
	var/pre_sx = pre_fy //Side movement
	var/pre_sy = -pre_fx
	var/pre_forward_movement = ((pre_fx * velocity_x) + (pre_fy * velocity_y)) //Forward/Backward movement dot product here.
	var/pre_side_movement = ((pre_sx * velocity_x) + (pre_sy * velocity_y)) //Side movement dot product here.
	var/friction = (pre_side_movement >= 0.01) ? kinetic_traction : static_traction
	var/braking_efficiency = 2
	var/acceleration = max_acceleration
	if(friction <= kinetic_traction && friction > 0) //Cars with no tyres don't squeak
		if(world.time >= last_squeak + 0.3 SECONDS)
			last_squeak = world.time
			playsound(src, pick('nsv13/sound/effects/tyres1.ogg','nsv13/sound/effects/tyres2.ogg'), 100, TRUE)
			new /obj/effect/decal/cleanable/tyre_marks(src.loc, angle)
		braking_efficiency = 0.5
		acceleration = 0.5*max_acceleration

	var/last_offset_x = offset_x
	var/last_offset_y = offset_y
	var/last_angle = angle
	var/desired_angular_velocity = 0
	if(user_thrust_dir & EAST)
		desired_angular_velocity = turnspeed
	if(user_thrust_dir & WEST)
		desired_angular_velocity = -turnspeed
	desired_angular_velocity *= pre_forward_movement
	var/angular_velocity_adjustment = CLAMP(desired_angular_velocity - angular_velocity, -max_angular_acceleration*delta_time, max_angular_acceleration*delta_time)
	if(angular_velocity_adjustment)
		last_rotate = angular_velocity_adjustment / delta_time
		angular_velocity += angular_velocity_adjustment
	else
		last_rotate = 0
	angle += angular_velocity * delta_time
	if(angle >= 360 || angle <= -360)
		angle = 0

	// calculate drag and shit

	var/velocity_mag = sqrt(velocity_x*velocity_x+velocity_y*velocity_y) // magnitude
	if(velocity_mag || angular_velocity)
		var/drag = 0
		for(var/turf/T in locs)
			if(isspaceturf(T))
				continue
			if(brakes)
				drag += braking_efficiency
			var/datum/gas_mixture/env = T.return_air()
			var/pressure = env.return_pressure()
			drag += velocity_mag * pressure * 0.0001 // 1 atmosphere should shave off 1% of velocity per tile
		if(velocity_mag > 20)
			drag = max(drag, (velocity_mag - 20) / delta_time)
		if(drag)
			if(velocity_mag)
				var/drag_factor = 1 - CLAMP(drag * delta_time / velocity_mag, 0, 1)
				velocity_x *= drag_factor
				velocity_y *= drag_factor
			if(angular_velocity != 0)
				var/drag_factor_spin = 1 - CLAMP(drag * 30 * delta_time / abs(angular_velocity), 0, 1)
				angular_velocity *= drag_factor_spin

	// Alright now calculate the THRUST
	var/thrust_x
	var/thrust_y
	var/fx = cos(90 - angle)
	var/fy = sin(90 - angle) //This appears to be a vector.
	var/sx = fy
	var/sy = -fx
	last_thrust_forward = 0
	last_thrust_right = 0
	if(brakes) //If our brakes are engaged, attempt to slow them down
		// basically calculates how much we can brake using our acceleration
		var/forward_thrust = -((fx * velocity_x) + (fy * velocity_y)) / delta_time
		var/right_thrust = -((sx * velocity_x) + (sy * velocity_y)) / delta_time
		forward_thrust = CLAMP(forward_thrust, -kinetic_traction, kinetic_traction)
		right_thrust = CLAMP(right_thrust, -kinetic_traction, kinetic_traction)
		thrust_x += forward_thrust * fx + right_thrust * sx;
		thrust_y += forward_thrust * fy + right_thrust * sy;
		last_thrust_forward = forward_thrust
		last_thrust_right = right_thrust
	else if(can_move())
		if(user_thrust_dir & NORTH)
			thrust_x += fx * acceleration
			thrust_y += fy * acceleration
			last_thrust_forward = acceleration
		if(user_thrust_dir & SOUTH)
			thrust_x -= fx * acceleration
			thrust_y -= fy * acceleration
			last_thrust_forward = -acceleration
	 //Stops you yeeting off at lightspeed.
	if(velocity_x > speed_limit)
		velocity_x = speed_limit
	if(velocity_y > speed_limit)
		velocity_y = speed_limit
	if(velocity_x < -speed_limit)
		velocity_x = -speed_limit
	if(velocity_y < -speed_limit)
		velocity_y = -speed_limit
	//Speed us up based on thrust
	velocity_x += thrust_x * delta_time //And speed us up based on how long we've been thrusting (up to a point)
	velocity_y += thrust_y * delta_time
	//Shave off the sideways movement in a skid.
	var/side_movement = (sx*velocity_x) + (sy*velocity_y)
	var/friction_impulse = friction * delta_time
	var/clamped_side_movement = CLAMP(side_movement, -friction_impulse, friction_impulse)
	velocity_x -= clamped_side_movement * sx
	velocity_y -= clamped_side_movement * sy
	//Reconcile everything into a movement vector
	offset_x += velocity_x * delta_time
	offset_y += velocity_y * delta_time

	// alright so now we reconcile the offsets with the in-world position.
	while((offset_x > 0 && velocity_x > 0) || (offset_y > 0 && velocity_y > 0) || (offset_x < 0 && velocity_x < 0) || (offset_y < 0 && velocity_y < 0))
		var/failed_x = FALSE
		var/failed_y = FALSE
		if(offset_x > 0 && velocity_x > 0)
			dir = EAST
			if(!Move(get_step(src, EAST)))
				offset_x = 0
				failed_x = TRUE
				velocity_x *= -bounce_factor
				velocity_y *= lateral_bounce_factor
			else
				offset_x--
				last_offset_x--
		else if(offset_x < 0 && velocity_x < 0)
			dir = WEST
			if(!Move(get_step(src, WEST)))
				offset_x = 0
				failed_x = TRUE
				velocity_x *= -bounce_factor
				velocity_y *= lateral_bounce_factor
			else
				offset_x++
				last_offset_x++
		else
			failed_x = TRUE
		if(offset_y > 0 && velocity_y > 0)
			dir = NORTH
			if(!Move(get_step(src, NORTH)))
				offset_y = 0
				failed_y = TRUE
				velocity_y *= -bounce_factor
				velocity_x *= lateral_bounce_factor
			else
				offset_y--
				last_offset_y--
		else if(offset_y < 0 && velocity_y < 0)
			dir = SOUTH
			if(!Move(get_step(src, SOUTH)))
				offset_y = 0
				failed_y = TRUE
				velocity_y *= -bounce_factor
				velocity_x *= lateral_bounce_factor
			else
				offset_y++
				last_offset_y++
		else
			failed_y = TRUE
		if(failed_x && failed_y)
			break
	// prevents situations where you go "wtf I'm clearly right next to it" as you enter a stationary spacepod
	if(velocity_x == 0)
		if(offset_x > 0.5)
			if(Move(get_step(src, EAST)))
				offset_x--
				last_offset_x--
			else
				offset_x = 0
		if(offset_x < -0.5)
			if(Move(get_step(src, WEST)))
				offset_x++
				last_offset_x++
			else
				offset_x = 0
	if(velocity_y == 0)
		if(offset_y > 0.5)
			if(Move(get_step(src, NORTH)))
				offset_y--
				last_offset_y--
			else
				offset_y = 0
		if(offset_y < -0.5)
			if(Move(get_step(src, SOUTH)))
				offset_y++
				last_offset_y++
			else
				offset_y = 0
	dir = NORTH //So that the matrix is always consistent
	var/matrix/mat_from = new()
	mat_from.Turn(last_angle)
	var/matrix/mat_to = new()
	mat_to.Turn(angle)
	transform = mat_from
	pixel_x = last_offset_x*32
	pixel_y = last_offset_y*32
	animate(src, transform=mat_to, pixel_x = offset_x*32, pixel_y = offset_y*32, time = delta_time*10, flags=ANIMATION_END_NOW)

	for(var/mob/living/M in return_occupants())
		var/client/C = M.client
		if(!C)
			continue
		C.pixel_x = last_offset_x*32
		C.pixel_y = last_offset_y*32
		animate(C, pixel_x = offset_x*32, pixel_y = offset_y*32, time = delta_time*10, flags=ANIMATION_END_NOW)
	user_thrust_dir = 0
	update_icon()

/obj/vehicle/sealed/car/realistic/Bumped(atom/movable/A)
	if(brakes || ismob(A)) //No :)
		return FALSE
	if(A.dir & NORTH)
		velocity_y += bump_impulse
	if(A.dir & SOUTH)
		velocity_y -= bump_impulse
	if(A.dir & EAST)
		velocity_x += bump_impulse
	if(A.dir & WEST)
		velocity_x -= bump_impulse
	return ..()

/obj/vehicle/sealed/car/realistic/Bump(atom/A)
	var/bump_velocity = 0
	if(dir & (NORTH|SOUTH))
		bump_velocity = abs(velocity_y) + (abs(velocity_x) / 15)
	else
		bump_velocity = abs(velocity_x) + (abs(velocity_y) / 15)
	if(istype(A, /obj/machinery/door/airlock)) // try to open doors
		if(!should_open_doors)
			return ..()
		var/obj/machinery/door/D = A
		if(!D.operating)
			if(D.allowed(D.id_scan_hacked() ? return_drivers()[1] : null))
				spawn(0)
					D.open()
			else
				D.do_animate("deny")
	var/atom/movable/AM = A
	if(istype(AM) && !AM.anchored && bump_velocity > 1)
		step(AM, dir)
	if(layer < A.layer) //Allows ships to "Layer under" things and not hit them. Especially useful for fighters.
		return ..()
	// if a bump is that fast then it's not a bump. It's a collision.
	if(bump_velocity >= 5 && !ismob(A))
		var/strength = bump_velocity / 7.5
		strength = strength * strength
		strength = min(strength, 5) // don't want the explosions *too* big
		// wew lad, might wanna slow down there
		explosion(A, -1, round((strength - 1) / 2), round(strength))
		take_damage(strength*10, BRUTE, "melee", TRUE)
		visible_message("<span class='danger'>The force of the impact causes a shockwave</span>")
	else if(isliving(A) && bump_velocity > 2)
		var/mob/living/M = A
		M.apply_damage(bump_velocity * 2)
		take_damage(bump_velocity, BRUTE, "melee", FALSE)
		playsound(M.loc, "swing_hit", 1000, 1, -1)
		M.Knockdown(bump_velocity * 2)
		M.visible_message("<span class='warning'>The force of the impact knocks [M] down!</span>","<span class='userdanger'>The force of the impact knocks you down!</span>")
	return ..()


//Atmos handling copypasta

/obj/vehicle/sealed/car/realistic/Initialize(mapload)
	. = ..()
	cabin_air = new
	cabin_air.set_temperature(T20C)
	cabin_air.set_volume(200)
	cabin_air.set_moles(GAS_O2, O2STANDARD*cabin_air.return_volume()/(R_IDEAL_GAS_EQUATION*cabin_air.return_temperature()))
	cabin_air.set_moles(GAS_N2, N2STANDARD*cabin_air.return_volume()/(R_IDEAL_GAS_EQUATION*cabin_air.return_temperature()))
	internal_tank = new /obj/machinery/portable_atmospherics/canister/air(src)


/obj/vehicle/sealed/car/realistic/remove_air(amount)
	return cabin_air.remove(amount)

/obj/vehicle/sealed/car/realistic/remove_air_ratio(ratio)
	return cabin_air.remove_ratio(ratio)

/obj/vehicle/sealed/car/realistic/return_air()
	return cabin_air

/obj/vehicle/sealed/car/realistic/return_analyzable_air()
	return cabin_air

/obj/vehicle/sealed/car/realistic/return_temperature()
	var/datum/gas_mixture/t_air = return_air()
	if(t_air)
		. = t_air.return_temperature()
	return

/obj/vehicle/sealed/car/realistic/portableConnectorReturnAir()
	return return_air()

/obj/vehicle/sealed/car/realistic/assume_air(datum/gas_mixture/giver)
	var/datum/gas_mixture/t_air = return_air()
	return t_air.merge(giver)

/obj/vehicle/sealed/car/realistic/slowprocess()
	. = ..()
	if(cabin_air && cabin_air.return_volume() > 0)
		var/delta = cabin_air.return_temperature() - T20C
		cabin_air.set_temperature(cabin_air.return_temperature() - max(-10, min(10, round(delta/4,0.1))))
	if(internal_tank && cabin_air)
		var/datum/gas_mixture/tank_air = internal_tank.return_air()
		var/release_pressure = ONE_ATMOSPHERE
		var/cabin_pressure = cabin_air.return_pressure()
		var/pressure_delta = min(release_pressure - cabin_pressure, (tank_air.return_pressure() - cabin_pressure)/2)
		var/transfer_moles = 0
		if(pressure_delta > 0) //cabin pressure lower than release pressure
			if(tank_air.return_temperature() > 0)
				transfer_moles = pressure_delta*cabin_air.return_volume()/(cabin_air.return_temperature() * R_IDEAL_GAS_EQUATION)
				tank_air.transfer_to(cabin_air,transfer_moles)
		else if(pressure_delta < 0) //cabin pressure higher than release pressure
			var/turf/T = get_turf(src)
			var/datum/gas_mixture/t_air = T.return_air()
			pressure_delta = cabin_pressure - release_pressure
			if(t_air)
				pressure_delta = min(cabin_pressure - t_air.return_pressure(), pressure_delta)
			if(pressure_delta > 0) //if location pressure is lower than cabin pressure
				transfer_moles = pressure_delta*cabin_air.return_volume()/(cabin_air.return_temperature() * R_IDEAL_GAS_EQUATION)
				cabin_air.transfer_to(t_air, transfer_moles)
