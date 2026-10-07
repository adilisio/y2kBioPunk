#include "menu_controller.hpp"

using namespace godot;

MenuController::MenuController() {
}

MenuController::~MenuController() {
}

void MenuController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	UtilityFunctions::print("[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.");

	// Auto-connect button signals dynamically as a safety fallback
	Button *btn_new = Object::cast_to<Button>(find_child("NewGameButton", true, false));
	if (btn_new && !btn_new->is_connected("pressed", Callable(this, "on_new_game_pressed"))) {
		btn_new->connect("pressed", Callable(this, "on_new_game_pressed"));
	}

	Button *btn_load = Object::cast_to<Button>(find_child("LoadGameButton", true, false));
	if (btn_load && !btn_load->is_connected("pressed", Callable(this, "on_load_game_pressed"))) {
		btn_load->connect("pressed", Callable(this, "on_load_game_pressed"));
	}

	Button *btn_options = Object::cast_to<Button>(find_child("OptionsButton", true, false));
	if (btn_options && !btn_options->is_connected("pressed", Callable(this, "on_options_pressed"))) {
		btn_options->connect("pressed", Callable(this, "on_options_pressed"));
	}

	Button *btn_credits = Object::cast_to<Button>(find_child("CreditsButton", true, false));
	if (btn_credits && !btn_credits->is_connected("pressed", Callable(this, "on_credits_pressed"))) {
		btn_credits->connect("pressed", Callable(this, "on_credits_pressed"));
	}

	Button *btn_exit = Object::cast_to<Button>(find_child("ExitButton", true, false));
	if (btn_exit && !btn_exit->is_connected("pressed", Callable(this, "on_exit_pressed"))) {
		btn_exit->connect("pressed", Callable(this, "on_exit_pressed"));
	}

	Node *save_manager = get_node_or_null(NodePath("/root/SaveManager"));
	if (btn_load && save_manager) {
		bool has_save = save_manager->call("has_save_data");
		btn_load->set_visible(has_save);
	}
}

void MenuController::on_new_game_pressed() {
	UtilityFunctions::print("[Y2K-MENU] 'NEW GAME' selected! Transitioning to main gameplay...");
	Node *save_manager = get_node_or_null(NodePath("/root/SaveManager"));
	if (save_manager) {
		save_manager->call("clear_save");
	}
	SceneTree *tree = get_tree();
	if (tree) {
		tree->change_scene_to_file("res://scenes/FloodedMall_Greybox.tscn");
	}
}

void MenuController::on_load_game_pressed() {
	UtilityFunctions::print("[Y2K-MENU] 'CONTINUE' selected! Loading save...");
	Node *save_manager = get_node_or_null(NodePath("/root/SaveManager"));
	if (save_manager) {
		save_manager->set("pending_load", true);
	}
	SceneTree *tree = get_tree();
	if (tree) {
		tree->change_scene_to_file("res://scenes/FloodedMall_Greybox.tscn");
	}
}

void MenuController::on_options_pressed() {
	UtilityFunctions::print("[Y2K-MENU] 'OPTIONS' selected! (Sound / Display / Controls configuration in development)");
}

void MenuController::on_credits_pressed() {
	UtilityFunctions::print("[Y2K-MENU] 'CREDITS' selected! Project: Bio-Punk ARPG (Y2K Retro-Future Biological Apocalypse)");
}

void MenuController::on_exit_pressed() {
	UtilityFunctions::print("[Y2K-MENU] 'EXIT GAME' selected! Terminating session...");
	SceneTree *tree = get_tree();
	if (tree) {
		tree->quit();
	}
}

String MenuController::get_target_game_scene() const {
	return target_game_scene;
}

void MenuController::set_target_game_scene(const String &p_path) {
	target_game_scene = p_path;
}

void MenuController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("on_new_game_pressed"), &MenuController::on_new_game_pressed);
	ClassDB::bind_method(D_METHOD("on_load_game_pressed"), &MenuController::on_load_game_pressed);
	ClassDB::bind_method(D_METHOD("on_options_pressed"), &MenuController::on_options_pressed);
	ClassDB::bind_method(D_METHOD("on_credits_pressed"), &MenuController::on_credits_pressed);
	ClassDB::bind_method(D_METHOD("on_exit_pressed"), &MenuController::on_exit_pressed);

	ClassDB::bind_method(D_METHOD("get_target_game_scene"), &MenuController::get_target_game_scene);
	ClassDB::bind_method(D_METHOD("set_target_game_scene", "path"), &MenuController::set_target_game_scene);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "target_game_scene"), "set_target_game_scene", "get_target_game_scene");
}
