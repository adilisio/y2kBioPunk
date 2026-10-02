#include "stranded_soldier_npc.hpp"
#include "player_controller.hpp"

#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/collision_shape2d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

StrandedSoldierNPC::StrandedSoldierNPC() {
}

StrandedSoldierNPC::~StrandedSoldierNPC() {
}

void StrandedSoldierNPC::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	// Ensure CollisionShape2D exists
	CollisionShape2D *col = Object::cast_to<CollisionShape2D>(find_child("CollisionShape2D", false, false));
	if (!col) {
		col = memnew(CollisionShape2D);
		Ref<CircleShape2D> circle;
		circle.instantiate();
		circle->set_radius(interaction_radius);
		col->set_shape(circle);
		add_child(col);
	}

	// Overhead prompt label
	prompt_label = Object::cast_to<Label>(find_child("PromptLabel", false, false));
	if (!prompt_label) {
		prompt_label = memnew(Label);
		prompt_label->set_name("PromptLabel");
		prompt_label->set_text("[E: Talk to Soldier]");
		prompt_label->set_position(Vector2(-60.0f, -55.0f));
		prompt_label->set_modulate(Color(0.2f, 1.0f, 0.75f, 1.0f));
		prompt_label->set_visible(false);
		add_child(prompt_label);
	}

	UtilityFunctions::print("[Y2K-NPC] '", npc_name, "' deployed at position ", get_global_position(), "! Vibe DC: ", vibe_check_difficulty);
}

void StrandedSoldierNPC::_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	Node *parent = get_parent();
	if (!parent) {
		return;
	}

	PlayerController *player = Object::cast_to<PlayerController>(parent->find_child("Player", false, false));
	if (player) {
		Vector3 p_pos = player->get_global_position();
		Vector2 p_pos_2d(p_pos.x, p_pos.z);
		float dist = (p_pos_2d - get_global_position()).length();
		is_player_in_range = (dist <= interaction_radius);
	} else {
		is_player_in_range = false;
	}

	if (prompt_label) {
		prompt_label->set_visible(is_player_in_range);
	}

	if (is_player_in_range) {
		Input *input = Input::get_singleton();
		bool e_down = input && input->is_key_pressed(Key::KEY_E);
		if (e_down && !e_key_was_pressed) {
			trigger_dialogue();
		}
		e_key_was_pressed = e_down;
	} else {
		e_key_was_pressed = false;
	}
}

void StrandedSoldierNPC::trigger_dialogue() {
	Node *parent = get_parent();
	if (!parent) {
		return;
	}

	PlayerController *player = Object::cast_to<PlayerController>(parent->find_child("Player", false, false));
	if (player) {
		player->set_movement_locked(true);
	}

	UtilityFunctions::print("[Y2K-NPC] Spoke to '", npc_name, "'! Opening dialogue window. Player movement locked.");
	emit_signal("dialogue_opened", this);
}

bool StrandedSoldierNPC::evaluate_vibe_check(PlayerController *p_player) {
	if (!p_player) {
		return false;
	}

	int effective_vibe = p_player->get_effective_vibe();
	bool passed = (effective_vibe >= vibe_check_difficulty);

	UtilityFunctions::print("[Y2K-SKILLCHECK] Evaluating [Vibe ", vibe_check_difficulty, "] Check: Player Effective Vibe is ", effective_vibe, " (Base: ", p_player->get_vibe(), ", Tape: '", p_player->get_current_tape(), "') -> Outcome: ", passed ? "SUCCESS!" : "FAILED!");

	if (passed) {
		already_persuaded = true;
	}
	return passed;
}

String StrandedSoldierNPC::get_npc_name() const {
	return npc_name;
}

void StrandedSoldierNPC::set_npc_name(const String &p_name) {
	npc_name = p_name;
}

int StrandedSoldierNPC::get_vibe_check_difficulty() const {
	return vibe_check_difficulty;
}

void StrandedSoldierNPC::set_vibe_check_difficulty(int p_diff) {
	vibe_check_difficulty = p_diff;
}

bool StrandedSoldierNPC::get_already_persuaded() const {
	return already_persuaded;
}

void StrandedSoldierNPC::set_already_persuaded(bool p_persuaded) {
	already_persuaded = p_persuaded;
}

bool StrandedSoldierNPC::get_is_player_in_range() const {
	return is_player_in_range;
}

void StrandedSoldierNPC::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_npc_name"), &StrandedSoldierNPC::get_npc_name);
	ClassDB::bind_method(D_METHOD("set_npc_name", "name"), &StrandedSoldierNPC::set_npc_name);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "npc_name"), "set_npc_name", "get_npc_name");

	ClassDB::bind_method(D_METHOD("get_vibe_check_difficulty"), &StrandedSoldierNPC::get_vibe_check_difficulty);
	ClassDB::bind_method(D_METHOD("set_vibe_check_difficulty", "difficulty"), &StrandedSoldierNPC::set_vibe_check_difficulty);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "vibe_check_difficulty"), "set_vibe_check_difficulty", "get_vibe_check_difficulty");

	ClassDB::bind_method(D_METHOD("get_already_persuaded"), &StrandedSoldierNPC::get_already_persuaded);
	ClassDB::bind_method(D_METHOD("set_already_persuaded", "persuaded"), &StrandedSoldierNPC::set_already_persuaded);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "already_persuaded"), "set_already_persuaded", "get_already_persuaded");

	ClassDB::bind_method(D_METHOD("get_is_player_in_range"), &StrandedSoldierNPC::get_is_player_in_range);

	ClassDB::bind_method(D_METHOD("trigger_dialogue"), &StrandedSoldierNPC::trigger_dialogue);
	ClassDB::bind_method(D_METHOD("evaluate_vibe_check", "player"), &StrandedSoldierNPC::evaluate_vibe_check);

	ADD_SIGNAL(MethodInfo("dialogue_opened", PropertyInfo(Variant::OBJECT, "npc")));
}
