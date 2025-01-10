//#define LOWMEMORYMODE //uncomment this to load centcom and runtime station and thats it.

#include "map_files\generic\CentCom.dmm"

#ifndef LOWMEMORYMODE
	#ifdef ALL_MAPS
		//Debug/Special Maps
		#include "map_files\Mining\Lavaland.dmm"
		#include "map_files\debug\runtimestation.dmm"

		//Atlas
		#include "map_files\Atlas\Atlas.dmm"
		#include "map_files\Atlas\Atlas2.dmm"

		//Aetherwhisp
		#include "map_files\Aetherwhisp\Aetherwhisp2.dmm"
		#include "map_files\Aetherwhisp\Aetherwhisp1.dmm"

		//Von Neumann
		#include "map_files\vonneumann\VNmk3.dmm"

		//Gladius
		#include "map_files\Gladius\Gladius1.dmm"
		#include "map_files\Gladius\Gladius2.dmm"

		//Tycoon
		#include "map_files\Tycoon\Tycoon1.dmm"
		#include "map_files\Tycoon\Tycoon2.dmm"

		//Eclipse
		#include "map_files\Eclipse\Eclipse1.dmm"
		#include "map_files\Eclipse\Eclipse2.dmm"

		//Galactica
		#include "map_files\Galactica\Galactica1.dmm"
		#include "map_files\Galactica\Galactica2.dmm"

		//Vago
		#include "map_files\Vago\vagodeck1.dmm"
		#include "map_files\Vago\vagodeck2.dmm"

		//Snake
		#include "map_files\Snake\snake_lower.dmm"
		#include "map_files\Snake\snake_upper.dmm"

		#ifdef CIBUILDING
			#include "templates.dm"
		#endif
	#endif
#endif
