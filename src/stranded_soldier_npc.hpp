#ifndef STRANDED_SOLDIER_NPC_HPP
#define STRANDED_SOLDIER_NPC_HPP

#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class PlayerController;

class StrandedSoldierNPC : public Area2D {
	GDCLASS(StrandedSoldierNPC, Area2D);

private:
	String npc_name = "Stranded Soldier (Sgt. Miller)";
	int vibe_check_difficulty = 15;
	float interaction_radius = 90.0f;
	bool is_player_in_range = false;
	bool already_persuaded = false;
	bool e_key_was_pressed = false;

	Label *prompt_label = nullptr;

protected:
	static void _bind_methods();

public:
	StrandedSoldierNPC();
	~StrandedSoldierNPC();

	void _ready() override;
	void _process(double p_delta) override;

	void trigger_dialogue();
	bool evaluate_vibe_check(PlayerController *p_player);

	// Getters & Setters
	String get_npc_name() const;
	void set_npc_name(const String &p_name);

	int get_vibe_check_difficulty() const;
	void set_vibe_check_difficulty(int p_diff);

	bool get_already_persuaded() const;
	void set_already_persuaded(bool p_persuaded);

	bool get_is_player_in_range() const;
};

} // namespace godot

#endif // STRANDED_SOLDIER_NPC_HPP
