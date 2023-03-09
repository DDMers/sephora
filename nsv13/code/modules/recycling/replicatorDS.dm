#define READY 1
#define REPLICATING 2

/obj/machinery/replicator
	name = "Food Replicator"
	desc = "An advanced energy to matter synthesizer which is charged by <i>biomatter</i>. Click it to see what's on the menu and simply say what you want to order from it."
	icon = 'nsv13/icons/obj/machinery/replicator.dmi'
	icon_state = "replicator"
	use_power = IDLE_POWER_USE
	idle_power_usage = 40
	density = TRUE
	circuit = /obj/item/circuitboard/machine/replicator
	var/list/menutier1 = list("rice", "egg", "ration pack", "glass", "tea earl grey") //It starts off terribly so the chef isn't replaced. You can then upgrade it via RnD to give actual food.
	var/list/menutier2 = list("burger", "steak", "fries","onion rings", "pancakes","coffee")
	var/list/menutier3 = list("cheese pizza", "mushroom pizza", "meat pizza", "pineapple pizza", "donkpocket pizza", "vegetable pizza")
	var/list/menutier4 = list("cake batter", "dough","egg box", "flour", "milk", "enzymes", "cheese wheel", "meat slab","activate iguana","deactivate iguana")
	var/list/all_menus = list() //All the menu items. Built on init(). We scan for menu items that've been ordered here.
	var/list/menualtnames = list("nutrients", "donk pizza", "veggie pizza","slab of meat","nutritional supplement")
	var/list/temperatures = list("cold", "warm", "hot", "extra hot", "well done")
	var/list/activator = list("computer", "alexa", "google", "ai", "voice")
	/// The list of possible surprises built in.
	var/list/surprises = list("surprise me", "you choose", "something", "i dont care", "an insult to pizza")
	var/list/iguanas = list()
	var/obj/machinery/biogenerator/biogen
	var/capacity_multiplier = 1
	var/failure_grade = 1
	var/speed_grade = 1
	var/menu_grade = 1
	var/emagged = FALSE
	var/ready = TRUE
	var/menutype = READY
	var/max_visual_biomass = 5000
	/// The research that is stored within this food replicator.
	var/datum/techweb/stored_research
	/// The different visual categories for the food replicator, for the tabs.
	var/list/show_categories = list("Tier 1", "Tier 2", "Tier 3", "Tier 4")
	/// Currently selected category in the UI
	var/selected_cat
	/// Currently selected temperature in the UI
	var/selected_temperature = "cold"

/obj/machinery/replicator/Initialize()
	. = ..()
	stored_research = new /datum/techweb/specialized/autounlocking/replicator
	all_menus += menutier1.Copy()
	all_menus += menutier2.Copy()
	all_menus += menutier3.Copy()
	all_menus += menutier4.Copy()
	all_menus += menualtnames.Copy()

	become_hearing_sensitive(ROUNDSTART_TRAIT)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/replicator/LateInitialize()
	. = ..()
	var/turf/object_current_turf = get_turf(src)
	var/Z_level = object_current_turf.get_virtual_z_level()
	var/valid_z = get_level_trait(Z_level)
	for(var/obj/machinery/biogenerator/Bio in GLOB.machines)
		if(Bio.get_virtual_z_level() in SSmapping.levels_by_trait(valid_z))
			var/area/location = get_area(Bio)
			if(location.name == "Hydroponics")
				biogen = Bio
				break

/obj/machinery/replicator/attackby(obj/item/O, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(default_deconstruction_screwdriver(user, "replicator-o", "replicator-on", O))
		return FALSE

	if(default_unfasten_wrench(user, O))
		return FALSE

	var/success = FALSE
	if(istype(O, /obj/item/reagent_containers/glass) || istype(O, /obj/item/trash))
		visible_message("<span class='warning'>[O] is vaporized by [src]</span>")
		playsound(src, 'nsv13/sound/effects/replicator-vaporize.ogg', 100, 1)
		qdel(O)
		return FALSE

	if(biogen.points < capacity_multiplier*600)
		if(istype(O, /obj/item/reagent_containers/food/snacks))
			convert_to_biomass(O)
			success = TRUE
		else if(istype(O, /obj/item/storage/bag/plants))
			var/obj/item/storage/bag/plants/P = O
			for(var/obj/item/reagent_containers/food/snacks/grown/G in P.contents)
				if(biogen.points < capacity_multiplier*600)
					convert_to_biomass(G)
				success = TRUE
	else
		to_chat(user, "<span class='warning'>[src]'s chemical fuel cells are full.</span>")
		return FALSE

	if(success)
		if(istype(O, /obj/item/storage/bag/plants))
			visible_message("<span class='warning'>The contents of [O] is vaporized by [src]</span>")
		else
			visible_message("<span class='warning'>[O] is vaporized by [src]</span>")
		playsound(src, 'nsv13/sound/effects/replicator-vaporize.ogg', 100, 1)
		use_power(50)
		return

/obj/machinery/replicator/ui_status(mob/user)
	if(machine_stat & BROKEN || panel_open)
		return UI_CLOSE
	return ..()

/obj/machinery/replicator/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/research_designs),
	)

/obj/machinery/replicator/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/replicator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Replicator", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/replicator/ui_data()
	var/list/data = list()
	data["replicating"] = ready
	data["biomass"] = biogen.points
	data["max_visual_biomass"] = max_visual_biomass
	data["efficiency"] = 100 - (failure_grade * 20)
	data["selected_temperature"] = selected_temperature
	data["menutier1"] = list()
	data["menutier2"] = list()
	data["menutier3"] = list()
	data["menutier4"] = list()
	if(menu_grade >= 1)
		for(var/foodname in menutier1)
			data["menutier1"] += foodname

	if(menu_grade >= 2)
		for(var/foodname in menutier2)
			data["menutier2"] += foodname

	if(menu_grade >= 3)
		for(var/foodname in menutier3)
			data["menutier3"] += foodname

	if(menu_grade >= 4)
		for(var/foodname in menutier4)
			data["menutier4"] += foodname

	return data

/obj/machinery/replicator/ui_static_data(mob/user)
	var/list/data = list()
	data["temperatures"] = temperatures
	data["categories"] = list()

	var/categories = show_categories.Copy()
	for(var/V in categories)
		categories[V] = list()
	for(var/V in stored_research.researched_designs)
		var/datum/design/replicator/D = SSresearch.techweb_design_by_id(V)
		for(var/C in categories)
			if(C in D.category)
				categories[C] += D

	for(var/category in categories)
		var/list/cat = list(
			"name" = category,
			"items" = (category == selected_cat ? list() : null))
		for(var/item in categories[category])
			var/datum/design/replicator/D = item
			var/obj/item/temporary = new D.build_path
			cat["items"] += list(list(
				"id" = D.id,
				"name" = D.name,
				"cost" = temporary.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment),
			))
			qdel(temporary)
		data["categories"] += list(cat)

	return data

/obj/machinery/replicator/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("replicate")
			if(!ready)
				say("I'm not ready to replicate yet!")
				return

			var/repli = params["id"]
			if(!stored_research.researched_designs.Find(repli))
				stack_trace("ID did not map to a researched datum [repli]")
				return

			if(menutype == READY)
				var/datum/design/replicator/D = SSresearch.techweb_design_by_id(repli)
				if(D && !istype(D, /datum/design/error_design))
					activation(D, selected_temperature, usr)
				else
					stack_trace("ID could not be turned into a valid techweb design datum [repli]")
					return

		if("select")
			selected_cat = params["category"]

		if("change_temperature")
			if(params["updated_temperature"] in temperatures)
				selected_temperature = params["updated_temperature"]

	return TRUE

/obj/machinery/replicator/emag_act(mob/user)
	if(!emagged)
		to_chat(user, "<span class='warning'>You corrupt the chemical processors.</span>")
		emagged = TRUE

/obj/machinery/replicator/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		capacity_multiplier = B.rating
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		speed_grade = M.rating
	for(var/obj/item/stock_parts/scanning_module/S in component_parts)
		menu_grade = S.rating
	for(var/obj/item/stock_parts/micro_laser/L in component_parts)
		failure_grade = L.rating

/obj/machinery/replicator/examine(mob/user)
	. = ..()
	ui_interact(user)
	to_chat(user, "<span class='notice'>Fuel reserves: <b>[biogen.points]</b>. Click it with any biomatter to recharge.</span>")

/obj/machinery/replicator/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode)
	. = ..()
	if(speaker == src)
		return
	else
		check_activation(speaker, raw_message)

/obj/machinery/replicator/proc/check_activation(atom/movable/speaker, raw_message)
	if(!powered() || !ready || panel_open)//Shut down.
		return
	if(!findtext(raw_message, activator))
		return FALSE //They have to say computer, like a discord bot prefix.
	if(menutype == READY)
		if(findtext(raw_message, "?")) //Burger? no be SPECIFIC. REEE
			return
		var/target
		var/temperature = null
		for(var/v in stored_research.researched_designs)
			var/datum/design/replicator/D = SSresearch.techweb_design_by_id(v)
			if(findtext(raw_message, D.name))
				target = lowertext(D.name)
		//for(var/X in all_menus)
		//	var/tofind = X
		//	if(findtext(raw_message, tofind))
		//		target = tofind //Alright they've asked for something on the menu.
		for(var/Y in temperatures) //See if they want it hot, or cold.
			var/hotorcold = Y
			if(findtext(raw_message, hotorcold))
				temperature = hotorcold //If they specifically request a temperature, we'll oblige. Else it doesn't rename.
		if(target && powered())
			activation(target, temperature, speaker)

/obj/machinery/replicator/proc/activation(var/menu, var/temperature, var/mob/living/user)
	menutype = REPLICATING
	idle_power_usage = 400
	icon_state = "replicator-replicating"
	playsound(src, 'nsv13/sound/effects/replicator.ogg', 100, 1)
	ready = FALSE
	var/speed_mult = 60 //Starts off hella slow.
	speed_mult -= (speed_grade*10) //Upgrade with manipulators to make this faster!
	if(istype(menu, /datum/design/replicator))
		var/datum/design/replicator/D = menu
		if(D.build_path)
			var/obj/item/build_path_item = new D.build_path
			menu = build_path_item.name
			qdel(build_path_item)
		else
			menu = D.name

	addtimer(CALLBACK(src, .proc/replicate, menu, temperature, user), speed_mult)
	addtimer(CALLBACK(src, .proc/set_ready, TRUE), speed_mult)

/obj/machinery/replicator/proc/set_ready()
	icon_state = "replicator-on"
	idle_power_usage = 40
	menutype = READY
	ready = TRUE

/obj/machinery/replicator/proc/convert_to_biomass(obj/item/reagent_containers/food/snacks/S)
	var/nutrimentgain = S.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment)
	if(nutrimentgain < 0.1)
		nutrimentgain = 1 * capacity_multiplier
	qdel(S)
	biogen.points += nutrimentgain
	return

/obj/machinery/replicator/proc/replicate(var/what, var/temp, var/mob/living/user)
	var/atom/food
	switch(what)
		if("egg","boiled egg")
			food = new /obj/item/reagent_containers/food/snacks/boiledegg(get_turf(src))
		if("rice","boiled rice")
			food = new /obj/item/reagent_containers/food/snacks/salad/boiledrice(get_turf(src))
		if("ration pack","nutrients","nutritional supplement")
			food = new /obj/item/reagent_containers/food/snacks/rationpack(get_turf(src))
		if("glass","drinking glass")
			food = new /obj/item/reagent_containers/food/drinks/drinkingglass(get_turf(src))
		if("tea earl grey")
			food = new /obj/item/reagent_containers/food/drinks/mug/tea(get_turf(src))
			food.name = "Earl Grey tea"
			food.desc = "Just how Captain Picard likes it."
			if(emagged)
				var/tea = food.reagents.get_reagent_amount(/datum/reagent/consumable/tea)
				food.reagents.add_reagent(/datum/reagent/consumable/ethanol, tea)
				food.reagents.remove_reagent(/datum/reagent/consumable/tea, tea)
		if("surprise me","you choose","something","i dont care")
			if(emagged)
				switch(rand(1,6))
					if(1)
						new /mob/living/simple_animal/hostile/killertomato(get_turf(src))
					if(2)
						new /mob/living/simple_animal/hostile/netherworld(get_turf(src))
					if(3)
						new /mob/living/simple_animal/hostile/bear(get_turf(src))
					if(4)
						new /mob/living/simple_animal/hostile/blob/blobspore(get_turf(src))
					if(5)
						new /mob/living/simple_animal/hostile/carp(get_turf(src))
					if(6)
						food = new /obj/item/reagent_containers/food/snacks/soup/mystery(get_turf(src))
				playsound(src.loc, 'sound/effects/explosion3.ogg', 50, 1)
				var/datum/effect_system/smoke_spread/bad/smoke = new
				smoke.set_up(2, src.loc)
				smoke.start()
				del(src)
				return
			else
				food = new /obj/item/reagent_containers/food/snacks/soup/mystery(get_turf(src))
	if(menu_grade >= 2) //SCANNER GRADE 2 (or above)!
		switch(what)
			if("burger")
				food = new /obj/item/reagent_containers/food/snacks/burger/plain(get_turf(src))
			if("steak")
				food = new /obj/item/reagent_containers/food/snacks/meat/steak/plain(get_turf(src))
			if("fries")
				food = new /obj/item/reagent_containers/food/snacks/fries(get_turf(src))
			if("onion rings")
				food = new /obj/item/reagent_containers/food/snacks/onionrings(get_turf(src))
			if("pancakes")
				food = new /obj/item/reagent_containers/food/snacks/pancakes(get_turf(src))
			if("coffee")
				food = new /obj/item/reagent_containers/food/drinks/coffee(get_turf(src))
				food.name = "coffee"
				food.desc = "A wise woman once said that coffee keeps you sane in deep space."
				if(emagged)
					var/coffee = food.reagents.get_reagent_amount(/datum/reagent/consumable/coffee)
					food.reagents.add_reagent(/datum/reagent/toxin/chloralhydrate, coffee)
					food.reagents.remove_reagent(/datum/reagent/consumable/coffee, coffee)
	if(menu_grade >= 3) //SCANNER GRADE 3 (or above)!
		switch(what)
			if("cheese pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/margherita(get_turf(src))
			if("meat pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/meat(get_turf(src))
			if("mushroom pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/mushroom(get_turf(src))
			if("veggie pizza","vegetable pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/vegetable(get_turf(src))
			if("pineapple pizza","an insult to pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/pineapple(get_turf(src))
			if("donk pizza","donkpocket pizza")
				food = new /obj/item/reagent_containers/food/snacks/pizzaslice/donkpocket(get_turf(src))
	if(menu_grade >= 4)
		switch(what)
			if("cake batter")
				food = new /obj/item/reagent_containers/food/snacks/cakebatter(get_turf(src))
			if("dough")
				food = new /obj/item/reagent_containers/food/snacks/dough(get_turf(src))
			if("egg box")
				food = new /obj/item/storage/fancy/egg_box(get_turf(src))
			if("flour")
				food = new /obj/item/reagent_containers/food/condiment/flour(get_turf(src))
			if("milk")
				food = new /obj/item/reagent_containers/food/condiment/milk(get_turf(src))
			if("enzymes")
				food = new /obj/item/reagent_containers/food/condiment/enzyme(get_turf(src))
			if("cheese wheel")
				food = new /obj/item/reagent_containers/food/snacks/store/cheesewheel(get_turf(src))
			if("meat slab","slab of meat")
				food = new /obj/item/reagent_containers/food/snacks/meat/slab(get_turf(src))
			if("activate iguana")
				if(length(iguanas) > 9)
					say("You have reached the iguana limit!")
					return
				iguanas += new /mob/living/simple_animal/kalo/leonard(get_turf(src))
			if("deactivate iguana")
				for(var/mob/M as() in iguanas)
					iguanas -= M
					qdel(M)

	if(food)
		var/nutriment = food.reagents.get_reagent_amount(/datum/reagent/consumable/nutriment)
		if(biogen.points >= nutriment && biogen.points >= 5)
			//time to check laser power.
			if(prob(6-failure_grade)) //Chance to make a burned mess so the chef is still useful.
				var/obj/item/reagent_containers/food/snacks/badrecipe/neelixcooking = new /obj/item/reagent_containers/food/snacks/badrecipe(get_turf(src))
				neelixcooking.name = "replicator mess"
				neelixcooking.desc = "perhaps you should invest in some higher quality parts."
				biogen.points -= 5
				qdel(food) //NO FOOD FOR YOU!
				return
			else
				if(temp)
					food.name = "[temp] [food.name]"
					switch(temp)
						if("cold")
							food.reagents.chem_temp = 0
						if("hot")
							food.reagents.chem_temp = 450
						if("extra hot")
							food.reagents.chem_temp = 5000
						if("well done")
							food.reagents.chem_temp = 2000000000000 //A nice warm Steak or a perfectly well boiled Cup of Tea
				if(nutriment > 0)
					biogen.points -= nutriment
				else
					biogen.points -= 5 //Default, in case the food is useless.
				if(emagged)
					food.reagents.add_reagent(/datum/reagent/toxin/munchyserum, nutriment)
					food.reagents.remove_reagent(/datum/reagent/consumable/nutriment, nutriment)
				var/currentHandIndex = user.get_held_index_of_item(food)
				user.put_in_hand(food,currentHandIndex)

		else
			visible_message("<span_class='warning'>Insufficient fuel to create [food]. [src] requires [nutriment] U of biomatter.</span>")
			qdel(food) //NO FOOD FOR YOU!
			return

/obj/item/circuitboard/machine/replicator
	name = "Food Replicator (Machine Board)"
	build_path = /obj/machinery/replicator
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/micro_laser = 1)

/mob/living/simple_animal/kalo/leonard
	name = "Leonard"
	desc = "A holographic pet lizard. Say 'deactivate iguana' if you're a square."

/datum/reagent/toxin/munchyserum //Tasteless alternative to lipolicide, less powerful. This has the reverse of the intended effect of a replicator and makes you hungrier.
	name = "Metabolism Override Toxin"
	description = "A strong toxin that increases the appetite of their victim while dampening their ability to absorb nutrients for as long as it is in their system."
	silent_toxin = TRUE
	reagent_state = LIQUID
	taste_mult = 0 //no flavor
	color = "#F0FFF0"
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/munchyserum/on_mob_life(mob/living/carbon/M)
	if(M.nutrition >= NUTRITION_LEVEL_STARVING+75)
		M.adjust_nutrition(-3)
		M.overeatduration = 0
	return ..()

#undef READY
#undef REPLICATING
