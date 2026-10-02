#include "mutated_bug_enemy.hpp"
#include "player_controller.hpp"

#include <godot_cpp/classes/callback_tweener.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

MutatedBugEnemy::MutatedBugEnemy() {
}

MutatedBugEnemy::~MutatedBugEnemy() {
}

void MutatedBugEnemy::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	set_motion_mode(MOTION_MODE_FLOATING);
	set_modulate(hostile_color);
	current_health = max_health;

	UtilityFunctions::print("[Y2K-BUG] MutatedBugEnemy '", bug_species, "' spawned! HP: ", current_health, "/", max_health, ". Cable Channel ", cable_channel_frequency, " dial-up hum online!");
}

Vector2 MutatedBugEnemy::get_random_isometric_direction() {
	static const Vector2 iso_dirs[8] = {
		Vector2(1.0f, 0.5f).normalized(),
		Vector2(-1.0f, -0.5f).normalized(),
		Vector2(-1.0f, 0.5f).normalized(),
		Vector2(1.0f, -0.5f).normalized(),
		Vector2(0.0f, 1.0f),
		Vector2(0.0f, -1.0f),
		Vector2(1.0f, 0.0f),
		Vector2(-1.0f, 0.0f)
	};

	int idx = UtilityFunctions::randi() % 8;
	return iso_dirs[idx];
}

void MutatedBugEnemy::_physics_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	if (is_dead) {
		set_velocity(Vector2(0.0f, 0.0f));
		move_and_slide();
		return;
	}

	wander_timer += p_delta;
	if (wander_timer >= wander_interval) {
		wander_timer = 0.0;
		if (UtilityFunctions::randf() < 0.3f) {
			wander_direction = Vector2(0.0f, 0.0f);
		} else {
			wander_direction = get_random_isometric_direction();
		}
	}

	set_velocity(wander_direction * movement_speed);
	move_and_slide();
}

void MutatedBugEnemy::take_damage(float p_damage) {
	if (is_dead) {
		return;
	}

	current_health = UtilityFunctions::maxf(0.0f, current_health - p_damage);
	UtilityFunctions::print("[Y2K-BUG] '", bug_species, "' took ", p_damage, " damage! HP remaining: ", current_health, "/", max_health);

	// Floating damage combat text
	spawn_floating_text("-" + String::num(static_cast<int>(p_damage)) + " HP", Color(1.0f, 0.85f, 0.2f, 1.0f));

	// Damage flash
	set_modulate(Color(1.0f, 0.2f, 0.2f, 1.0f));
	Ref<Tween> flash_tween = create_tween();
	if (flash_tween.is_valid()) {
		flash_tween->tween_property(this, NodePath("modulate"), hostile_color, 0.15);
	}

	emit_signal("health_changed", current_health, max_health);

	if (current_health <= 0.0f) {
		die();
	}
}

void MutatedBugEnemy::die() {
	if (is_dead) {
		return;
	}
	is_dead = true;

	UtilityFunctions::print("[Y2K-BUG] *** SQUASHED! *** '", bug_species, "' health reached 0. Freeing queue.");
	spawn_floating_text("-BUG SQUASHED! (+35 XP)-", Color(1.0f, 0.2f, 0.2f, 1.0f));

	// Award XP to player
	Node *parent = get_parent();
	if (parent) {
		PlayerController *player = Object::cast_to<PlayerController>(parent->find_child("Player", false, false));
		if (player) {
			player->gain_xp(35);
		}
	}

	drop_bio_sample();
	emit_signal("died");

	queue_free();
}

void MutatedBugEnemy::drop_bio_sample() {
	if (sample_dropped) {
		return;
	}
	sample_dropped = true;

	Node *parent = get_parent();
	if (!parent) {
		return;
	}

	Node2D *sample_node = memnew(Node2D);
	sample_node->set_name("BioSampleItem");
	sample_node->set_global_position(get_global_position() + Vector2(0.0f, 18.0f));

	Sprite2D *sample_sprite = memnew(Sprite2D);
	sample_sprite->set_scale(Vector2(0.28f, 0.28f));
	sample_sprite->set_modulate(Color(1.0f, 0.85f, 0.25f, 1.0f)); // Glowing amber bio-vial

	Ref<Texture2D> tex = ResourceLoader::get_singleton()->load("res://icon.svg");
	if (tex.is_valid()) {
		sample_sprite->set_texture(tex);
	}
	sample_node->add_child(sample_sprite);

	Label *sample_label = memnew(Label);
	sample_label->set_text("[BIO-SAMPLE]");
	sample_label->set_position(Vector2(-42.0f, 16.0f));
	sample_label->set_modulate(Color(1.0f, 0.9f, 0.35f, 1.0f));
	sample_node->add_child(sample_label);

	parent->add_child(sample_node);
}

void MutatedBugEnemy::spawn_floating_text(const String &p_text, const Color &p_color) {
	Node *parent = get_parent();
	if (!parent) {
		return;
	}

	Label *floating_label = memnew(Label);
	floating_label->set_text(p_text);
	floating_label->set_modulate(p_color);
	floating_label->set_global_position(get_global_position() + Vector2(-75.0f, -45.0f));

	parent->add_child(floating_label);

	Ref<Tween> tween = create_tween();
	if (tween.is_valid()) {
		Vector2 target_pos = floating_label->get_position() + Vector2(0.0f, -55.0f);
		tween->tween_property(floating_label, NodePath("position"), target_pos, 1.3);
		Color fade_color = p_color;
		fade_color.a = 0.0f;
		tween->parallel()->tween_property(floating_label, NodePath("modulate"), fade_color, 1.3);
		tween->tween_callback(Callable(floating_label, "queue_free"));
	}
}

float MutatedBugEnemy::get_current_health() const {
	return current_health;
}

void MutatedBugEnemy::set_current_health(float p_hp) {
	current_health = UtilityFunctions::clampf(p_hp, 0.0f, max_health);
	if (current_health <= 0.0f && !is_dead) {
		die();
	}
}

float MutatedBugEnemy::get_max_health() const {
	return max_health;
}

void MutatedBugEnemy::set_max_health(float p_max_hp) {
	max_health = UtilityFunctions::maxf(1.0f, p_max_hp);
}

bool MutatedBugEnemy::get_is_dead() const {
	return is_dead;
}

String MutatedBugEnemy::get_bug_species() const {
	return bug_species;
}

void MutatedBugEnemy::set_bug_species(const String &p_species) {
	bug_species = p_species;
}

float MutatedBugEnemy::get_movement_speed() const {
	return movement_speed;
}

void MutatedBugEnemy::set_movement_speed(float p_speed) {
	movement_speed = p_speed;
}

int MutatedBugEnemy::get_cable_channel_frequency() const {
	return cable_channel_frequency;
}

void MutatedBugEnemy::set_cable_channel_frequency(int p_channel) {
	cable_channel_frequency = p_channel;
}

void MutatedBugEnemy::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_current_health"), &MutatedBugEnemy::get_current_health);
	ClassDB::bind_method(D_METHOD("set_current_health", "health"), &MutatedBugEnemy::set_current_health);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_health"), "set_current_health", "get_current_health");

	ClassDB::bind_method(D_METHOD("get_max_health"), &MutatedBugEnemy::get_max_health);
	ClassDB::bind_method(D_METHOD("set_max_health", "max_health"), &MutatedBugEnemy::set_max_health);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_health"), "set_max_health", "get_max_health");

	ClassDB::bind_method(D_METHOD("get_is_dead"), &MutatedBugEnemy::get_is_dead);

	ClassDB::bind_method(D_METHOD("get_bug_species"), &MutatedBugEnemy::get_bug_species);
	ClassDB::bind_method(D_METHOD("set_bug_species", "species"), &MutatedBugEnemy::set_bug_species);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "bug_species"), "set_bug_species", "get_bug_species");

	ClassDB::bind_method(D_METHOD("get_movement_speed"), &MutatedBugEnemy::get_movement_speed);
	ClassDB::bind_method(D_METHOD("set_movement_speed", "speed"), &MutatedBugEnemy::set_movement_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "movement_speed"), "set_movement_speed", "get_movement_speed");

	ClassDB::bind_method(D_METHOD("get_cable_channel_frequency"), &MutatedBugEnemy::get_cable_channel_frequency);
	ClassDB::bind_method(D_METHOD("set_cable_channel_frequency", "channel"), &MutatedBugEnemy::set_cable_channel_frequency);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "cable_channel_frequency"), "set_cable_channel_frequency", "get_cable_channel_frequency");

	ClassDB::bind_method(D_METHOD("take_damage", "damage"), &MutatedBugEnemy::take_damage);
	ClassDB::bind_method(D_METHOD("die"), &MutatedBugEnemy::die);

	ADD_SIGNAL(MethodInfo("health_changed", PropertyInfo(Variant::FLOAT, "current_health"), PropertyInfo(Variant::FLOAT, "max_health")));
	ADD_SIGNAL(MethodInfo("died"));
}
