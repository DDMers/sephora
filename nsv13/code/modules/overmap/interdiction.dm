/*
This component, when added to a overmap object (e.g. asteroid or ship) will allow said object to prevent anything of a different faction from jumping out of its own system.
Welcome to the gardens of kadesh. You shall never leave.
*/

/datum/component/interdiction
    var/obj/structure/overmap/owner

/datum/component/interdiction/Initialize()
    if(!istype(parent, /obj/structure/overmap))
        return COMPONENT_INCOMPATIBLE
    owner = parent
    RegisterSignal(SSdcs, COMSIG_GLOB_CHECK_INTERDICT, PROC_REF(check_interdict))    //It just works - the syndicate, probably.

/datum/component/interdiction/proc/check_interdict(datum/source, obj/structure/overmap/interdicted)
    SIGNAL_HANDLER
    if(!owner.current_system || owner.current_system != interdicted.current_system)
        return
    if(owner.faction == interdicted.faction)
        return
    owner.on_interdict()
    return WEAK_INTERDICT


/*
Is executed if this ship successfully interdicts something. By default, does nothing.
*/
/obj/structure/overmap/proc/on_interdict()
    return
