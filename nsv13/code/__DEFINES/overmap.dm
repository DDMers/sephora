//Weapon modes

#define FIRE_MODE_ANTI_AIR 1
#define FIRE_MODE_TORPEDO 2

//Revision 2.
#define FIRE_MODE_AMS_LASER 3 // Laser AMS should be fired before expensive missiles are fired, so this is prioritized first
#define FIRE_MODE_AMS 4 //You don't get to physically fire this one.
#define FIRE_MODE_MAC 5
#define FIRE_MODE_RAILGUN 6
#define FIRE_MODE_GAUSS 7
#define FIRE_MODE_PDC 8
#define FIRE_MODE_BROADSIDE 9
#define FIRE_MODE_PHORON 10

//Base Armor Values

#define OM_ARMOR list("melee" = 100, "bullet" = 100, "laser" = 100, "energy" = 100, "bomb" = 80, "bio" = 100, "rad" = 100, "acid" = 100, "stamina" = 100)

//Deprecated / legacy weapons.


#define FIRE_MODE_FLAK 11
#define FIRE_MODE_MISSILE 12
#define FIRE_MODE_FIGHTER_SLOT_ONE 13
#define FIRE_MODE_FIGHTER_SLOT_TWO 14

//Special cases

#define FIRE_MODE_RED_LASER 15
#define FIRE_MODE_LASER_PD 16
#define FIRE_MODE_BLUE_LASER 17
#define FIRE_MODE_HYBRID_RAIL 18

#define MAX_POSSIBLE_FIREMODE 18 //This should relate to the maximum number of weapons a ship can ever have. Keep this up to date please!

//Weapon classes for AIs
#define WEAPON_CLASS_LIGHT 1
#define WEAPON_CLASS_HEAVY 2

// AMS targeting modes for STS
#define AMS_LOCKED_TARGETS "Locked Targets"
#define AMS_PAINTED_TARGETS "Painted Targets"

//Northeast, Northwest, Southeast, Southwest
#define ARMOUR_FORWARD_PORT "forward_port"
#define ARMOUR_FORWARD_STARBOARD "forward_starboard"
#define ARMOUR_AFT_PORT "aft_port"
#define ARMOUR_AFT_STARBOARD "aft_starboard"

//AI behaviour

#define AI_AGGRESSIVE 1
#define AI_PASSIVE 2
#define AI_RETALIATE 3
#define AI_GUARD 4

#define isovermap(A) (istype(A, /obj/structure/overmap))
#define isasteroid(A) (istype(A, /obj/structure/overmap/asteroid))
#define isanomaly(A) (istype(A, /obj/effect/overmap_anomaly))

//Assigning player ships goes here

#define NORMAL_OVERMAP 1
#define MAIN_OVERMAP 2
#define MAIN_MINING_SHIP 3
#define PVP_SHIP 4
#define INSTANCED_MIDROUND_SHIP 5

//Sensor resolution

#define SENSOR_VISIBILITY_FULL 1
#define SENSOR_VISIBILITY_TARGETABLE 0.70 //You have to be close up, or not cloaked to be targetable by the ship's gunner.
#define SENSOR_VISIBILITY_FAINT 0.5
#define SENSOR_VISIBILITY_VERYFAINT 0.25
#define SENSOR_VISIBILITY_GHOST 0 //Totally impervious to scans.

#define SENSOR_RANGE_DEFAULT 40
#define SENSOR_RANGE_FIGHTER 30 //Fighters have crappier sensors. Coordinate with the ATC!

#define CLOAK_TEMPORARY_LOSS 2 //Cloak handling. When you fire a weapon, you temporarily lose your cloak, and AIs can target you.

GLOBAL_LIST_INIT(overmap_objects, list())
GLOBAL_LIST_INIT(overmap_anomalies, list())
GLOBAL_LIST_INIT(overmap_impact_sounds, list('nsv13/sound/effects/ship/freespace2/impacts/boom_1.wav','nsv13/sound/effects/ship/freespace2/impacts/boom_2.wav','nsv13/sound/effects/ship/freespace2/impacts/boom_3.wav','nsv13/sound/effects/ship/freespace2/impacts/boom_4.wav','nsv13/sound/effects/ship/freespace2/impacts/m_hit.wav','nsv13/sound/effects/ship/freespace2/impacts/subhit.wav','nsv13/sound/effects/ship/freespace2/impacts/subhit2.wav','nsv13/sound/effects/ship/damage/consolehit.ogg','nsv13/sound/effects/ship/damage/consolehit2.ogg','nsv13/sound/effects/ship/damage/consolehit3.ogg','nsv13/sound/effects/ship/damage/consolehit4.ogg','nsv13/sound/effects/ship/damage/shiphit.ogg','nsv13/sound/effects/ship/damage/shiphit2.ogg','nsv13/sound/effects/ship/damage/shiphit3.ogg','nsv13/sound/effects/ship/damage/shiphit4.ogg','nsv13/sound/effects/ship/damage/torpedo_hit.ogg','nsv13/sound/effects/ship/damage/explosionfar_2.ogg','nsv13/sound/effects/ship/damage/explosionfar_3.ogg','nsv13/sound/effects/ship/damage/explosionfar_4.ogg','nsv13/sound/effects/ship/damage/explosionfar_5.ogg','nsv13/sound/effects/ship/damage/explosionfar_6.ogg'))

//Unique identifiers for each faction. Keep this updated when you make a new faction.
#define FACTION_ID_UNALIGNED 0
#define FACTION_ID_NT 1
#define FACTION_ID_SYNDICATE 2
#define FACTION_ID_SOLGOV 3
#define FACTION_ID_UNATHI 4
#define FACTION_ID_PIRATES 5

#define NO_INTERIOR 0
#define INTERIOR_EXCLUSIVE 1 // Only one of them at a time, occupies a whole Z level
#define INTERIOR_DYNAMIC 2 // Can have more than one, reserves space on the reserved Z

#define INTERIOR_NOT_LOADED 0
#define INTERIOR_LOADING 1
#define INTERIOR_READY 2
#define INTERIOR_DELETING 3
#define INTERIOR_DELETED 4

//Overmap flags
#define OVERMAP_FLAG_ZLEVEL_CARRIER (1<<0) //! This overmap is meant to carry a z with it, prompting restoration in certain cases.

//Ship mass
#define MASS_TINY 1 //1 Player - Fighters
#define MASS_SMALL 2 //2-5 Players - FoB/Mining Ship
#define MASS_MEDIUM 3 //10-20 Players - Small Capital Ships
#define MASS_MEDIUM_LARGE 5 //10-20 Players - Small Capital Ships
#define MASS_LARGE 7 //20-40 Players - Medium Capital Ships
#define MASS_TITAN 150 //40+ Players - Large Capital Ships
#define MASS_IMMOBILE 200 //Things that should not be moving. See: stations

//Collision stuff
#define OVERMAP_COLLISION_COOLDOWN 1 SECONDS //! Cooldown between collisions.
#define OVERMAP_COLLISION_MAGNIFIER 4 //! All collision damage big enough to go into the damage calculation itself is multiplied by this.
#define HAMMERHEAD_COLLISION_GUARD_ANGLE 55 //! Angle that determines maximum variance of collision angle to ship angle to count as "head" impact.

//Fun tools
#define SHIELD_NOEFFECT 0 //!Shield failed to absorb hit.
#define SHIELD_ABSORB 1 //!Shield absorbed hit.
#define SHIELD_FORCE_DEFLECT 2 //!Shield absorbed hit and is redirecting projectile with slightly turned vector.
#define SHIELD_FORCE_REFLECT 3 //!Shield absorbed hit and is redirecting projectile in reverse direction.

//Emergency FTL stuff.

#define EMERGENCY_FTL_RANGE 120 //! Range of Emergency FTL jump (uncontrolled)
#define EMERGENCY_FTL_COOLDOWN 35 MINUTES //!Cooldown of FTL drives between emergency jumps.

//Interior instancing comsig, aka cursed things.
#define COMSIG_INTERIOR_DONE_LOADING "interior_done_loading"
