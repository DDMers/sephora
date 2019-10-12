/datum/job/emt
	title = "Paramedic"
	flag = EMT
	department_head = list("Chief Medical Officer")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 5
	spawn_positions = 3
	supervisors = "the chief medical officer"
	selection_color = "#ffeef0"

	outfit = /datum/outfit/job/emt

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CHEMISTRY, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_VIROLOGY, ACCESS_MECH_MEDICAL, ACCESS_RESEARCH, ACCESS_ENGINE, ACCESS_MINERAL_STOREROOM, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CLONING, ACCESS_MECH_MEDICAL, ACCESS_RESEARCH, ACCESS_ENGINE, ACCESS_MINERAL_STOREROOM, ACCESS_MAINT_TUNNELS)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED

	display_order = JOB_DISPLAY_ORDER_MEDICAL_DOCTOR

/datum/outfit/job/emt
	name = "Paramedic"
	jobtype = /datum/job/emt

	id = /obj/item/card/id/job/med
	belt = /obj/item/pda/medical
	ears = /obj/item/radio/headset/headset_med
	uniform = /obj/item/clothing/under/rank/medical
	shoes = /obj/item/clothing/shoes/sneakers/white
	head = /obj/item/clothing/head/soft/emt
	suit =  /obj/item/clothing/suit/toggle/labcoat/emt
	l_hand = /obj/item/storage/firstaid/regular
	l_pocket = /obj/item/pinpointer/crew
	suit_store = /obj/item/sensor_device
	backpack_contents = 

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med

	chameleon_extras = /obj/item/gun/syringe
