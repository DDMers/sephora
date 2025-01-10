/obj/structure/closet/secure_closet/master_at_arms
	name = "\proper master at arms' locker"
	req_access = list(ACCESS_MAA)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "maa"
	anchored = TRUE

/obj/structure/closet/secure_closet/master_at_arms/PopulateContents()
	..()
	new /obj/item/card/id/departmental_budget/mun(src)
	new /obj/item/door_remote/master_at_arms(src)
	new /obj/item/radio/headset/heads/master_at_arms(src)
	new /obj/item/clothing/suit/ship/maa_jacket(src)
	new /obj/item/clothing/suit/hazardvest(src)
	new /obj/item/clothing/head/bomb_hood(src)
	new /obj/item/clothing/suit/bomb_suit(src)
	new /obj/item/clothing/head/hardhat/orange(src)
	new /obj/item/clothing/head/ship/maa_hat(src)
	new /obj/item/pet_carrier(src)
	new /obj/item/clothing/neck/petcollar(src)
	new /obj/item/storage/box/radiokey/mun(src)
	new /obj/item/storage/box/radiokey/pilot(src)
	new /obj/item/encryptionkey/atc(src)
	new /obj/item/circuitboard/machine/techfab/department/munitions(src)
	new /obj/item/stamp/maa(src)
	new /obj/item/pinpointer/munitions(src)

/obj/structure/closet/secure_closet/munitions_technician
	name = "munitions technician's locker"
	req_access = list(ACCESS_MUNITIONS_STORAGE)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "mun"
	anchored = TRUE

/obj/structure/closet/secure_closet/munitions_technician/PopulateContents()
	..()
	new /obj/item/radio/headset/munitions/munitions_tech(src)
	new /obj/item/clothing/under/rank/munitions_tech(src)
	new /obj/item/clothing/under/ship/decktech(src)
	new /obj/item/clothing/suit/ship/munitions_jacket(src)
	new /obj/item/clothing/head/helmet/decktech(src)
	new /obj/item/storage/belt/utility/full/engi(src)

/obj/structure/closet/secure_closet/deck_technician
	name = "deck technician's locker"
	req_access = list(ACCESS_MUNITIONS_STORAGE)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "deck"
	anchored = FALSE

/obj/structure/closet/secure_closet/deck_technician/PopulateContents()
	..()
	new /obj/item/radio/headset/munitions/munitions_tech(src)
	new /obj/item/clothing/under/ship/decktech(src)
	new /obj/item/clothing/head/helmet/decktech(src)
	new /obj/item/clothing/suit/hazardvest(src)
	new /obj/item/storage/belt/utility/full/engi(src)
	new /obj/item/key/fighter_tug(src)

/obj/structure/closet/secure_closet/atc
	name = "air traffic controller's locker"
	req_access = list(ACCESS_MUNITIONS)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "atc"
	anchored = FALSE

/obj/structure/closet/secure_closet/atc/PopulateContents()
	..()
	new /obj/item/binoculars(src)
	new /obj/item/radio/headset/munitions/atc(src)
	new /obj/item/clothing/under/ship/officer(src)
	new /obj/item/clothing/head/beret/ship/pilot(src)
	new /obj/item/clothing/suit/hazardvest(src)
	new /obj/item/flashlight/atc_wavy_sticks(src)

/obj/structure/closet/secure_closet/combat_pilot
	name = "combat pilot's locker"
	req_access = list(ACCESS_COMBAT_PILOT)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "pilot"
	icon_door = "cpilot"
	anchored = TRUE

/obj/structure/closet/secure_closet/combat_pilot/PopulateContents()
	..()
	new /obj/item/radio/headset/munitions/pilot(src)
	new /obj/item/clothing/under/ship/pilot(src)
	new /obj/item/clothing/head/beret/ship/pilot(src)
	new /obj/item/clothing/gloves/color/black(src)

/obj/structure/closet/secure_closet/transport_pilot
	name = "transport pilot's locker"
	req_access = list(ACCESS_TRANSPORT_PILOT)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_door = "tpilot"
	icon_state = "pilot"
	anchored = TRUE

/obj/structure/closet/secure_closet/transport_pilot/PopulateContents()
	..()
	new /obj/item/radio/headset/munitions/pilot(src)
	new /obj/item/clothing/under/ship/pilot/transport(src)
	new /obj/item/clothing/head/helmet/transport_pilot(src)
	new /obj/item/clothing/gloves/color/brown(src)
	new /obj/item/clothing/glasses/sunglasses(src)

/obj/structure/closet/secure_closet/bridge
	name = "bridge staff's locker"
	req_access = list(ACCESS_HEADS)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "bridge"
	anchored = FALSE

/obj/structure/closet/secure_closet/bridge/PopulateContents()
	..()
	new /obj/item/radio/headset/headset_bridge(src)
	new /obj/item/clothing/under/ship/officer(src)
	new /obj/item/clothing/head/beret/durathread(src)
	new /obj/item/clothing/glasses/sunglasses(src)

/obj/structure/closet/secure_closet/puce
	name = "puce closet"
	req_access = list(ACCESS_CENT_CAPTAIN)
	icon = 'nsv13/icons/obj/custom_closets.dmi'
	icon_state = "definitelynotpuce"
	anchored = FALSE
