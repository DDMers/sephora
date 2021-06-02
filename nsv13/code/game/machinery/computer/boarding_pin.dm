GLOBAL_VAR_INIT(boarding_guns_z_locked, TRUE) // Around the time I wanted to make it both a PDA program and a computer and it needed to be mirrored to all the guns

// Computer controlled
// Can work either on non-player-ship Z levels, or as a regular firing pin
/obj/item/firing_pin/boarding
	name = "boarding firing pin"
	desc = "This safety firing pin allows weapons to be fired only on enemy ships at the HOS's discretion."
	fail_message = "<span class='warning'>USE NOT AUTHORIZED.</span>"
	pin_removeable = TRUE
	force_replace = TRUE

/obj/item/firing_pin/boarding/pin_auth(mob/living/user)
	if(!istype(user))
		return FALSE
	if(GLOB.boarding_guns_z_locked)
		// Check if we're on a friendly ship
		var/obj/structure/overmap/OM = get_overmap()
		if((OM.role == MAIN_OVERMAP) || (OM.role == MAIN_MINING_SHIP))
			return FALSE
		else
			return TRUE
	else
		return (GLOB.security_level >= SEC_LEVEL_RED)
	return FALSE

// A box
/obj/item/storage/box/boardingpins
        name = "box of boarding firing pins"
        desc = "A box full of boarding firing pins, to keep uppity grunts from ruining the ship."
        illustration = "id"

/obj/item/storage/box/boardingpins/PopulateContents()
	for(var/i in 1 to 15)
		new /obj/item/firing_pin/boarding(src)

// The control computer
// This not being buildable is a feature, thank you have a nice day
/obj/machinery/computer/boarding_guns
	name = "boarding weapons control console"
	desc = "Used to remotely lockdown or authorize weapons with boarding firing pins installed."
	icon_screen = "robot"
	icon_keyboard = "rd_key"
	req_access = list(ACCESS_ARMORY)
	circuit = null //obj/item/circuitboard/computer/boarding_guns
	light_color = LIGHT_COLOR_RED
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/computer/boarding_guns/ui_interact(mob/user)
	. = ..()

	var/dat = "[GLOB.boarding_guns_z_locked ? "Guns are set to Away only." : "Guns are set to General Quarters."]<br>"
	dat += "Current alert level: [get_security_level()]<br>"

	if(!GLOB.boarding_guns_z_locked)
		dat += "<A href='?src=[REF(src)];locked=true'>Lock weapons on ship.</A><br>"
	else
		dat += "<A href='?src=[REF(src)];locked=false'>Unlock weapons during General Quarters.</A><br>"

	dat += "<a href='?src=[REF(user)];mach_close=computer'>Close</a>"

	var/datum/browser/popup = new(user, "computer", "boarding weapon management", 300, 150) //width, height
	popup.set_content("<center>[dat]</center>")
	popup.open()


/obj/machinery/computer/boarding_guns/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	add_fingerprint(usr)
	if(!allowed(usr))
		to_chat(usr, "<span class='danger'>Access denied.</span>")
		return

	if(href_list["locked"] == "true")
		GLOB.boarding_guns_z_locked = TRUE
		say("Boarding pins set to Away.")
	else if(href_list["locked"] == "false")
		GLOB.boarding_guns_z_locked = FALSE
		say("Boarding pins set to General Quarters.")

	updateUsrDialog()

/obj/machinery/computer/boarding_guns/screwdriver_act(mob/living/user, obj/item/I)
	return FALSE
