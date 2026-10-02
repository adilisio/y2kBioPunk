#ifndef MENU_CONTROLLER_HPP
#define MENU_CONTROLLER_HPP

#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class MenuController : public Control {
	GDCLASS(MenuController, Control);

private:
	String target_game_scene = "res://main.tscn";

protected:
	static void _bind_methods();

public:
	MenuController();
	~MenuController();

	void _ready() override;

	// Button Callbacks
	void on_new_game_pressed();
	void on_load_game_pressed();
	void on_options_pressed();
	void on_credits_pressed();
	void on_exit_pressed();

	// Target Scene Property
	String get_target_game_scene() const;
	void set_target_game_scene(const String &p_path);
};

} // namespace godot

#endif // MENU_CONTROLLER_HPP
