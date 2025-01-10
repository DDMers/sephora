// Laser PD system control console
/obj/machinery/computer/laser_pd
	name = "point-defense laser console"
	desc = "A computer that allows you to control a connected point-defense laser."
	icon_screen = "50cal"
	circuit = /obj/item/circuitboard/computer/laser_pd
	var/obj/machinery/ship_weapon/energy/laser_pd/turret
	var/gun_id = 0 // Used for map linkage

/obj/machinery/computer/laser_pd/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/laser_pd/LateInitialize()
	for(var/obj/machinery/ship_weapon/energy/laser_pd/pd_gun in GLOB.machines)
		if(gun_id && pd_gun.gun_id == gun_id)
			turret = pd_gun
			break

/obj/machinery/computer/laser_pd/attack_robot(mob/user)
	return attack_hand(user)

/obj/machinery/computer/laser_pd/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/computer/laser_pd/multitool_act(mob/living/user, obj/item/multitool/tool)
	. = TRUE
	var/obj/machinery/ship_weapon/energy/laser_pd/stored_gun = tool.buffer
	if(stored_gun && istype(stored_gun))
		turret = stored_gun
		to_chat(user, "<span class='warning'>Successfully linked [src] to [turret].")
	else
		to_chat(user, "<span class='warning'>No compatible weapon type found in buffer.")

/obj/machinery/computer/laser_pd/attack_hand(mob/user)
	. = ..()
	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, "<span class='warning'>[src] doesn't seem to be working.</span>")
		return
	if(!turret)
		to_chat(user, "<span class='warning'>[src] is not linked to a laser turret! You can link it with a multitool.</span>")
		return
	turret.start_gunning(user)

// Overmap gunning component for laser PD
/datum/component/overmap_gunning/laser_pd
	fire_mode = FIRE_MODE_LASER_PD
	fire_delay = 1.5 SECONDS

// The laser PD turret itself
/obj/machinery/ship_weapon/energy/laser_pd
	name = "laser point defense turret"
	desc = "A low-wattage laser designed to provide close-combat relief to large ships."
	icon ='nsv13/icons/obj/energy_weapons.dmi'
	icon_state = "pd_cannon"
	bound_width = 64
	pixel_x = -32
	pixel_y = -32
	dir = EAST
	safety = FALSE
	idle_power_usage = 2500
	active = FALSE

	fire_mode = FIRE_MODE_LASER_PD
	energy_weapon_type = /datum/ship_weapon/phaser_pd
	charge = 0
	charge_rate = 700000
	charge_per_shot = 1000000 // requires 1 MW to fire a burst
	max_charge = 4000000 // Stores 1 burst base
	power_modifier_cap = 1 // PL cap of 2
	static_charge = TRUE
	firing_sound = null
	bang = FALSE // It's a light laser weapon, not a cannon going off

	circuit = /obj/item/circuitboard/machine/laser_pd
	var/gunning_component_type = /datum/component/overmap_gunning/laser_pd
	var/mob/gunner = null
	var/gun_id = 0 // Used for map linkage
	max_heat = 1000
	heat_per_shot = 80
	heat_rate = 15
	storage_rate = 100


/obj/machinery/ship_weapon/energy/laser_pd/proc/start_gunning(mob/user)
	if(gunner)
		remove_gunner()
	gunner = user
	user.AddComponent(gunning_component_type, src, TRUE)

/obj/machinery/ship_weapon/energy/laser_pd/proc/remove_gunner()
	get_overmap().stop_piloting(gunner)

/obj/machinery/ship_weapon/energy/laser_pd/RefreshParts()
	var/temp_cell_increase = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		temp_cell_increase += (C.rating)
	power_modifier_cap = round(initial(power_modifier_cap) + (temp_cell_increase * 0.2)) // 5 capacitors
	max_charge = initial(max_charge) + ((temp_cell_increase * 0.2) - 1) * 5000000 // Max upgraded powermod of 5, max upgraded charge of 5 MW
