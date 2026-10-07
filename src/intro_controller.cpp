#include "intro_controller.hpp"

using namespace godot;

IntroController::IntroController() {
}

IntroController::~IntroController() {
}

void IntroController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	set_process(true);
	set_process_input(true);

	skip_label = Object::cast_to<Label>(find_child("SkipLabel", true, false));

	VideoStreamPlayer *player = Object::cast_to<VideoStreamPlayer>(find_child("VideoStreamPlayer", true, false));
	if (player) {
		if (!player->is_connected("finished", Callable(this, "_on_video_finished"))) {
			player->connect("finished", Callable(this, "_on_video_finished"));
		}
	}

	UtilityFunctions::print("[Y2K-INTRO] IntroController ready! Press any key or mouse button to skip.");
}

void IntroController::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	blink_timer += static_cast<float>(p_delta);
	if (skip_label) {
		float alpha = 0.35f + 0.65f * (0.5f * (1.0f + Math::sin(blink_timer * 4.5f)));
		skip_label->set_modulate(Color(0.85f, 0.95f, 1.0f, alpha));
	}
}

void IntroController::_input(const Ref<InputEvent> &p_event) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	if (p_event.is_null()) {
		return;
	}

	Ref<InputEventKey> key_event = p_event;
	if (key_event.is_valid() && key_event->is_pressed() && !key_event->is_echo()) {
		transition_to_main_menu();
		return;
	}

	Ref<InputEventMouseButton> mouse_event = p_event;
	if (mouse_event.is_valid() && mouse_event->is_pressed()) {
		transition_to_main_menu();
		return;
	}
}

void IntroController::_gui_input(const Ref<InputEvent> &p_event) {
	_input(p_event);
}

void IntroController::_on_video_finished() {
	UtilityFunctions::print("[Y2K-INTRO] Video finished playback. Advancing to Main Menu...");
	transition_to_main_menu();
}

void IntroController::transition_to_main_menu() {
	if (has_transitioned) {
		return;
	}
	has_transitioned = true;

	UtilityFunctions::print("[Y2K-INTRO] Transitioning to Main Menu (", target_menu_scene, ")...");
	SceneTree *tree = get_tree();
	if (tree) {
		tree->change_scene_to_file("res://scenes/main_menu.tscn");
	}
}

String IntroController::get_target_menu_scene() const {
	return target_menu_scene;
}

void IntroController::set_target_menu_scene(const String &p_scene) {
	target_menu_scene = p_scene;
}

void IntroController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_on_video_finished"), &IntroController::_on_video_finished);
	ClassDB::bind_method(D_METHOD("transition_to_main_menu"), &IntroController::transition_to_main_menu);

	ClassDB::bind_method(D_METHOD("get_target_menu_scene"), &IntroController::get_target_menu_scene);
	ClassDB::bind_method(D_METHOD("set_target_menu_scene", "scene_path"), &IntroController::set_target_menu_scene);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "target_menu_scene"), "set_target_menu_scene", "get_target_menu_scene");
}
