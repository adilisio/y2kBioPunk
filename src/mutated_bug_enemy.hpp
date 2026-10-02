#ifndef MUTATED_BUG_ENEMY_HPP
#define MUTATED_BUG_ENEMY_HPP

#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class MutatedBugEnemy : public CharacterBody2D {
	GDCLASS(MutatedBugEnemy, CharacterBody2D);

private:
	String bug_species = "Neon Dial-Up Cicada";
	float max_health = 60.0f;
	float current_health = 60.0f;
	float movement_speed = 90.0f;
	bool is_dead = false;
	bool sample_dropped = false;
	int cable_channel_frequency = 3;

	Color hostile_color = Color(0.2f, 1.0f, 0.45f, 1.0f);  // Hostile neon-green

	double wander_timer = 0.0;
	double wander_interval = 2.5;
	Vector2 wander_direction = Vector2(0.0f, 0.0f);

	Vector2 get_random_isometric_direction();
	void drop_bio_sample();
	void spawn_floating_text(const String &p_text, const Color &p_color);

protected:
	static void _bind_methods();

public:
	MutatedBugEnemy();
	~MutatedBugEnemy();

	void _ready() override;
	void _physics_process(double p_delta) override;

	// Traditional Combat Damage & Death
	void take_damage(float p_damage);
	void die();

	// Getters & Setters
	float get_current_health() const;
	void set_current_health(float p_hp);

	float get_max_health() const;
	void set_max_health(float p_max_hp);

	bool get_is_dead() const;

	String get_bug_species() const;
	void set_bug_species(const String &p_species);

	float get_movement_speed() const;
	void set_movement_speed(float p_speed);

	int get_cable_channel_frequency() const;
	void set_cable_channel_frequency(int p_channel);
};

} // namespace godot

#endif // MUTATED_BUG_ENEMY_HPP
