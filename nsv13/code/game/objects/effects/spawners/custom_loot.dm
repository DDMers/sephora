/obj/effect/spawner/lootdrop/random_seeds
	name = "random seed spawner"
	lootcount = 10
	fan_out_items = TRUE
	loot = list(
				/obj/item/seeds/ambrosia,
				/obj/item/seeds/apple,
				/obj/item/seeds/cotton,
				/obj/item/seeds/banana,
				/obj/item/seeds/berry,
				/obj/item/seeds/cabbage,
				/obj/item/seeds/carrot,
				/obj/item/seeds/cherry,
				/obj/item/seeds/chanter,
				/obj/item/seeds/chili,
				/obj/item/seeds/cocoapod,
				/obj/item/seeds/coffee,
				/obj/item/seeds/corn,
				/obj/item/seeds/eggplant,
				/obj/item/seeds/garlic,
				/obj/item/seeds/grape,
				/obj/item/seeds/grass,
				/obj/item/seeds/lemon,
				/obj/item/seeds/lime,
				/obj/item/seeds/onion,
				/obj/item/seeds/orange,
				/obj/item/seeds/pineapple,
				/obj/item/seeds/potato,
				/obj/item/seeds/poppy,
				/obj/item/seeds/pumpkin,
				/obj/item/seeds/replicapod,
				/obj/item/seeds/wheat/rice,
				/obj/item/seeds/soya,
				/obj/item/seeds/sunflower,
				/obj/item/seeds/sugarcane,
				/obj/item/seeds/tea,
				/obj/item/seeds/tobacco,
				/obj/item/seeds/tomato,
				/obj/item/seeds/tower,
				/obj/item/seeds/watermelon,
				/obj/item/seeds/wheat,
				/obj/item/seeds/whitebeet
				)
/obj/effect/spawner/lootdrop/anti_air
	name = "anti-air gun supplies spawner"
	loot = list(
		/obj/item/ammo_box/magazine/nsv/anti_air = 15,
		/obj/machinery/computer/anti_air = 2,
		/obj/machinery/ship_weapon/anti_air = 1,
		/obj/machinery/ship_weapon/anti_air/heavy = 1
		)
	lootcount = 1

/obj/effect/spawner/lootdrop/pdc
	name = "\improper PDC supplies spawner"
	loot = list(
		/obj/item/ammo_box/magazine/nsv/pdc = 10,
		/obj/machinery/ship_weapon/pdc_mount = 2
	)
	lootcount = 1

/obj/effect/spawner/lootdrop/railgun
	name = "railgun supplies spawner"
	loot = list(
		/obj/item/ship_weapon/ammunition/railgun_ammo = 15,
		/obj/item/circuitboard/computer/ship/munitions_computer = 2,
		/obj/machinery/ship_weapon/railgun = 1
		)
	lootcount = 2

/obj/effect/spawner/lootdrop/nac_ammo
	name = "\improper NAC ammo spawner"
	loot = list(
		/obj/item/ship_weapon/ammunition/naval_artillery = 1,
		/obj/item/ship_weapon/ammunition/naval_artillery/ap = 1,
		/obj/item/powder_bag = 1,
		/obj/item/powder_bag/plasma = 1,
		/obj/item/ship_weapon/ammunition/naval_artillery/cannonball = 1
		)
	lootcount = 3

/obj/effect/spawner/lootdrop/nac_supplies
	name = "\improper NAC stuff spawner"
	loot = list(
		/obj/item/powder_bag = 10,
		/obj/machinery/computer/deckgun = 1,
		/obj/machinery/deck_turret/core = 1,
		/obj/machinery/deck_turret/payload_gate = 1,
		/obj/machinery/deck_turret/autoelevator = 1,
		/obj/machinery/deck_turret/powder_gate = 1
		)
	lootcount = 1

/obj/effect/spawner/lootdrop/syndicate_fighter
	name = "syndicate fighter / raptor / frame spawner"
	loot = list(
		/obj/structure/overmap/small_craft/combat/light/syndicate = 2,
		/obj/structure/overmap/small_craft/transport/sabre/syndicate = 1,
		/obj/structure/fighter_frame = 1
		)
	lootcount = 1

/obj/effect/spawner/lootdrop/fighter
	name = "nanotrasen fighter / raptor / frame spawner"
	loot = list(
		/obj/structure/overmap/small_craft/combat/light = 2,
		/obj/structure/overmap/small_craft/transport/sabre = 1,
		/obj/structure/overmap/small_craft/combat/heavy = 1,
		/obj/structure/fighter_frame = 1
		)
	lootcount = 1
