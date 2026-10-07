#include "player_controller.hpp"
#include "mutated_bug_enemy.hpp"

#include <godot_cpp/classes/animation_player.hpp>
#include <godot_cpp/classes/audio_stream.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/cylinder_mesh.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/gpu_particles3d.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/particle_process_material.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/callback_tweener.hpp>
#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/classes/sphere_mesh.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/basis.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

static Ref<AudioStreamWAV> create_sfx_stream(const String &type);

PlayerController::PlayerController() {
}

PlayerController::~PlayerController() {
}

void PlayerController::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	set_motion_mode(MOTION_MODE_GROUNDED);
	set_collision_layer(1 | 2);

	// Retrieve Visuals node
	visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
	if (!visuals) {
		visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
	}

	// Retrieve AnimationPlayer node safely
	anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer", true, false));
	if (!anim_player) {
		anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer2", true, false));
	}
	if (!anim_player && visuals) {
		anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer", true, false));
		if (!anim_player) {
			anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer2", true, false));
		}
	}
	if (anim_player) {
		anim_player->set_default_blend_time(0.12);
		for (const char *name : { "Walking", "Running", "Skate_Grind" }) {
			if (anim_player->has_animation(name)) {
				anim_player->get_animation(name)->set_loop_mode(Animation::LOOP_LINEAR);
			}
		}
		process_animation();
	}

	if (visuals) {
		skin_meshes = visuals->find_children("Mesh_*", "MeshInstance3D", true, false);
		for (int i = 0; i < skin_meshes.size(); ++i) {
			MeshInstance3D *mesh = Object::cast_to<MeshInstance3D>(skin_meshes[i]);
			skin_overlays.append(mesh->get_material_overlay());
		}
	}
	hurt_overlay.instantiate();
	hurt_overlay->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);

	// Retrieve FlamethrowerParticles node (child of Visuals)
	flame_particles = Object::cast_to<GPUParticles3D>(find_child("FlamethrowerParticles", true, false));
	if (!flame_particles && visuals) {
		flame_particles = Object::cast_to<GPUParticles3D>(visuals->find_child("FlamethrowerParticles", true, false));
		if (!flame_particles) {
			TypedArray<Node> v_children = visuals->get_children();
			for (int i = 0; i < v_children.size(); i++) {
				GPUParticles3D *gp = Object::cast_to<GPUParticles3D>(v_children[i]);
				if (gp) {
					flame_particles = gp;
					break;
				}
			}
		}
	}
	if (!flame_particles) {
		if (!visuals) {
			visuals = memnew(Node3D);
			visuals->set_name("Visuals");
			add_child(visuals);
		}
		flame_particles = memnew(GPUParticles3D);
		flame_particles->set_name("FlamethrowerParticles");
		flame_particles->set_position(Vector3(0.0f, 0.8f, -0.4f));
		flame_particles->set_amount(48);
		flame_particles->set_lifetime(0.45);
		flame_particles->set_emitting(false);

		Ref<ParticleProcessMaterial> proc_mat;
		proc_mat.instantiate();
		proc_mat->set_direction(Vector3(0.0f, 0.0f, -1.0f));
		proc_mat->set_spread(15.0f);
		proc_mat->set_param_min(ParticleProcessMaterial::PARAM_INITIAL_LINEAR_VELOCITY, 7.0f);
		proc_mat->set_param_max(ParticleProcessMaterial::PARAM_INITIAL_LINEAR_VELOCITY, 11.0f);
		proc_mat->set_gravity(Vector3(0.0f, 0.0f, 0.0f));
		proc_mat->set_color(Color(0.25f, 1.0f, 0.35f, 0.85f));
		flame_particles->set_process_material(proc_mat);

		Ref<StandardMaterial3D> sphere_mat;
		sphere_mat.instantiate();
		sphere_mat->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);
		sphere_mat->set_albedo(Color(0.25f, 1.0f, 0.35f, 0.85f));

		Ref<SphereMesh> s_mesh;
		s_mesh.instantiate();
		s_mesh->set_radius(0.08f);
		s_mesh->set_height(0.16f);
		s_mesh->set_material(sphere_mat);
		flame_particles->set_draw_pass_mesh(0, s_mesh);

		visuals->add_child(flame_particles);
	}
	if (flame_particles) {
		flame_particles->set_emitting(false);
	}

	// Setup Walkman audio player
	walkman_audio = Object::cast_to<AudioStreamPlayer>(find_child("WalkmanAudio", false, false));
	if (!walkman_audio) {
		walkman_audio = memnew(AudioStreamPlayer);
		walkman_audio->set_name("WalkmanAudio");
		add_child(walkman_audio);
	}
	if (!walkman_audio->is_connected("finished", Callable(walkman_audio, "play"))) {
		walkman_audio->connect("finished", Callable(walkman_audio, "play"));
	}

	// Setup SFX audio player
	sfx_audio = Object::cast_to<AudioStreamPlayer>(find_child("SFXAudio", false, false));
	if (!sfx_audio) {
		sfx_audio = memnew(AudioStreamPlayer);
		sfx_audio->set_name("SFXAudio");
		add_child(sfx_audio);
	}

	sfx_pool[0] = sfx_audio;
	for (int i = 1; i < 4; ++i) {
		sfx_pool[i] = memnew(AudioStreamPlayer);
		sfx_pool[i]->set_name(String("SFXAudio") + String::num_int64(i));
		add_child(sfx_pool[i]);
	}
	for (const char *name : { "hit", "swing", "evade", "death", "slam", "yum", "hurt", "jump", "land" }) {
		sfx_cache[name] = create_sfx_stream(name);
	}

	// Setup Grindable Area3D Sensor for detecting grind rails
	grind_sensor = Object::cast_to<Area3D>(find_child("GrindSensor", false, false));
	if (!grind_sensor) {
		grind_sensor = memnew(Area3D);
		grind_sensor->set_name("GrindSensor");
		grind_sensor->set_collision_layer(0);
		grind_sensor->set_collision_mask_value(1, true); // World
		grind_sensor->set_collision_mask_value(3, true); // Grindable Layer 3
		grind_sensor->set_collision_mask_value(4, true); // Grindable Layer 4

		CollisionShape3D *sensor_shape = memnew(CollisionShape3D);
		sensor_shape->set_name("SensorShape");
		CapsuleShape3D *capsule = memnew(CapsuleShape3D);
		capsule->set_radius(0.6f);
		capsule->set_height(1.8f);
		sensor_shape->set_shape(capsule);
		grind_sensor->add_child(sensor_shape);
		add_child(grind_sensor);
	}
	if (!grind_sensor->is_connected("area_entered", Callable(this, "_on_grind_area_entered"))) {
		grind_sensor->connect("area_entered", Callable(this, "_on_grind_area_entered"));
	}

	// Setup Attack Area3D Hitbox Sensor for melee combat
	attack_sensor = Object::cast_to<Area3D>(find_child("AttackSensor", false, false));
	if (!attack_sensor) {
		attack_sensor = Object::cast_to<Area3D>(find_child("WeaponHitbox", false, false));
	}
	if (!attack_sensor) {
		attack_sensor = memnew(Area3D);
		attack_sensor->set_name("AttackSensor");
		attack_sensor->set_collision_layer(0);
		attack_sensor->set_collision_mask_value(1, true); // World
		attack_sensor->set_collision_mask_value(2, true); // Player/Entities
		attack_sensor->set_collision_mask_value(3, true); // Layer 3
		attack_sensor->set_collision_mask_value(4, true); // Layer 4
		attack_sensor->set_monitorable(false);
		attack_sensor->set_monitoring(true);

		CollisionShape3D *atk_col = memnew(CollisionShape3D);
		atk_col->set_name("HitboxShape");
		Ref<SphereShape3D> sphere;
		sphere.instantiate();
		sphere->set_radius(2.2f);
		atk_col->set_shape(sphere);

		attack_sensor->add_child(atk_col);
		add_child(attack_sensor);
	}
	attack_sensor->set_collision_mask(attack_sensor->get_collision_mask() & ~1u);
	attack_sensor->set_position(facing_direction * 1.2f + Vector3(0.0f, 0.5f, 0.0f));

	recalculate_derived_stats();
	current_health = max_health;

	// Start initial tape audio track
	switch_tape(current_tape);

	emit_signal("adrenaline_changed", current_adrenaline, max_adrenaline);

	UtilityFunctions::print("[Y2K-PLAYER] 3D PlayerController ready! Level ", level, " (XP: ", current_xp, "/", xp_to_level, "). Unspent Points: ", unspent_stat_points, ". Current Tape: '", current_tape, "'. HP: ", current_health, "/", max_health, ". Adrenaline: ", current_adrenaline, "/", max_adrenaline);
}

void PlayerController::recalculate_derived_stats() {
	max_health = static_cast<float>(get_effective_vitality() * 10);
	if (current_health > max_health) {
		current_health = max_health;
	}
	emit_signal("stats_changed");
	emit_signal("health_changed", current_health, max_health);
}

void PlayerController::gain_xp(int p_amount) {
	current_xp += p_amount;
	UtilityFunctions::print("[Y2K-XP] Gained ", p_amount, " XP! (Progress: ", current_xp, "/", xp_to_level, ")");

	int xp_iterations = 0;
	while (current_xp >= xp_to_level) {
		if (++xp_iterations > 100) {
			UtilityFunctions::print("[Y2K-XP] Safety break: gain_xp loop exceeded 100 iterations.");
			break;
		}
		current_xp -= xp_to_level;
		level++;
		unspent_stat_points += 1;
		xp_to_level = static_cast<int>(static_cast<float>(xp_to_level) * 1.5f);
		if (xp_to_level <= 0) {
			xp_to_level = 100;
		}

		UtilityFunctions::print("[Y2K-LEVEL] *** LEVEL UP! *** Now Level ", level, "! Gained 1 Stat Point. Unspent: ", unspent_stat_points, " | Next Level XP: ", xp_to_level);
		emit_signal("leveled_up", level, unspent_stat_points);
	}

	emit_signal("xp_changed", current_xp, xp_to_level, level);
}

bool PlayerController::spend_stat_point(const String &p_stat_name) {
	if (unspent_stat_points <= 0) {
		UtilityFunctions::print("[Y2K-STATS] Cannot allocate stat point: 0 unspent points!");
		return false;
	}

	String lower = p_stat_name.to_lower();
	if (lower == "strength" || lower == "str") {
		base_stats.strength += 1;
	} else if (lower == "agility" || lower == "agi") {
		base_stats.agility += 1;
	} else if (lower == "vitality" || lower == "vit") {
		base_stats.vitality += 1;
	} else if (lower == "vibe") {
		base_stats.vibe += 1;
	} else {
		UtilityFunctions::print("[Y2K-STATS] Unknown stat: '", p_stat_name, "'");
		return false;
	}

	unspent_stat_points--;
	recalculate_derived_stats();

	UtilityFunctions::print("[Y2K-STATS] Stat point allocated to '", p_stat_name, "'! Remaining unspent points: ", unspent_stat_points);
	emit_signal("stat_point_spent", p_stat_name, unspent_stat_points);
	return true;
}

float PlayerController::get_movement_speed() const {
	if (is_skating || is_equipped_skates) {
		return skate_speed;
	}
	// Movement speed tied directly to agility stat (scaled for 3D meters/second: 5.0f - 8.0f m/s range)
	return base_movement_speed + static_cast<float>(get_effective_agility()) * 0.15f;
}

Vector2 PlayerController::get_raw_input_direction() const {
	Vector2 dir(0.0f, 0.0f);
	Input *input = Input::get_singleton();
	if (!input) {
		return dir;
	}

	InputMap *input_map = InputMap::get_singleton();
	bool has_left = input_map && input_map->has_action("move_left");
	bool has_right = input_map && input_map->has_action("move_right");
	bool has_forward = input_map && input_map->has_action("move_forward");
	bool has_backward = input_map && input_map->has_action("move_backward");
	bool has_up = input_map && input_map->has_action("move_up");
	bool has_down = input_map && input_map->has_action("move_down");

	bool left = (has_left && input->is_action_pressed("move_left")) || input->is_key_pressed(Key::KEY_A) || input->is_key_pressed(Key::KEY_LEFT);
	bool right = (has_right && input->is_action_pressed("move_right")) || input->is_key_pressed(Key::KEY_D) || input->is_key_pressed(Key::KEY_RIGHT);
	bool forward = (has_forward && input->is_action_pressed("move_forward")) || (has_up && input->is_action_pressed("move_up")) || input->is_key_pressed(Key::KEY_W) || input->is_key_pressed(Key::KEY_UP);
	bool backward = (has_backward && input->is_action_pressed("move_backward")) || (has_down && input->is_action_pressed("move_down")) || input->is_key_pressed(Key::KEY_S) || input->is_key_pressed(Key::KEY_DOWN);

	if (right) {
		dir.x += 1.0f;
	}
	if (left) {
		dir.x -= 1.0f;
	}
	if (backward) {
		dir.y += 1.0f;
	}
	if (forward) {
		dir.y -= 1.0f;
	}

	if (dir.length_squared() > 0.0001f) {
		return dir.normalized();
	}
	return Vector2(0.0f, 0.0f);
}

void PlayerController::_physics_process(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}
	Vector3 change = get_velocity() - observed_velocity;
	change.y = 0;
	// Honor external velocity shoves instead of overwriting them on the next tick.
	if (change.length_squared() > 0.01f && current_state != STATE_GRINDING) {
		knockback_timer = Math::max(knockback_timer, 0.12f);
	}
	step_physics(p_delta);
	if (pending_slam && is_on_floor() && get_velocity().y <= 0.0f) {
		pending_slam = false;
		execute_grind_slam(pending_slam_direction);
	}
	observed_velocity = get_velocity();
}

void PlayerController::step_physics(double p_delta) {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	float delta_f = static_cast<float>(p_delta);
	hurt_invuln_timer = Math::max(0.0f, hurt_invuln_timer - delta_f);
	if (hurt_flash_timer > 0.0f) {
		hurt_flash_timer = Math::max(0.0f, hurt_flash_timer - delta_f);
		hurt_overlay->set_albedo(hurt_flash_timer > 0.10f ? Color(1, 1, 1) : Color(1, 0.1f, 0.1f));
		for (int i = 0; i < skin_meshes.size(); ++i) {
			MeshInstance3D *mesh = Object::cast_to<MeshInstance3D>(skin_meshes[i]);
			if (hurt_flash_timer <= 0) {
				Ref<Material> original = skin_overlays[i];
				mesh->set_material_overlay(original);
			}
		}
	}

	if (current_state == STATE_DEAD) {
		set_velocity(Vector3(0.0f, 0.0f, 0.0f));
		move_and_slide();
		if (flame_particles && flame_particles->is_emitting()) {
			flame_particles->set_emitting(false);
		}

		death_timer -= delta_f;
		if (death_timer <= 0.0f && is_inside_tree() && get_tree()) {
			get_tree()->reload_current_scene();
		}
		return;
	}

	Input *jump_input = Input::get_singleton();
	coyote_timer = is_on_floor() ? 0.10f : Math::max(0.0f, coyote_timer - delta_f);
	jump_buffer_timer = Math::max(0.0f, jump_buffer_timer - delta_f);
	recent_jump_timer = Math::max(0.0f, recent_jump_timer - delta_f);
	if (jump_input && jump_input->is_action_just_pressed("jump")) {
		jump_buffer_timer = 0.12f;
		recent_jump_timer = 0.15f;
	}
	Vector3 current_velocity = get_velocity();

	// Update cooldowns
	if (grind_cooldown > 0.0f) {
		grind_cooldown -= delta_f;
	}
	if (evade_cooldown > 0.0f) {
		evade_cooldown -= delta_f;
	}
	if (secondary_cooldown > 0.0f) {
		secondary_cooldown -= delta_f;
	}
	if (flame_tick_timer > 0.0f) {
		flame_tick_timer -= delta_f;
	}

	if (!is_movement_locked) {
		dispatch_gameplay_input();
	}

	// =========================================================================
	// STATE_GRINDING: Rail Spline Traversal & Adrenaline Generation
	// =========================================================================
	if (current_state == STATE_GRINDING) {
		// Adrenaline meter generation (+10.0f per second)
		current_adrenaline = Math::min(max_adrenaline, current_adrenaline + 10.0f * delta_f);
		emit_signal("adrenaline_changed", current_adrenaline, max_adrenaline);

		if (!current_grind_path) {
			dismount_grind(Vector3(0.0f, 0.0f, 0.0f));
			return;
		}

		Ref<Curve3D> curve = current_grind_path->get_curve();
		if (!curve.is_valid()) {
			dismount_grind(Vector3(0.0f, 0.0f, 0.0f));
			return;
		}

		float baked_len = curve->get_baked_length();
		if (baked_len <= 0.001f) {
			dismount_grind(Vector3(0.0f, 0.0f, 0.0f));
			return;
		}

		// Safety timeout: Maximum 30 seconds of continuous grinding per rail
		grind_elapsed_time += delta_f;
		if (grind_elapsed_time > 30.0f) {
			dismount_grind(facing_direction * grind_speed);
			return;
		}

		// Direction and speed sanitization
		if (Math::is_zero_approx(grind_direction)) {
			grind_direction = 1.0f;
		}
		grind_speed = Math::max(grind_speed, 4.0f);

		// Synchronize grind_progress if PathFollow3D was modified externally
		if (grind_path_follow) {
			float follow_prog = grind_path_follow->get_progress();
			float follow_ratio = grind_path_follow->get_progress_ratio();
			if (follow_ratio >= 0.999f && grind_direction > 0.0f) {
				grind_progress = baked_len;
			} else if (follow_ratio <= 0.001f && grind_direction < 0.0f) {
				grind_progress = 0.0f;
			} else if (Math::abs(follow_prog - grind_progress) > 1.0f) {
				grind_progress = follow_prog;
			}
		}

		// Advance along the rail curve
		grind_progress += (grind_direction * grind_speed * delta_f);
		float ratio = (baked_len > 0.001f) ? (grind_progress / baked_len) : 1.0f;

		if (grind_path_follow) {
			grind_path_follow->set_progress(grind_progress);
			if (grind_path_follow->is_inside_tree()) {
				float follow_ratio = grind_path_follow->get_progress_ratio();
				if (follow_ratio > 0.0f) {
					ratio = (grind_direction > 0.0f) ? Math::max(ratio, follow_ratio) : Math::min(ratio, follow_ratio);
				}
			}
		}

		// Snap player position along the rail
		Vector3 rail_pos;
		if (grind_path_follow && grind_path_follow->is_inside_tree()) {
			rail_pos = grind_path_follow->get_global_position();
		} else {
			Vector3 curve_point = curve->sample_baked(Math::clamp(grind_progress, 0.0f, baked_len));
			if (current_grind_path->is_inside_tree()) {
				rail_pos = current_grind_path->get_global_transform().xform(curve_point);
			} else {
				rail_pos = current_grind_path->get_position() + curve_point;
			}
		}
		rail_pos.y += 0.3f;
		rail_pos = grind_entry_position.lerp(rail_pos, Math::clamp(grind_elapsed_time / 0.06f, 0.0f, 1.0f));
		if (is_inside_tree()) {
			set_global_position(rail_pos);
		} else {
			set_position(rail_pos);
		}

		// 1. Calculate the forward vector of the Path3D curve at the player's current progress_ratio
		float current_offset = Math::clamp(ratio * baked_len, 0.0f, baked_len);
		float sample_delta = 0.25f;
		float offset_fwd = Math::min(current_offset + sample_delta, baked_len);
		float offset_bwd = Math::max(current_offset - sample_delta, 0.0f);

		Vector3 pt_fwd = curve->sample_baked(offset_fwd);
		Vector3 pt_bwd = curve->sample_baked(offset_bwd);
		Vector3 curve_forward = pt_fwd - pt_bwd;

		if (curve_forward.length_squared() < 0.0001f) {
			if (offset_fwd + 0.5f <= baked_len) {
				curve_forward = curve->sample_baked(Math::min(offset_fwd + 0.5f, baked_len)) - pt_bwd;
			} else if (offset_bwd - 0.5f >= 0.0f) {
				curve_forward = pt_fwd - curve->sample_baked(Math::max(0.0f, offset_bwd - 0.5f));
			}
		}

		// Transform forward vector from Path3D local coordinates to world space
		Vector3 world_forward = curve_forward;
		if (current_grind_path->is_inside_tree()) {
			world_forward = current_grind_path->get_global_transform().basis.xform(curve_forward);
		}

		// Account for traversal direction along the spline (forward vs backward)
		Vector3 travel_forward = world_forward * (grind_direction >= 0.0f ? 1.0f : -1.0f);
		travel_forward.y = 0.0f; // Level on horizontal plane

		if (travel_forward.length_squared() > 0.0001f) {
			travel_forward.normalize();
		} else if (facing_direction.length_squared() > 0.0001f) {
			travel_forward = facing_direction;
		} else {
			travel_forward = Vector3(0.0f, 0.0f, 1.0f);
		}

		if (!visuals) {
			visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
			if (!visuals) {
				visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
			}
		}

		// 2. Smoothly rotate the player's Visuals node using look_at()
		if (visuals) {
			float rot_weight = static_cast<float>(Math::clamp((rotation_speed > 0.0f ? rotation_speed : 12.0f) * delta_f, 0.0f, 1.0f));
			if (facing_direction.length_squared() < 0.001f) {
				facing_direction = travel_forward;
			} else {
				facing_direction = facing_direction.slerp(travel_forward, rot_weight).normalized();
			}

			if (visuals->is_inside_tree()) {
				Vector3 vis_pos = visuals->get_global_position();
				Vector3 target_pos = vis_pos + facing_direction;
				if (vis_pos.distance_squared_to(target_pos) > 0.0001f) {
					visuals->look_at(target_pos, Vector3(0.0f, 1.0f, 0.0f));
				}
			} else {
				Basis tb = Basis::looking_at(facing_direction, Vector3(0.0f, 1.0f, 0.0f));
				Transform3D vt = visuals->get_transform();
				vt.basis = tb;
				visuals->set_transform(vt);
			}
		}

		// Dismount condition: End of curve reached (progress_ratio >= 1.0 or <= 0.0)
		bool reached_end = false;
		if (grind_direction > 0.0f && (grind_progress >= baked_len || ratio >= 0.999f)) {
			reached_end = true;
		} else if (grind_direction < 0.0f && (grind_progress <= 0.0f || ratio <= 0.001f)) {
			reached_end = true;
		}

		// Also allow manual jump dismount (triggers directional shockwave slam!)
		Input *input = Input::get_singleton();
		bool jump_dismount = false;
		if (input && grind_elapsed_time >= 0.15f && input->is_action_just_pressed("jump")) {
			reached_end = true;
			jump_dismount = true;
		}
		if (input && grind_elapsed_time >= 0.15f && input->is_action_just_pressed("attack")) {
			reached_end = true;
			jump_dismount = true;
		}

		if (reached_end) {
			Vector3 launch_dir = facing_direction;
			if (launch_dir.length_squared() < 0.001f) {
				launch_dir = Vector3(0.0f, 0.0f, 1.0f);
			}
			launch_dir.normalize();
			Vector3 launch_vel = launch_dir * (grind_speed * 1.25f);
			launch_vel.y = jump_dismount ? 5.0f : 3.0f; // Higher launch hop on jump slam
			dismount_grind(launch_vel);
			if (jump_dismount) {
				pending_slam = true;
				pending_slam_direction = launch_dir;
			}
		}
		return;
	}

	// =========================================================================
	// STATE_EVADING: Slide-Dodge Mechanic (Velocity Boost & I-Frames)
	// =========================================================================
	if (current_state == STATE_EVADING) {
		evade_timer = Math::max(0.0f, evade_timer - delta_f);
		float elapsed = evade_duration - evade_timer;
		is_invincible = elapsed < 0.18f;
		float blend = Math::clamp((elapsed / evade_duration - 0.7f) / 0.3f, 0.0f, 1.0f);
		blend = blend * blend * (3.0f - 2.0f * blend);
		float speed = Math::lerp(evade_speed, get_movement_speed(), blend);
		if (knockback_timer > 0) {
			knockback_timer = Math::max(0.0f, knockback_timer - delta_f);
		} else {
			current_velocity.x = evade_direction.x * speed;
			current_velocity.z = evade_direction.z * speed;
		}
		if (!is_on_floor()) {
			current_velocity.y -= (current_velocity.y < 0 ? fall_gravity : gravity) * delta_f;
		}
		set_velocity(current_velocity);
		move_and_slide();
		rotate_visuals(evade_direction, p_delta);
		if (evade_timer <= 0) {
			set_state(is_on_floor() ? STATE_NORMAL : STATE_AIRBORNE);
			process_animation();
		}
		return;
	}

	// 1. Apply gravity: If not on floor, subtract gravity * delta from velocity.y
	if (!is_on_floor()) {
		current_velocity.y -= (current_velocity.y < 0 ? fall_gravity : gravity) * delta_f;
		if (current_state == STATE_NORMAL && !is_attacking) {
			set_state(STATE_AIRBORNE);
		}
	} else {
		if (current_state == STATE_AIRBORNE) {
			set_state(STATE_NORMAL);
		}
	}

	// Movement paused during dialogue
	if (is_movement_locked) {
		current_velocity.x = 0.0f;
		current_velocity.z = 0.0f;
		set_velocity(current_velocity);
		move_and_slide();
		if (anim_player) {
			process_animation();
		}
		return;
	}

	if (is_attacking) {
		attack_timer -= delta_f;
		if (pending_hit_timer >= 0.0f) {
			pending_hit_timer -= delta_f;
			if (pending_hit_timer <= 0.0f) {
				pending_hit_timer = -1.0f;
				execute_bat_attack();
			}
		}
		if (attack_timer <= 0.0f) {
			if (combo_buffered && combo_hit < 3) {
				start_combo_hit(combo_hit + 1);
			} else {
				is_attacking = false;
				set_state(is_on_floor() ? STATE_NORMAL : STATE_AIRBORNE);
			}
		}
	}

	// Check if input actions were just pressed
	Input *input = Input::get_singleton();
	if (input) {

		if (jump_buffer_timer > 0 && coyote_timer > 0 && !is_attacking) {
			current_velocity.y = jump_velocity;
			play_sfx("jump");
			jump_buffer_timer = coyote_timer = 0.0f;
			set_state(STATE_AIRBORNE);
		}
		if (input->is_action_just_released("jump") && current_velocity.y > 0) {
			current_velocity.y *= 0.5f;
		}


	}

	// Check for grind rail collisions
	if ((is_skating || is_equipped_skates) && grind_cooldown <= 0.0f && current_state != STATE_GRINDING) {
		if (grind_sensor) {
			TypedArray<Area3D> overlapping = grind_sensor->get_overlapping_areas();
			int loop_iter = 0;
			for (int i = 0; i < overlapping.size(); i++) {
				if (++loop_iter > 100) {
					break;
				}
				Area3D *area = Object::cast_to<Area3D>(overlapping[i]);
				if (area && (area->is_in_group("grindable") || area->get_collision_layer_value(3) || area->get_collision_layer_value(4))) {
					Path3D *path = Object::cast_to<Path3D>(area->get_parent());
					if (!path) {
						path = Object::cast_to<Path3D>(area->find_parent("Path3D"));
					}
					if (path && try_start_grind(path)) {
						return;
					}
				}
			}
		}
	}

	Vector3 move_direction(0.0f, 0.0f, 0.0f);
	// 2. Retrieve input as a Vector2 (WASD)
	Vector2 input_dir = get_raw_input_direction();

	// 3. Convert input to camera-relative 3D direction vector
	if (input_dir.length_squared() > 0.0001f) {
		Vector3 raw_dir(input_dir.x, 0.0f, input_dir.y);

		// Fetch active camera transform
		Camera3D *camera = nullptr;
		Viewport *viewport = get_viewport();
		if (viewport) {
			camera = viewport->get_camera_3d();
		}

		if (camera) {
			// Transform the raw input direction by the camera's global transform basis
			Vector3 cam_dir = camera->get_global_transform().basis.xform(raw_dir);
			// Nullify the Y-axis component and normalize()
			cam_dir.y = 0.0f;
			if (cam_dir.length_squared() > 0.0001f) {
				move_direction = cam_dir.normalized();
			}
		} else {
			move_direction = raw_dir.normalized();
		}
	}

	float speed = get_movement_speed() * (is_attacking ? 0.25f : 1.0f);
	Vector3 hv(current_velocity.x, 0, current_velocity.z);
	bool skating = is_skating || is_equipped_skates;
	bool has_input = move_direction.length_squared() > 0.0001f;
	if (knockback_timer > 0) {
		knockback_timer = Math::max(0.0f, knockback_timer - delta_f);
	} else if (!is_on_floor()) {
		if (has_input) {
			hv = hv.move_toward(move_direction * speed, 20.0f * delta_f);
		}
	} else if (!skating) {
		bool braking = has_input && hv.length_squared() > 0.01f && hv.normalized().dot(move_direction) < -0.3f;
		hv = hv.move_toward(move_direction * speed, (has_input && !braking ? 70.0f : 90.0f) * delta_f);
	} else if (!has_input) {
		hv = hv.move_toward(Vector3(), 4.0f * delta_f);
	} else if (hv.length_squared() > 0.01f && hv.normalized().dot(move_direction) < -0.3f) {
		// Brake before reversing rather than instantly flipping the skate trajectory.
		hv = hv.move_toward(move_direction * speed, 28.0f * delta_f);
	} else {
		float h_speed = hv.length();
		Vector3 direction = h_speed > 0.01f ? hv / h_speed : move_direction;
		float angle = direction.signed_angle_to(move_direction, Vector3(0, 1, 0));
		float turn_rate = Math::lerp(360.0f, 200.0f, Math::clamp((h_speed - 6.0f) / 6.0f, 0.0f, 1.0f));
		float turn = Math::deg_to_rad(turn_rate) * delta_f;
		direction = direction.rotated(Vector3(0, 1, 0), Math::clamp(angle, -turn, turn));
		hv = direction * Math::move_toward(h_speed, speed, 16.0f * delta_f);
	}
	if (lunge_timer > 0.0f) {
		lunge_timer -= delta_f;
		hv = move_direction * speed + facing_direction * 4.0f;
	}
	current_velocity.x = hv.x;
	current_velocity.z = hv.z;

	bool was_on_floor = is_on_floor();
	set_velocity(current_velocity);
	move_and_slide();
	if (!was_on_floor && is_on_floor()) {
		play_sfx("land");
	}

	// 4. Rotation: If attacking or firing secondary, cursor aiming overrides visual facing direction.
	// Otherwise, if the movement vector is greater than zero, update the character's rotation
	// strictly on the visuals node (using look_at or slerp) so the root body and camera remain independent.
	bool is_firing_secondary_active = false;
	Input *input_for_aim = Input::get_singleton();
	if (input_for_aim) {
		bool sec_held = input_for_aim->is_action_pressed("secondary_fire") ||
		                input_for_aim->is_action_pressed("secondary_attack") ||
		                input_for_aim->is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_RIGHT) ||
		                input_for_aim->is_key_pressed(Key::KEY_F);
		if (sec_held && (current_state != STATE_GRINDING && current_state != STATE_EVADING && current_state != STATE_DEAD && !is_movement_locked)) {
			is_firing_secondary_active = true;
		}
	}

	bool aimed_at_cursor = false;
	if (is_attacking || is_firing_secondary_active) {
		aimed_at_cursor = orient_towards_cursor();
	}

	if (!aimed_at_cursor && move_direction.length_squared() > 0.0001f) {
		facing_direction = move_direction;
		if (attack_sensor) {
			attack_sensor->set_position(facing_direction * 1.2f + Vector3(0.0f, 0.5f, 0.0f));
		}

		if (!visuals) {
			visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
			if (!visuals) {
				visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
			}
		}

		rotate_visuals(move_direction, p_delta);
	}

	process_animation();
}

void PlayerController::rotate_visuals(const Vector3 &p_direction, double p_delta) {
	if (!visuals || p_direction.length_squared() < 0.0001f) {
		return;
	}
	Transform3D transform = visuals->is_inside_tree() ? visuals->get_global_transform() : visuals->get_transform();
	Vector3 scale = transform.basis.get_scale();
	Basis target_basis = Basis::looking_at(p_direction, Vector3(0, 1, 0));
	float weight = Math::clamp(rotation_speed * static_cast<float>(p_delta), 0.0f, 1.0f);
	transform.basis = transform.basis.orthonormalized().slerp(target_basis, weight).orthonormalized().scaled(scale);
	if (visuals->is_inside_tree()) {
		visuals->set_global_transform(transform);
	} else {
		visuals->set_transform(transform);
	}
}

void PlayerController::process_animation() {
	if (!anim_player || is_attacking || current_state == STATE_EVADING || current_state == STATE_GRINDING || current_state == STATE_DEAD) {
		return;
	}
	Vector3 hv = get_velocity();
	hv.y = 0;
	float speed = hv.length();
	if (!is_on_floor() && !is_movement_locked) {
		if (anim_player->has_animation("Running")) {
			anim_player->play("Running");
			anim_player->seek(0.18, true);
			anim_player->pause();
		}
	} else if (speed < 0.1f || is_movement_locked) {
		if (anim_player->has_animation("Punch_Combo_1")) {
			anim_player->set_speed_scale(1.0f);
			anim_player->play("Punch_Combo_1");
			anim_player->seek(2.10, true);
			anim_player->pause();
		}
	} else {
		bool glide = (is_skating || is_equipped_skates) && speed >= 6.0f;
		String clip = glide && anim_player->has_animation("Skate_Grind") ? "Skate_Grind" : "Running";
		float rate = clip == "Skate_Grind" ? 1.0f : (glide ? 2.2f : Math::clamp(speed / 2.62f, 0.8f, 2.2f));
		Input *input = Input::get_singleton();
		bool aiming = input && (input->is_action_pressed("secondary_fire") || input->is_action_pressed("secondary_attack"));
		if (aiming && facing_direction.dot(hv.normalized()) < -0.3f) {
			rate = -rate;
		}
		anim_player->set_speed_scale(rate);
		if (anim_player->has_animation(clip) && (anim_player->get_current_animation() != clip || !anim_player->is_playing())) {
			anim_player->play(clip);
		}
	}
}

void PlayerController::_process(double p_delta) {
	(void)p_delta;
	if (hit_stop_end_msec != 0 && Time::get_singleton()->get_ticks_msec() >= hit_stop_end_msec) {
		Engine::get_singleton()->set_time_scale(previous_time_scale);
		hit_stop_end_msec = 0;
	}
}

void PlayerController::dispatch_gameplay_input() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	Input *input = Input::get_singleton();
	if (!input) {
		return;
	}

	InputMap *input_map = InputMap::get_singleton();
	bool tape_pressed = input->is_action_just_pressed("switch_tape");
	bool raw_t = input->is_key_pressed(Key::KEY_T);
	if (tape_pressed || (raw_t && !tape_key_was_pressed)) {
		switch_tape();
	}
	tape_key_was_pressed = raw_t;
	bool skate_pressed = input->is_action_just_pressed("toggle_skates") || input->is_action_just_pressed("equip_skates");
	bool raw_k = input->is_key_pressed(Key::KEY_K);
	if (skate_pressed || (raw_k && !skates_key_was_pressed)) {
		set_is_skating(!is_skating);
	}
	skates_key_was_pressed = raw_k;

	// Attacks are disabled when movement is locked (e.g. in dialogue)
	if (is_movement_locked) {
		return;
	}

	// 3. Secondary Weapon Cycle (Q key or cycle_secondary action)
	bool is_q_pressed = input->is_key_pressed(Key::KEY_Q);
	if (input_map && input_map->has_action("cycle_secondary")) {
		if (input->is_action_just_pressed("cycle_secondary")) {
			is_q_pressed = true;
		}
	}
	if (is_q_pressed && !cycle_key_was_pressed) {
		cycle_secondary_weapon();
	}
	cycle_key_was_pressed = is_q_pressed;

	// 4. Secondary Weapon Attack Trigger (strictly isolate secondary_fire from melee attack)
	bool is_sec_just_pressed = false;
	bool is_sec_pressed = false;

	if (input_map && input_map->has_action("secondary_fire")) {
		is_sec_just_pressed = input->is_action_just_pressed("secondary_fire");
		is_sec_pressed = input->is_action_pressed("secondary_fire");
	} else if (input_map && input_map->has_action("secondary_attack")) {
		is_sec_just_pressed = input->is_action_just_pressed("secondary_attack");
		is_sec_pressed = input->is_action_pressed("secondary_attack");
	}

	// Fallback secondary triggers: RMB (Button 2) or Key F (strictly never LMB / Button 1)
	if (!is_sec_pressed && (input->is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_RIGHT) || input->is_key_pressed(Key::KEY_F))) {
		if (!secondary_key_was_pressed) {
			is_sec_just_pressed = true;
		}
		is_sec_pressed = true;
	}
	secondary_key_was_pressed = input->is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_RIGHT) || input->is_key_pressed(Key::KEY_F);

	bool is_aerosol = (current_secondary == SECONDARY_SPRAY_FLAMETHROWER);
	bool can_secondary = (current_state != STATE_GRINDING && current_state != STATE_EVADING && current_state != STATE_DEAD && !is_movement_locked);
	bool should_emit_flame = can_secondary && is_aerosol && is_sec_pressed;

	if (flame_particles) {
		if (flame_particles->is_emitting() != should_emit_flame) {
			flame_particles->set_emitting(should_emit_flame);
		}
	}

	if (can_secondary) {
		if (is_aerosol) {
			if (is_sec_pressed) {
				fire_secondary();
			}
		} else if (current_secondary == SECONDARY_DISK_LAUNCHER) {
			if (is_sec_just_pressed) {
				fire_secondary();
			}
		}
	}

	// Evade / Power-Slide Trigger
	bool evade_pressed = input->is_action_just_pressed("evade");
	if (!evade_pressed && input_map && input_map->has_action("dodge")) {
		evade_pressed = input->is_action_just_pressed("dodge");
	}
	if (!evade_pressed && (input->is_key_pressed(Key::KEY_SHIFT) || input->is_key_pressed(Key::KEY_V))) {
		if (!evade_key_was_pressed) {
		evade_pressed = true;
		}
	}
	evade_key_was_pressed = input->is_key_pressed(Key::KEY_SHIFT) || input->is_key_pressed(Key::KEY_V);

	if (evade_pressed && current_state != STATE_EVADING && current_state != STATE_GRINDING && !is_movement_locked) {
		if (try_evade()) {
		return;
		}
	}

	// Combat Attack Trigger: Bind strictly to custom action "attack" (and LMB)
	bool is_atk_pressed = input->is_action_just_pressed("attack");
	if (!is_atk_pressed && input_map && input_map->has_action("bat_swing")) {
		is_atk_pressed = input->is_action_just_pressed("bat_swing");
	}
	if (!is_atk_pressed && input->is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT) && !attack_key_was_pressed) {
		is_atk_pressed = true;
	}
	attack_key_was_pressed = input->is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT);

	if (is_atk_pressed) {
		attack();
	}
}

bool PlayerController::get_cursor_world_position(Vector3 &r_pos) {
	Viewport *viewport = get_viewport();
	if (!viewport) {
		return false;
	}
	Camera3D *camera = viewport->get_camera_3d();
	if (!camera && get_tree() && get_tree()->get_root()) {
		camera = Object::cast_to<Camera3D>(get_tree()->get_root()->find_child("Camera3D", true, false));
	}
	if (!camera) {
		return false;
	}

	Vector2 mouse_pos = viewport->get_mouse_position();
	if (!mouse_pos.is_finite()) {
		return false;
	}

	Vector3 ray_origin = camera->project_ray_origin(mouse_pos);
	Vector3 ray_normal = camera->project_ray_normal(mouse_pos);

	if (!ray_origin.is_finite() || !ray_normal.is_finite() || ray_normal.length_squared() < 0.0001f) {
		return false;
	}

	Vector3 player_pos = is_inside_tree() ? get_global_position() : get_position();
	if (!player_pos.is_finite()) {
		return false;
	}

	Plane ground_plane(Vector3(0.0f, 1.0f, 0.0f), player_pos.y);

	Vector3 hit_point;
	bool hit_success = ground_plane.intersects_ray(ray_origin, ray_normal, &hit_point);
	if (!hit_success || !hit_point.is_finite() || Math::is_nan(hit_point.x) || Math::is_nan(hit_point.y) || Math::is_nan(hit_point.z) || Math::is_inf(hit_point.x) || Math::is_inf(hit_point.y) || Math::is_inf(hit_point.z)) {
		return false;
	}

	r_pos = hit_point;
	return true;
}

Vector3 PlayerController::get_cursor_world_position_bind() {
	Vector3 hit_pos(0.0f, 0.0f, 0.0f);
	if (get_cursor_world_position(hit_pos)) {
		return hit_pos;
	}
	return is_inside_tree() ? get_global_position() + facing_direction : get_position() + facing_direction;
}

bool PlayerController::orient_towards_point(const Vector3 &p_target_world_pos) {
	// Strict validation check of target position before applying rotation
	if (!p_target_world_pos.is_finite() || Math::is_nan(p_target_world_pos.x) || Math::is_nan(p_target_world_pos.y) || Math::is_nan(p_target_world_pos.z) || Math::is_inf(p_target_world_pos.x) || Math::is_inf(p_target_world_pos.y) || Math::is_inf(p_target_world_pos.z)) {
		return false;
	}

	Vector3 current_pos = is_inside_tree() ? get_global_position() : get_position();
	if (!current_pos.is_finite() || Math::is_nan(current_pos.x) || Math::is_nan(current_pos.y) || Math::is_nan(current_pos.z)) {
		return false;
	}

	// Flatten the target position: Explicitly force the target's Y-coordinate to exactly match
	// the player's current Y-coordinate (target_pos.y = current_pos.y) to ensure a purely horizontal rotation
	// and prevent the mesh from pitching or rolling into invalid bounds.
	Vector3 target_pos = p_target_world_pos;
	target_pos.y = current_pos.y;

	// Add a distance safeguard: Only apply the rotation if the distance between the player's position
	// and the cursor target position is greater than a small threshold (e.g. current_pos.distance_squared_to(target_pos) > 0.01f).
	// If the cursor is dead-center on the player, skip the rotation update to prevent a zero-length direction vector calculation.
	if (current_pos.distance_squared_to(target_pos) <= 0.01f) {
		return false;
	}

	Vector3 to_target = target_pos - current_pos;
	to_target.y = 0.0f; // strictly purely horizontal

	float dist_sq = to_target.length_squared();
	if (dist_sq <= 0.01f || !to_target.is_finite()) {
		return false;
	}

	Vector3 aim_dir = to_target.normalized();
	if (!aim_dir.is_finite() || aim_dir.length_squared() < 0.0001f) {
		return false;
	}

	facing_direction = aim_dir;

	if (!visuals) {
		visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
		if (!visuals) {
			visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
		}
	}

	rotate_visuals(aim_dir, get_physics_process_delta_time());

	if (!attack_sensor) {
		attack_sensor = Object::cast_to<Area3D>(find_child("AttackSensor", false, false));
		if (!attack_sensor) {
			attack_sensor = Object::cast_to<Area3D>(find_child("WeaponHitbox", false, false));
		}
	}

	if (attack_sensor) {
		attack_sensor->set_position(facing_direction * 1.2f + Vector3(0.0f, 0.5f, 0.0f));
		if (attack_sensor->is_inside_tree()) {
			Vector3 sensor_pos = attack_sensor->get_global_position();
			Vector3 sensor_target = sensor_pos + aim_dir;
			sensor_target.y = sensor_pos.y;
			if (sensor_pos.distance_squared_to(sensor_target) > 0.01f) {
				attack_sensor->look_at(sensor_target, Vector3(0.0f, 1.0f, 0.0f));
			}
		} else {
			attack_sensor->set_basis(Basis::looking_at(aim_dir, Vector3(0.0f, 1.0f, 0.0f)));
		}
	}

	return true;
}

bool PlayerController::orient_towards_cursor() {
	Vector3 cursor_pos;
	if (get_cursor_world_position(cursor_pos)) {
		if (!cursor_pos.is_finite()) {
			return false;
		}
		return orient_towards_point(cursor_pos);
	}
	return false;
}

float PlayerController::get_effective_bat_damage() const {
	return base_attack_damage + static_cast<float>(get_effective_strength()) * 2.5f;
}

void PlayerController::attack() {
	// Melee cannot interrupt an evade; its exit always owns i-frame cleanup.
	if (current_state == STATE_DEAD || current_state == STATE_EVADING || current_state == STATE_GRINDING || is_movement_locked) {
		return;
	}
	if (is_attacking) {
		if (attack_timer <= 0.15f && combo_hit < 3) {
			combo_buffered = true;
		}
		return;
	}
	orient_towards_cursor();
	set_state(STATE_ATTACKING);
	start_combo_hit(1);
}

void PlayerController::start_combo_hit(int p_hit) {
	combo_hit = p_hit;
	combo_buffered = false;
	is_attacking = true;
	attack_timer = 0.29f;
	pending_hit_timer = p_hit == 2 ? 0.06f : 0.10f;
	lunge_timer = 0.08f;
	if (anim_player && anim_player->has_animation("Punch_Combo_1")) {
		anim_player->set_speed_scale(2.4f);
		anim_player->play("Punch_Combo_1");
		anim_player->seek(p_hit == 1 ? 0.45 : (p_hit == 2 ? 0.80 : 1.15), true);
	}
}

void PlayerController::execute_bat_attack() {
	orient_towards_cursor();
	float multiplier = combo_hit == 3 ? 1.5f : 1.0f;
	float damage = get_effective_bat_damage() * multiplier;
	Array damaged_nodes;
	if (attack_sensor && is_inside_tree()) {
		// Area overlap caches lag a physics frame. Query the newly positioned shape directly.
		attack_sensor->set_position(facing_direction * 1.2f + Vector3(0, 0.5f, 0));
		CollisionShape3D *shape = Object::cast_to<CollisionShape3D>(attack_sensor->find_child("*", false, false));
		if (shape && shape->get_shape().is_valid()) {
			Ref<PhysicsShapeQueryParameters3D> query;
			query.instantiate();
			query->set_shape(shape->get_shape());
			query->set_transform(shape->get_global_transform());
			query->set_collision_mask(attack_sensor->get_collision_mask() & ~1u);
			query->set_collide_with_areas(true);
			TypedArray<RID> excluded;
			excluded.append(get_rid());
			excluded.append(attack_sensor->get_rid());
			query->set_exclude(excluded);
			TypedArray<Dictionary> hits = get_world_3d()->get_direct_space_state()->intersect_shape(query, 64);
			for (int i = 0; i < hits.size(); ++i) {
				Dictionary result = hits[i];
				Node *target = Object::cast_to<Node>(result["collider"]);
				if (Object::cast_to<Area3D>(target) && !target->has_method("take_damage")) {
					target = target->get_parent();
				}
				Node3D *body = Object::cast_to<Node3D>(target);
				if (!body || target == this || !target->has_method("take_damage") || damaged_nodes.has(target)) {
					continue;
				}
				Vector3 offset = body->get_global_position() - get_global_position();
				if (Math::abs(offset.y) > 2.0f) {
					continue;
				}
				offset.y = 0;
				float reach = target->is_in_group("boss") ? 4.8f : attack_reach;
				if (offset.length() > reach || (offset.length_squared() > 0.001f && facing_direction.dot(offset.normalized()) < 0.5f)) {
					continue;
				}
				damaged_nodes.append(target);
				target->call("take_damage", static_cast<int>(damage), facing_direction * multiplier);
			}
		}
	}
	if (!damaged_nodes.is_empty()) {
		play_sfx("hit");
		hit_stop(combo_hit == 3 ? 0.10f : 0.06f);
		add_camera_trauma(0.25f);
	} else {
		play_sfx("swing");
	}
	emit_signal("attack_executed", damage);
}

void PlayerController::add_camera_trauma(float p_amount) {
	Node *rig = find_child("IsometricCameraRig", true, false);
	if (rig && rig->has_method("add_trauma")) {
		rig->call("add_trauma", p_amount);
	}
}

void PlayerController::hit_stop(float p_duration) {
	if (!is_inside_tree()) {
		return;
	}
	if (hit_stop_end_msec == 0) {
		previous_time_scale = Engine::get_singleton()->get_time_scale();
	}
	hit_stop_end_msec = Math::max(hit_stop_end_msec, Time::get_singleton()->get_ticks_msec() + static_cast<uint64_t>(p_duration * 1000));
	Engine::get_singleton()->set_time_scale(0.05);
}

void PlayerController::_exit_tree() {
	if (hit_stop_end_msec != 0) {
		Engine::get_singleton()->set_time_scale(previous_time_scale);
		hit_stop_end_msec = 0;
	}
}

void PlayerController::switch_tape(const String &p_tape_name) {
	static const char *k_tapes[] = {
		"Bubblegum",
		"Bounce",
		"Metal",
		"Eurodance",
		"Skatr",
		"FIGHT",
		"Big-Beat",
		"Anthem"
	};
	static const int k_tape_count = 8;

	if (!p_tape_name.is_empty()) {
		bool matched = false;
		int loop_iter1 = 0;
		for (int i = 0; i < k_tape_count; i++) {
			if (++loop_iter1 > 100) {
				break;
			}
			if (p_tape_name == k_tapes[i]) {
				current_tape = k_tapes[i];
				matched = true;
				break;
			}
		}
		if (!matched) {
			String lower = p_tape_name.to_lower().strip_edges();
			if (lower == "bubblegum" || lower.contains("bubblegum") || lower.contains("pop")) {
				current_tape = "Bubblegum";
			} else if (lower == "bounce" || lower.contains("bounce") || lower.contains("hip-hop") || lower.contains("hiphop")) {
				current_tape = "Bounce";
			} else if (lower == "metal" || lower.contains("metal") || lower.contains("nu-metal") || lower.contains("numetal")) {
				current_tape = "Metal";
			} else if (lower == "eurodance" || lower.contains("eurodance") || lower.contains("euro")) {
				current_tape = "Eurodance";
			} else if (lower == "skatr" || lower == "skater" || lower.contains("skat") || lower.contains("punk")) {
				current_tape = "Skatr";
			} else if (lower == "fight" || lower == "combat" || lower.contains("fight") || lower.contains("combat") || lower.contains("menacing")) {
				current_tape = "FIGHT";
			} else if (lower == "big-beat" || lower == "bigbeat" || lower.contains("big-beat") || lower.contains("bigbeat") || lower.contains("big beat") || lower.contains("rave")) {
				current_tape = "Big-Beat";
			} else if (lower == "anthem" || lower.contains("anthem") || lower.contains("asphalt") || lower.contains("pop-rock") || lower.contains("pop rock")) {
				current_tape = "Anthem";
			} else {
				current_tape = p_tape_name;
			}
		}
	} else {
		// Cycle to next tape
		int current_idx = 0;
		int loop_iter2 = 0;
		for (int i = 0; i < k_tape_count; i++) {
			if (++loop_iter2 > 100) {
				break;
			}
			if (current_tape == k_tapes[i]) {
				current_idx = i;
				break;
			}
		}
		current_tape = k_tapes[(current_idx + 1) % k_tape_count];
	}

	recalculate_derived_stats();

	// Print debug line showing the stat change
	String buff_desc = "";
	if (current_tape == "Bubblegum" || current_tape == "Bubblegum Pop") {
		buff_desc = "Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!)";
	} else if (current_tape == "Bounce" || current_tape == "Bouncy Hip-Hop") {
		buff_desc = "Strength +8 (Boom-bap rhythm & solid baseball bat power!)";
	} else if (current_tape == "Metal" || current_tape == "Nu-Metal Rage") {
		buff_desc = "Strength +5, Vitality +5 (Heavy distortion & armored bruiser grit!)";
	} else if (current_tape == "Eurodance" || current_tape == "Eurodance Radio") {
		buff_desc = "Agility +5, Vibe +10 (Hypnotic rave focus & radiant charisma!)";
	} else if (current_tape == "Skatr" || current_tape == "skater") {
		buff_desc = "Agility +12, Strength +3 (Max skate velocity & fast punk adrenaline!)";
	} else if (current_tape == "FIGHT" || current_tape == "combat") {
		buff_desc = "Strength +10, Vitality +6 (Menacing combat riff & heavy bat impact!)";
	} else if (current_tape == "Big-Beat" || current_tape == "bigbeat") {
		buff_desc = "Vibe +12, Agility +6 (Chaotic rave breaks & high-voltage swagger!)";
	} else if (current_tape == "Anthem" || current_tape == "anthem") {
		buff_desc = "Vitality +8, Vibe +8 (Stadium rock resilience & unshakeable team spirit!)";
	}

	float current_bat_dmg = get_effective_bat_damage();
	UtilityFunctions::print("[Y2K-WALKMAN] *CLACK!* Inserted cassette: '", current_tape, "' | Buff: ", buff_desc,
		" | STR: ", get_effective_strength(), " (Bat DMG: ", current_bat_dmg, ")",
		" | AGI: ", get_effective_agility(), " (Speed: ", get_movement_speed(), ")",
		" | VIT: ", get_effective_vitality(), " (Max HP: ", max_health, ")",
		" | VIBE: ", get_effective_vibe());

	emit_signal("tape_switched", current_tape, buff_desc);

	// Walkman Audio Playback
	if (walkman_audio) {
		walkman_audio->stop();

		const char *candidates[8] = { nullptr };
		if (current_tape == "Bubblegum" || current_tape == "Bubblegum Pop") {
			candidates[0] = "res://music/bubblegum.mp3";
			candidates[1] = "res://music/bubblegum_pop.mp3";
		} else if (current_tape == "Bounce" || current_tape == "Bouncy Hip-Hop") {
			candidates[0] = "res://music/bounce.mp3";
			candidates[1] = "res://music/hiphop.mp3";
			candidates[2] = "res://music/bouncy_hip_hop.mp3";
		} else if (current_tape == "Metal" || current_tape == "Nu-Metal Rage") {
			candidates[0] = "res://music/metal.mp3";
			candidates[1] = "res://music/numetal.mp3";
			candidates[2] = "res://music/nu_metal.mp3";
		} else if (current_tape == "Eurodance" || current_tape == "Eurodance Radio") {
			candidates[0] = "res://music/eurodance.mp3";
			candidates[1] = "res://music/eurodance_radio.mp3";
		} else if (current_tape == "Skatr" || current_tape == "skater") {
			candidates[0] = "res://music/skatr.mp3";
			candidates[1] = "res://music/skater.mp3";
			candidates[2] = "res://music/the_skater.mp3";
		} else if (current_tape == "FIGHT" || current_tape == "combat") {
			candidates[0] = "res://music/fight.mp3";
			candidates[1] = "res://music/combat.mp3";
			candidates[2] = "res://music/the_combat.mp3";
		} else if (current_tape == "Big-Beat" || current_tape == "bigbeat") {
			candidates[0] = "res://music/big-beat.mp3";
			candidates[1] = "res://music/bigbeat.mp3";
			candidates[2] = "res://music/big_beat.mp3";
		} else if (current_tape == "Anthem" || current_tape == "anthem") {
			candidates[0] = "res://music/anthem.mp3";
			candidates[1] = "res://music/Asphalt_Anthem.mp3";
			candidates[2] = "res://music/the_anthem.mp3";
		}

		String chosen_path = "";
		int loop_iter3 = 0;
		for (int i = 0; i < 8 && candidates[i] != nullptr; i++) {
			if (++loop_iter3 > 100) {
				break;
			}
			if (FileAccess::file_exists(candidates[i]) || ResourceLoader::get_singleton()->exists(candidates[i])) {
				chosen_path = candidates[i];
				break;
			}
		}

		if (chosen_path.is_empty() && candidates[0] != nullptr) {
			chosen_path = candidates[0];
		}

		if (FileAccess::file_exists(chosen_path) || ResourceLoader::get_singleton()->exists(chosen_path)) {
			Ref<AudioStream> stream = ResourceLoader::get_singleton()->load(chosen_path);
			if (stream.is_valid()) {
				walkman_audio->set_stream(stream);
				if (walkman_audio->is_inside_tree()) {
					walkman_audio->play();
				}
				UtilityFunctions::print("[Y2K-WALKMAN] *PLAY* Playing audio track: '", chosen_path, "' on WalkmanAudio.");
			} else {
				UtilityFunctions::print("[Y2K-WALKMAN] *ERROR* Failed to load audio stream from '", chosen_path, "'.");
			}
		} else {
			walkman_audio->set_stream(Ref<AudioStream>());
			UtilityFunctions::print("[Y2K-WALKMAN] *INFO* Audio track '", chosen_path, "' not found in res://music/ (place .mp3 files here to play music).");
		}
	}
}

int PlayerController::get_effective_strength() const {
	int val = base_stats.strength;
	if (current_tape == "Bounce" || current_tape == "Bouncy Hip-Hop") {
		val += 8;
	} else if (current_tape == "Metal" || current_tape == "Nu-Metal Rage") {
		val += 5;
	} else if (current_tape == "Skatr" || current_tape == "skater" || current_tape == "The Skater (Fast Punk)") {
		val += 3;
	} else if (current_tape == "FIGHT" || current_tape == "combat" || current_tape == "The Combat (Menacing)") {
		val += 10;
	}
	return val;
}

int PlayerController::get_effective_agility() const {
	int val = base_stats.agility;
	if (current_tape == "Bubblegum" || current_tape == "Bubblegum Pop") {
		val += 8;
	} else if (current_tape == "Eurodance" || current_tape == "Eurodance Radio") {
		val += 5;
	} else if (current_tape == "Skatr" || current_tape == "skater" || current_tape == "The Skater (Fast Punk)") {
		val += 12;
	} else if (current_tape == "Big-Beat" || current_tape == "bigbeat" || current_tape == "The Big Beat (Sample Rave)") {
		val += 6;
	}
	return val;
}

int PlayerController::get_effective_vitality() const {
	int val = base_stats.vitality;
	if (current_tape == "Metal" || current_tape == "Nu-Metal Rage") {
		val += 5;
	} else if (current_tape == "FIGHT" || current_tape == "combat" || current_tape == "The Combat (Menacing)") {
		val += 6;
	} else if (current_tape == "Anthem" || current_tape == "anthem" || current_tape == "The Anthem (Asphalt Rock)") {
		val += 8;
	}
	return val;
}

int PlayerController::get_effective_vibe() const {
	int val = base_stats.vibe;
	if (current_tape == "Eurodance" || current_tape == "Eurodance Radio") {
		val += 10;
	} else if (current_tape == "Bubblegum" || current_tape == "Bubblegum Pop") {
		val += 4;
	} else if (current_tape == "Big-Beat" || current_tape == "bigbeat" || current_tape == "The Big Beat (Sample Rave)") {
		val += 12;
	} else if (current_tape == "Anthem" || current_tape == "anthem" || current_tape == "The Anthem (Asphalt Rock)") {
		val += 8;
	}
	return val;
}

int PlayerController::get_level() const {
	return level;
}

void PlayerController::set_level(int p_lvl) {
	level = UtilityFunctions::maxi(1, p_lvl);
	emit_signal("xp_changed", current_xp, xp_to_level, level);
}

int PlayerController::get_current_xp() const {
	return current_xp;
}

void PlayerController::set_current_xp(int p_xp) {
	current_xp = p_xp;
	emit_signal("xp_changed", current_xp, xp_to_level, level);
}

int PlayerController::get_xp_to_level() const {
	return xp_to_level;
}

void PlayerController::set_xp_to_level(int p_next) {
	xp_to_level = UtilityFunctions::maxi(1, p_next);
	emit_signal("xp_changed", current_xp, xp_to_level, level);
}

int PlayerController::get_unspent_stat_points() const {
	return unspent_stat_points;
}

void PlayerController::set_unspent_stat_points(int p_points) {
	unspent_stat_points = UtilityFunctions::maxi(0, p_points);
	emit_signal("stats_changed");
}

bool PlayerController::get_movement_locked() const {
	return is_movement_locked;
}

void PlayerController::set_movement_locked(bool p_locked) {
	is_movement_locked = p_locked;
	if (is_movement_locked && current_state != STATE_DEAD) {
		set_state(is_on_floor() ? STATE_NORMAL : STATE_AIRBORNE);
		set_velocity(Vector3(0.0f, 0.0f, 0.0f));
	}
}

bool PlayerController::get_is_attacking() const {
	return is_attacking;
}

void PlayerController::set_is_attacking(bool p_attacking) {
	if (p_attacking) {
		attack();
	} else if (current_state == STATE_ATTACKING) {
		set_state(is_on_floor() ? STATE_NORMAL : STATE_AIRBORNE);
	}
}

bool PlayerController::get_is_skating() const {
	return is_skating;
}

void PlayerController::set_is_skating(bool p_skating) {
	is_skating = p_skating;
	is_equipped_skates = p_skating;
	UtilityFunctions::print("[Y2K-EQUIPMENT] Roller skates ", is_skating ? "EQUIPPED! (12.0 m/s)" : "UNEQUIPPED! (Walking)");
	emit_signal("skates_toggled", is_skating);
}

float PlayerController::get_skate_speed() const {
	return skate_speed;
}

void PlayerController::set_skate_speed(float p_speed) {
	skate_speed = p_speed;
}

bool PlayerController::get_is_equipped_skates() const {
	return is_skating;
}

void PlayerController::set_is_equipped_skates(bool p_equipped) {
	set_is_skating(p_equipped);
}

Vector3 PlayerController::get_facing_direction() const {
	return facing_direction;
}

void PlayerController::set_facing_direction(const Vector3 &p_dir) {
	if (p_dir.length_squared() > 0.0001f) {
		facing_direction = p_dir.normalized();
	}
}

float PlayerController::get_rotation_speed() const {
	return rotation_speed;
}

void PlayerController::set_rotation_speed(float p_speed) {
	rotation_speed = p_speed;
}

float PlayerController::get_gravity() const {
	return gravity;
}

void PlayerController::set_gravity(float p_gravity) {
	gravity = p_gravity;
}

float PlayerController::get_base_movement_speed() const {
	return base_movement_speed;
}

void PlayerController::set_base_movement_speed(float p_speed) {
	base_movement_speed = p_speed;
}

int PlayerController::get_strength() const {
	return base_stats.strength;
}

void PlayerController::set_strength(int p_val) {
	base_stats.strength = p_val;
	recalculate_derived_stats();
}

int PlayerController::get_agility() const {
	return base_stats.agility;
}

void PlayerController::set_agility(int p_val) {
	base_stats.agility = p_val;
	recalculate_derived_stats();
}

int PlayerController::get_vitality() const {
	return base_stats.vitality;
}

void PlayerController::set_vitality(int p_val) {
	base_stats.vitality = p_val;
	recalculate_derived_stats();
}

int PlayerController::get_vibe() const {
	return base_stats.vibe;
}

void PlayerController::set_vibe(int p_val) {
	base_stats.vibe = p_val;
	recalculate_derived_stats();
}

float PlayerController::get_current_health() const {
	return current_health;
}

void PlayerController::set_current_health(float p_hp) {
	if (current_state == STATE_DEAD) {
		return;
	}
	current_health = UtilityFunctions::clampf(p_hp, 0.0f, max_health);
	emit_signal("health_changed", current_health, max_health);
	if (current_health <= 0.0f) {
		die();
	}
}

float PlayerController::get_max_health() const {
	return max_health;
}

void PlayerController::set_max_health(float p_max_hp) {
	max_health = UtilityFunctions::maxf(1.0f, p_max_hp);
	emit_signal("health_changed", current_health, max_health);
}

String PlayerController::get_current_tape() const {
	return current_tape;
}

void PlayerController::set_current_tape(const String &p_tape) {
	switch_tape(p_tape);
}

void PlayerController::take_damage(float p_amount, const Vector3 &p_knockback) {
	if (current_state == STATE_DEAD || is_invincible || hurt_invuln_timer > 0 || p_amount <= 0) {
		return;
	}
	current_health = Math::max(0.0f, current_health - p_amount);
	hurt_invuln_timer = 0.6f;
	hurt_flash_timer = 0.18f;
	if (hurt_overlay.is_valid()) {
		hurt_overlay->set_albedo(Color(1, 1, 1));
		for (int i = 0; i < skin_meshes.size(); ++i) {
			Object::cast_to<MeshInstance3D>(skin_meshes[i])->set_material_overlay(hurt_overlay);
		}
	}
	Vector3 direction = p_knockback;
	direction.y = 0;
	if (direction.length_squared() > 0.001f) {
		Vector3 velocity = direction.normalized() * 7.0f;
		velocity.y = get_velocity().y;
		set_velocity(velocity);
		knockback_timer = 0.12f;
	}
	play_sfx("hurt");
	add_camera_trauma(0.45f);
	emit_signal("player_hurt", p_amount);
	emit_signal("health_changed", current_health, max_health);
	if (current_health <= 0.0f) {
		die();
	}
}

void PlayerController::heal(float p_amount) {
	if (current_state == STATE_DEAD) {
		return;
	}
	current_health = UtilityFunctions::minf(max_health, current_health + p_amount);
	emit_signal("health_changed", current_health, max_health);
}

static Ref<AudioStreamWAV> create_sfx_stream(const String &type) {
	Ref<AudioStreamWAV> wav;
	wav.instantiate();
	wav->set_format(AudioStreamWAV::FORMAT_8_BITS);
	wav->set_mix_rate(22050);
	wav->set_loop_mode(AudioStreamWAV::LOOP_DISABLED);

	int samples = 0;
	PackedByteArray data;

	if (type == "hit") {
		samples = static_cast<int>(22050 * 0.12f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float env = 1.0f - t;
			float freq = 140.0f - t * 70.0f;
			float sine = Math::sin(static_cast<float>(i) * (Math_TAU * freq / 22050.0f));
			float noise = (static_cast<float>(rand() % 256) / 128.0f - 1.0f) * 0.4f;
			float val = Math::clamp((sine * 0.6f + noise) * env, -1.0f, 1.0f);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else if (type == "evade") {
		samples = static_cast<int>(22050 * 0.22f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float env = Math::sin(t * Math_PI);
			float freq = 220.0f + t * 450.0f;
			float noise = (static_cast<float>(rand() % 256) / 128.0f - 1.0f);
			float sine = Math::sin(static_cast<float>(i) * (Math_TAU * freq / 22050.0f));
			float val = Math::clamp((sine * 0.3f + noise * 0.7f) * env * 0.7f, -1.0f, 1.0f);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else if (type == "death") {
		samples = static_cast<int>(22050 * 0.75f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float env = 1.0f - t * 0.7f;
			float freq = 440.0f * (1.0f - t * 0.8f);
			float square = (Math::sin(static_cast<float>(i) * (Math_TAU * freq / 22050.0f)) > 0.0f) ? 0.5f : -0.5f;
			float noise = (static_cast<float>(rand() % 256) / 128.0f - 1.0f) * (t * 0.5f);
			float val = Math::clamp((square + noise) * env * 0.8f, -1.0f, 1.0f);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else if (type == "slam") {
		samples = static_cast<int>(22050 * 0.3f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float env = (1.0f - t) * (1.0f - t);
			float freq = 100.0f - t * 60.0f;
			float sine = Math::sin(static_cast<float>(i) * (Math_TAU * freq / 22050.0f));
			float noise = (static_cast<float>(rand() % 256) / 128.0f - 1.0f) * 0.5f;
			float val = Math::clamp((sine * 0.8f + noise * 0.2f) * env, -1.0f, 1.0f);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else if (type == "yum") {
		// Juicy Gusher pop & sweet rising harmonic chime
		samples = static_cast<int>(22050 * 0.35f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float val = 0.0f;
			if (t < 0.35f) {
				float t_part = t / 0.35f;
				float pop_freq = Math::lerp(440.0f, 160.0f, t_part);
				float pop_sine = Math::sin(static_cast<float>(i) * (Math_TAU * pop_freq / 22050.0f));
				val += pop_sine * (1.0f - t_part) * 0.45f;
			}
			if (t >= 0.15f) {
				float t_chime = (t - 0.15f) / 0.85f;
				float chime_freq = (t < 0.55f) ? 880.0f : 1318.5f;
				float chime_sine = Math::sin(static_cast<float>(i) * (Math_TAU * chime_freq / 22050.0f));
				float chime_harm = Math::sin(static_cast<float>(i) * (Math_TAU * (chime_freq * 2.0f) / 22050.0f)) * 0.25f;
				float chime_env = Math::exp(-t_chime * 4.5f);
				val += (chime_sine + chime_harm) * chime_env * 0.55f;
			}
			val = Math::clamp(val, -1.0f, 1.0f);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else if (type == "hurt" || type == "jump" || type == "land") {
		float duration = type == "hurt" ? 0.15f : (type == "jump" ? 0.12f : 0.10f);
		samples = static_cast<int>(22050 * duration);
		data.resize(samples);
		float phase = 0;
		for (int i = 0; i < samples; ++i) {
			float t = static_cast<float>(i) / samples;
			float frequency = type == "hurt" ? Math::lerp(300.0f, 120.0f, t) : (type == "jump" ? Math::lerp(180.0f, 650.0f, t) : Math::lerp(110.0f, 45.0f, t));
			phase += static_cast<float>(Math_TAU) * frequency / 22050.0f;
			float wave = type == "hurt" ? (Math::sin(phase) > 0 ? 0.5f : -0.5f) : Math::sin(phase) * 0.6f;
			float val = wave * (1.0f - t) * (1.0f - t);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	} else {
		samples = static_cast<int>(22050 * 0.08f);
		data.resize(samples);
		for (int i = 0; i < samples; i++) {
			float t = static_cast<float>(i) / samples;
			float sine = Math::sin(static_cast<float>(i) * (Math_TAU * 500.0f / 22050.0f));
			float val = sine * (1.0f - t);
			data[i] = static_cast<uint8_t>(static_cast<int8_t>(Math::clamp(static_cast<int>(val * 127.0f), -128, 127)));
		}
	}

	wav->set_data(data);
	return wav;
}

void PlayerController::play_sfx(const String &p_name) {
	// Bare off-tree test instances have no audio voices until READY.
	AudioStreamPlayer *voice = sfx_pool[sfx_voice];
	if (!voice) {
		return;
	}
	if (!sfx_cache.has(p_name)) {
		sfx_cache[p_name] = create_sfx_stream(p_name);
	}
	Ref<AudioStream> stream = sfx_cache[p_name];
	voice->set_stream(stream);
	if (voice->is_inside_tree()) {
		voice->play();
	}
	sfx_voice = (sfx_voice + 1) % 4;
}

bool PlayerController::is_dead() const {
	return current_state == STATE_DEAD;
}

void PlayerController::die() {
	if (current_state == STATE_DEAD) {
		return;
	}

	set_state(STATE_DEAD);
	current_health = 0.0f;
	death_timer = 2.5f;
	is_invincible = true;
	set_velocity(Vector3(0.0f, 0.0f, 0.0f));

	if (flame_particles) {
		flame_particles->set_emitting(false);
	}

	play_sfx("death");

	UtilityFunctions::print("[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...");

	// 1. Death Animation
	if (!anim_player) {
		anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer", true, false));
	}
	if (anim_player) {
		if (anim_player->has_animation("Death")) {
			anim_player->play("Death");
		} else if (anim_player->has_animation("Die")) {
			anim_player->play("Die");
		} else if (anim_player->has_animation("Fall")) {
			anim_player->play("Fall");
		} else {
			anim_player->stop();
		}
	}

	// 2. Collapse Visuals Backward
	if (!visuals) {
		visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
		if (!visuals) {
			visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
		}
	}
	if (visuals && is_inside_tree()) {
		Ref<Tween> tween = create_tween();
		if (tween.is_valid()) {
			tween->set_parallel(true);
			tween->set_ease(Tween::EASE_OUT);
			tween->set_trans(Tween::TRANS_QUAD);
			tween->tween_property(visuals, "rotation:x", -1.45f, 0.5);
			tween->tween_property(visuals, "position:y", 0.05f, 0.5);
		}
	}

	// 3. Visual Death FX (Crimson Bio-Hazard Flatline Mesh)
	MeshInstance3D *death_fx = memnew(MeshInstance3D);
	death_fx->set_name("PlayerDeathFX");

	Ref<CylinderMesh> cyl_mesh;
	cyl_mesh.instantiate();
	cyl_mesh->set_top_radius(0.3f);
	cyl_mesh->set_bottom_radius(0.3f);
	cyl_mesh->set_height(0.05f);
	death_fx->set_mesh(cyl_mesh);

	Ref<StandardMaterial3D> mat;
	mat.instantiate();
	mat->set_transparency(BaseMaterial3D::TRANSPARENCY_ALPHA);
	mat->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);
	mat->set_cull_mode(BaseMaterial3D::CULL_DISABLED);
	mat->set_albedo(Color(1.0f, 0.1f, 0.15f, 0.9f));
	death_fx->set_material_override(mat);

	Vector3 my_pos = is_inside_tree() ? get_global_position() : get_position();
	death_fx->set_position(my_pos + Vector3(0.0f, 0.08f, 0.0f));

	Node *scene_target = nullptr;
	if (is_inside_tree() && get_tree()) {
		scene_target = get_tree()->get_current_scene();
	}
	if (!scene_target) {
		scene_target = get_parent();
	}
	if (scene_target) {
		scene_target->add_child(death_fx);
		death_fx->set_global_position(my_pos + Vector3(0.0f, 0.08f, 0.0f));

		Ref<Tween> fx_tween = death_fx->create_tween();
		if (fx_tween.is_valid()) {
			fx_tween->set_parallel(true);
			fx_tween->set_ease(Tween::EASE_OUT);
			fx_tween->set_trans(Tween::TRANS_QUAD);
			fx_tween->tween_property(death_fx, "scale", Vector3(5.0f, 1.0f, 5.0f), 1.2);
			fx_tween->tween_property(mat.ptr(), "albedo_color", Color(0.4f, 0.0f, 0.05f, 0.0f), 1.2);
			fx_tween->chain()->tween_callback(Callable(death_fx, "queue_free"));
		}
	}

	emit_signal("player_died");
	emit_signal("health_changed", 0.0f, max_health);
}

Node3D *PlayerController::get_visuals() const {
	return visuals;
}

void PlayerController::set_visuals(Node3D *p_visuals) {
	visuals = p_visuals;
}

AnimationPlayer *PlayerController::get_animation_player() const {
	return anim_player;
}

void PlayerController::set_animation_player(AnimationPlayer *p_anim) {
	anim_player = p_anim;
}

GPUParticles3D *PlayerController::get_flame_particles() const {
	return flame_particles;
}

void PlayerController::set_flame_particles(GPUParticles3D *p_particles) {
	flame_particles = p_particles;
}

bool PlayerController::try_start_grind(Path3D *p_path) {
	if (current_state == STATE_DEAD || !p_path || current_state == STATE_GRINDING || current_state == STATE_ATTACKING || current_state == STATE_EVADING || is_movement_locked || grind_cooldown > 0.0f) {
		return false;
	}
	if (!is_skating && !is_equipped_skates) {
		return false;
	}

	Vector3 vel = get_velocity();
	float speed = vel.length();
	float horiz_speed = Math::sqrt(vel.x * vel.x + vel.z * vel.z);
	// Minimum threshold: > 4.0 m/s
	if (horiz_speed < 4.0f || (is_on_floor() && recent_jump_timer <= 0.0f)) {
		return false;
	}

	Ref<Curve3D> curve = p_path->get_curve();
	if (!curve.is_valid() || curve->get_point_count() < 2) {
		return false;
	}

	// 1. Calculate the nearest point on the Path3D
	Vector3 player_pos = is_inside_tree() ? get_global_position() : get_position();
	Vector3 local_player = (p_path->is_inside_tree() && is_inside_tree()) ? p_path->to_local(player_pos) : (player_pos - p_path->get_position());
	float closest_offset = curve->get_closest_offset(local_player);
	float baked_len = curve->get_baked_length();
	if (baked_len <= 0.001f) {
		return false;
	}

	// 2. Calculate curve tangent to determine entry direction along spline
	float sample_ahead = Math::min(closest_offset + 0.5f, baked_len);
	float sample_behind = Math::max(closest_offset - 0.5f, 0.0f);
	Vector3 p_ahead = curve->sample_baked(sample_ahead);
	Vector3 p_behind = curve->sample_baked(sample_behind);
	Vector3 local_tangent = (p_ahead - p_behind).normalized();
	Vector3 world_tangent = p_path->is_inside_tree() ? p_path->get_global_transform().basis.xform(local_tangent) : local_tangent;
	world_tangent.y = 0.0f;
	if (world_tangent.length_squared() > 0.001f) {
		world_tangent.normalize();
	}

	Vector3 hv(vel.x, 0, vel.z);
	if (world_tangent.length_squared() < 0.001f || Math::abs(hv.normalized().dot(world_tangent)) < 0.5f) {
		return false;
	}
	float dot = hv.dot(world_tangent);
	grind_direction = (dot >= 0.0f) ? 1.0f : -1.0f;

	// Translate entry velocity into progression speed along rail
	grind_speed = Math::max(speed, skate_speed);
	grind_progress = closest_offset;
	grind_elapsed_time = 0.0f;

	// 3. Find or instantiate PathFollow3D on Path3D
	grind_path_follow = Object::cast_to<PathFollow3D>(p_path->find_child("PathFollow3D", false, false));
	if (!grind_path_follow) {
		grind_path_follow = memnew(PathFollow3D);
		grind_path_follow->set_name("PathFollow3D");
		p_path->add_child(grind_path_follow);
	}
	grind_path_follow->set_loop(false);
	grind_path_follow->set_progress(closest_offset);

	// Smooth the entry from this root position over the next 0.06 seconds.
	grind_entry_position = player_pos;

	current_grind_path = p_path;
	set_state(STATE_GRINDING);

	// Align visuals facing along rail upon entry
	Vector3 face_dir = world_tangent * (grind_direction >= 0.0f ? 1.0f : -1.0f);
	face_dir.y = 0.0f;
	if (face_dir.length_squared() > 0.0001f) {
		facing_direction = face_dir.normalized();
	}
	if (!visuals) {
		visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
		if (!visuals) {
			visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
		}
	}
	rotate_visuals(facing_direction, get_physics_process_delta_time());

	// Animation State: Explicitly command AnimationPlayer to play "Skate_Grind"
	if (!anim_player) {
		anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer", true, false));
		if (!anim_player) {
			anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer2", true, false));
		}
		if (!anim_player && visuals) {
			anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer", true, false));
			if (!anim_player) {
				anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer2", true, false));
			}
		}
	}

	if (anim_player) {
		anim_player->set_speed_scale(1.0f);
		if (anim_player->has_animation("Skate_Grind")) {
			anim_player->play("Skate_Grind");
		} else if (anim_player->has_animation("Grind")) {
			anim_player->play("Grind");
		} else {
			anim_player->play("Running");
		}
	}

	UtilityFunctions::print("[Y2K-GRIND] >>> ENTERED STATE_GRINDING on rail '", p_path->get_name(), "'! Speed: ", grind_speed, " m/s | Dir: ", grind_direction > 0 ? "Forward" : "Backward", " | Progress: ", closest_offset, "/", baked_len);
	emit_signal("grind_started", p_path, grind_speed);
	return true;
}

void PlayerController::start_grind(Path3D *p_path) {
	try_start_grind(p_path);
}

void PlayerController::dismount_grind(const Vector3 &p_exit_velocity) {
	Vector3 exit_vel = p_exit_velocity;
	if (exit_vel.length_squared() < 0.001f && facing_direction.length_squared() > 0.001f) {
		exit_vel = facing_direction * (is_skating ? skate_speed : base_movement_speed);
		exit_vel.y = 2.5f;
	}

	if (current_state != STATE_GRINDING) {
		return;
	}
	set_velocity(exit_vel);
	set_state(STATE_AIRBORNE);

	if (!anim_player) {
		anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer", true, false));
		if (!anim_player) {
			anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer2", true, false));
		}
		if (!anim_player && visuals) {
			anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer", true, false));
			if (!anim_player) {
				anim_player = Object::cast_to<AnimationPlayer>(visuals->find_child("AnimationPlayer2", true, false));
			}
		}
	}

	if (anim_player) {
		anim_player->set_speed_scale(1.0f);
		String anim_to_play = (is_skating || is_equipped_skates) ? "Running" : "Walking";
		anim_player->play(anim_to_play);
	}

	UtilityFunctions::print("[Y2K-GRIND] <<< EXITED STATE_GRINDING! Restored exit momentum: ", exit_vel);
}

void PlayerController::_on_grind_area_entered(Area3D *p_area) {
	if (!p_area || current_state == STATE_GRINDING || grind_cooldown > 0.0f) {
		return;
	}
	if (!is_skating && !is_equipped_skates) {
		return;
	}
	if (p_area->is_in_group("grindable") || p_area->get_collision_layer_value(3) || p_area->get_collision_layer_value(4)) {
		Path3D *path = Object::cast_to<Path3D>(p_area->get_parent());
		if (!path) {
			path = Object::cast_to<Path3D>(p_area->find_parent("Path3D"));
		}
		if (path) {
			try_start_grind(path);
		}
	}
}

PlayerController::MovementState PlayerController::get_movement_state() const {
	return current_state;
}

void PlayerController::set_movement_state(PlayerController::MovementState p_state) {
	set_state(p_state);
}

void PlayerController::set_state(MovementState p_state) {
	if (p_state < STATE_NORMAL || p_state > STATE_DEAD || p_state == current_state) {
		return;
	}
	switch (current_state) {
		case STATE_EVADING:
			is_invincible = false;
			evade_timer = 0;
			evade_cooldown = evade_cooldown_max;
			emit_signal("evade_ended");
			break;
		case STATE_ATTACKING:
			is_attacking = false;
			attack_timer = 0;
			pending_hit_timer = -1;
			lunge_timer = 0;
			combo_buffered = false;
			combo_hit = 0;
			break;
		case STATE_GRINDING:
			current_grind_path = nullptr;
			grind_path_follow = nullptr;
			grind_progress = 0;
			grind_elapsed_time = 0;
			grind_cooldown = 0.5f;
			emit_signal("grind_ended", get_velocity());
			break;
		default:
			break;
	}
	current_state = p_state;
	if (p_state == STATE_ATTACKING) {
		is_attacking = true;
	}
	if (p_state == STATE_DEAD) {
		pending_slam = false;
		jump_buffer_timer = coyote_timer = 0;
	}
}

bool PlayerController::is_grinding() const {
	return current_state == STATE_GRINDING;
}

float PlayerController::get_current_adrenaline() const {
	return current_adrenaline;
}

void PlayerController::set_current_adrenaline(float p_val) {
	current_adrenaline = UtilityFunctions::clampf(p_val, 0.0f, max_adrenaline);
	emit_signal("adrenaline_changed", current_adrenaline, max_adrenaline);
}

float PlayerController::get_max_adrenaline() const {
	return max_adrenaline;
}

void PlayerController::set_max_adrenaline(float p_val) {
	max_adrenaline = UtilityFunctions::maxf(1.0f, p_val);
	emit_signal("adrenaline_changed", current_adrenaline, max_adrenaline);
}

float PlayerController::get_jump_velocity() const {
	return jump_velocity;
}

void PlayerController::set_jump_velocity(float p_val) {
	jump_velocity = p_val;
}

Area3D *PlayerController::get_attack_sensor() const {
	return attack_sensor;
}

void PlayerController::set_attack_sensor(Area3D *p_sensor) {
	attack_sensor = p_sensor;
}

void PlayerController::simulate_physics(double p_delta) {
	_physics_process(p_delta);
}

bool PlayerController::try_evade() {
	if (current_state == STATE_DEAD || evade_cooldown > 0.0f || current_state == STATE_EVADING || current_state == STATE_GRINDING || is_movement_locked) {
		return false;
	}

	Vector2 raw_input = get_raw_input_direction();
	Vector3 evade_dir = facing_direction;

	if (raw_input.length_squared() > 0.001f) {
		Vector3 raw_3d(raw_input.x, 0.0f, raw_input.y);
		Camera3D *camera = nullptr;
		Viewport *viewport = get_viewport();
		if (viewport) {
			camera = viewport->get_camera_3d();
		}
		if (camera) {
			Vector3 cam_dir = camera->get_global_transform().basis.xform(raw_3d);
			cam_dir.y = 0.0f;
			if (cam_dir.length_squared() > 0.001f) {
				evade_dir = cam_dir.normalized();
			}
		} else {
			evade_dir = raw_3d.normalized();
		}
	}

	start_evade(evade_dir);
	return true;
}

void PlayerController::start_evade(const Vector3 &p_direction) {
	if (is_movement_locked || current_state == STATE_DEAD || current_state == STATE_GRINDING || current_state == STATE_EVADING || evade_cooldown > 0) {
		return;
	}
	set_state(STATE_EVADING);
	evade_direction = p_direction.length_squared() > 0.001f ? p_direction.normalized() : facing_direction;
	facing_direction = evade_direction;
	evade_timer = evade_duration;
	is_invincible = true;

	if (!visuals) {
		visuals = Object::cast_to<Node3D>(get_node_or_null("Visuals"));
		if (!visuals) {
			visuals = Object::cast_to<Node3D>(find_child("Visuals", true, false));
		}
	}
	rotate_visuals(evade_direction, get_physics_process_delta_time());

	if (!anim_player) {
		anim_player = Object::cast_to<AnimationPlayer>(find_child("AnimationPlayer", true, false));
	}
	if (anim_player) {
		anim_player->set_speed_scale(2.5f);
		if (anim_player->has_animation("Slide")) {
			anim_player->play("Slide");
		} else if (anim_player->has_animation("Power_Slide")) {
			anim_player->play("Power_Slide");
		} else if (anim_player->has_animation("Skate_Grind")) {
			anim_player->play("Skate_Grind");
		} else {
			anim_player->play("Running");
		}
	}

	UtilityFunctions::print("[Y2K-MOVEMENT] >>> POWER-SLIDE EVADE! Boost: ", evade_speed, " m/s (Invincible for ", evade_duration, "s)");
	play_sfx("evade");
	emit_signal("evade_started", evade_direction, evade_speed);
}

bool PlayerController::get_is_invincible() const {
	return is_invincible;
}

void PlayerController::set_is_invincible(bool p_inv) {
	is_invincible = p_inv;
}

float PlayerController::get_evade_cooldown() const {
	return evade_cooldown;
}

float PlayerController::get_evade_speed() const {
	return evade_speed;
}

void PlayerController::set_evade_speed(float p_speed) {
	evade_speed = p_speed;
}

void PlayerController::execute_grind_slam(const Vector3 &p_direction) {
	Vector3 slam_dir = p_direction.length_squared() > 0.001f ? p_direction.normalized() : facing_direction;
	Vector3 slam_pos = is_inside_tree() ? get_global_position() : get_position();

	float slam_damage = base_slam_damage + static_cast<float>(get_effective_strength()) * 3.0f + (current_adrenaline * 0.25f);
	UtilityFunctions::print("[Y2K-GRIND] *BOOM!* Rail Dismount Shockwave Slam! Dealing ", slam_damage, " damage (Radius: ", slam_radius, "m)");
	play_sfx("slam");
	hit_stop(0.10f);
	add_camera_trauma(0.6f);

	// Visual Shockwave Effect (CylinderMesh with transparent, unshaded StandardMaterial3D)
	MeshInstance3D *shockwave = memnew(MeshInstance3D);
	shockwave->set_name("GrindSlamShockwave");

	Ref<CylinderMesh> cyl_mesh;
	cyl_mesh.instantiate();
	cyl_mesh->set_top_radius(1.0f);
	cyl_mesh->set_bottom_radius(1.0f);
	cyl_mesh->set_height(0.06f);
	cyl_mesh->set_radial_segments(32);
	cyl_mesh->set_rings(1);
	shockwave->set_mesh(cyl_mesh);

	Ref<StandardMaterial3D> mat;
	mat.instantiate();
	mat->set_transparency(BaseMaterial3D::TRANSPARENCY_ALPHA);
	mat->set_shading_mode(BaseMaterial3D::SHADING_MODE_UNSHADED);
	mat->set_cull_mode(BaseMaterial3D::CULL_DISABLED);
	Color cyan_color(0.15f, 0.95f, 1.0f, 0.85f);
	mat->set_albedo(cyan_color);
	shockwave->set_material_override(mat);

	Vector3 landing_pos = slam_pos + Vector3(0.0f, 0.05f, 0.0f);
	shockwave->set_position(landing_pos);
	shockwave->set_scale(Vector3(0.2f, 1.0f, 0.2f));

	Node *scene_target = nullptr;
	if (is_inside_tree() && get_tree()) {
		scene_target = get_tree()->get_current_scene();
	}
	if (!scene_target) {
		scene_target = get_parent();
	}

	if (scene_target) {
		scene_target->add_child(shockwave);
		shockwave->set_global_position(landing_pos);

		Ref<Tween> tween;
		if (shockwave->is_inside_tree()) {
			tween = shockwave->create_tween();
		} else if (is_inside_tree() && get_tree()) {
			tween = get_tree()->create_tween();
		}

		if (tween.is_valid()) {
			tween->set_parallel(true);
			tween->set_ease(Tween::EASE_OUT);
			tween->set_trans(Tween::TRANS_QUAD);
			Vector3 target_scale(slam_radius, 1.0f, slam_radius);
			tween->tween_property(shockwave, "scale", target_scale, 0.35);
			Color yellow_color(1.0f, 0.92f, 0.2f, 0.0f);
			tween->tween_property(mat.ptr(), "albedo_color", yellow_color, 0.35);
			tween->chain()->tween_callback(Callable(shockwave, "queue_free"));
		}
	}

	Array hit_targets;
	Node *parent = get_parent();
	if (parent) {
		Array candidates;
		TypedArray<Node> direct_children = parent->get_children();
		for (int i = 0; i < direct_children.size(); i++) {
			Node *child = Object::cast_to<Node>(direct_children[i]);
			if (child && child != this) {
				candidates.append(child);
				if (child->get_name() == StringName("Enemies") || child->is_in_group("enemies")) {
					TypedArray<Node> sub_children = child->get_children();
					for (int j = 0; j < sub_children.size(); j++) {
						candidates.append(sub_children[j]);
					}
				}
			}
		}

		for (int i = 0; i < candidates.size(); i++) {
			Node3D *target_3d = Object::cast_to<Node3D>(candidates[i]);
			if (target_3d && target_3d != this) {
				Vector3 to_target = target_3d->get_global_position() - slam_pos;
				to_target.y = 0.0f;
				float dist = to_target.length();
				if (dist <= slam_radius && dist > 0.001f) {
					Vector3 dir = to_target / dist;
					if (slam_dir.dot(dir) >= -0.2f) {
						hit_targets.append(target_3d);
					}
				}
			}
		}
	}

	Array damaged_nodes;
	for (int i = 0; i < hit_targets.size(); i++) {
		Node *target = Object::cast_to<Node>(hit_targets[i]);
		if (!target || damaged_nodes.has(target)) {
			continue;
		}

		bool is_enemy = target->is_in_group("enemies") ||
		                (target->get_parent() && target->get_parent()->get_name() == StringName("Enemies")) ||
		                target->has_method("take_damage");

		if (is_enemy) {
			damaged_nodes.append(target);
			Node3D *target_3d = Object::cast_to<Node3D>(target);
			Vector3 knock_dir = slam_dir;
			if (target_3d) {
				Vector3 diff = target_3d->get_global_position() - slam_pos;
				diff.y = 0.0f;
				if (diff.length_squared() > 0.001f) {
					knock_dir = diff.normalized();
				}
			}
			if (target->has_method("take_damage")) {
				target->call("take_damage", static_cast<int>(slam_damage), knock_dir * 12.0f);
			} else {
				MutatedBugEnemy *bug = Object::cast_to<MutatedBugEnemy>(target);
				if (bug) {
					bug->take_damage(slam_damage);
				}
			}
		}
	}

	emit_signal("grind_slam_executed", slam_pos, slam_dir, slam_damage);
}

void PlayerController::cycle_secondary_weapon() {
	if (current_secondary == SECONDARY_SPRAY_FLAMETHROWER) {
		current_secondary = SECONDARY_DISK_LAUNCHER;
		if (flame_particles) {
			flame_particles->set_emitting(false);
		}
		UtilityFunctions::print("[Y2K-ARSENAL] Switched secondary weapon to: [Y2K Mini-Disc Launcher]");
	} else {
		current_secondary = SECONDARY_SPRAY_FLAMETHROWER;
		UtilityFunctions::print("[Y2K-ARSENAL] Switched secondary weapon to: [Aerosol Spray Paint Flamethrower]");
	}
	emit_signal("secondary_weapon_switched", static_cast<int>(current_secondary), get_secondary_weapon_name());
}

int PlayerController::get_secondary_weapon() const {
	return static_cast<int>(current_secondary);
}

void PlayerController::set_secondary_weapon(int p_weapon) {
	current_secondary = static_cast<SecondaryWeapon>(p_weapon);
	if (current_secondary != SECONDARY_SPRAY_FLAMETHROWER && flame_particles) {
		flame_particles->set_emitting(false);
	}
}

String PlayerController::get_secondary_weapon_name() const {
	if (current_secondary == SECONDARY_SPRAY_FLAMETHROWER) {
		return "Aerosol Spray Flamethrower";
	} else if (current_secondary == SECONDARY_DISK_LAUNCHER) {
		return "Mini-Disc Launcher";
	}
	return "None";
}

void PlayerController::set_secondary_weapon_name(const String &p_name) {
	String lower = p_name.to_lower();
	if (lower.contains("spray") || lower.contains("flame") || lower.contains("aerosol")) {
		current_secondary = SECONDARY_SPRAY_FLAMETHROWER;
	} else if (lower.contains("disk") || lower.contains("disc") || lower.contains("launcher")) {
		current_secondary = SECONDARY_DISK_LAUNCHER;
	} else {
		current_secondary = SECONDARY_NONE;
	}
	if (current_secondary != SECONDARY_SPRAY_FLAMETHROWER && flame_particles) {
		flame_particles->set_emitting(false);
	}
}

void PlayerController::fire_secondary() {
	if (current_state == STATE_DEAD) {
		return;
	}
	orient_towards_cursor();
	if (current_secondary == SECONDARY_SPRAY_FLAMETHROWER) {
		fire_spray_flamethrower();
	} else if (current_secondary == SECONDARY_DISK_LAUNCHER) {
		fire_disk_launcher();
	}
}

void PlayerController::fire_spray_flamethrower() {
	orient_towards_cursor();
	if (flame_tick_timer > 0.0f) {
		return;
	}
	flame_tick_timer = 0.12f;

	float flame_damage = 5.0f + static_cast<float>(get_effective_vibe()) * 0.6f;
	Vector3 my_pos = is_inside_tree() ? get_global_position() : get_position();
	Vector3 fire_dir = facing_direction;

	UtilityFunctions::print("[Y2K-ARSENAL] *FSSSSHHH-WHOOSH!* Aerosol Spray Flamethrower streaming flames! DMG tick: ", flame_damage);

	Node *parent = get_parent();
	if (parent) {
		Array candidates;
		TypedArray<Node> direct_children = parent->get_children();
		for (int i = 0; i < direct_children.size(); i++) {
			Node *child = Object::cast_to<Node>(direct_children[i]);
			if (child && child != this) {
				candidates.append(child);
				if (child->get_name() == StringName("Enemies") || child->is_in_group("enemies")) {
					TypedArray<Node> sub_children = child->get_children();
					for (int j = 0; j < sub_children.size(); j++) {
						candidates.append(sub_children[j]);
					}
				}
			}
		}

		if (SceneTree *st = get_tree()) {
			TypedArray<Node> boss_nodes = st->get_nodes_in_group("boss");
			for (int i = 0; i < boss_nodes.size(); i++) {
				Node *bn = Object::cast_to<Node>(boss_nodes[i]);
				if (bn && !candidates.has(bn)) {
					candidates.append(bn);
				}
			}
		}

		for (int i = 0; i < candidates.size(); i++) {
			Node3D *target_3d = Object::cast_to<Node3D>(candidates[i]);
			if (target_3d && target_3d != this) {
				Vector3 to_node = target_3d->get_global_position() - my_pos;
				to_node.y = 0.0f;
				float dist = to_node.length();
				float allowed_dist = (target_3d->is_in_group("boss") || target_3d->get_name() == StringName("DialUpQueen")) ? 6.0f : 4.2f;
				if (dist <= allowed_dist && dist > 0.001f) {
					Vector3 dir = to_node / dist;
					if (fire_dir.dot(dir) >= 0.5f) {
						if (target_3d->has_method("take_damage")) {
							target_3d->call("take_damage", static_cast<int>(flame_damage), fire_dir * 2.0f);
						} else {
							MutatedBugEnemy *bug = Object::cast_to<MutatedBugEnemy>(target_3d);
							if (bug) {
								bug->take_damage(flame_damage);
							}
						}
					}
				}
			}
		}
	}

	emit_signal("secondary_fired", static_cast<int>(SECONDARY_SPRAY_FLAMETHROWER), my_pos, fire_dir, flame_damage);
}

void PlayerController::fire_disk_launcher() {
	orient_towards_cursor();
	if (secondary_cooldown > 0.0f) {
		return;
	}
	secondary_cooldown = 0.45f;

	float disk_damage = 25.0f + static_cast<float>(get_effective_agility()) * 2.2f;
	Vector3 my_pos = is_inside_tree() ? get_global_position() : get_position();
	Vector3 fire_dir = facing_direction;
	Vector3 spawn_pos = my_pos + fire_dir * 1.0f + Vector3(0.0f, 0.8f, 0.0f);

	UtilityFunctions::print("[Y2K-ARSENAL] *SHICK-ZWIP!* Fired Y2K Mini-Disc! DMG: ", disk_damage);

	Node *parent = get_parent();
	if (parent && ResourceLoader::get_singleton()) {
		String proj_path = "";
		if (ResourceLoader::get_singleton()->exists("res://scripts/disk_projectile.gd")) {
			proj_path = "res://scripts/disk_projectile.gd";
		} else if (ResourceLoader::get_singleton()->exists("res://disk_projectile.gd")) {
			proj_path = "res://disk_projectile.gd";
		}

		if (!proj_path.is_empty()) {
			Ref<Script> script = ResourceLoader::get_singleton()->load(proj_path);
			if (script.is_valid()) {
				Area3D *disk = memnew(Area3D);
				disk->set_script(script);
				disk->set_position(spawn_pos);
				parent->add_child(disk);
				if (disk->has_method("setup_projectile")) {
					disk->call("setup_projectile", fire_dir, 24.0f, disk_damage, this);
				}
			}
		} else {
			if (parent) {
				TypedArray<Node> direct_children = parent->get_children();
				for (int i = 0; i < direct_children.size(); i++) {
					Node3D *node_3d = Object::cast_to<Node3D>(direct_children[i]);
					if (node_3d && node_3d != this && node_3d->has_method("take_damage")) {
						Vector3 to_t = node_3d->get_global_position() - spawn_pos;
						to_t.y = 0.0f;
						float dist = to_t.length();
						if (dist <= 18.0f && fire_dir.dot(to_t.normalized()) >= 0.7f) {
							node_3d->call("take_damage", static_cast<int>(disk_damage), fire_dir * 8.0f);
							break;
						}
					}
				}
			}
		}
	}

	emit_signal("secondary_fired", static_cast<int>(SECONDARY_DISK_LAUNCHER), spawn_pos, fire_dir, disk_damage);
}

void PlayerController::_bind_methods() {
	// XP & Leveling
	ClassDB::bind_method(D_METHOD("get_level"), &PlayerController::get_level);
	ClassDB::bind_method(D_METHOD("set_level", "level"), &PlayerController::set_level);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "level"), "set_level", "get_level");

	ClassDB::bind_method(D_METHOD("get_current_xp"), &PlayerController::get_current_xp);
	ClassDB::bind_method(D_METHOD("set_current_xp", "xp"), &PlayerController::set_current_xp);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "current_xp"), "set_current_xp", "get_current_xp");

	ClassDB::bind_method(D_METHOD("get_xp_to_level"), &PlayerController::get_xp_to_level);
	ClassDB::bind_method(D_METHOD("set_xp_to_level", "xp_to_level"), &PlayerController::set_xp_to_level);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "xp_to_level"), "set_xp_to_level", "get_xp_to_level");

	ClassDB::bind_method(D_METHOD("get_unspent_stat_points"), &PlayerController::get_unspent_stat_points);
	ClassDB::bind_method(D_METHOD("set_unspent_stat_points", "points"), &PlayerController::set_unspent_stat_points);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "unspent_stat_points"), "set_unspent_stat_points", "get_unspent_stat_points");

	ClassDB::bind_method(D_METHOD("gain_xp", "amount"), &PlayerController::gain_xp);
	ClassDB::bind_method(D_METHOD("spend_stat_point", "stat_name"), &PlayerController::spend_stat_point);

	// Movement & Equipment
	ClassDB::bind_method(D_METHOD("get_movement_locked"), &PlayerController::get_movement_locked);
	ClassDB::bind_method(D_METHOD("set_movement_locked", "locked"), &PlayerController::set_movement_locked);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "movement_locked"), "set_movement_locked", "get_movement_locked");

	ClassDB::bind_method(D_METHOD("get_is_skating"), &PlayerController::get_is_skating);
	ClassDB::bind_method(D_METHOD("set_is_skating", "skating"), &PlayerController::set_is_skating);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "is_skating"), "set_is_skating", "get_is_skating");

	ClassDB::bind_method(D_METHOD("get_skate_speed"), &PlayerController::get_skate_speed);
	ClassDB::bind_method(D_METHOD("set_skate_speed", "speed"), &PlayerController::set_skate_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "skate_speed"), "set_skate_speed", "get_skate_speed");

	ClassDB::bind_method(D_METHOD("get_is_equipped_skates"), &PlayerController::get_is_equipped_skates);
	ClassDB::bind_method(D_METHOD("set_is_equipped_skates", "equipped"), &PlayerController::set_is_equipped_skates);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "is_equipped_skates"), "set_is_equipped_skates", "get_is_equipped_skates");

	ClassDB::bind_method(D_METHOD("get_facing_direction"), &PlayerController::get_facing_direction);
	ClassDB::bind_method(D_METHOD("set_facing_direction", "direction"), &PlayerController::set_facing_direction);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "facing_direction"), "set_facing_direction", "get_facing_direction");

	ClassDB::bind_method(D_METHOD("get_rotation_speed"), &PlayerController::get_rotation_speed);
	ClassDB::bind_method(D_METHOD("set_rotation_speed", "speed"), &PlayerController::set_rotation_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "rotation_speed"), "set_rotation_speed", "get_rotation_speed");

	ClassDB::bind_method(D_METHOD("get_gravity"), &PlayerController::get_gravity);
	ClassDB::bind_method(D_METHOD("set_gravity", "gravity"), &PlayerController::set_gravity);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "gravity"), "set_gravity", "get_gravity");

	ClassDB::bind_method(D_METHOD("get_base_movement_speed"), &PlayerController::get_base_movement_speed);
	ClassDB::bind_method(D_METHOD("set_base_movement_speed", "speed"), &PlayerController::set_base_movement_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "base_movement_speed"), "set_base_movement_speed", "get_base_movement_speed");

	ClassDB::bind_method(D_METHOD("get_jump_velocity"), &PlayerController::get_jump_velocity);
	ClassDB::bind_method(D_METHOD("set_jump_velocity", "velocity"), &PlayerController::set_jump_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "jump_velocity"), "set_jump_velocity", "get_jump_velocity");

	ClassDB::bind_method(D_METHOD("get_movement_speed"), &PlayerController::get_movement_speed);

	// Visuals & Animation
	ClassDB::bind_method(D_METHOD("get_visuals"), &PlayerController::get_visuals);
	ClassDB::bind_method(D_METHOD("set_visuals", "visuals"), &PlayerController::set_visuals);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "visuals", PROPERTY_HINT_NODE_TYPE, "Node3D"), "set_visuals", "get_visuals");

	ClassDB::bind_method(D_METHOD("get_animation_player"), &PlayerController::get_animation_player);
	ClassDB::bind_method(D_METHOD("set_animation_player", "anim_player"), &PlayerController::set_animation_player);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "animation_player", PROPERTY_HINT_NODE_TYPE, "AnimationPlayer"), "set_animation_player", "get_animation_player");

	ClassDB::bind_method(D_METHOD("get_flame_particles"), &PlayerController::get_flame_particles);
	ClassDB::bind_method(D_METHOD("set_flame_particles", "particles"), &PlayerController::set_flame_particles);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "flame_particles", PROPERTY_HINT_NODE_TYPE, "GPUParticles3D"), "set_flame_particles", "get_flame_particles");

	// Stats
	ClassDB::bind_method(D_METHOD("get_strength"), &PlayerController::get_strength);
	ClassDB::bind_method(D_METHOD("set_strength", "strength"), &PlayerController::set_strength);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "strength"), "set_strength", "get_strength");

	ClassDB::bind_method(D_METHOD("get_agility"), &PlayerController::get_agility);
	ClassDB::bind_method(D_METHOD("set_agility", "agility"), &PlayerController::set_agility);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "agility"), "set_agility", "get_agility");

	ClassDB::bind_method(D_METHOD("get_vitality"), &PlayerController::get_vitality);
	ClassDB::bind_method(D_METHOD("set_vitality", "vitality"), &PlayerController::set_vitality);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "vitality"), "set_vitality", "get_vitality");

	ClassDB::bind_method(D_METHOD("get_vibe"), &PlayerController::get_vibe);
	ClassDB::bind_method(D_METHOD("set_vibe", "vibe"), &PlayerController::set_vibe);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "vibe"), "set_vibe", "get_vibe");

	ClassDB::bind_method(D_METHOD("get_effective_strength"), &PlayerController::get_effective_strength);
	ClassDB::bind_method(D_METHOD("get_effective_agility"), &PlayerController::get_effective_agility);
	ClassDB::bind_method(D_METHOD("get_effective_vitality"), &PlayerController::get_effective_vitality);
	ClassDB::bind_method(D_METHOD("get_effective_vibe"), &PlayerController::get_effective_vibe);

	ClassDB::bind_method(D_METHOD("get_current_health"), &PlayerController::get_current_health);
	ClassDB::bind_method(D_METHOD("set_current_health", "health"), &PlayerController::set_current_health);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_health"), "set_current_health", "get_current_health");

	ClassDB::bind_method(D_METHOD("get_max_health"), &PlayerController::get_max_health);
	ClassDB::bind_method(D_METHOD("set_max_health", "max_health"), &PlayerController::set_max_health);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_health"), "set_max_health", "get_max_health");

	// Combat
	ClassDB::bind_method(D_METHOD("get_is_attacking"), &PlayerController::get_is_attacking);
	ClassDB::bind_method(D_METHOD("set_is_attacking", "attacking"), &PlayerController::set_is_attacking);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "is_attacking"), "set_is_attacking", "get_is_attacking");

	ClassDB::bind_method(D_METHOD("attack"), &PlayerController::attack);
	ClassDB::bind_method(D_METHOD("get_effective_bat_damage"), &PlayerController::get_effective_bat_damage);
	ClassDB::bind_method(D_METHOD("take_damage", "amount", "knockback"), &PlayerController::take_damage, DEFVAL(Vector3()));
	ClassDB::bind_method(D_METHOD("heal", "amount"), &PlayerController::heal);

	// Walkman System
	ClassDB::bind_method(D_METHOD("get_current_tape"), &PlayerController::get_current_tape);
	ClassDB::bind_method(D_METHOD("set_current_tape", "tape"), &PlayerController::set_current_tape);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "current_tape"), "set_current_tape", "get_current_tape");

	ClassDB::bind_method(D_METHOD("switch_tape", "tape_name"), &PlayerController::switch_tape, DEFVAL(""));

	// Traversal State Machine & Grinding
	BIND_ENUM_CONSTANT(STATE_NORMAL);
	BIND_ENUM_CONSTANT(STATE_ATTACKING);
	BIND_ENUM_CONSTANT(STATE_GRINDING);
	BIND_ENUM_CONSTANT(STATE_AIRBORNE);
	BIND_ENUM_CONSTANT(STATE_EVADING);
	BIND_ENUM_CONSTANT(STATE_DEAD);

	// Player Death
	ClassDB::bind_method(D_METHOD("die"), &PlayerController::die);
	ClassDB::bind_method(D_METHOD("is_dead"), &PlayerController::is_dead);

	// Secondary Off-Hand Arsenal Enums
	BIND_ENUM_CONSTANT(SECONDARY_NONE);
	BIND_ENUM_CONSTANT(SECONDARY_SPRAY_FLAMETHROWER);
	BIND_ENUM_CONSTANT(SECONDARY_DISK_LAUNCHER);

	// Evade / Power-Slide
	ClassDB::bind_method(D_METHOD("try_evade"), &PlayerController::try_evade);
	ClassDB::bind_method(D_METHOD("start_evade", "direction"), &PlayerController::start_evade);
	ClassDB::bind_method(D_METHOD("get_is_invincible"), &PlayerController::get_is_invincible);
	ClassDB::bind_method(D_METHOD("set_is_invincible", "invincible"), &PlayerController::set_is_invincible);
	ClassDB::bind_method(D_METHOD("get_evade_cooldown"), &PlayerController::get_evade_cooldown);
	ClassDB::bind_method(D_METHOD("get_evade_speed"), &PlayerController::get_evade_speed);
	ClassDB::bind_method(D_METHOD("set_evade_speed", "speed"), &PlayerController::set_evade_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "evade_speed"), "set_evade_speed", "get_evade_speed");

	// Grind Dismount Slam
	ClassDB::bind_method(D_METHOD("execute_grind_slam", "direction"), &PlayerController::execute_grind_slam, DEFVAL(Vector3(0.0f, 0.0f, 0.0f)));

	// Secondary Arsenal
	ClassDB::bind_method(D_METHOD("fire_secondary"), &PlayerController::fire_secondary);
	ClassDB::bind_method(D_METHOD("fire_spray_flamethrower"), &PlayerController::fire_spray_flamethrower);
	ClassDB::bind_method(D_METHOD("fire_disk_launcher"), &PlayerController::fire_disk_launcher);
	ClassDB::bind_method(D_METHOD("cycle_secondary_weapon"), &PlayerController::cycle_secondary_weapon);
	ClassDB::bind_method(D_METHOD("get_secondary_weapon"), &PlayerController::get_secondary_weapon);
	ClassDB::bind_method(D_METHOD("set_secondary_weapon", "weapon"), &PlayerController::set_secondary_weapon);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "secondary_weapon"), "set_secondary_weapon", "get_secondary_weapon");
	ClassDB::bind_method(D_METHOD("get_secondary_weapon_name"), &PlayerController::get_secondary_weapon_name);
	ClassDB::bind_method(D_METHOD("set_secondary_weapon_name", "name"), &PlayerController::set_secondary_weapon_name);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "secondary_weapon_name"), "set_secondary_weapon_name", "get_secondary_weapon_name");

	// Cursor Aiming
	ClassDB::bind_method(D_METHOD("get_cursor_world_position"), &PlayerController::get_cursor_world_position_bind);
	ClassDB::bind_method(D_METHOD("orient_towards_point", "target_world_pos"), &PlayerController::orient_towards_point);
	ClassDB::bind_method(D_METHOD("orient_towards_cursor"), &PlayerController::orient_towards_cursor);

	ClassDB::bind_method(D_METHOD("get_attack_sensor"), &PlayerController::get_attack_sensor);
	ClassDB::bind_method(D_METHOD("set_attack_sensor", "sensor"), &PlayerController::set_attack_sensor);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "attack_sensor", PROPERTY_HINT_NODE_TYPE, "Area3D"), "set_attack_sensor", "get_attack_sensor");

	ClassDB::bind_method(D_METHOD("get_movement_state"), &PlayerController::get_movement_state);
	ClassDB::bind_method(D_METHOD("set_movement_state", "state"), &PlayerController::set_movement_state);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "movement_state"), "set_movement_state", "get_movement_state");

	ClassDB::bind_method(D_METHOD("is_grinding"), &PlayerController::is_grinding);
	ClassDB::bind_method(D_METHOD("try_start_grind", "path"), &PlayerController::try_start_grind);
	ClassDB::bind_method(D_METHOD("start_grind", "path"), &PlayerController::start_grind);
	ClassDB::bind_method(D_METHOD("dismount_grind", "exit_velocity"), &PlayerController::dismount_grind, DEFVAL(Vector3(0.0f, 0.0f, 0.0f)));
	ClassDB::bind_method(D_METHOD("_on_grind_area_entered", "area"), &PlayerController::_on_grind_area_entered);
	ClassDB::bind_method(D_METHOD("simulate_physics", "delta"), &PlayerController::simulate_physics);

	// Adrenaline System
	ClassDB::bind_method(D_METHOD("get_current_adrenaline"), &PlayerController::get_current_adrenaline);
	ClassDB::bind_method(D_METHOD("set_current_adrenaline", "adrenaline"), &PlayerController::set_current_adrenaline);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_adrenaline"), "set_current_adrenaline", "get_current_adrenaline");

	ClassDB::bind_method(D_METHOD("get_max_adrenaline"), &PlayerController::get_max_adrenaline);
	ClassDB::bind_method(D_METHOD("set_max_adrenaline", "max_adrenaline"), &PlayerController::set_max_adrenaline);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_adrenaline"), "set_max_adrenaline", "get_max_adrenaline");

	ClassDB::bind_method(D_METHOD("play_sfx", "name"), &PlayerController::play_sfx);

	// Signals
	ADD_SIGNAL(MethodInfo("player_hurt", PropertyInfo(Variant::FLOAT, "amount")));
	ADD_SIGNAL(MethodInfo("attack_executed", PropertyInfo(Variant::FLOAT, "damage")));
	ADD_SIGNAL(MethodInfo("health_changed", PropertyInfo(Variant::FLOAT, "current_health"), PropertyInfo(Variant::FLOAT, "max_health")));
	ADD_SIGNAL(MethodInfo("stats_changed"));
	ADD_SIGNAL(MethodInfo("tape_switched", PropertyInfo(Variant::STRING, "tape_name"), PropertyInfo(Variant::STRING, "buff_desc")));
	ADD_SIGNAL(MethodInfo("skates_toggled", PropertyInfo(Variant::BOOL, "is_equipped")));
	ADD_SIGNAL(MethodInfo("xp_changed", PropertyInfo(Variant::INT, "current_xp"), PropertyInfo(Variant::INT, "xp_to_level"), PropertyInfo(Variant::INT, "level")));
	ADD_SIGNAL(MethodInfo("leveled_up", PropertyInfo(Variant::INT, "new_level"), PropertyInfo(Variant::INT, "unspent_points")));
	ADD_SIGNAL(MethodInfo("stat_point_spent", PropertyInfo(Variant::STRING, "stat_name"), PropertyInfo(Variant::INT, "remaining_points")));
	ADD_SIGNAL(MethodInfo("adrenaline_changed", PropertyInfo(Variant::FLOAT, "current"), PropertyInfo(Variant::FLOAT, "max")));
	ADD_SIGNAL(MethodInfo("grind_started", PropertyInfo(Variant::OBJECT, "rail_path", PROPERTY_HINT_NODE_TYPE, "Path3D"), PropertyInfo(Variant::FLOAT, "entry_speed")));
	ADD_SIGNAL(MethodInfo("grind_ended", PropertyInfo(Variant::VECTOR3, "exit_velocity")));
	ADD_SIGNAL(MethodInfo("grind_slam_executed", PropertyInfo(Variant::VECTOR3, "position"), PropertyInfo(Variant::VECTOR3, "direction"), PropertyInfo(Variant::FLOAT, "damage")));
	ADD_SIGNAL(MethodInfo("evade_started", PropertyInfo(Variant::VECTOR3, "direction"), PropertyInfo(Variant::FLOAT, "speed")));
	ADD_SIGNAL(MethodInfo("evade_ended"));
	ADD_SIGNAL(MethodInfo("secondary_fired", PropertyInfo(Variant::INT, "weapon_type"), PropertyInfo(Variant::VECTOR3, "position"), PropertyInfo(Variant::VECTOR3, "direction"), PropertyInfo(Variant::FLOAT, "damage")));
	ADD_SIGNAL(MethodInfo("secondary_weapon_switched", PropertyInfo(Variant::INT, "weapon_type"), PropertyInfo(Variant::STRING, "weapon_name")));
	ADD_SIGNAL(MethodInfo("player_died"));
}
