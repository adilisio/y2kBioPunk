#include "register_types.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "player_controller.hpp"
#include "mutated_bug_enemy.hpp"
#include "stranded_soldier_npc.hpp"
#include "menu_controller.hpp"
#include "intro_controller.hpp"

using namespace godot;

void initialize_biopunk_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_CLASS(PlayerController);
	GDREGISTER_CLASS(MutatedBugEnemy);
	GDREGISTER_CLASS(StrandedSoldierNPC);
	GDREGISTER_CLASS(MenuController);
	GDREGISTER_CLASS(IntroController);
}

void uninitialize_biopunk_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
// GDExtension library entry point matching entry_symbol in biopunk.gdextension
GDExtensionBool GDE_EXPORT biopunk_library_init(
	GDExtensionInterfaceGetProcAddress p_get_proc_address,
	GDExtensionClassLibraryPtr p_library,
	GDExtensionInitialization *r_initialization
) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_biopunk_module);
	init_obj.register_terminator(uninitialize_biopunk_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
