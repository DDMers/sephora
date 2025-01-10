//Cargo

/datum/map_template/shuttle/cargo/hammerhead
	suffix = "hammerhead"
	name = "\[NSV\] cargo ferry (Hammerhead)"

/datum/map_template/shuttle/ferry/galactica
	suffix = "galactica"
	name = "\[NSV\] centcom ferry (Galactica)"

/datum/map_template/shuttle/cargo/sausage
	suffix = "sausage"
	name = "\[NSV\] cargo ferry (Jolly Sausage)"

/datum/map_template/shuttle/cargo/gladius
	suffix = "gladius"
	name = "\[NSV\] cargo ferry (Gladius)"

/datum/map_template/shuttle/cargo/atlas
	suffix = "atlas"
	name = "\[NSV\] cargo elevator (Atlas)"

/datum/map_template/shuttle/cargo/shrike
	suffix = "shrike"
	name = "\[NSV\] cargo ferry (Shrike)"

/datum/map_template/shuttle/cargo/serendipity
	suffix = "serendipity"
	name = "\[NSV\] cargo ferry (Serendipity)"

/datum/map_template/shuttle/cargo/aiship
	suffix = "aiship"
	name = "\[NSV\] cargo ferry (Von Neumann)"

//Arrivals

/datum/map_template/shuttle/arrival/aetherwhisp
	suffix = "aetherwhisp"
	name = "arrival shuttle (Aetherwhisp)"

/datum/map_template/shuttle/arrival/gladius
	suffix = "gladius"
	name = "arrival shuttle (Gladius)"

/datum/map_template/shuttle/arrival/shrike
	suffix = "shrike"
	name = "arrival shuttle (Shrike)"

/datum/map_template/shuttle/arrival/serendipity
	suffix = "serendipity"
	name = "arrival shuttle (Serendipity)"

/datum/map_template/shuttle/hammurabi //This is definitely an elevator trust me.
	prefix = "_maps/shuttles/turbolifts/"
	port_id = "elevator"
	suffix = "hammurabi"
	name = "Hammurabi mining elevator"
//Mining

/datum/map_template/shuttle/mining/shrike
	suffix = "shrike"
	name = "mining shuttle (Shrike)"

//Escape
/datum/map_template/shuttle/escape_pod/shrike
	suffix = "shrike"
	name = "escape pod (Shrike)"

/datum/map_template/shuttle/emergency/void
	suffix = "void"
	name = "Void Emergency Shuttle"
	description = "Not even a shuttle."
	admin_notes = "Used for escape pod only maps"
	credit_cost = 0
	can_be_bought = FALSE

/datum/map_template/shuttle/emergency/atlas
	suffix = "atlas"
	name = "Danube Class Yacht"
	description = "A small, luxurious shuttle capable of ferrying small - medium crews in comfort and style."
	credit_cost = 4000

/datum/map_template/shuttle/emergency/celerity
	suffix = "celerity"
	name = "Dominion of Light Evacuation Shuttle, Celerity Class"
	admin_notes = "This shuttle will not work for any other ship than the Serendipity"
	can_be_bought = FALSE
