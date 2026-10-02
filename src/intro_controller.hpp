#ifndef INTRO_CONTROLLER_HPP
#define INTRO_CONTROLLER_HPP

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/video_stream_player.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class IntroController : public Control {
	GDCLASS(IntroController, Control);

private:
	bool has_transitioned = false;
	float blink_timer = 0.0f;
	Label *skip_label = nullptr;
	String target_menu_scene = "res://main_menu.tscn";

protected:
	static void _bind_methods();

public:
	IntroController();
	~IntroController();

	void _ready() override;
	void _process(double p_delta) override;
	void _input(const Ref<InputEvent> &p_event) override;
	void _gui_input(const Ref<InputEvent> &p_event) override;

	void _on_video_finished();
	void transition_to_main_menu();

	String get_target_menu_scene() const;
	void set_target_menu_scene(const String &p_scene);
};

} // namespace godot

#endif // INTRO_CONTROLLER_HPP
