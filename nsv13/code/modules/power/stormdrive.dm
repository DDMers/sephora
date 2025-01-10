/*

HOW 2 Stormdrive?! - A guide for M*ppers

General Checklist:
 - 3x3 Minimum dedicated room containing one: (/obj/machinery/atmospherics/components/binary/stormdrive_reactor)
 - Input pipe
 - Output pipe
 - 10x standard control rods (/obj/item/control_rod)
 - Magnetic constrictors x2 minimum (/obj/machinery/atmospherics/components/binary/magnetic_constrictor)
 - Reactor Control Computer (/obj/machinery/computer/ship/reactor_control_computer)
 - Particle Accelerator

///ADDITIONAL INFORMATION///

The Fuel Line (Input Pipe)
	This is where the fuel is pumped into the 'drive, in its most basic form, it just a pipe running from ATMOS Plasma storage tank.
	Things to consider:
						Constricted Plasma is a more effective fuel than just Plasma, creating a line from the ATMOS Plasma storage tank to a couple Magnetic Constrictors in PARALLEL and then into the fuel line is considered to be the standard configuration
						All standard gases found in ATMOS storage have an effect on the operation of the 'drive, consider including support for mixing directly into the fuel line

The Waste Line (Output Pipe)
	This is where the "waste" is from the 'drive comes out, venting it straight to space is an option, but a bad one
	Things to consider:
						The waste line can become clogged, this is by design, give options to manage pressure
						Dumped fuel will be deposited in this line - it can be reclaimed
						Depleted fuel/Nucleium is used by the FTL Drive and is VERY HOT

Stormdrive Orientation
	The default orientation has the INPUT on the EASTERN side and the OUTPUT on the WESTERN side. While this can be changed, it is considered the standard and should not be changed without a VERY good reason.

Reactor Control Computer
	This is computer that allows for control and monitoring of the stormdrive.
	Things to consider:
						Placing the Reactor Control Computer close to the Particle Accelerator Console makes starting the 'drive much easier.
						Both the Reactor Control Computer and the Stormdrive start with null IDs, var edit them to match for linking at round start.

Particle Accelerator Positioning
	Note: The Stormdrive has audio and visual indicators when it starts or fails to start. Placing the PA Console in a position that allows the player to see the 'drive is recommended.

Magnetic Constrictor Pressure Caps
	Mag constrictors have a maximum pressure they can output constricted plasma, consider ways of managing this.

Control Rods
	The ship is intended on having 5 operational rods, and 5 spare at round start. Additional rods can be printed or acquired from cargo.
*/

//Gas Interactions
#define LOW_ROR 0.5
#define NORMAL_ROR 1
#define HIGH_ROR 1.5
#define HINDER_ROR -0.5
#define REALLY_HINDER_ROR -1
#define NULL_ROR 0

#define LOW_IPM 0.5
#define MEDIOCRE_IPM 0.85
#define HIGH_IPM 1.25
#define VERY_HIGH_IPM 2.5

#define LOW_COOLING 0.75
#define HIGH_COOLING 2.025
#define VERY_HIGH_COOLING 4

#define LOW_RADIATION 0.75
#define HIGH_RADIATION 5
#define VERY_HIGH_RADIATION 10

#define LOW_REINFORCEMENT 0.75
#define HIGH_REINFORCEMENT 1.25
#define VERY_HIGH_REINFORCEMENT 1.5

#define HIGH_DEG_PROTECTION 0.75
#define VERY_HIGH_DEG_PROTECTION 0.5

//Reactor variables

#define REACTOR_STATE_MAINTENANCE 1
#define REACTOR_STATE_IDLE 2
#define REACTOR_STATE_RUNNING 3
#define REACTOR_STATE_MELTDOWN 4
#define REACTOR_STATE_REPAIR 5
#define REACTOR_STATE_REINFORCE 6
#define REACTOR_STATE_REFIT 7

#define WARNING_STATE_NONE 0
#define WARNING_STATE_OVERHEAT 1
#define WARNING_STATE_MELTDOWN 2

#define MAX_CONTROL_RODS 5

//////Stormdrive///////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor
	name = "class IV nuclear storm drive"
	desc = "This monstrosity is what we got when nanotrasen engineers decided to inject magnetically constricted plasma into a nuclear reactor. It's able of outputting an ungodly amount of super-heated plasma, radiation, and fire... But god help you if it ever melts down."
	icon = 'nsv13/goonstation/icons/reactor.dmi'
	icon_state = "reactor_off"
	pixel_x = -16
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	light_color = LIGHT_COLOR_CYAN
	dir = 8
	var/start_threshold = 20 //N mol of constricted plasma to fire it up. N heat to start it up
	var/heat = 0 //How hot are we? In Celcius
	var/target_heat = 200 //For control rods. How hot do we want the reactor to get? We'll attempt to cool the reactor to this temperature.
	var/cooling_power = 10 //How much heat we can drain per tick. Matches up with target_heat
	var/cooling_power_modifier = 1 //Modifier to handle gas cooling values
	var/control_rod_percent = 0 //Handles the insertion depth of the control rods into the reactor
	var/control_rod_integrity = 0 //Aggrigate of the integrity of all control rods
	var/control_rod_modifier = 1 //Handles the effective aggrigate of control rods
	var/control_rod_degradation_modifier = 1 //Modifier to handle protection of control rods
	var/control_rod_installation = FALSE //Check for if a rod is being installed or removed
	var/list/control_rods = list()
	var/heat_gain = 5
	var/heat_gain_modifier = 1 //Not currently used
	var/warning_state = WARNING_STATE_NONE //Are we warning people about a meltdown already? If we are, don't spam them with sounds. Also works for when it's actually exploding
	var/reaction_rate = 0 //N mol of constricted plasma / tick to keep the reaction going, if you shut this off, the reactor will cool.
	var/reaction_rate_modifier = 1 //Modifier to handle gas RoR values
	var/target_reaction_rate = 0
	var/delta_reaction_rate = 0
	var/power_loss = 2 //For subtypes, if you want a less efficient reactor - Not currently used
	var/input_power = 0
	var/input_power_modifier = 1 //Modifier to handle gas power values
	var/state = REACTOR_STATE_IDLE
	var/rod_integrity = 100 //Control rods take damage over time
	var/obj/item/radio/radio //For engineering alerts.
	var/radio_key = /obj/item/encryptionkey/headset_eng
	var/engineering_channel = "Engineering"
	var/can_alert = TRUE //Prevents spamming up the radio channels.
	var/alert_cooldown = 20 SECONDS
	var/last_power_produced = 0 //For UI tracking. Shows your power output.
	var/theoretical_maximum_power = 15000000 //For UI
	var/radiation_modifier = 1 //Modifier to handle gas radiation values
	var/reactor_temperature_nominal = 200 //Base state temperature theshold value
	var/reactor_temperature_hot = 400 //Base state temperature theshold value
	var/reactor_temperature_critical = 650 //Base state temperature theshold value
	var/reactor_temperature_meltdown = 800 //Base state temperature theshold value
	var/reactor_temperature_modifier = 1 //Modifier handling temperature thesholds
	var/reactor_stability = 100 //Stability of the reaction
	var/obj/effect/countdown/stormdrive/stability //Our not so visible stability factor
	var/reactor_id = null //This should match the reactor_id on the reactor control console during INITALIZATION - and should follow this general guideline for standard gameplay: 1 = primary ship, 2 = secondary ship, 3 = syndicate ship -- alternatively you can make players have to link them manually every round
	var/souls_devoured = null //Some questions should not be asked
	var/dumping_fuel = FALSE //Are we dumping our fuel?
	var/list/gas_records = list() //TGUI 3 Graph GOOD
	var/gas_records_length = 120
	var/gas_records_interval = 10
	var/gas_records_next_interval = 0
	var/base_power = 67500 //Base power modifier, this gets attacked by a cubic function
	var/next_slowprocess = 0 //Used for slowing the stormdrive processing down to once per second
	var/reactor_end_times = FALSE //This is the end times for this reactor, we know this because the third error has been made
	var/repairing = FALSE //Flag for SD repairs to stop duplicate actions

	//Gas Variables Here
	var/gas_modifier = 5 //Initially % modifier
	var/constricted_plasma_modifier = 1
	var/plasma_modifier = 1
	var/tritium_modifier = 1
	var/o2_modifier = 1
	var/n2_modifier = 1
	var/co2_modifier = 1
	var/h2o_modifier = 1
	var/nob_modifier = 1
	var/n2o_modifier = 1
	var/no2_modifier = 1
	var/bz_modifier = 1
	var/stim_modifier = 1
	var/pluoxium_modifier = 1
	var/nucleium_modifier = 1

///////// REACTOR SUBTYPES ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/syndicate
	radio_key = /obj/item/encryptionkey/syndicate
	engineering_channel = "Syndicate"

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/solgov
	name = "class V ionic storm drive"
	desc = "A highly advanced ionic drive used by SolGov to power their space vessels. Through the application of inverse-ions to the endostorm, more efficient matter to energy conversion is achieved."
	base_power = 85000 //26% more power than class 4
	icon = 'nsv13/goonstation/icons/reactor_solgov.dmi'
	theoretical_maximum_power = 20000000

//////// REACTOR INTERACTIONS /////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/attackby(obj/item/I, mob/living/carbon/user, params)
	if(repairing)
		return
	if(istype(I, /obj/item/control_rod))
		if(control_rod_installation) //check for if someone is already moving rods
			to_chat(user, "<span class='notice'>A control rod is already being installed into [src].</span>")
			return
		if(state >= REACTOR_STATE_MELTDOWN)
			to_chat(user, "<span class='notice'>It is definitely too late to add [src] now.")
			return
		switch(state)
			if(REACTOR_STATE_IDLE) //while we could allow this here, may as well do it safely
				to_chat(user, "<span class='warning'>[src] is not in maintenance mode! Enagage maintenance safety protocols before opening the lid!</span>")
				return FALSE
			if(REACTOR_STATE_MAINTENANCE)
				if(control_rods.len >= MAX_CONTROL_RODS)
					to_chat(user, "<span class='notice'>[src] already has [MAX_CONTROL_RODS] mounted.</span>")
					return
				else
					to_chat(user, "<span class='notice'>You begin mounting the [I.name] to the reactor control coupling...</span>")
					control_rod_installation = TRUE
					if(!do_after(user, 50, target = src))
						control_rod_installation = FALSE
						return
					control_rod_installation = FALSE
					if ( state == REACTOR_STATE_IDLE ) // Need to recheck the maintenance mode in case someone switched it while pushing in rods
						to_chat(user, "<span class='warning'>[src] is not in maintenance mode! Enagage maintenance safety protocols before opening the lid!</span>")
						return FALSE
					to_chat(user, "<span class='notice'>You mount the [I.name] to the reactor control coupleing. </span>")
					control_rods += I
					I.forceMove(src)
					update_icon()
					handle_control_rod_efficiency()
					handle_control_rod_integrity()
			if(REACTOR_STATE_RUNNING)
				if(alert("[src] is not in maintenance mode! Manually inserting a control rod into an active nuclear reaction would probably be fatal.",name,"Continue","Reconsider") == "Continue" && Adjacent(user))
					if(control_rods.len >= MAX_CONTROL_RODS)
						to_chat(user, "<span class='notice'>[src] already has [MAX_CONTROL_RODS] control rods installed.</span>")
						return
					else
						to_chat(user, "<span class='notice'>You begin mounting the [I.name] to the reactor control coupling...</span>")
						to_chat(user, "<span class='danger'>A blue glow envelopes your hands!</span>")
						control_rod_installation = TRUE
						empulse(3, 5)
						user.radiation += 250 * radiation_modifier
						radiation_pulse(src, 1000 * radiation_modifier, 5)
						playsound(src, 'sound/items/welder.ogg', 100, TRUE) //temp - find a better sound
						if(!do_after(user, 50, target = src))
							control_rod_installation = FALSE
							return
						to_chat(user, "<span class='notice'>You mount the [I.name] to the reactor control coupleing. </span>")
						control_rod_installation = FALSE
						control_rods += I
						I.forceMove(src)
						update_icon()
						empulse(3, 5)
						user.radiation += 250 * radiation_modifier
						radiation_pulse(src, 1000 * radiation_modifier, 5)
						playsound(src, 'sound/items/welder.ogg', 100, TRUE) //temp - find a better sound
						handle_control_rod_efficiency()
						handle_control_rod_integrity()
	if(I.tool_behaviour == TOOL_MULTITOOL)
		if(!multitool_check_buffer(user, I))
			return
		var/obj/item/multitool/M = I
		M.buffer = src
		playsound(src, 'sound/items/flashlight_on.ogg', 100, TRUE)
		to_chat(user, "<span class='notice'>Buffer loaded</span>")

	if(I.tool_behaviour == TOOL_SHOVEL)
		if(icon_state != "broken")
			return
		to_chat(user, "<span class='notice'>You start cleaning out the reactor pit...</span>")
		repairing = TRUE
		if(!do_after(user, 5 SECONDS, target=src))
			repairing = FALSE
			return
		to_chat(user, "<span class='warning'>Some of the sludge spills on the floor!</span>")
		var/obj/effect/landmark/nuclear_waste_spawner/weak/sludge_spawner = new (get_turf(src))
		if (sludge_spawner)
			sludge_spawner.fire()
		state = REACTOR_STATE_REPAIR
		repairing = FALSE
		update_icon()

	if(istype(I, /obj/item/stack/sheet/duranium))
		var/obj/item/stack/sheet/duranium/D = I
		if(state == REACTOR_STATE_REPAIR)
			if(D.get_amount() < 25)
				to_chat(user, "<span class='notice'>You need at least twenty five pieces of durnaium to reline the reactor pit!</span>")
				return
			to_chat(user, "<span class='notice'>You start relining the reactor pit with duranium...</span>")
			repairing = TRUE
			if(!do_after(user, 5 SECONDS, target=src) || !Adjacent(user))
				repairing = FALSE
				return
			D.use(25)
			to_chat(user, "<span class='notice'>The reactor pit has been relined with duranium")
			state = REACTOR_STATE_REINFORCE
			repairing = FALSE
			update_icon()

	if(istype(I, /obj/item/stormdrive_core))
		if(state == REACTOR_STATE_REFIT)
			to_chat(user, "<span class='notice'>You start installing the reactor core...</span>")
			repairing = TRUE
			if(!do_after(user, 5 SECONDS, target=src) || !Adjacent(user))
				repairing = FALSE
				return
			to_chat(user, "<span class='notice'>The reactor core has been installed.")
			repairing = FALSE
			qdel(I)
			control_rods = list()
			for(var/atom/A in contents)
				qdel(A)
			deactivate() //Factory Reset Approved

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/welder_act(mob/user, obj/item/tool)
	. = FALSE
	if(state == REACTOR_STATE_REINFORCE)
		to_chat(user, "<span class='notice'>You start reinforcing the reactor shielding...</span>")
		if(tool.use_tool(src, user, 5 SECONDS, volume=100))
			to_chat(user, "<span class='notice'>The reactor shielding has been reinforced.</span>")
			state = REACTOR_STATE_REFIT
			update_icon()
			return TRUE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/bullet_act(obj/item/projectile/Proj)
	if(state == REACTOR_STATE_RUNNING)
		var/turf/L = loc
		if(!istype(L))
			return FALSE
		if(!istype(Proj.firer, /obj/structure/particle_accelerator/particle_emitter))
			investigate_log("has been hit by [Proj] fired by [key_name(Proj.firer)]", INVESTIGATE_ENGINES)
		if(Proj.flag != "bullet")
			reactor_stability -= Proj.damage / 15
		else
			reactor_stability -= Proj.damage / 100 //It is pretty durable
		return BULLET_ACT_HIT

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/blob_act(obj/structure/blob/B)
	if(state == REACTOR_STATE_RUNNING)
		if(heat < 400)
			reactor_stability -= B.obj_integrity / 10
			B.take_damage(100, BURN)
		else
			reactor_stability -= B.obj_integrity / 10
			B.take_damage(1000, BURN)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/attack_alien(mob/living/carbon/alien/A)
	if(state == REACTOR_STATE_RUNNING)
		if(heat < 400)
			reactor_stability -= 1.5
			A.take_bodypart_damage(burn = 20)
		else
			reactor_stability -= 1.5
			A.take_bodypart_damage(burn = 75)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/attack_hand(mob/living/carbon/user)
	.=..()
	if(state >= REACTOR_STATE_MELTDOWN)
		return
	ui_interact(user)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StormdriveControlRods")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	if(!in_range(src, usr))
		return
	switch(action)
		if("remove_rod")
			if(control_rod_installation)
				to_chat(usr, "<span class='notice'>A control rod is already being removed from [src].</span>")
				return
			switch(state)
				if(REACTOR_STATE_IDLE)
					to_chat(usr, "<span class='warning'>[src] is not in maintenance mode! Enagage maintenance safety protocols before opening the lid!</span>")
					return FALSE
				if(REACTOR_STATE_MAINTENANCE)
					if(control_rods.len <= 0)
						to_chat(usr, "<span class='notice'> [src] has no control rods mounted.</span>")
						return
					else
						to_chat(usr, "<span class='notice'>You begin removing a control rod from the [src]...</span>")
						control_rod_installation = TRUE
						if(!do_after(usr, 50, target = src))
							control_rod_installation = FALSE
							return
						control_rod_installation = FALSE
						if ( state == REACTOR_STATE_IDLE ) // Need to recheck the maintenance mode in case someone switched it while pulling out rods
							to_chat(usr, "<span class='warning'>[src] is not in maintenance mode! Enagage maintenance safety protocols before opening the lid!</span>")
							return FALSE
						to_chat(usr, "<span class='notice'>You remove the control rod from the [src].</span>")
						var/obj/item/control_rod/cr = locate(params["target"])
						control_rods -= cr
						cr?.forceMove(get_turf(usr))
						update_icon()
						handle_control_rod_efficiency()
						handle_control_rod_integrity()
				if(REACTOR_STATE_RUNNING)
					if(alert("[src] is not in maintenance mode! Manually inserting a control rod into an active nuclear reaction would probably be fatal.",name,"Continue","Reconsider") != "Continue" && Adjacent(usr))
						if(control_rods.len <= 0)
							to_chat(usr, "<span class='notice'> [src] has no control rods mounted.</span>")
							return
					else
						var/prot = 0
						var/mob/living/carbon/human/H = usr
						if(H.gloves)
							var/obj/item/clothing/gloves/G = H.gloves
							if(G.max_heat_protection_temperature)
								prot = (G.max_heat_protection_temperature > heat)
						if(prot > 0 || HAS_TRAIT(usr, TRAIT_RESISTHEAT) || HAS_TRAIT(usr, TRAIT_RESISTHEATHANDS)) //Investigate RESISTTHEATHANDS and potentially check for other solutions to this
							to_chat(usr, "<span class='notice'>You begin removing a control rod from the [src]...</span>")
							to_chat(usr, "<span class='danger'>A blue glow envelopes your hands!</span>")
							control_rod_installation = TRUE
							var/obj/item/bodypart/affecting = H.get_bodypart("[(usr.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
							if(affecting && affecting.receive_damage( 0, 20 )) // partially damage the hand
								H.update_damage_overlays()
							empulse(3, 5)
							H.radiation += (heat/2) * radiation_modifier
							radiation_pulse(src, (heat * 2) * radiation_modifier, 5)
							playsound(src, 'sound/items/welder.ogg', 100, TRUE) //temp - find a better sound
							if(!do_after(usr, 50, target = src))
								control_rod_installation = FALSE
								return
							to_chat(usr, "<span class='notice'>You remove the control rod from the [src].</span>")
							var/obj/item/control_rod/cr = locate(params["target"])
							control_rods -= cr
							cr?.forceMove(get_turf(usr))
							update_icon()
							control_rod_installation = FALSE
							if(affecting && affecting.receive_damage( 0, 20 )) //damage it even more
								H.update_damage_overlays()
							empulse(3, 5)
							H.radiation += (heat/2) * radiation_modifier
							radiation_pulse(src, (heat * 2) * radiation_modifier, 5)
							playsound(src, 'sound/items/welder.ogg', 100, TRUE) //temp - find a better sound
							handle_control_rod_efficiency()
							handle_control_rod_integrity()
							return
						else
							var/obj/item/bodypart/affecting = H.get_bodypart("[(usr.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
							if(affecting && affecting.receive_damage( 0, 75 )) // 75 burn damage should disable the body part
								to_chat(usr, "<span class='danger'><B>The control rod melts through your hand!</B></span>")
								playsound(src, 'sound/effects/phasein.ogg', 100, TRUE) //temp - find a better sound
								if(prob(25))
									affecting.dismember(damtype) //Goodbye arm - Investigate how to delete this severed limb
								H.update_damage_overlays()
								return


/obj/machinery/atmospherics/components/binary/stormdrive_reactor/ui_data(mob/user)
	var/list/data = list()
	var/list/control_rod_data = list()
	for(var/obj/item/control_rod/C in contents)
		var/list/control_rod_info = list()
		control_rod_info["name"] = C.name
		control_rod_info["id"] = "\ref[C]"
		control_rod_info["health"] = C.rod_integrity
		control_rod_info["max_health"] = initial(C.rod_integrity)
		control_rod_data[++control_rod_data.len] = control_rod_info
	data["mounted_control_rods"] = control_rod_data
	return data

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/engage_maintenance()
	if(state == REACTOR_STATE_IDLE)
		deactivate()
		state = REACTOR_STATE_MAINTENANCE
		update_icon()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/disengage_maintenance()
	if(state == REACTOR_STATE_MAINTENANCE)
		state = REACTOR_STATE_IDLE
		icon_state = initial(icon_state)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/deactivate()
	if(state == REACTOR_STATE_RUNNING)
		send_alert("Fission reaction terminated. Reactor now off-line.")
	icon_state = initial(icon_state)
	if(state != REACTOR_STATE_IDLE) //protect our warmup
		heat = 0
	last_power_produced = 0 //Update UI to show that it's not making power now
	reaction_rate = 0
	reactor_stability = 0
	if(state != REACTOR_STATE_MAINTENANCE)
		state = REACTOR_STATE_IDLE //Force reactor restart.
	set_light(0)
	var/area/AR = get_area(src)
	AR.ambient_buzz = 'nsv13/sound/ambience/shipambience.ogg'

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.listening = 0
	radio.recalculateChannels()
	stability = new(src)
	stability.start()
	gas_records["constricted_plasma"] = list()
	gas_records["plasma"] = list()
	gas_records["tritium"] = list()
	gas_records["o2"] = list()
	gas_records["n2"] = list()
	gas_records["co2"] = list()
	gas_records["water_vapour"] = list()
	gas_records["nob"] = list()
	gas_records["n2o"] = list()
	gas_records["no2"] = list()
	gas_records["bz"] = list()
	gas_records["stim"] = list()
	gas_records["pluoxium"] = list()
	gas_records["nucleium"] = list()
	handle_gas_modifiers()

/////// REACTOR START PROCS ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/bullet_act(obj/item/projectile/energy/accelerated_particle/P, def_zone, piercing_hit = FALSE)
	if(istype(P))
		heat += P.energy
		try_start()
	else
		. = ..()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/try_start()

	if(state == REACTOR_STATE_RUNNING || state == REACTOR_STATE_MELTDOWN || state == REACTOR_STATE_MAINTENANCE)
		return FALSE
	icon_state = "reactor_starting"
	var/datum/gas_mixture/air1 = airs[1]
	var/fuel_check = air1.get_moles(GAS_PLASMA) * LOW_ROR + \
					air1.get_moles(GAS_CONSTRICTED_PLASMA) * NORMAL_ROR + \
					air1.get_moles(GAS_CO2) * HINDER_ROR + \
					air1.get_moles(GAS_H2O) * HINDER_ROR + \
					air1.get_moles(GAS_TRITIUM) * HIGH_ROR + \
					air1.get_moles(GAS_HYPERNOB) * REALLY_HINDER_ROR

	if(fuel_check >= start_threshold && heat >= start_threshold) //Checking equivalent of 20 moles of fuel and is hot enough
		heat = start_threshold+10 //Avoids it getting heated up to 10000 by the PA, then turning it on, then getting insta meltdown.
		visible_message("<span class='danger'>[src] starts to glow an ominous blue!</span>")
		icon_state = "reactor_on"
		state = REACTOR_STATE_RUNNING
		reactor_stability = 100
		set_light(5)
		var/startup_sound = pick('nsv13/sound/effects/ship/reactor/startup.ogg', 'nsv13/sound/effects/ship/reactor/startup2.ogg')
		playsound(loc, startup_sound, 100)
		send_alert("Fission reaction initiated. Reactor now on-line.", override=TRUE)
		var/area/AR = get_area(src)
		AR.ambient_buzz = 'nsv13/sound/ambience/engineering.ogg'
		if(reaction_rate <= 0)
			reaction_rate = 5
		SSblackbox.record_feedback("tally", "engine_stats", 1, "started")
		SSblackbox.record_feedback("tally", "engine_stats", 1, "stormdrive")
		return TRUE
	return FALSE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/lazy_startup() //Admin only command to instantly start a reactor
	if(control_rods.len <= 0)
		for(var/I = 0, I < MAX_CONTROL_RODS, I++) //install control rods
			control_rods += new /obj/item/control_rod(src)
		handle_control_rod_integrity()

	heat = start_threshold+10
	var/datum/gas_mixture/air1 = airs[1]
	air1.adjust_moles(GAS_CONSTRICTED_PLASMA, 1000)
	air1.adjust_moles(GAS_O2, 500)
	air1.adjust_moles(GAS_N2, 500)
	try_start()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/juice_up(var/datum/gas/juice, var/quantity) //Admin command to add a specified amount of chosen gas to the drive
	var/datum/gas_mixture/air1 = airs[1]
	air1.adjust_moles(juice.id, quantity)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_gas_modifiers() //Sets up the minor differences in each instance of Stormdrive
	constricted_plasma_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	plasma_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	tritium_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	o2_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	n2_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	co2_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	h2o_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	nob_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	n2o_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	no2_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	bz_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	stim_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	pluoxium_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100
	nucleium_modifier = (rand((100 - gas_modifier), (100 + gas_modifier))) / 100

/////// REACTOR PROCESSING ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/process()
	update_parents() //sanitary check
	if(next_slowprocess < world.time)
		slowprocess() //Process the Stormdrive
		next_slowprocess = world.time + 1 SECONDS //Set to wait for another second before processing again, we don't need to process more than once a second

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/slowprocess()
	if(state >= REACTOR_STATE_REPAIR)
		return

	if(state == REACTOR_STATE_MELTDOWN)
		radiation_pulse(src, (1000 * radiation_modifier), 10)
		return

	if(reactor_end_times)
		handle_reactor_destabilization()

	if(dumping_fuel)
		var/max_output_pressure = 4500
		var/datum/gas_mixture/air1 = airs[1]
		var/datum/gas_mixture/air2 = airs[2]
		var/output_starting_pressure = air2.return_pressure()
		if(output_starting_pressure >= max_output_pressure)
			send_alert("Error: Dump pressure line exceeds pump pressure capacities. Process aborted.")
			dumping_fuel = FALSE
		else if(output_starting_pressure < max_output_pressure)
			var/moles = air1.total_moles()
			var/datum/gas_mixture/buffer = air1.remove(min(25, moles)) //This doesn't appear to actually work. Feature.
			var/heat_kelvin = heat + 273.15
			air2.merge(buffer)
			air2.set_temperature(heat_kelvin) //Gets spicy
			update_parents()

	if(state != REACTOR_STATE_RUNNING || heat <= start_threshold)
		deactivate()
		return

	var/datum/gas_mixture/air1 = airs[1]
	var/nucleium_power_reduction = 0

	var/fuel_check = air1.total_moles() <= 0 ? 0 : ((air1.get_moles(GAS_PLASMA) + air1.get_moles(GAS_CONSTRICTED_PLASMA) + air1.get_moles(GAS_TRITIUM)) / air1.total_moles()) * 100
	if(air1.total_moles() >= reaction_rate && fuel_check >= 12.5) //1:8 ratio
		var/datum/gas_mixture/reaction_chamber_gases = air1.remove(reaction_rate)

		//calculate the actual fuel mix
		var/chamber_ror_total = reaction_chamber_gases.get_moles(GAS_PLASMA) * (LOW_ROR * plasma_modifier) + \
								reaction_chamber_gases.get_moles(GAS_CONSTRICTED_PLASMA) * (NORMAL_ROR * constricted_plasma_modifier) + \
								reaction_chamber_gases.get_moles(GAS_TRITIUM) * (HIGH_ROR * tritium_modifier) + \
								reaction_chamber_gases.get_moles(GAS_N2) * (HINDER_ROR * n2_modifier) + \
								reaction_chamber_gases.get_moles(GAS_H2O) * (HINDER_ROR * h2o_modifier) + \
								reaction_chamber_gases.get_moles(GAS_HYPERNOB) * (REALLY_HINDER_ROR * nob_modifier)
		reaction_rate_modifier = chamber_ror_total / reaction_rate

		//checking for gas modifiers
		var/chamber_ipm_total = reaction_rate + reaction_chamber_gases.get_moles(GAS_TRITIUM) * (HIGH_IPM * tritium_modifier) + \
												reaction_chamber_gases.get_moles(GAS_O2) * (HIGH_IPM * o2_modifier) + \
												reaction_chamber_gases.get_moles(GAS_PLUOXIUM) * (HIGH_IPM * pluoxium_modifier) + \
												reaction_chamber_gases.get_moles(GAS_STIMULUM) * (VERY_HIGH_IPM * stim_modifier) - \
												reaction_chamber_gases.get_moles(GAS_PLASMA) * (MEDIOCRE_IPM * plasma_modifier) - \
												reaction_chamber_gases.get_moles(GAS_CO2) * (LOW_IPM * co2_modifier) - \
												reaction_chamber_gases.get_moles(GAS_HYPERNOB) * (LOW_IPM * nob_modifier)
		input_power_modifier = chamber_ipm_total / reaction_rate

		var/chamber_cooling_total = reaction_rate + reaction_chamber_gases.get_moles(GAS_HYPERNOB) * (VERY_HIGH_COOLING * nob_modifier) + \
													reaction_chamber_gases.get_moles(GAS_NITRYL) * (HIGH_COOLING * no2_modifier) + \
													reaction_chamber_gases.get_moles(GAS_N2) * (HIGH_COOLING * n2_modifier) + \
													reaction_chamber_gases.get_moles(GAS_CO2) * (HIGH_COOLING * co2_modifier) - \
													reaction_chamber_gases.get_moles(GAS_TRITIUM) * (LOW_COOLING * tritium_modifier) - \
													reaction_chamber_gases.get_moles(GAS_NUCLEIUM) * (LOW_COOLING * nucleium_modifier) - \
													reaction_chamber_gases.get_moles(GAS_STIMULUM) * (LOW_COOLING * stim_modifier)
		cooling_power_modifier = chamber_cooling_total / reaction_rate

		var/chamber_radiation_total = reaction_rate + reaction_chamber_gases.get_moles(GAS_TRITIUM) * (VERY_HIGH_RADIATION * tritium_modifier) + \
													reaction_chamber_gases.get_moles(GAS_PLASMA) * (HIGH_RADIATION * plasma_modifier) + \
													reaction_chamber_gases.get_moles(GAS_NUCLEIUM) * (HIGH_RADIATION * nucleium_modifier) + \
													reaction_chamber_gases.get_moles(GAS_BZ) * (HIGH_RADIATION * bz_modifier) - \
													reaction_chamber_gases.get_moles(GAS_STIMULUM) * (LOW_RADIATION * stim_modifier) - \
													reaction_chamber_gases.get_moles(GAS_NITRYL) * (LOW_RADIATION * no2_modifier)
		radiation_modifier = chamber_radiation_total / reaction_rate

		var/chamber_reinforcement_total = reaction_rate + reaction_chamber_gases.get_moles(GAS_PLUOXIUM) * (VERY_HIGH_REINFORCEMENT * pluoxium_modifier) + \
														reaction_chamber_gases.get_moles(GAS_TRITIUM) * (HIGH_REINFORCEMENT * tritium_modifier) + \
														reaction_chamber_gases.get_moles(GAS_NITROUS) * (HIGH_REINFORCEMENT * no2_modifier) - \
														reaction_chamber_gases.get_moles(GAS_NUCLEIUM) * (LOW_REINFORCEMENT * nucleium_modifier) - \
														reaction_chamber_gases.get_moles(GAS_STIMULUM) * (LOW_REINFORCEMENT * stim_modifier) - \
														reaction_chamber_gases.get_moles(GAS_BZ) * (LOW_REINFORCEMENT * bz_modifier)
		reactor_temperature_modifier = chamber_reinforcement_total / reaction_rate

		var/chamber_degradation_total = reaction_rate + reaction_chamber_gases.get_moles(GAS_NITROUS) * (HIGH_DEG_PROTECTION * no2_modifier) + \
														reaction_chamber_gases.get_moles(GAS_HYPERNOB) * (VERY_HIGH_DEG_PROTECTION * nob_modifier) + \
														reaction_chamber_gases.get_moles(GAS_PLUOXIUM) * (HIGH_DEG_PROTECTION * pluoxium_modifier)
		control_rod_degradation_modifier = chamber_degradation_total / reaction_rate

		nucleium_power_reduction = reaction_chamber_gases.get_moles(GAS_NUCLEIUM) * 1000 //nucleium

		heat_gain = initial(heat_gain) + reaction_rate
		reaction_chamber_gases.clear()

		if(air1.total_moles() > ((reaction_rate * 12) + 20)) //Overpressurized input
			reactor_stability -= 0.51 //Enough to counter below

		if(fuel_check >= 25) //1:4 fuel ratio
			if(reactor_stability < 100)
				reactor_stability += 0.5

		else
			reactor_stability -= 0.01 //Unideal ratio leads to destabilization

	else
		reactor_stability --
		heat_gain = -5 //No plasma to react, so the reaction slowly dies off.

	input_power = ((heat/150)**3) * input_power_modifier //Higher temperature = more power. Crank the temperature up, stop being so scared.
	var/power_produced = base_power
	last_power_produced = max(0,(power_produced*input_power) - nucleium_power_reduction)

	handle_reaction_rate()
	handle_heat()
	handle_temperature_reinforcement()
	handle_ftl_fuel_production()
	handle_gas_records()
	handle_reactor_stability()
	update_icon()
	radiation_pulse(src, (heat * radiation_modifier), 2)
	ambient_temp_bleed()

	if(last_power_produced > 3000000) //3MW
		handle_overload()

	var/turf/T = get_turf(src)
	var/obj/structure/cable/C = T.get_cable_node()
	if(!C || !C.powernet)
		return
	else
		C.powernet.newavail += last_power_produced

//////// PROCESSING PROCS ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/ambient_temp_bleed()
	var/turf/open/L = get_turf(src)
	if(!istype(L) || !(L.air))
		return
	var/datum/gas_mixture/env = L.return_air()
	var/heat_kelvin = heat + 273.15
	if(env.return_temperature() <= heat_kelvin)
		var/delta_env = heat_kelvin - env.return_temperature()
		var/temperature = env.return_temperature()
		env.set_temperature(temperature += delta_env / 2)
		air_update_turf()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/can_cool()
	for(var/obj/item/control_rod/cr in contents)
		if(cr.rod_integrity <= 0 && !istype(cr, /obj/item/control_rod/irradiated)) //tag any failed rods
			control_rods -= cr
			qdel(cr)
			control_rods += new /obj/item/control_rod/irradiated(src)
			handle_control_rod_efficiency()
		if(prob(80 * control_rod_degradation_modifier))
			cr.rod_integrity -= ((input_power/75000) * control_rod_degradation_modifier) * control_rod_percent //control rod decay occurs here
	handle_control_rod_integrity()
	if(control_rod_integrity < 0)
		control_rod_integrity = 0
		if(state == REACTOR_STATE_RUNNING)
			send_alert("DANGER: Primary control rods have failed!")
		return FALSE
	if(control_rod_integrity <= 35 && warning_state <= WARNING_STATE_NONE) //If there isn't a more important thing to notify them about, engineers should be told that their rods are failing.
		if(state == REACTOR_STATE_RUNNING)
			send_alert("WARNING: Reactor control rods failing at [control_rod_integrity]% integrity, intervention required to avoid possible meltdown.")
	if(control_rod_integrity > 0)
		return TRUE //TODO: Check control rod health
	else
		return FALSE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_control_rod_efficiency()
	if(control_rods.len > 0)
		var/control_rod_effectiveness_total = 0
		for(var/obj/item/control_rod/cr in contents)
			control_rod_effectiveness_total += cr.rod_effectiveness
		control_rod_modifier = control_rod_effectiveness_total / control_rods.len
	else
		control_rod_modifier = 1

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_control_rod_integrity()
	if(control_rods.len > 0)
		var/control_rod_integrity_total = 0
		for(var/obj/item/control_rod/cr in contents)
			control_rod_integrity_total += cr.rod_integrity
		control_rod_integrity = control_rod_integrity_total / control_rods.len
	else
		control_rod_integrity = 0

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_heat()
	heat += heat_gain
	target_heat = (-1)+2**(0.1*((100-control_rod_percent) * control_rod_modifier)) //Let there be math
	if(heat > target_heat+((cooling_power * cooling_power_modifier)-heat_gain)) //If it's hotter than the desired temperature, + our cooling power, we need to cool it off.
		if(can_cool())
			if(control_rod_percent > 0)
				heat -= cooling_power * cooling_power_modifier

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_reaction_rate()
	target_reaction_rate = (0.5+(1e-03*((100-control_rod_percent) * control_rod_modifier)**2) * reaction_rate_modifier) + 1e-05*(heat**2)  //let the train derail!
	delta_reaction_rate = target_reaction_rate - reaction_rate
	reaction_rate += delta_reaction_rate/2

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_ftl_fuel_production()
	if(heat > initial(reactor_temperature_hot))
		var/max_output_pressure = 4500
		var/datum/gas_mixture/air1 = airs[1]
		var/datum/gas_mixture/air2 = airs[2]
		var/output_starting_pressure = air2.return_pressure()
		var/heat_kelvin = heat + 273.15
		var/fuel_amount = air1.get_moles(GAS_PLASMA) + air1.get_moles(GAS_CONSTRICTED_PLASMA) + air1.get_moles(GAS_TRITIUM)
		if(output_starting_pressure >= max_output_pressure) //if pressured capped, nucleium backs up into the drive
			air1.adjust_moles(GAS_NUCLEIUM, ((fuel_amount / reaction_rate) / 10) * input_power_modifier)
			air1.set_temperature(heat_kelvin)
			update_parents()
		else
			air2.adjust_moles(GAS_NUCLEIUM, (reaction_rate / 10) * input_power_modifier)
			air2.set_temperature(heat_kelvin)
			update_parents()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_temperature_reinforcement() //Adjusting temperature thresholds
	var/delta_rt_nominal = (initial(reactor_temperature_nominal) * reactor_temperature_modifier) - reactor_temperature_nominal
	reactor_temperature_nominal += delta_rt_nominal / 2
	var/delta_rt_hot = (initial(reactor_temperature_hot) * reactor_temperature_modifier) - reactor_temperature_hot
	reactor_temperature_hot += delta_rt_hot / 2
	var/delta_rt_critical = (initial(reactor_temperature_critical) * reactor_temperature_modifier) - reactor_temperature_critical
	reactor_temperature_critical += delta_rt_critical / 2
	var/delta_rt_meltdown = (initial(reactor_temperature_meltdown) * reactor_temperature_modifier) - reactor_temperature_meltdown
	reactor_temperature_meltdown += delta_rt_meltdown / 2

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_gas_records()
	if(world.time >= gas_records_next_interval)
		gas_records_next_interval = world.time + gas_records_interval

		var/datum/gas_mixture/air1 = airs[1]

		var/list/constricted_plasma = gas_records["constricted_plasma"]
		constricted_plasma += (air1.get_moles(GAS_CONSTRICTED_PLASMA) / air1.total_moles()) * 100
		if(constricted_plasma.len > gas_records_length)
			constricted_plasma.Cut(1, 2)
		var/list/plasma = gas_records["plasma"]
		plasma += (air1.get_moles(GAS_PLASMA) / air1.total_moles()) * 100
		if(plasma.len > gas_records_length)
			plasma.Cut(1, 2)
		var/list/tritium = gas_records["tritium"]
		tritium += (air1.get_moles(GAS_TRITIUM) / air1.total_moles()) * 100
		if(tritium.len > gas_records_length)
			tritium.Cut(1, 2)
		var/list/o2 = gas_records["o2"]
		o2 += (air1.get_moles(GAS_O2) / air1.total_moles()) * 100
		if(o2.len > gas_records_length)
			o2.Cut(1, 2)
		var/list/n2 = gas_records["n2"]
		n2 += (air1.get_moles(GAS_N2) / air1.total_moles()) * 100
		if(n2.len > gas_records_length)
			n2.Cut(1, 2)
		var/list/co2 = gas_records["co2"]
		co2 += (air1.get_moles(GAS_CO2) / air1.total_moles()) * 100
		if(co2.len > gas_records_length)
			co2.Cut(1, 2)
		var/list/water_vapour = gas_records["water_vapour"]
		water_vapour += (air1.get_moles(GAS_H2O) / air1.total_moles()) * 100
		if(water_vapour.len > gas_records_length)
			water_vapour.Cut(1, 2)
		var/list/nob = gas_records["nob"]
		nob += (air1.get_moles(GAS_HYPERNOB) / air1.total_moles()) * 100
		if(nob.len > gas_records_length)
			nob.Cut(1, 2)
		var/list/n2o = gas_records["n2o"]
		n2o += (air1.get_moles(GAS_NITROUS) / air1.total_moles()) * 100
		if(n2o.len > gas_records_length)
			n2o.Cut(1, 2)
		var/list/no2 = gas_records["no2"]
		no2 += (air1.get_moles(GAS_NITRYL) / air1.total_moles()) * 100
		if(no2.len > gas_records_length)
			no2.Cut(1, 2)
		var/list/bz = gas_records["bz"]
		bz += (air1.get_moles(GAS_BZ) / air1.total_moles()) * 100
		if(bz.len > gas_records_length)
			bz.Cut(1, 2)
		var/list/stim = gas_records["stim"]
		stim += (air1.get_moles(GAS_STIMULUM) / air1.total_moles()) * 100
		if(stim.len > gas_records_length)
			stim.Cut(1, 2)
		var/list/pluoxium = gas_records["pluoxium"]
		pluoxium += (air1.get_moles(GAS_PLUOXIUM) / air1.total_moles()) * 100
		if(pluoxium.len > gas_records_length)
			pluoxium.Cut(1, 2)
		var/list/nucleium = gas_records["nucleium"]
		nucleium += (air1.get_moles(GAS_NUCLEIUM) / air1.total_moles()) * 100
		if(nucleium.len > gas_records_length)
			nucleium.Cut(1, 2)

//////// STABILITY PROCS ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/Bumped(atom/movable/A)
	if(!ismob(A))
		return
	var/mob/living/carbon/C = A
	if(C.has_status_effect(/datum/status_effect/incapacitating/knockdown)) //check to see if they are valid prey
		switch(reactor_stability)
			if(50 to INFINITY) //Concussions for the Concussiondrive
				if(C.get_bodypart(BODY_ZONE_HEAD))
					var/obj/item/bodypart/affecting = C.get_bodypart(BODY_ZONE_HEAD)
					if(affecting && affecting.receive_damage(5)) //minor brute damage
						if(!istype(C.head, /obj/item/clothing/head/helmet))
							C.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5, 60)
							C.update_damage_overlays() //do i still need this??

					C.visible_message("<span class='warning'>You bonk your head on the outcasing of the [src]</span>")
					playsound(src, 'sound/effects/bang.ogg', 100, TRUE) //temp - find a better sound
					return
			if(25 to 50) //Flesh for the Fleshdrive
				if(C.get_bodypart(BODY_ZONE_L_LEG))
					var/obj/item/bodypart/affecting = C.get_bodypart(BODY_ZONE_L_LEG)
					C.visible_message("<span class='danger'><B>A blue glow envelops your leg!</B></span>")
					affecting.dismember(damtype) // can't seem to find a command for deleting the limb, rather than dropping it
					playsound(src, 'sound/effects/phasein.ogg', 100, TRUE) //temp - find a better sound

					var/datum/gas_mixture/air1 = airs[1]
					air1.adjust_moles(GAS_PLASMA, 25)
					return

				if(C.get_bodypart(BODY_ZONE_R_LEG))
					var/obj/item/bodypart/affecting = C.get_bodypart(BODY_ZONE_R_LEG)
					C.visible_message("<span class='danger'><B>A blue glow envelops your leg!</B></span>")
					affecting.dismember(damtype)
					playsound(src, 'sound/effects/phasein.ogg', 100, TRUE) //temp - find a better sound

					var/datum/gas_mixture/air1 = airs[1]
					air1.adjust_moles(GAS_PLASMA, 25)
					return

			if(-INFINITY to 25) //Souls for the Souldrive
				C.visible_message("<span class='danger'><B>Blue particles surround your body!</B></span>")
				C.gib()
				playsound(src, 'sound/effects/phasein.ogg', 100, TRUE) //temp - find a better sound

				handle_souldrive()

				var/datum/gas_mixture/air1 = airs[1]
				air1.adjust_moles(GAS_PLASMA, 100)
				return

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_souldrive()
	var/json_file = file("data/npc_saves/Stormdrive.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	souls_devoured = json["souls_devoured"]
	souls_devoured ++
	json["souls_devoured"] = souls_devoured
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(json))

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_reactor_stability()
	if(reactor_stability > 100)
		reactor_stability = 100
	if(reactor_stability < 0)
		reactor_stability = 0

	if(prob((100 - reactor_stability) / 3)) //Localized gravity event as a warning
		grav_pull()
		playsound(loc, 'sound/effects/empulse.ogg', 100)
		for(var/mob/living/M in orange(((heat / 40) + 5), src))
			shake_with_inertia(M, 2, 1)

	if(reactor_stability < 75)
		if(prob((100 - reactor_stability) / 4)) //Destabilize the balance a little
			if(prob(50))
				heat += reaction_rate * rand(5,8)
			else
				reaction_rate += reaction_rate / rand(3,5)

	if(reactor_stability < 15)
		if(prob(1))
			var/anom = rand(1,10)
			switch(anom)
				if(1 to 4)
					new /obj/effect/anomaly/stormdrive/surge(src, rand(2000, 5000))
				if(5 to 8)
					new /obj/effect/anomaly/stormdrive/sheer(src, rand(2000, 5000))
				if(9 to 10)
					new /obj/effect/anomaly/stormdrive/squall(src, rand(2000, 5000))
			reactor_stability += 15 //Spike that stab back up
			playsound(loc, 'sound/effects/empulse.ogg', 100)

	switch(reactor_stability) //Entropy nudge
		if(0 to 1)
			heat += 1
		if(1 to 15)
			heat += 0.5
		if(15 to 30)
			heat += 0.1
		if(30 to 75)
			heat += 0.01

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/grav_pull()
	for(var/obj/O in orange((heat / 40), src))
		if(!O.anchored)
			step_towards(O,src)
	for(var/mob/living/M in orange((heat / 40), src))
		if(!M.mob_negates_gravity())
			step_towards(M,src)
			M.Knockdown(40)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/relaymove(mob/user)
	if(user.incapacitated())
		return
	if(prob(40))
		audible_message("<span class='danger'>CLANG, clang!</span>")
	shake_animation(3)
	playsound(src, 'sound/effects/clang.ogg', 45, 1)

//////// OTHER PROCS ////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/send_alert(message, override=FALSE)
	if(!message)
		return
	if(can_alert || override) //We have an override to ignore continuous alerts like control rod reports in favour of screaming that the reactor is about to go nuclear.
		can_alert = FALSE
		radio.talk_into(src, message, engineering_channel)
		addtimer(VARSET_CALLBACK(src, can_alert, TRUE), alert_cooldown)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/check_meltdown_warning()
	if(warning_state >= WARNING_STATE_OVERHEAT)
		if(heat <= reactor_temperature_critical) //This implies that we've now stopped melting down.
			var/obj/structure/overmap/OM = get_overmap()
			OM?.stop_relay(CHANNEL_REACTOR_ALERT)
			warning_state = 0
			send_alert("Nuclear meltdown averted. Manual reactor inspection is strongly advised", override=TRUE)
		return FALSE
	if(heat >= reactor_temperature_critical)
		send_alert("DANGER: Reactor core overheating. Nuclear meltdown imminent", override=TRUE)
		warning_state = WARNING_STATE_OVERHEAT
		var/sound = 'nsv13/sound/effects/ship/reactor/core_overheating.ogg'
		var/obj/structure/overmap/OM = get_overmap()
		OM?.relay(sound, null, loop=TRUE, channel = CHANNEL_REACTOR_ALERT)
		return TRUE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_overload()
	switch(last_power_produced)
		if(3000000 to 5000000) //3MW to 5MW
			if(prob(0.1))
				for(var/obj/machinery/light/L in orange(8, src))
					if(prob(25))
						L.flicker()
		if(5000000 to 8000000) //5MW to 8MW
			if(prob(0.1))
				for(var/obj/machinery/light/L in orange(25, src))
					if(prob(25))
						L.flicker()
			if(prob(1))
				for(var/obj/machinery/light/L in orange(8, src))
					if(prob(25))
						L.flicker()
		if(8000000 to 12000000) //8MW to 12MW
			if(prob(0.1))
				for(var/ar in SSmapping.areas_in_z["[z]"])
					var/area/AR = ar
					for(var/obj/machinery/light/L in AR)
						if(prob(25))
							L.flicker()
			if(prob(1))
				var/list/light_candidates = list()
				for(var/obj/machinery/light/L in orange(12, src))
					light_candidates += L

				for(var/I = 0, I < 3, I++)
					if(length(light_candidates))
						var/obj/machinery/light/OL = pick_n_take(light_candidates)
						var/fate = rand(1, 100)
						switch(fate)
							if(1 to 25)
								OL.burn_out()
							if(26 to 35)
								OL.break_light_tube()
					else
						break
			if(prob(0.02))
				for(var/obj/machinery/power/grounding_rod/R in orange(5, src))
					R.take_damage(rand(25, 50))
				tesla_zap(src, 5, 1000)
				reactor_stability -= rand(5, 10)
		if(12000000 to INFINITY) //12MW+
			if(prob(1))
				for(var/obj/machinery/light/L in GLOB.machines)
					if(prob(50) && shares_overmap(src, L))
						L.flicker()
			if(prob(5))
				var/list/light_candidates = list()
				for(var/obj/machinery/light/L in orange(12, src))
					light_candidates += L

				for(var/I = 0, I < 5, I++)
					if(length(light_candidates))
						var/obj/machinery/light/OL = pick_n_take(light_candidates)
						var/fate = rand(1, 100)
						switch(fate)
							if(1 to 25)
								OL.burn_out()
							if(25 to 35)
								OL.break_light_tube()
					else
						break
			if(prob(0.2))
				for(var/obj/machinery/power/grounding_rod/R in orange(8, src))
					R.take_damage(rand(25, 75))
				tesla_zap(src, 8, 2000)
				reactor_stability -= rand(10, 20)

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/update_icon() //include overlays for radiation output levels and power output levels (ALSO 1k+ levels)
	if(state == REACTOR_STATE_MELTDOWN)
		icon_state = "broken"
		return
	if(state == REACTOR_STATE_REPAIR) //TEMP
		icon_state = "broken"
		return
	if(state == REACTOR_STATE_REINFORCE) //TEMP
		icon_state = "broken"
		return
	if(state == REACTOR_STATE_REINFORCE) //TEMP
		icon_state = "broken"
		return
	cut_overlays()
	if(can_cool()) //If control rods aren't destroyed.
		switch(round(control_rod_percent)) //move the control rods up and down
			if(0 to 24)
				add_overlay("rods_[control_rods.len]_1")
			if(25 to 49)
				add_overlay("rods_[control_rods.len]_2")
			if(50 to 74)
				add_overlay("rods_[control_rods.len]_3")
			if(75 to 100)
				add_overlay("rods_[control_rods.len]_4")
	if(state == REACTOR_STATE_MAINTENANCE)
		icon_state = "reactor_maintenance" //If we're in maint, don't make it appear hot.
		return
	if(state == REACTOR_STATE_RUNNING)
		icon_state = "reactor_on" //Default to being on.
		check_meltdown_warning()
		var/illumination = max(2, heat/100)
		if(heat > 0 && heat <= reactor_temperature_nominal) //checking temperature ranges
			icon_state = "reactor_on"
			light_color = LIGHT_COLOR_CYAN
			set_light(illumination)
		else if(heat > reactor_temperature_nominal && heat <= reactor_temperature_hot)
			icon_state = "reactor_hot"
			light_color = LIGHT_COLOR_CYAN
			set_light(illumination)
		else if(heat > reactor_temperature_hot && heat <= reactor_temperature_critical)
			icon_state = "reactor_hot" //NEED NEW ICON
			light_color = LIGHT_COLOR_CYAN
			set_light(illumination)
		else if(heat > reactor_temperature_critical && heat <= reactor_temperature_meltdown) //Final Warning
			icon_state = "reactor_overheat"
			light_color = LIGHT_COLOR_RED
			set_light(illumination)
		else if(heat > reactor_temperature_meltdown)
			icon_state = "reactor_overheat"
			light_color = LIGHT_COLOR_RED
			set_light(illumination)
			start_meltdown() //Epsilon or Death

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/Destroy()
	for(var/atom/X in contents)
		qdel(X)
	.=..()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/examine(mob/user)
	. = ..()
	if(icon_state == "broken")
		. += "<span class='notice'>The reactor pit is full of plutonium sludge.</span>"
	switch(state)
		if(REACTOR_STATE_REPAIR)
			. += "<span class='notice'>The duranium lining of the reactor pit is severly degraded.</span>"
		if(REACTOR_STATE_REINFORCE)
			. += "<span class='notice'>The lining requires reinforcing and welding in place.</span>"
		if(REACTOR_STATE_REFIT)
			. += "<span class='notice'>It is missing a reactor core.</span>"

/obj/effect/countdown/stormdrive
	name = "stormdrive stability"
	text_size = 1
	color = "#00aeff"

/obj/effect/countdown/stormdrive/get_value()
	var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/S = attached_to
	if(!istype(S))
		return
	return "<div align='center' valign='middle' style='position:relative; top:0px; left:0px'>[round(S.reactor_stability, 1)]%</div>"

////////MELTDOWN////////

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/start_meltdown()
	if(warning_state >= WARNING_STATE_MELTDOWN)
		return
	for(var/obj/item/control_rod/cr in contents) //Burn through the control rods if we haven't already.
		cr.rod_integrity = 0
		control_rods -= cr
		qdel(cr)
		control_rods += new /obj/item/control_rod/irradiated(src)
	handle_control_rod_efficiency()
	send_alert("ERROR IN MODULE FISSREAC0 AT ADDRESS 0x12DF. CONTROL RODS HAVE FAILED. IMMEDIATE INTERVENTION REQUIRED.", override=TRUE)
	warning_state = WARNING_STATE_MELTDOWN
	var/sound = 'nsv13/sound/effects/ship/reactor/meltdown.ogg'
	addtimer(CALLBACK(src, PROC_REF(meltdown)), 18 SECONDS)
	var/obj/structure/overmap/OM = get_overmap()
	OM?.relay(sound, null, loop=FALSE, channel = CHANNEL_REACTOR_ALERT)
	reactor_end_times = TRUE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/handle_reactor_destabilization()
	if(prob(40))
		for(var/obj/structure/window/W in orange(6, src))
			W.take_damage(rand(50, 200))

		for(var/mob/living/M in orange(12, src))
			shake_with_inertia(M, 2, 1)

		for(var/mob/living/M in orange(5, src))
			M.knockOver()

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/meltdown()
	if(heat >= reactor_temperature_meltdown)
		state = REACTOR_STATE_MELTDOWN
		var/sound = 'nsv13/sound/effects/ship/reactor/explode.ogg'
		var/obj/structure/overmap/OM = get_overmap()
		OM?.relay(sound, null, loop=FALSE, channel = CHANNEL_REACTOR_ALERT)
		cut_overlays()
		flick("meltdown", src)
		do_meltdown_effects()
		fail_meltdown_objective()
		sleep(10)
		icon_state = "broken"
		reactor_end_times = FALSE //We don't need this anymore
		SSblackbox.record_feedback("tally", "engine_stats", 1, "failed")
		SSblackbox.record_feedback("tally", "engine_stats", 1, "stormdrive")
	else
		warning_state = WARNING_STATE_NONE
		reactor_end_times = FALSE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/fail_meltdown_objective()
	for(var/client/C in GLOB.clients)
		if(C)
			if(CONFIG_GET(flag/allow_crew_objectives))
				var/mob/M = C.mob
				if(M?.mind?.current && LAZYLEN(M.mind.crew_objectives) && (M.job == "Station Engineer" || M.job == "Chief Engineer" || M.job == "Atmospheric Technician"))
					for(var/datum/objective/crew/meltdown/MO in M.mind.crew_objectives)
						MO.meltdown = TRUE

/obj/machinery/atmospherics/components/binary/stormdrive_reactor/proc/do_meltdown_effects()
	explosion(get_turf(src), 0, 0, 10, 20, TRUE, TRUE)
	empulse(src, 25, 50)
	radiation_pulse(src, 10000, 1)
	src.atmos_spawn_air("o2=750;plasma=200;nucleium=100;TEMP=5000")

	for(var/mob/living/M in GLOB.alive_mob_list)
		if(shares_overmap(src, M))
			shake_with_inertia(M, 3, 2)
			if(!M.mob_negates_gravity())
				M.Knockdown(50)
				to_chat(M, "<span class='danger'You feel a wave of energy wash over you!</span>")

	for(var/X in GLOB.landmarks_list)
		if(istype(X, /obj/effect/landmark/nuclear_waste_spawner))
			var/obj/effect/landmark/nuclear_waste_spawner/WS = X
			if(shares_overmap(src, WS))
				var/epi = get_turf(WS)
				if(WS.range < 10) //small spawner
					empulse(epi, 5, 15)
					radiation_pulse(epi, 100)
					if(prob(50))
						var/anom = rand(1,10)
						switch(anom)
							if(1 to 4)
								new /obj/effect/anomaly/stormdrive/surge(epi, rand(2000, 5000))
							if(5 to 8)
								new /obj/effect/anomaly/stormdrive/sheer(epi, rand(2000, 5000))
							if(9 to 10)
								new /obj/effect/anomaly/stormdrive/squall(epi, rand(2000, 5000))
				else //larger spawner
					empulse(epi, 10, 25)
					radiation_pulse(epi, 500)
					var/anom = rand(1,10)
					switch(anom) //spawn SD anom
						if(1 to 4)
							new /obj/effect/anomaly/stormdrive/surge(epi, rand(2000, 5000))
						if(5 to 8)
							new /obj/effect/anomaly/stormdrive/sheer(epi, rand(2000, 5000))
						if(9 to 10)
							new /obj/effect/anomaly/stormdrive/squall(epi, rand(2000, 5000))

//////// Reactor Computer////////

/obj/machinery/computer/ship/reactor_control_computer
	name = "Seegson model RBMK reactor control console"
	desc = "A state of the art terminal which is linked to a nuclear storm drive reactor. It has several buttons labelled 'AZ' on the keyboard."
	icon_screen = "reactor_control"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/computer/stormdrive_reactor_control
	var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/reactor //Our parent reactor
	req_access = list(ACCESS_ENGINE_EQUIP)
	var/reactor_id = null //set your ID here

/obj/machinery/computer/ship/reactor_control_computer/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_MULTITOOL)
		if(!multitool_check_buffer(user, I))
			return
		var/obj/item/multitool/M = I
		reactor = M.buffer
		M.buffer = null
		playsound(src, 'sound/items/flashlight_on.ogg', 100, TRUE)
		to_chat(user, "<span class='notice'>Buffer transfered</span>")

/obj/machinery/computer/ship/reactor_control_computer/attack_hand(mob/user)
	if(!allowed(user))
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Access denied</span>")
		return
	if(!reactor)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked reactor</span>")
		return

	ui_interact(user)

/obj/machinery/computer/ship/reactor_control_computer/attack_ai(mob/user)
	. = ..()
	if(!reactor)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked reactor</span>")
		return
	ui_interact(user)

/obj/machinery/computer/ship/reactor_control_computer/attack_robot(mob/user)
	. = ..()
	if(!reactor)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Unable to detect linked reactor</span>")
		return
	ui_interact(user)

/obj/machinery/computer/ship/reactor_control_computer/attack_ghost(mob/user)
	if(!reactor)
		to_chat(user, "<span class='warning'>Unable to detect linked reactor</span>")
		return
	. = ..() //parent should call ui_interact

/obj/machinery/computer/ship/reactor_control_computer/Initialize(mapload)
	. = ..()
	new /obj/item/book/manual/wiki/stormdrive(get_turf(src))
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/ship/reactor_control_computer/LateInitialize()
	if(reactor_id) //If mappers set an ID)
		for(var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/sdr in GLOB.machines)
			if(sdr.reactor_id == reactor_id)
				reactor = sdr

/obj/machinery/computer/ship/reactor_control_computer/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	if(!reactor)
		return
	switch(action)
		if("control_rod_percent")
			var/adjust = text2num(params["adjust"])
			adjust = CLAMP(adjust, 0, 100)
			reactor.control_rod_percent = adjust
			reactor.update_icon()
		if("rods_1")
			reactor.control_rod_percent = 0
			message_admins("[key_name(usr)] has fully raised reactor control rods in [get_area(usr)] [ADMIN_JMP(usr)]")
			reactor.update_icon()
		if("rods_2")
			reactor.control_rod_percent = 5
			reactor.update_icon()
		if("rods_3")
			reactor.control_rod_percent = 16
			reactor.update_icon()
		if("rods_4")
			reactor.control_rod_percent = 33.6
			reactor.update_icon()
		if("rods_5")
			reactor.control_rod_percent = 100
			reactor.update_icon()
			to_chat(usr, "<span class='danger'>SCRAM protocols engaged. Attempting reactor shutdown!</span>")
		if("maintenance")
			if(reactor.state == REACTOR_STATE_MAINTENANCE)
				reactor.disengage_maintenance()
				to_chat(usr, "<span class='danger'>Maintenance protocols disengaged.</span>")
				attack_hand(usr)
				return
			if(reactor.state == REACTOR_STATE_IDLE)
				reactor.engage_maintenance()
				to_chat(usr, "<span class='danger'>Maintenance protocols engaged.</span>")
				attack_hand(usr)
				return
			else
				to_chat(usr, "<span class='danger'>DANGER! Maintenance protocols cannot be initiated while the reactor is active</span>")
		if("pipe") //change my words
			reactor.dumping_fuel = !reactor.dumping_fuel

/obj/machinery/computer/ship/reactor_control_computer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StormdriveConsole")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/ship/reactor_control_computer/ui_data(mob/user)
	var/list/data = list()
	data["heat"] = reactor.heat
	data["rod_integrity"] = reactor.control_rod_integrity
	data["control_rod_percent"] = reactor.control_rod_percent
	data["pipe_open"] = reactor.dumping_fuel
	data["last_power_produced"] = reactor.last_power_produced
	data["theoretical_maximum_power"] = reactor.theoretical_maximum_power
	data["reaction_rate"] = reactor.reaction_rate
	data["reactor_hot"] = reactor.reactor_temperature_hot
	data["reactor_critical"] = reactor.reactor_temperature_critical
	data["reactor_meltdown"] = reactor.reactor_temperature_meltdown
	if(reactor.state == REACTOR_STATE_MAINTENANCE)
		data["reactor_maintenance"] = TRUE
	else
		data["reactor_maintenance"] = FALSE

	var/datum/gas_mixture/air1 = reactor.airs[1]

	data["fuel_mix"] = air1.get_moles(GAS_PLASMA) + air1.get_moles(GAS_CONSTRICTED_PLASMA) + air1.get_moles(GAS_TRITIUM)
	if(reactor.state == REACTOR_STATE_RUNNING)
		data["mole_threshold_very_high"] = (reactor.reaction_rate * 18) + 20
		data["mole_threshold_high"] = (reactor.reaction_rate * 12) + 20
	else
		data["mole_threshold_very_high"] = 120 //Just need to avoid that inital orange
		data["mole_threshold_high"] = 80

	data["o2"] = air1.get_moles(GAS_O2)
	data["n2"] = air1.get_moles(GAS_N2)
	data["co2"] = air1.get_moles(GAS_CO2)
	data["plasma"] = air1.get_moles(GAS_PLASMA)
	data["water_vapour"] = air1.get_moles(GAS_H2O)
	data["nob"] = air1.get_moles(GAS_HYPERNOB)
	data["n2o"] = air1.get_moles(GAS_NITROUS)
	data["no2"] = air1.get_moles(GAS_NITRYL)
	data["tritium"] = air1.get_moles(GAS_TRITIUM)
	data["bz"] = air1.get_moles(GAS_BZ)
	data["stim"] = air1.get_moles(GAS_STIMULUM)
	data["pluoxium"] = air1.get_moles(GAS_PLUOXIUM)
	data["constricted_plasma"] = air1.get_moles(GAS_CONSTRICTED_PLASMA)
	data["nucleium"] = air1.get_moles(GAS_NUCLEIUM)
	data["total_moles"] = air1.total_moles()

	data["gas_records"] = reactor.gas_records

	return data

/obj/item/circuitboard/computer/stormdrive_reactor_control
	name = "Stormdrive Reactor Control Console (Computer Board)"
	build_path = /obj/machinery/computer/ship/reactor_control_computer

/datum/design/board/stormdrive_reactor_control
	name = "Computer Design (Stormdrive Reactor Control Console)"
	desc = "Allows for the construction of circuit boards used to build a new stormdrive reactor control console."
	id = "sd_r_c_c"
	build_path = /obj/item/circuitboard/computer/stormdrive_reactor_control
	category = list("Computer Boards")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/techweb_node/stormdrive_reactor_control
	id = "sd_rcc+cons"
	display_name = "Seegson Storm Drive Machinery"
	description = "Seegson's latest and greatest (within your budget range) reactor control and plasma constriction designs!"
	prereq_ids = list("adv_engi", "adv_power")
	design_ids = list("sd_r_c_c", "mag_cons")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	export_price = 5000

/////// Constricted Plasma///////

/obj/machinery/atmospherics/components/trinary/filter/atmos/constricted_plasma
	name = "constricted plasma filter"
	filter_type = "constricted_plasma"

/obj/machinery/atmospherics/components/trinary/filter/atmos/constricted_plasma/flipped
	icon_state = "filter_on_f"
	flipped = TRUE

/obj/machinery/atmospherics/components/trinary/filter/atmos/plasma/flipped
	icon_state = "filter_on_f"
	flipped = TRUE

/obj/machinery/portable_atmospherics/canister/constricted_plasma
	name = "constricted plasma canister"
	desc = "Highly volatile plasma which has been magnetically constricted. The fuel which nuclear storm drives run off of."
	gas_type = GAS_CONSTRICTED_PLASMA
	greyscale_config = /datum/greyscale_config/canister/hazard
	greyscale_colors = "#aa18c7#000000"

/obj/machinery/portable_atmospherics/canister/nucleium
	name = "nucleium canister"
	desc = "A waste plasma biproduct produced in the Stormdrive, used in quantum waveform generation."
	gas_type = GAS_NUCLEIUM
	greyscale_colors = "#66C88F#000000"
	greyscale_config = /datum/greyscale_config/canister/hazard

/datum/weather/nuclear_fallout
	name = "nuclear fallout"
	desc = "Irradiated dust falls down everywhere."
	telegraph_duration = 50
	telegraph_message = "<span class='boldwarning'>The air suddenly becomes dusty..</span>"
	weather_message = "<span class='userdanger'><i>You feel a wave of hot ash fall down on you.</i></span>"
	weather_overlay = "light_ash"
	telegraph_overlay = "light_snow"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_color = "green"
	telegraph_sound = null
	weather_sound = 'nsv13/sound/effects/ship/reactor/falloutwind.ogg'
	end_duration = 100
	area_type = /area
	protected_areas = list(/area/maintenance, /area/ai_monitored/turret_protected/ai_upload, /area/ai_monitored/turret_protected/ai_upload_foyer,
	/area/ai_monitored/turret_protected/ai, /area/storage/emergency/starboard, /area/storage/emergency/port, /area/shuttle)
	target_trait = ZTRAIT_STATION
	end_message = "<span class='notice'>The ash stops falling.</span>"
	immunity_type = "rad"

/datum/weather/nuclear_fallout/weather_act(mob/living/L)
	L.rad_act(100)

/datum/weather/nuclear_fallout/telegraph()
	..()
	status_alarm(TRUE)

/datum/weather/nuclear_fallout/proc/status_alarm(active)	//Makes the status displays show the radiation warning for those who missed the announcement.
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return

	var/datum/signal/signal = new
	if (active)
		signal.data["command"] = "alert"
		signal.data["picture_state"] = "radiation"
	else
		signal.data["command"] = "shuttle"

	var/atom/movable/virtualspeaker/virt = new(null)
	frequency.post_signal(virt, signal)

/datum/weather/nuclear_fallout/end()
	if(..())
		return
	status_alarm(FALSE)

/////// ANOMALIES ///////

/obj/effect/anomaly/stormdrive //PARENT
	name = "\improper Stormdrive Anomaly - PARENT "
	desc = "A mysterious anomaly, unknown in origin."
	var/freq_shift = null
	var/code_shift = null

/obj/effect/anomaly/stormdrive/Initialize(mapload, new_lifespan)
	.=..()
	freq_shift = rand(1, 10) / 10
	code_shift = rand(1, 10) / 10
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/anomaly/stormdrive/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	return

/obj/effect/anomaly/stormdrive/attackby(obj/item/I, mob/user, params) //Not going to make this easy
	if(I.tool_behaviour == TOOL_ANALYZER)
		var/mem_address = rand(10000, 99999)
		if(prob(50))
			var/freq_1 = format_frequency(aSignal.frequency - freq_shift)
			var/freq_2 = format_frequency(aSignal.frequency + freq_shift)
			to_chat(user, "<span class='notice'>Analyzing... ERROR: Unable to #%##freq0x000[mem_address] [freq_1] - [freq_2].</span>")
		else
			var/code_1 = aSignal.code - code_shift
			var/code_2 = aSignal.code + code_shift
			to_chat(user, "<span class='notice'>Analyzing... ERROR: Unable to dete cod//^##e0x000[mem_address] [code_1] - [code_2].</span>")

/obj/effect/anomaly/stormdrive/sheer //Radiation + Plasma
	name = "storm sheer anomaly"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bluespace"

/obj/effect/anomaly/stormdrive/sheer/anomalyEffect()
	..()
	if(prob(90))
		radiation_pulse(src, 25)
	else
		radiation_pulse(src, 125)
		var/turf/open/L = get_turf(src)
		if(!istype(L) || !L.air)
			return
		var/datum/gas_mixture/env = L.return_air()
		var/temperature = env.return_temperature() + 25 //Not super spicy
		atmos_spawn_air("nucleium=15;TEMP=[temperature]")

/obj/effect/anomaly/stormdrive/sheer/on_entered(datum/source, mob/living/M)
	radiation_pulse(src, 125)

/obj/effect/anomaly/stormdrive/sheer/Bump(mob/living/M)
	radiation_pulse(src, 125)

/obj/effect/anomaly/stormdrive/sheer/Bumped(atom/movable/AM)
	radiation_pulse(src, 125)

/obj/effect/anomaly/stormdrive/sheer/detonate()
	radiation_pulse(src, 5000)
	src.atmos_spawn_air("o2=125;plasma=50;nucleium=50;TEMP=5000")
	explosion(src, 0, 0, 1, 18, FALSE)
	new /obj/effect/particle_effect/sparks(loc)

/obj/effect/anomaly/stormdrive/surge //EMP + Flux
	name = "storm surge anomaly"
	icon_state = "electricity2"
	var/canshock = FALSE
	var/shockdamage = 20

/obj/effect/anomaly/stormdrive/surge/anomalyEffect()
	..()
	canshock = TRUE
	if(prob(90))
		empulse(src, 0, 3)
		for(var/mob/living/M in orange(0, src))
			mobShock(M)
	else
		empulse(src, 1, 5)
		explosion(src, 0, 0, 0, 10, FALSE)
		for(var/mob/living/M in orange(2, src))
			mobShock(M)

/obj/effect/anomaly/stormdrive/surge/on_entered(datum/source, mob/living/M)
	mobShock(M)

/obj/effect/anomaly/stormdrive/surge/Bump(mob/living/M)
	mobShock(M)

/obj/effect/anomaly/stormdrive/surge/Bumped(atom/movable/AM)
	mobShock(AM)

/obj/effect/anomaly/stormdrive/surge/proc/mobShock(mob/living/M)
	if(canshock && istype(M))
		canshock = FALSE
		if(iscarbon(M))
			if(ishuman(M))
				M.electrocute_act(shockdamage, "[name]", safety=1)
				return
			M.electrocute_act(shockdamage, "[name]")
			return
		else
			M.adjustFireLoss(shockdamage)
			M.visible_message("<span class='danger'>[M] was shocked by \the [name]!</span>", \
		"<span class='userdanger'>You feel a powerful shock coursing through your body!</span>", \
		"<span class='italics'>You hear a heavy electrical crack.</span>")

/obj/effect/anomaly/stormdrive/surge/detonate() //because tesla_zap is so awful
	for(var/mob/living/M in orange(5, src))
		mobShock(M)
	empulse(src, 5, 10)
	explosion(src, 0, 0, 1, 18, FALSE)
	do_sparks(10, FALSE, src)

/obj/effect/anomaly/stormdrive/squall //Gravity + Brute
	name = "storm squall anomaly"
	icon_state = "dragnetfield"
	alpha = 65 //Not exactly easy to see

/obj/effect/anomaly/stormdrive/squall/anomalyEffect()
	var/direction = pick(GLOB.alldirs)
	var/times = rand(2, 4)
	for(var/I = 0, I < times, I++) //Appears to hop around, but actually passes through mobs
		step(src, direction)

	if(prob(90))
		var/turf/open/L = get_turf(src)
		if(!istype(L) || !L.air)
			return
		var/datum/gas_mixture/env = L.return_air()
		var/temperature = env.return_temperature()
		atmos_spawn_air("o2=5,n2=15;TEMP=[temperature]") //Add a little extra oxygenated air

	else //throw everything away
		for(var/atom/movable/AM in orange(4, src))
			if(isliving(AM))
				var/mob/living/M = AM
				M.Paralyze(20)
				M.Dizzy(5)
				M.apply_damage(10)
				var/atom/target = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
				M.throw_at(target, 4, 2)
				continue
			if(isobj(AM) && !AM.anchored)
				var/atom/target = get_edge_target_turf(AM, get_dir(src, get_step_away(AM, src)))
				AM.throw_at(target, 4, 2)

/obj/effect/anomaly/stormdrive/squall/on_entered(datum/source, mob/living/M)
	polarise(M)

/obj/effect/anomaly/stormdrive/squall/Bump(mob/living/M)
	polarise(M)

/obj/effect/anomaly/stormdrive/squall/Bumped(atom/movable/AM)
	polarise(AM)

/obj/effect/anomaly/stormdrive/squall/proc/polarise(mob/living/A)
	if(istype(A))
		A.Dizzy(10)
		A.Jitter(5)
		A.adjust_disgust(20)
		A.visible_message("<span class='danger'>The space around [A] begins to shimmer!</span>", \
		"<span class='userdanger'>Your head swims as space appears to bend around you!</span>",
		"<span class='italics'>You feel space shift slightly in your vicinity.</span>")
		addtimer(CALLBACK(src, PROC_REF(equalise), A), 5 SECONDS)

/obj/effect/anomaly/stormdrive/squall/proc/equalise(mob/living/A)
	var/list/throwlist = orange(6, A)
	for(var/obj/O in throwlist)
		if(!O.anchored)
			O.throw_at(A, 6, 3)
	for(var/mob/living/M in throwlist)
		if(!M.mob_negates_gravity())
			M.throw_at(A, 6, 3)

	if(istype(A, /mob/living/carbon))
		var/mob/living/carbon/C = A
		var/list/parts = list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
		var/selected = pick_n_take(parts)
		if(C.get_bodypart(selected)) //First Attempt
			var/obj/item/bodypart/affecting = C.get_bodypart(selected)
			affecting.dismember(damtype)
		else
			selected = pick_n_take(parts) //Second Attempt
			if(C.get_bodypart(selected))
				var/obj/item/bodypart/affecting = C.get_bodypart(selected)
				affecting.dismember(damtype)
			else //Probably already dying
				C.apply_damage(20)
	else
		A.apply_damage(20)

/obj/effect/anomaly/stormdrive/squall/detonate()
	for(var/atom/movable/AM in orange(6, src))
		if(isliving(AM))
			var/mob/living/M = AM
			M.Paralyze(40)
			M.Dizzy(10)
			M.apply_damage(20)
			var/atom/target = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
			M.throw_at(target, 6, 5)
		if(isobj(AM) && !AM.anchored)
			var/atom/target = get_edge_target_turf(AM, get_dir(src, get_step_away(AM, src)))
			AM.throw_at(target, 6, 5)

	var/turf/open/L = get_turf(src)
	if(!istype(L) || !L.air)
		return
	var/datum/gas_mixture/env = L.return_air()
	var/temperature = env.return_temperature()
	atmos_spawn_air("o2=200,n2=200;TEMP=[temperature]") //Hope there is nothing flammable in here

//////// MISC ///////

/obj/item/book/manual/wiki/stormdrive
	name = "\improper Stormdrive Class IV SOP"
	icon_state ="bookEngineering2"
	author = "CogWerk Engineering Reactor Design Department"
	title = "Stormdrive Class IV SOP"
	page_link = "Guide_to_the_Stormdrive_Engine"

/obj/item/stormdrive_core
	name = "\improper Class IV Nuclear Storm Drive Reactor Core"
	desc = "This crate contains a live reactor core for a class IV nuclear storm drive."
	icon = 'icons/obj/crates.dmi'
	icon_state = "crate"
	w_class = WEIGHT_CLASS_GIGANTIC

/obj/item/stormdrive_core/Initialize(mapload)
	.=..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/////// MOD COMP MONITORING PROGRAM ///////

/datum/computer_file/program/stormdrive_monitor
	filename = "stormdrivemonitor"
	filedesc = "Storm Drive Monitoring"
	ui_header = "smmon_0.gif"
	program_icon_state = "smmon_0"
	extended_desc = "This program connects to specially calibrated sensors to provide information on the status of the storm drive."
	requires_ntnet = TRUE
	transfer_access = ACCESS_CONSTRUCTION
	category = PROGRAM_CATEGORY_ENGI
	network_destination = "storm drive monitoring system"
	size = 2
	tgui_id = "NtosStormdriveMonitor"
	program_icon = "atom"
	var/active = TRUE //Easy process throttle
	var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/reactor //Our reactor.

/datum/computer_file/program/stormdrive_monitor/process_tick()
	..()
	if(!reactor || !active)
		return FALSE
	var/stage = 0
	switch(reactor.state)
		if(REACTOR_STATE_MAINTENANCE)
			stage = 1
		if(REACTOR_STATE_IDLE)
			stage = 1
		if(REACTOR_STATE_RUNNING)
			if(reactor.heat > 0 && reactor.heat <= reactor.reactor_temperature_nominal)
				stage = 2
			if(reactor.heat > reactor.reactor_temperature_nominal && reactor.heat <= reactor.reactor_temperature_hot)
				stage = 3
			if(reactor.heat > reactor.reactor_temperature_hot && reactor.heat <= reactor.reactor_temperature_critical)
				stage = 4
			if(reactor.heat > reactor.reactor_temperature_critical)
				stage = 5
		if(REACTOR_STATE_MELTDOWN)
			stage = 6
	ui_header = "smmon_[stage].gif"
	program_icon_state = "smmon_[stage]"
	if(istype(computer))
		computer.update_icon()

/datum/computer_file/program/stormdrive_monitor/on_start(mob/living/user)
	. = ..(user)
	//No reactor? Go find one then.
	if(!reactor)
		for(var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/R in GLOB.machines)
			if(shares_overmap(user, R))
				reactor = R
				break
	active = TRUE

/datum/computer_file/program/stormdrive_monitor/kill_program(forced = FALSE)
	active = FALSE
	..()

/datum/computer_file/program/stormdrive_monitor/ui_data()
	var/list/data = list()
	data["heat"] = reactor.heat
	data["rod_integrity"] = reactor.control_rod_integrity
	data["control_rod_percent"] = reactor.control_rod_percent
	data["last_power_produced"] = reactor.last_power_produced
	data["theoretical_maximum_power"] = reactor.theoretical_maximum_power
	data["reaction_rate"] = reactor.reaction_rate
	data["reactor_hot"] = reactor.reactor_temperature_hot
	data["reactor_critical"] = reactor.reactor_temperature_critical
	data["reactor_meltdown"] = reactor.reactor_temperature_meltdown

	var/datum/gas_mixture/air1 = reactor.airs[1]
	data["total_moles"] = air1.total_moles()
	if(reactor.state == REACTOR_STATE_RUNNING)
		data["mole_threshold_very_high"] = (reactor.reaction_rate * 18) + 20
		data["mole_threshold_high"] = (reactor.reaction_rate * 12) + 20
	else
		data["mole_threshold_very_high"] = 120 //Just need to avoid that inital orange
		data["mole_threshold_high"] = 80


	return data

/datum/computer_file/program/stormdrive_monitor/ui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("swap_reactor")
			var/list/choices = list()
			for(var/obj/machinery/atmospherics/components/binary/stormdrive_reactor/R in GLOB.machines)
				if(!shares_overmap(usr, R))
					continue
				choices += R
			reactor = input(usr, "What stormdrive reactor do you wish to monitor?", "[src]", null) as null|anything in choices
			return TRUE

#undef LOW_ROR
#undef NORMAL_ROR
#undef HIGH_ROR
#undef HINDER_ROR
#undef REALLY_HINDER_ROR
#undef NULL_ROR
#undef LOW_IPM
#undef MEDIOCRE_IPM
#undef HIGH_IPM
#undef VERY_HIGH_IPM
#undef LOW_COOLING
#undef HIGH_COOLING
#undef VERY_HIGH_COOLING
#undef LOW_RADIATION
#undef HIGH_RADIATION
#undef VERY_HIGH_RADIATION
#undef LOW_REINFORCEMENT
#undef HIGH_REINFORCEMENT
#undef VERY_HIGH_REINFORCEMENT
#undef HIGH_DEG_PROTECTION
#undef VERY_HIGH_DEG_PROTECTION

#undef REACTOR_STATE_MAINTENANCE
#undef REACTOR_STATE_IDLE
#undef REACTOR_STATE_RUNNING
#undef REACTOR_STATE_MELTDOWN
#undef REACTOR_STATE_REPAIR
#undef REACTOR_STATE_REINFORCE
#undef REACTOR_STATE_REFIT
#undef WARNING_STATE_NONE
#undef WARNING_STATE_OVERHEAT
#undef WARNING_STATE_MELTDOWN
#undef MAX_CONTROL_RODS
