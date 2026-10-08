#ifndef PLAYER_CONTROLLER_HPP
#define PLAYER_CONTROLLER_HPP

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/area3d.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/curve3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/path3d.hpp>
#include <godot_cpp/classes/path_follow3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/plane.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class GPUParticles3D;

// Traditional ARPG Player Stats Structure
struct PlayerStats {
	int strength = 10;
	int agility = 10;
	int vitality = 10;
	int vibe = 10;
};

class PlayerController : public CharacterBody3D {
	GDCLASS(PlayerController, CharacterBody3D);

public:
	enum MovementState {
		STATE_NORMAL = 0,
		STATE_ATTACKING = 1,
		STATE_GRINDING = 2,
		STATE_AIRBORNE = 3,
		STATE_EVADING = 4,
		STATE_DEAD = 5
	};

	enum SecondaryWeapon {
		SECONDARY_NONE = 0,
		SECONDARY_SPRAY_FLAMETHROWER = 1,
		SECONDARY_DISK_LAUNCHER = 2
	};

private:
	// Traversal State Machine
	MovementState current_state = STATE_NORMAL;
	bool ready_initialized = false;
	Path3D *current_grind_path = nullptr;
	PathFollow3D *grind_path_follow = nullptr;
	float grind_progress = 0.0f;
	float grind_direction = 1.0f;
	float grind_speed = 12.0f;
	float grind_cooldown = 0.0f;
	float grind_elapsed_time = 0.0f;
	Vector3 grind_entry_position;
	bool pending_slam = false;
	Vector3 pending_slam_direction;
	Area3D *grind_sensor = nullptr;

	// Adrenaline Meter Core
	float current_adrenaline = 0.0f;
	float max_adrenaline = 100.0f;

	// Dismount & Grind Slam Attack
	float base_slam_damage = 40.0f;
	float slam_radius = 4.5f;

	// Evade / Power-Slide State
	float evade_duration = 0.22f;
	float evade_timer = 0.0f;
	float evade_cooldown = 0.0f;
	float evade_cooldown_max = 0.35f;
	float evade_speed = 24.0f;
	Vector3 evade_direction = Vector3(0.0f, 0.0f, 1.0f);
	bool is_invincible = false;
	bool evade_key_was_pressed = false;

	// Secondary Weapon Arsenal (Spray Flamethrower & Disk Launcher)
	SecondaryWeapon current_secondary = SECONDARY_SPRAY_FLAMETHROWER;
	float secondary_cooldown = 0.0f;
	float flame_tick_timer = 0.0f;
	bool secondary_key_was_pressed = false;
	bool cycle_key_was_pressed = false;

	// Death State
	float death_timer = 0.0f;

	// RPG Stats
	PlayerStats base_stats;
	float current_health = 100.0f;
	float max_health = 100.0f;

	// XP & Leveling System
	int level = 1;
	int current_xp = 0;
	int xp_to_level = 50;
	int unspent_stat_points = 1;

	// Movement & Equipment
	bool is_skating = false;
	float skate_speed = 12.0f; // Roughly double standard walking speed (12.0 m/s)
	bool is_equipped_skates = false; // Default: responsive 3D walking
	bool is_movement_locked = false; // Pauses movement during dialogue / menus
	Vector3 facing_direction = Vector3(0.0f, 0.0f, 1.0f);
	float rotation_speed = 25.0f;
	float gravity = 22.0f;
	float fall_gravity = 36.0f;
	float coyote_timer = 0.0f;
	float jump_buffer_timer = 0.0f;
	float recent_jump_timer = 0.0f;
	float base_movement_speed = 6.0f;
	float jump_velocity = 7.2f;

	// Combat: Baseball Bat Melee Attack
	float attack_timer = 0.0f;
	float pending_hit_timer = -1.0f;
	float lunge_timer = 0.0f;
	int combo_hit = 0;
	bool combo_buffered = false;
	uint64_t hit_stop_end_msec = 0;
	double previous_time_scale = 1.0;
	float hurt_invuln_timer = 0.0f;
	float hurt_flash_timer = 0.0f;
	float knockback_timer = 0.0f;
	Vector3 observed_velocity;
	Array skin_meshes;
	Array skin_overlays;
	Ref<StandardMaterial3D> hurt_overlay;
	float base_attack_damage = 15.0f;
	float attack_reach = 2.5f;
	bool is_attacking = false;
	bool attack_key_was_pressed = false;
	Area3D *attack_sensor = nullptr;

	// Walkman System
	String current_tape = "Bubblegum";
	bool tape_key_was_pressed = false;
	bool skates_key_was_pressed = false;
	AudioStreamPlayer *walkman_audio = nullptr;
	AudioStreamPlayer *walkman_audio_b = nullptr;
	Ref<Tween> walkman_tween;
	Dictionary tape_positions;
	AudioStreamPlayer *sfx_audio = nullptr;
	AudioStreamPlayer *sfx_pool[4] = { nullptr, nullptr, nullptr, nullptr };
	int sfx_voice = 0;
	Dictionary sfx_cache;
	AudioStreamPlayer *sfx_loop_grind = nullptr;
	AudioStreamPlayer *sfx_loop_flame = nullptr;

	// Visuals & Animation
	Node3D *visuals = nullptr;
	Vector3 visuals_rest_position;
	AnimationPlayer *anim_player = nullptr;
	GPUParticles3D *flame_particles = nullptr;

	Vector2 get_raw_input_direction() const;
	void execute_bat_attack();
	void recalculate_derived_stats();
	void process_animation();
	void rotate_visuals(const Vector3 &p_direction, double p_delta);
	void start_combo_hit(int p_hit);
	void hit_stop(float p_duration);
	void add_camera_trauma(float p_amount);
	void step_physics(double p_delta);
	void dispatch_gameplay_input();
	void setup_sfx();
	void set_state(MovementState p_state);

protected:
	static void _bind_methods();

public:
	PlayerController();
	~PlayerController();

	void _ready() override;
	void _physics_process(double p_delta) override;
	void _process(double p_delta) override;
	void _exit_tree() override;

	// XP & Leveling
	int get_level() const;
	void set_level(int p_lvl);
	int get_current_xp() const;
	void set_current_xp(int p_xp);
	int get_xp_to_level() const;
	void set_xp_to_level(int p_next);
	int get_unspent_stat_points() const;
	void set_unspent_stat_points(int p_points);

	void gain_xp(int p_amount);
	bool spend_stat_point(const String &p_stat_name);

	// Movement & Equipment
	bool get_is_skating() const;
	void set_is_skating(bool p_skating);
	float get_skate_speed() const;
	void set_skate_speed(float p_speed);
	bool get_is_equipped_skates() const;
	void set_is_equipped_skates(bool p_equipped);
	bool get_movement_locked() const;
	void set_movement_locked(bool p_locked);
	Vector3 get_facing_direction() const;
	void set_facing_direction(const Vector3 &p_dir);
	float get_rotation_speed() const;
	void set_rotation_speed(float p_speed);
	float get_gravity() const;
	void set_gravity(float p_gravity);
	float get_base_movement_speed() const;
	void set_base_movement_speed(float p_speed);

	// Base RPG Stats
	int get_strength() const;
	void set_strength(int p_val);
	int get_agility() const;
	void set_agility(int p_val);
	int get_vitality() const;
	void set_vitality(int p_val);
	int get_vibe() const;
	void set_vibe(int p_val);

	// Effective Stats (Altered by Walkman tapes)
	int get_effective_strength() const;
	int get_effective_agility() const;
	int get_effective_vitality() const;
	int get_effective_vibe() const;

	float get_current_health() const;
	void set_current_health(float p_hp);
	float get_max_health() const;
	void set_max_health(float p_max_hp);
	float get_movement_speed() const;
	float get_jump_velocity() const;
	void set_jump_velocity(float p_val);

	// Traditional Combat
	bool get_is_attacking() const;
	void set_is_attacking(bool p_attacking);
	void attack();
	float get_effective_bat_damage() const;
	void take_damage(float p_amount, const Vector3 &p_knockback = Vector3());
	void heal(float p_amount);
	Area3D *get_attack_sensor() const;
	void set_attack_sensor(Area3D *p_sensor);

	// Visuals & Animation
	Node3D *get_visuals() const;
	void set_visuals(Node3D *p_visuals);
	AnimationPlayer *get_animation_player() const;
	void set_animation_player(AnimationPlayer *p_anim);
	GPUParticles3D *get_flame_particles() const;
	void set_flame_particles(GPUParticles3D *p_particles);

	// Walkman System
	String get_current_tape() const;
	void set_current_tape(const String &p_tape);
	void switch_tape(const String &p_tape_name = "");

	// State Machine & Grind Traversal
	MovementState get_movement_state() const;
	void set_movement_state(MovementState p_state);
	bool is_grinding() const;
	bool try_start_grind(Path3D *p_path);
	void start_grind(Path3D *p_path);
	void dismount_grind(const Vector3 &p_exit_velocity = Vector3(0.0f, 0.0f, 0.0f));
	void _on_grind_area_entered(Area3D *p_area);
	void simulate_physics(double p_delta);

	// Adrenaline System
	float get_current_adrenaline() const;
	void set_current_adrenaline(float p_val);
	float get_max_adrenaline() const;
	void set_max_adrenaline(float p_val);

	// Evade / Power-Slide
	bool try_evade();
	void start_evade(const Vector3 &p_direction);
	bool get_is_invincible() const;
	void set_is_invincible(bool p_inv);
	float get_evade_cooldown() const;
	float get_evade_speed() const;
	void set_evade_speed(float p_speed);

	// Grind Dismount Slam
	void execute_grind_slam(const Vector3 &p_direction = Vector3(0.0f, 0.0f, 0.0f));

	// Secondary Off-Hand Weapons
	void fire_secondary();
	void fire_spray_flamethrower();
	void fire_disk_launcher();
	void cycle_secondary_weapon();
	int get_secondary_weapon() const;
	void set_secondary_weapon(int p_weapon);
	String get_secondary_weapon_name() const;
	void set_secondary_weapon_name(const String &p_name);

	// Cursor-Directed Aiming
	bool get_cursor_world_position(Vector3 &r_pos);
	Vector3 get_cursor_world_position_bind();
	bool orient_towards_point(const Vector3 &p_target_world_pos);
	bool orient_towards_cursor();

	// Player Death & Audio SFX
	void die();
	bool is_dead() const;
	void play_sfx(const String &p_name);
};

} // namespace godot

VARIANT_ENUM_CAST(godot::PlayerController::MovementState);
VARIANT_ENUM_CAST(godot::PlayerController::SecondaryWeapon);

#endif // PLAYER_CONTROLLER_HPP
