#define STATE_OVERLOAD 2
#define STATE_VENTING 1
#define STATE_NOTHING 0
//#define STATE(ACTIVE) 1
//#define STATE(INACTIVE) 0 dunno how to adapt somem of these things right now


/obj/machinery/ship_weapon/energy
	name = "burst phaser MK2"
	desc = "A coaxial laser system, capable of firing controlled laser bursts at a target."
	icon ='nsv13/icons/obj/energy_weapons.dmi'
	icon_state = "phase_cannon"
	fire_mode = FIRE_MODE_RED_LASER //Shot by the pilot.
	ammo_type = /obj/item/ship_weapon/ammunition/railgun_ammo
	circuit = /obj/item/circuitboard/machine/burst_phaser
	bound_width = 64
	pixel_x = -32
	pixel_y = -32
	maintainable = FALSE //Laser do shoot good and reliably.
	safety = FALSE //Ready to go right from the start.
	idle_power_usage =  2500
	var/active = FALSE
	var/max_charge = 3300000 //5 shots before it has to recharge.
	var/power_modifier = 0 //Power youre inputting into this thing.
	var/power_modifier_cap = 3 //Which means that your guns are spitting bursts that do 60 damage.
	var/energy_weapon_type = /datum/ship_weapon/burst_phaser
	var/static_charge = FALSE //Controls whether power and energy cost scale with power modifier. True = no scaling
	var/alignment = 100 //stolen from railguns and the plasma gun
	var/freq = 100
	var/max_freq = 100
	var/combo_target = "omega" //Randomized sequence for the recalibration minigame.
	var/list/letters = list("delta,", "omega,", "phi,")
	var/combo = null
	var/combocount = 0 //How far into the combo are they?
	var/overheat_sound = 'sound/effects/smoke.ogg'
	var/list/cooling = list()
	var/cooling_amount = 0
	var/storage_amount = 0
	var/storage_rate = 100
	var/weapon_state = STATE_NOTHING
	var/ventnumber = 1
	// These variables only pertain to energy weapons, but need to be checked later in /proc/fire //I moved these over to the energyweapon basetype. if everything explodes, someone else told me to
	var/charge = 0
	var/heat = 0
	var/charge_rate = 430000 //How quickly do we charge?
	var/charge_per_shot = 660000 //How much power per shot do we have to use?
	var/heat_per_shot = 250 //how much heat do we make per shot
	var/heat_rate = 10 // how fast do we discharge heat
	var/max_heat = 1000 //how much heat before ::fun:: happens
	var/overloaded = 0 //have we cooked ourself
	var/complexenergy = 1 //todo, makes special energy weapons exempt
	var/lockout = 0 //todo, make only one person work on something at a time
	max_integrity = 1200 //don't blow up before we're ready
	obj_integrity = 1200

/obj/machinery/ship_weapon/energy/beam
	name = "phase cannon"
	desc = "An extremely powerful directed energy weapon which is capable of delivering a devastating beam attack."
	icon_state = "ion_cannon"
	fire_mode = FIRE_MODE_BLUE_LASER
	energy_weapon_type = /datum/ship_weapon/phaser
	circuit = /obj/item/circuitboard/machine/phase_cannon
	charge_rate = 800000 // At power level 5, requires 3MW per tick to charge(this is wrong. but I don't have the proper numbers)
	charge_per_shot = 3800000 // At power level 5, requires 20MW total to fire, takes about 12 seconds to gain 1 charge (ditto). I'm actually making this less demanding so that heat becomes the limiting factor, especially for this one.
	max_charge = 8000000 // Store 2 charges
	power_modifier_cap = 5 //Allows you to do insanely powerful oneshot lasers. Maximum theoretical damage of 500.
	max_heat = 2000
	heat_per_shot = 1200
	heat_rate = 5
	storage_rate = 140

/obj/machinery/ship_weapon/energy/Initialize()
	. = ..()
	combo_target = "[pick(letters)][pick(letters)][pick(letters)][pick(letters)][pick(letters)]"  //actually making the random sequince


/obj/machinery/ship_weapon/energy/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The Thermal Transceiver is currently at <b>[length(cooling)]0%</b> connection capacity.</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The heatsink display reads <b>[(heat)]</b> out of <b>[(max_heat)]</b>.</span>"
		if(maint_state != MSTATE_CLOSED)
			. +=  "<span class='warning'>[src]'s realignment sequence is: [combo_target].</span>"
		if(weapon_state == STATE_VENTING) //are we venting heat?)
			. +=  "<span class='warning'>[src]'s thermal managment system is in overdrive.</span>"
		if(weapon_state == STATE_OVERLOAD) //have we overheated?
			. +=  "<span class='warning'>[src]'s thermal managment system is in failure recovery mode.</span>"

/obj/machinery/ship_weapon/energy/lazyload()
	active = TRUE
	power_modifier = 1
	. = ..()
	//Comedy.
	sleep(10)
	charge = max_charge

/obj/machinery/ship_weapon/energy/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EnergyWeapons")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/ship_weapon/energy/proc/vent()
	if(heat > max_heat*0.25)
		weapon_state = STATE_VENTING
		ventnumber = max_heat*0.25
	else
		ventnumber = max_heat
		weapon_state = STATE_VENTING
		playsound(src, 'sound/effects/turbolift/turbolift-close.ogg', 100, 1)
		playsound(src, overheat_sound, 100, 1)

/obj/machinery/ship_weapon/energy/ui_act(action, params)

	if(..())
		return
	var/value = text2num(params["input"])
	switch(action)
		if("power")
			power_modifier = value
		if("activeToggle")
			active = !active
		if("vent")
			vent()
	return

/obj/machinery/ship_weapon/energy/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/ship_weapon/energy/attack_ai(mob/user)
	ui_interact(user)

/obj/machinery/ship_weapon/energy/attack_robot(mob/user)
	ui_interact(user)

/obj/machinery/ship_weapon/energy/ui_data(mob/user)
	. = ..()
	var/list/data = list()
	data["progress"] = charge
	data["goal"] = max_charge
	data["alignment"] = alignment
	data["heat"] = heat
	data["maxheat"] = max_heat
	data["frequency"] = freq
	data["chargeRate"] = charge_rate
	data["maxChargeRate"] = initial(charge_rate)*power_modifier_cap
	data["powerAlloc"] = power_modifier
	data["maxPower"] = power_modifier_cap //Hard cap for now. Allow them to increase this via stock parts when??
	data["active"] = active
	return data

/obj/machinery/ship_weapon/energy/update()
	if(!safety)
		if(src in weapon_type.weapons["loaded"])
			return
		LAZYADD(weapon_type.weapons["loaded"] , src)
	else
		if(src in weapon_type.weapons["loaded"])
			LAZYREMOVE(weapon_type.weapons["loaded"] , src)

/obj/machinery/ship_weapon/energy/set_position(obj/structure/overmap/OM) //Use this to tell your ship what weapon category this belongs in
	for(var/I = FIRE_MODE_ANTI_AIR; I <= MAX_POSSIBLE_FIREMODE; I++) //We should ALWAYS default to PDCs.
		var/datum/ship_weapon/SW = OM.weapon_types[I]
		if(!SW)
			continue
		if(istype(SW, energy_weapon_type)) //Does this ship have a weapon type registered for us? Prevents phantom weapon groups.
			OM.add_weapon(src)
			return TRUE
	OM.weapon_types[fire_mode] = new energy_weapon_type(OM)
	OM.add_weapon(src)

/obj/machinery/ship_weapon/energy/can_fire(shots = weapon_type.burst_size)
	if (maint_state != MSTATE_CLOSED) //Are we in maintenance?
		return FALSE
	if(charge < charge_per_shot*shots) //Do we have enough ammo?
		return FALSE
	if(weapon_state == STATE_OVERLOAD) //have we overheated?
		return FALSE
	if(weapon_state == STATE_VENTING) //are we venting heat?)
		return FALSE
	if(freq <=10) //is the frequincy of the weapon high enough to fire?
		overload()
		return FALSE
	if(alignment == 0)
		playsound(src, malfunction_sound, 100, 1)
		for(var/mob/living/M in get_hearers_in_view(7, src)) //burn out eyes in view
			if(M.stat != DEAD && M.get_eye_protection() < 2) //checks for eye protec
				M.flash_act(10)
				to_chat(M, "<span class='warning'>You have a second to watch the casing of the gun glow a dull red before it erupts in a blinding flash as it self-destructs</span>")   // stealing this from the plasmagun as well
		explosion(get_turf(src), 0, 1, 3, 5, flame_range = 4)
		overload()
		return FALSE
	return TRUE

/obj/machinery/ship_weapon/energy/get_max_ammo()
	return max_charge

/obj/machinery/ship_weapon/energy/get_ammo()
	return charge

/obj/machinery/ship_weapon/energy/beam/animate_projectile(atom/target)
	var/obj/item/projectile/P = ..()
	if(!static_charge)
		P.damage *= power_modifier
	P.damage *= (freq/100)

/obj/machinery/ship_weapon/energy/process()
	process_heat()
	if(weapon_state == STATE_OVERLOAD)
		return
	if(weapon_state == STATE_VENTING)
		return
	charge_rate = initial(charge_rate) * power_modifier
	max_charge = initial(max_charge) * power_modifier
	if(!static_charge)
		charge_per_shot = max(initial(charge_per_shot) * power_modifier, 10) //No getting infinite ammo by setting power mod to 0 :))
	if(charge >= max_charge)
		charge = max_charge //Time to fricking ignore thermodynamics gamers!
		idle_power_usage = 0 //No power draw when fully charged
		return
	if(!active)
		idle_power_usage = 0
		return
	else
		idle_power_usage = 1000
	if(idle_power_usage <= 0 || !try_use_power(charge_rate))
		return
	charge += charge_rate

/obj/machinery/ship_weapon/energy/after_fire()
	if(maint_state != MSTATE_CLOSED) //MSTATE_CLOSED
		tesla_zap(src, 4, 1000) //Munitions Officer definitely had the best uniform
		for(var/mob/living/carbon/C in orange(4, src))
			C.flash_act()
		for(var/mob/living/carbon/C in orange(12, src))
			to_chat(C, "<span class='danger'>Electricity arcs from the exposed firing mechanism.</span>")
	handle_alignment()
	..()





//Well hey! here's this piece of code again...
/obj/machinery/ship_weapon/energy/proc/try_use_power(amount) // Although the machine may physically be powered, it may not have enough power to sustain a shield.
	if(!powered())
		return FALSE
	var/turf/T = get_turf(src)
	var/obj/structure/cable/C = T.get_cable_node()
	if(C)
		if(!C.powernet)
			return FALSE
		var/power_in_net = C.powernet.avail-C.powernet.load

		if(power_in_net && power_in_net >= amount)
			C.powernet.load += amount
			return TRUE
		return FALSE
	return FALSE


/obj/machinery/ship_weapon/energy/beam/admin //ez weapon for quickly testing.
	charge_per_shot = 0



/obj/machinery/ship_weapon/energy/proc/process_heat()//heat management. don't push your weapons too hard. actual heat generation is in _ship_weapons.dm
	cooling_amount = 0
	for(var/obj/machinery/cooling/cooler/C in cooling)
		if(!(C.machine_stat & (BROKEN|NOPOWER|MAINT)))
			cooling_amount++
	storage_amount = 0
	for(var/obj/machinery/cooling/storage/C in cooling)
		if(!(C.machine_stat & (BROKEN|NOPOWER|MAINT)))
			storage_amount++
	max_heat = initial(max_heat) + (storage_amount*storage_rate)
	var/H = heat-cooling_amount*heat_rate
	if(heat > 0)
		heat = max((H),0)
	switch(weapon_state)
		if(STATE_OVERLOAD)
			if(heat <= (max_heat/50))
				weapon_state = STATE_NOTHING
			else
				return
		if(STATE_VENTING)
			if(heat <= ventnumber)
				weapon_state = STATE_NOTHING
				return
			heat = max(heat-(cooling_amount*(heat_rate+(0.25*heat_rate))),0)
			return
	if(heat >= max_heat)
		overload()


/obj/machinery/ship_weapon/energy/proc/overload() //this is what happens when you can't control yourself
	playsound(src, malfunction_sound, 100, 1)
	playsound(src, overheat_sound, 100, 1)
	do_sparks(4, FALSE, src)
	weapon_state = STATE_OVERLOAD
	alignment = 0
	freq = 0
	say("WARNING! Critical heat density, emergency venting and shutdown initiated!")
	atmos_spawn_air("water_vapor=200;TEMP=1000")
	heat = max_heat
	charge = 0
	return

/obj/machinery/ship_weapon/energy/proc/handle_alignment() //this is the basic bad stuff that happens, don't fire when your gun is at 0 alignment, or it'll blow itself up
	var/turf/detonation_turf = get_turf(src)
	if(heat >= (3*(max_heat/4)))
		freq -= rand(1,4)
	switch(alignment)
		if(51 to 75)
			if(prob(50))
				do_sparks(4, FALSE, src)
				freq -= rand(1,10)
		if(26 to 50)
			var/roll = roll(1,20)
			switch(roll)
				if(1 to 9)
					do_sparks(4, FALSE, src)
					freq -= rand(1,10)
					playsound(src, malfunction_sound, 100, 1)
				if(10)
					playsound(src, malfunction_sound, 100, 1)
					freq -= rand(1,10)
					explosion(detonation_turf, 0, 0, 2, 3, flame_range = 2)
		if(0 to 25)
			var/roll2 = roll(1,4)
			switch(roll2)
				if(1)
					do_sparks(4, FALSE, src)
					playsound(src, malfunction_sound, 100, 1)
					freq -= rand(1,10)
				if(2)
					playsound(src, malfunction_sound, 100, 1)
					freq -= rand(1,10)
					explosion(detonation_turf, 0, 0, 3, 4, flame_range = 3)
				if(3,4)
					var/list/shootat_turf = RANGE_TURFS(5,detonation_turf) - RANGE_TURFS(4, detonation_turf)
					var/obj/item/projectile/beam/laser/P = new(detonation_turf)
					//Shooting Code:
					P.range = 6
					P.preparePixelProjectile(pick(shootat_turf), detonation_turf)
					P.fire()
					freq -= rand(1,10)
	alignment = max(alignment-(rand(0, 4)),0)


	// dilithium crystal alignment minigame stolen from ds13 - I need to rip this out and rewrite it to not be completely cursed - TODO
/obj/machinery/ship_weapon/energy/screwdriver_act(mob/user, obj/item/tool)
	. = ..()
	if(maint_state == MSTATE_UNBOLTED)
		.=TRUE
		var/sound/thesound = pick('nsv13/sound/effects/computer/beep.ogg','nsv13/sound/effects/computer/beep2.ogg','nsv13/sound/effects/computer/beep3.ogg','nsv13/sound/effects/computer/beep4.ogg','nsv13/sound/effects/computer/beep5.ogg','nsv13/sound/effects/computer/beep6.ogg','nsv13/sound/effects/computer/beep7.ogg','nsv13/sound/effects/computer/beep8.ogg','nsv13/sound/effects/computer/beep9.ogg','nsv13/sound/effects/computer/beep10.ogg','nsv13/sound/effects/computer/beep11.ogg','nsv13/sound/effects/computer/beep12.ogg',)
		SEND_SOUND(user, thesound)
		var/list/options = letters
		for(var/option in options)
			options[option] = image(icon = 'nsv13/icons/actions/engine_actions.dmi', icon_state = "[option]")
		var/dowhat = show_radial_menu(user,src,options)
		if(!dowhat)
			return
		combo += "[dowhat]"
		combocount ++
		to_chat(user, "<span class='warning'>You inputted [dowhat] into the command sequence.</span>")
		playsound(src, 'sound/machines/sm/supermatter3.ogg', 20, 1)
		if(combocount <= 4)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom,screwdriver_act), user),2)   // *scream  addtimer(CALLBACK(object|null, GLOBAL_PROC_REF(type/path|procstring), arg1, arg2, ... argn), time, timertype)
		if(combocount >= 5) //Completed the sequence
			if(combo == combo_target)
				to_chat(user, "<span class='warning'>Realignment of weapon energy direction matrix complete.</span>")
				playsound(src, 'sound/machines/sm/supermatter1.ogg', 30, 1)
				freq = max_freq
				combo = null
				combocount = 0
			else
				to_chat(user, "<span class='warning'>Realignment failed. Continued failure risks dangerous heat overload. Rotating command sequence.</span>")
				playsound(src, 'nsv13/sound/effects/warpcore/overload.ogg', 100, 1)
				combo_target = "[pick(letters)][pick(letters)][pick(letters)][pick(letters)][pick(letters)]"
				heat = max(heat+(heat_per_shot*4),max_heat) //Penalty for fucking it up. You risk destroying the crystal... //well... actually overheating the gun
				combocount = 0
				combo = null

/obj/machinery/ship_weapon/energy/multitool_act(mob/living/user, obj/item/multitool/I)
	switch(maint_state)
		if(MSTATE_CLOSED)
			if(istype(I))
				to_chat(user, "<span class='notice'>You log [src] in the multitool's buffer.</span>")
				I.buffer = src
				return TRUE
		if(MSTATE_UNSCREWED)
			to_chat(user, "<span class='notice'>You must <I>unbolt</I> the protective casing before aligning the lenses!</span>")
			return TRUE
		if(MSTATE_UNBOLTED)
			to_chat(user, "<span class='notice'>You being aligning the lenses.</span>")
			while(alignment < 100)
				if(!do_after(user, 5, target = src))
					return TRUE
				alignment += rand(1,2)
				if(alignment >= 100)
					alignment = 100
					to_chat(user, "<span class='notice'>You finish aligning the lenses.</span>")
					return TRUE
	return ..()

/obj/machinery/ship_weapon/energy/Destroy()
	for(var/obj/machinery/cooling/E in cooling)
		E.parent = null
	. = ..()
