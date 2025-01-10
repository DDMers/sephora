//Nsv13 - Some of our necessary defines. The rest are inline with upstream's files.
#define TRAIT_NODIGEST			"no_digest"
#define TRAIT_SEASICK			"seasick"
#define TRAIT_MARINE_METABOLISM "marine-metabolism"
#define TRAIT_BINARY_SPEAKER	"speaks_binary"
#define TRAIT_MUNITIONS_METABOLISM    "munitions-metabolism" //NSV13
#define TRAIT_MUTATEIMMUNE             "mutate_immune" //NSV13 - IPCs do not get human mutations
#define TRAIT_IPCRADBRAINDAMAGE        "rad_brain_damage" //NSV13 - IPCs take brain damage when exposed to radiation

#define COMSIG_AI_UPDATE_LAWS 	"ai_law_update"

//Lazy cables
#define CABLE_LAYER_1 "l1"
#define CABLE_LAYER_2 "l2"
#define CABLE_LAYER_3 "l3"

#define WRAP_AROUND_VALUE(value, min, max) ( min + ((value - min) % (max - min)) )
#define COMSIG_ALERT_LEVEL_CHANGE "alert_level_changed" //For general quarters

#define COLOR_PUCE "#CC8899"

#define CONQUEST_ROLE_ADMIRAL "Admiral"
#define CONQUEST_ROLE_CAPTAIN "Captain"
#define CONQUEST_ROLE_BRIDGE "Bridge Staff"
#define CONQUEST_ROLE_REQUISITIONS "Requisitions"
#define CONQUEST_ROLE_TECHNICIAN "Technician"
#define CONQUEST_ROLE_CAG "CAG"
#define CONQUEST_ROLE_PILOT "Pilot"
#define CONQUEST_ROLE_SERGEANT "Sergeant"
#define CONQUEST_ROLE_CLOWN "Clown"
#define CONQUEST_ROLE_LINECOOK "Line Cook"
#define CONQUEST_ROLE_GRUNT "Autofill"

//Lizard hiss preference options
#define LIZARD_HISS_LEGACY "Legacy (s only)"
#define LIZARD_HISS_EXPANDED "Expanded (x and s)"

GLOBAL_DATUM_INIT(conquest_role_handler, /datum/conquest_role_handler, new)

#define COMSIG_ATOM_DAMAGE_ACT "comsig_atom_damage_act" //Used when an atom takes damage.

#define PASSDOOR (1<<7) //Can you pass doors?

//Math. Lame.
#define KPA_TO_PSI(A) (A/6.895)
#define PSI_TO_KPA(A) (A*6.895)
#define MEGAWATTS /1e+6

#define HARDPOINT_SLOT_PRIMARY "Primary"
#define HARDPOINT_SLOT_SECONDARY "Secondary"
#define HARDPOINT_SLOT_UTILITY "Utility"
#define HARDPOINT_SLOT_ARMOUR "Armour"
#define HARDPOINT_SLOT_DOCKING "Docking Module"
#define HARDPOINT_SLOT_CANOPY "Canopy"
#define HARDPOINT_SLOT_FUEL "Fuel Tank"
#define HARDPOINT_SLOT_ENGINE "Engine"
#define HARDPOINT_SLOT_RADAR "Radar"
#define HARDPOINT_SLOT_OXYGENATOR "Atmospheric Regulator"
#define HARDPOINT_SLOT_BATTERY "Battery"
#define HARDPOINT_SLOT_APU "APU"
#define HARDPOINT_SLOT_FTL "FTL"
#define HARDPOINT_SLOT_COUNTERMEASURE "Countermeasure"
#define HARDPOINT_SLOT_UTILITY_PRIMARY "Primary Utility"
#define HARDPOINT_SLOT_UTILITY_SECONDARY "Secondary Utility"

#define ALL_HARDPOINT_SLOTS list(HARDPOINT_SLOT_PRIMARY, HARDPOINT_SLOT_SECONDARY,HARDPOINT_SLOT_UTILITY, HARDPOINT_SLOT_ARMOUR, HARDPOINT_SLOT_FUEL, HARDPOINT_SLOT_ENGINE, HARDPOINT_SLOT_RADAR, HARDPOINT_SLOT_CANOPY, HARDPOINT_SLOT_OXYGENATOR,HARDPOINT_SLOT_DOCKING, HARDPOINT_SLOT_BATTERY, HARDPOINT_SLOT_APU, HARDPOINT_SLOT_FTL, HARDPOINT_SLOT_COUNTERMEASURE)
#define HARDPOINT_SLOTS_STANDARD list(HARDPOINT_SLOT_PRIMARY, HARDPOINT_SLOT_SECONDARY, HARDPOINT_SLOT_ARMOUR, HARDPOINT_SLOT_FUEL, HARDPOINT_SLOT_ENGINE, HARDPOINT_SLOT_RADAR,HARDPOINT_SLOT_CANOPY, HARDPOINT_SLOT_OXYGENATOR,HARDPOINT_SLOT_DOCKING, HARDPOINT_SLOT_BATTERY, HARDPOINT_SLOT_APU, HARDPOINT_SLOT_FTL, HARDPOINT_SLOT_COUNTERMEASURE)
#define HARDPOINT_SLOTS_UTILITY list(HARDPOINT_SLOT_UTILITY_PRIMARY,HARDPOINT_SLOT_UTILITY_SECONDARY, HARDPOINT_SLOT_ARMOUR, HARDPOINT_SLOT_FUEL, HARDPOINT_SLOT_ENGINE, HARDPOINT_SLOT_RADAR, HARDPOINT_SLOT_DOCKING, HARDPOINT_SLOT_BATTERY, HARDPOINT_SLOT_APU, HARDPOINT_SLOT_FTL, HARDPOINT_SLOT_COUNTERMEASURE)

#define LOADOUT_DEFAULT_FIGHTER /datum/component/ship_loadout
#define LOADOUT_UTILITY_ONLY /datum/component/ship_loadout/utility

#define ENGINE_RPM_SPUN 8000

#define COMSIG_SHIP_BOARDED "ship_boarded"
#define COMSIG_GLOB_CHECK_INTERDICT "check_interdict"							//from interdiction component
#define WEAK_INTERDICT (1<<0)													//! Not a "true" interdiction in that it disrupts the drive field, relies on scrambling calculations and rendering a jump too dangerous to execute.
#define STRONG_INTERDICT (1<<1)													//! The "true" interdiction, disrupts drive fields to the point any shift is impossible.

//Gaming
#define shares_overmap(A, B) (A.get_overmap() == B.get_overmap())
#define SHARES_OVERMAP_ALLIED(A,B) (A.get_overmap()?.faction == B.get_overmap()?.faction)

#define YEAR_OFFSET 240

//Overmap deletion behavior - Occupants are defined as non-simple mobs.
#define DAMAGE_ALWAYS_DELETES 		0 // Not a real bitflag, just here for readability. If no damage flags are set, damage will delete the overmap immediately regardless of anyone in it
#define DAMAGE_STARTS_COUNTDOWN		(1<<0) // When the overmap takes enough damage to be destroyed, begin a countdown after which it will be deleted
#define DAMAGE_DELETES_UNOCCUPIED	(1<<1) // When the overmap takes enough damage to be destroyed, if there are no occupants, delete it immediately. Modifies DAMAGE_STARTS_COUNTDOWN
#define NEVER_DELETE_OCCUPIED		(1<<2) // Even if the overmap takes enough damage to be destroyed, never delete it if it's occupied. I don't know when we'd use this it just seems useful
#define DELETE_UNOCCUPIED_ON_DEPARTURE 	(1<<3) // When a fighter/dropship leaves the map level for the overmap level, look for remaining occupants. If none exist, delete
#define FIGHTERS_ARE_OCCUPANTS		(1<<4) // Docked overmaps count as occupants when deciding whether to delete something

// Squads
//These names ought to be self explanatory for any XO when he assigns them.
#define DC_SQUAD "Damage Control Team"
#define MEDICAL_SQUAD "Medical Team"
#define SECURITY_SQUAD "Security Support"
#define COMBAT_AIR_PATROL "Combat Air Patrol"
#define MUNITIONS_SUPPORT "Munitions Support"
#define CIC_OPS "CIC Ops"
#define SQUAD_TYPES list(DC_SQUAD, MEDICAL_SQUAD, SECURITY_SQUAD, COMBAT_AIR_PATROL, MUNITIONS_SUPPORT, CIC_OPS)

// Keybindings
#define COMSIG_KB_OVERMAP_ROTATELEFT_DOWN "keybinding_overmap_rotateleft_down"
#define COMSIG_KB_OVERMAP_ROTATERIGHT_DOWN "keybinding_overmap_rotateright_down"
#define COMSIG_KB_OVERMAP_BOOST_DOWN "keybinding_overmap_boost_down"
#define COMSIG_KB_OVERMAP_TOGGLEBRAKES_DOWN "keybinding_overmap_togglebrakes_down"
#define COMSIG_KB_OVERMAP_TOGGLEINERTIA_DOWN "keybinding_overmap_toggleinertia_down"
#define COMSIG_KB_OVERMAP_TOGGLEMOUSEMOVE_DOWN "keybinding_overmap_togglemousemove_down"
#define COMSIG_KB_OVERMAP_CYCLEFIREMODE_DOWN "keybinding_overmap_cyclefiremode_down"
#define COMSIG_KB_OVERMAP_COUNTERMEASURE_DOWN "keybinding_overmap_countermeasure_down"
#define COMSIG_KB_OVERMAP_TOGGLESAFETY_DOWN "keybinding_overmap_togglesafety_down"
#define COMSIG_KB_OVERMAP_WEAPON1_DOWN "keybinding_overmap_weapon1_down"
#define COMSIG_KB_OVERMAP_WEAPON2_DOWN "keybinding_overmap_weapon2_down"
#define COMSIG_KB_OVERMAP_WEAPON3_DOWN "keybinding_overmap_weapon3_down"
#define COMSIG_KB_OVERMAP_WEAPON4_DOWN "keybinding_overmap_weapon4_down"
#define COMSIG_KB_VEHICLE_TOGGLE_BRAKES "keybinding_vehicle_toggle_brakes"
#define COMSIG_KB_OVERMAP_UNLOCK_DOWN "keybinding_overmap_unlock_down"

#define OVERMAP_USER_ROLE_PILOT (1<<0)
#define OVERMAP_USER_ROLE_GUNNER (1<<1)
#define OVERMAP_USER_ROLE_SECONDARY_GUNNER (1<<2)
#define OVERMAP_USER_ROLE_OBSERVER (1<<3)

#define HOLOMAP_EXTRA_STATIONMAP "stationmapformatted"
#define HOLOMAP_EXTRA_STATIONMAPAREAS "stationareas"
#define HOLOMAP_EXTRA_STATIONMAPSMALL "stationmapsmall"

/// AI Hologram Related
#define DUMMY_HUMAN_SLOT_HOLOFORM "dummy_holoform_generation" //NSV13 - AI Custom Holographic Form

#define CUSTOM_HOLOFORM_DELAY 10 SECONDS //prevents spamming to make lag. it's pretty expensive to do this.

#define HOLOFORM_FILTER_AI "FILTER_AI"
#define HOLOFORM_FILTER_STATIC "FILTER_STATIC"
