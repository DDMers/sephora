/*
 * File for system miners. As opposed to being infinite, these get their gasses from accessing a star system's gas resources, via proximity to gas clouds.
 * systems outside the commonly traversed areas generally are the main source for these, as they are usually pretty mined out otherwise.
*/

#define GASMINER_POWER_NONE 0
#define GASMINER_POWER_STATIC 1
#define GASMINER_POWER_MOLES 2	//Scaled from here on down.
#define GASMINER_POWER_KPA 3
#define GASMINER_POWER_FULLSCALE 4

/obj/machinery/atmospherics/miner/system
    name = "long-range gas collector"
    desc = "A marvel of engineering, these devices use highly complicated processes to collect gasses over big distances."
    power_draw = GASMINER_POWER_STATIC
    var/obj/structure/overmap/attached_overmap = null
    spawn_mol = 200 //200 moles mined per tick, if there is enough.

/obj/machinery/atmospherics/miner/system/Initialize()
    . = ..()
    return INITIALIZE_HINT_LATELOAD

/obj/machinery/atmospherics/miner/system/LateInitialize()
    . = ..()
    attached_overmap = get_overmap()

/obj/machinery/atmospherics/miner/system/check_operation()
    if(!attached_overmap)
        broken_message = "<span class='boldwarning'>DEVICE INSTALLED IN INVALID OPERATING ENVIRONMENT</span>"
        set_broken(TRUE)
        return FALSE
    var/obj/effect/overmap_anomaly/gas_cloud/gas_cloud = attached_overmap.locked_gas_cloud
    if(!gas_cloud)
        broken_message = "<span class='boldnotice'>No harvestable gas sources are currently targeted.</span>"
        set_broken(TRUE)
        return FALSE
    if(!gas_cloud.gas_resources[spawn_id] || gas_cloud.gas_resources[spawn_id] <= 0)
        broken_message = "<span class='boldnotice'>No more accessible gas of configured type detected.</span>"
        set_broken(TRUE)
        return FALSE
    return ..()

//OVERRIDES PARENT PROC due to some changes in this
/obj/machinery/atmospherics/miner/system/mine_gas()
    var/turf/open/O = get_turf(src)
    if(!isopenturf(O))
        return FALSE
    var/datum/gas_mixture/merger = new
    var/list/minables = attached_overmap.locked_gas_cloud.gas_resources
    var/available = minables["[spawn_id]"]
    var/extracting = min(available, spawn_mol)
    minables["[spawn_id]"] -= extracting
    merger.set_moles(spawn_id, extracting)
    merger.set_temperature(spawn_temp)
    O.assume_air(merger)
    O.air_update_turf(TRUE)

/obj/machinery/atmospherics/miner/system/examine(mob/user)
    . = ..()
    if(!spawn_id)
        return
    if(!attached_overmap || !attached_overmap.locked_gas_cloud)
        return
    var/gas_amount = 0
    if(attached_overmap.locked_gas_cloud.gas_resources["[spawn_id]"])
        gas_amount = attached_overmap.locked_gas_cloud.gas_resources["[spawn_id]"]
    var/datum/gas/gas_prototype = spawn_id
    . += "Remaining [initial(gas_prototype.name)] supply within currently targeted source: <b>[gas_amount]</b> moles."

/obj/machinery/atmospherics/miner/system/n2o
	name = "\improper N2O Gas Collector"
	overlay_color = "#FFCCCC"
	spawn_id = /datum/gas/nitrous_oxide

/obj/machinery/atmospherics/miner/system/nitrogen
	name = "\improper N2 Gas Collector"
	overlay_color = "#CCFFCC"
	spawn_id = /datum/gas/nitrogen

/obj/machinery/atmospherics/miner/system/oxygen
	name = "\improper O2 Gas Collector"
	overlay_color = "#007FFF"
	spawn_id = /datum/gas/oxygen

/obj/machinery/atmospherics/miner/system/toxins
	name = "\improper Plasma Gas Collector"
	overlay_color = "#FF0000"
	spawn_id = /datum/gas/plasma

/obj/machinery/atmospherics/miner/system/carbon_dioxide
	name = "\improper CO2 Gas Collector"
	overlay_color = "#CDCDCD"
	spawn_id = /datum/gas/carbon_dioxide

/obj/machinery/atmospherics/miner/system/bz
	name = "\improper BZ Gas Collector"
	overlay_color = "#FAFF00"
	spawn_id = /datum/gas/bz

/obj/machinery/atmospherics/miner/system/water_vapor
	name = "\improper Water Vapor Gas Collector"
	overlay_color = "#99928E"
	spawn_id = /datum/gas/water_vapor


#undef GASMINER_POWER_NONE 
#undef GASMINER_POWER_STATIC 
#undef GASMINER_POWER_MOLES
#undef GASMINER_POWER_KPA 
#undef GASMINER_POWER_FULLSCALE 
