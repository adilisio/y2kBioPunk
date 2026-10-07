extends CanvasLayer

# Pager Box UI
@onready var pager_box: PanelContainer = $HUDOverlay/PagerBox
var hp_bar: ProgressBar = null
var adrenaline_bar: ProgressBar = null
var hp_label: Control = null
var xp_bar: ProgressBar = null
var level_xp_label: Control = null
var active_tape_label: Control = null
var stats_label: Control = null
var equip_label: Control = null
var control_tip: Control = null
var sheet_prompt_label: Control = null

# Action Bar UI
var action_bar: HBoxContainer = null
var action_tape_icon: ColorRect = null
var action_primary_icon: ColorRect = null
var action_secondary_icon: ColorRect = null
var action_tape_label: Label = null
var action_secondary_label: Label = null

# Walkman UI
@onready var walkman_box: PanelContainer = $HUDOverlay/WalkmanBox
@onready var tape_header: Label = $HUDOverlay/WalkmanBox/VBox/TapeHeader
@onready var tape_buff_label: Label = $HUDOverlay/WalkmanBox/VBox/TapeBuffLabel
@onready var eq_container: HBoxContainer = $HUDOverlay/WalkmanBox/VBox/TapeDeckHBox/EqualizerHBox
@onready var reel_l: Label = $HUDOverlay/WalkmanBox/VBox/TapeDeckHBox/ReelLeft
@onready var reel_r: Label = $HUDOverlay/WalkmanBox/VBox/TapeDeckHBox/ReelRight

# Character Sheet Modal
@onready var character_sheet: PanelContainer = $HUDOverlay/CharacterSheet
@onready var sheet_level_xp_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/LevelXPLabel
@onready var sheet_points_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/PointsLabel
@onready var sheet_str_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/StrRow/Label
@onready var sheet_btn_str: Button = $HUDOverlay/CharacterSheet/Margin/VBox/StrRow/BtnAddStr
@onready var sheet_agi_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/AgiRow/Label
@onready var sheet_btn_agi: Button = $HUDOverlay/CharacterSheet/Margin/VBox/AgiRow/BtnAddAgi
@onready var sheet_vit_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/VitRow/Label
@onready var sheet_btn_vit: Button = $HUDOverlay/CharacterSheet/Margin/VBox/VitRow/BtnAddVit
@onready var sheet_vibe_label: Label = $HUDOverlay/CharacterSheet/Margin/VBox/VibeRow/Label
@onready var sheet_btn_vibe: Button = $HUDOverlay/CharacterSheet/Margin/VBox/VibeRow/BtnAddVibe
@onready var sheet_btn_close: Button = $HUDOverlay/CharacterSheet/Margin/VBox/BtnCloseSheet

# Dialogue Box Modal
@onready var dialogue_box: PanelContainer = $HUDOverlay/DialogueBox
@onready var speaker_label: Label = $HUDOverlay/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_body_label: Label = $HUDOverlay/DialogueBox/Margin/VBox/BodyLabel
@onready var btn_standard_choice: Button = $HUDOverlay/DialogueBox/Margin/VBox/ChoicesVBox/BtnStandardChoice
@onready var btn_vibe_choice: Button = $HUDOverlay/DialogueBox/Margin/VBox/ChoicesVBox/BtnVibeChoice
@onready var btn_exit_choice: Button = $HUDOverlay/DialogueBox/Margin/VBox/ChoicesVBox/BtnExitChoice

# Boss HP Bar UI
var boss_container: PanelContainer = null
var boss_hp_bar: ProgressBar = null
var boss_title_label: RichTextLabel = null
var boss_hp_num_label: Label = null
var active_boss: Node = null

var player: Node = null
var soldier_npc: Area2D = null
var anim_time: float = 0.0
var reel_frames = ["|", "/", "-", "\\"]
var reel_step: int = 0

func _build_boss_bar() -> void:
	if boss_container:
		return
	var overlay = get_node_or_null("HUDOverlay")
	if not overlay:
		return

	boss_container = PanelContainer.new()
	boss_container.name = "BossBarContainer"
	boss_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_container.anchor_left = 0.5
	boss_container.anchor_right = 0.5
	boss_container.anchor_top = 0.0
	boss_container.anchor_bottom = 0.0
	boss_container.offset_left = -300.0
	boss_container.offset_right = 300.0
	boss_container.offset_top = 18.0
	boss_container.offset_bottom = 85.0
	boss_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_container.visible = false

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.12, 0.9)
	panel_style.border_color = Color(1.0, 0.1, 0.35, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	boss_container.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(boss_container)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	boss_container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	boss_title_label = RichTextLabel.new()
	boss_title_label.name = "BossTitleLabel"
	boss_title_label.bbcode_enabled = true
	boss_title_label.fit_content = true
	boss_title_label.scroll_active = false
	boss_title_label.text = "[center][b][color=#ff0055]⚠ DIAL-UP QUEEN // SERVER MATRIARCH[/color][/b]  [color=#00ffcc][PHASE 1][/color][/center]"
	vbox.add_child(boss_title_label)

	var bar_box = HBoxContainer.new()
	bar_box.add_theme_constant_override("separation", 8)
	vbox.add_child(bar_box)

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.name = "BossHPBar"
	boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_hp_bar.custom_minimum_size = Vector2(0, 16)
	boss_hp_bar.max_value = 600
	boss_hp_bar.value = 600
	boss_hp_bar.show_percentage = false

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.15, 0.3, 1.0)
	fill_style.set_corner_radius_all(2)
	boss_hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.18, 0.22, 1.0)
	bg_style.set_corner_radius_all(2)
	boss_hp_bar.add_theme_stylebox_override("background", bg_style)
	bar_box.add_child(boss_hp_bar)

	boss_hp_num_label = Label.new()
	boss_hp_num_label.name = "BossHPNum"
	boss_hp_num_label.text = "600 / 600"
	boss_hp_num_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	bar_box.add_child(boss_hp_num_label)

func setup_boss_bar(boss_node: Node) -> void:
	active_boss = boss_node
	if not boss_container:
		_build_boss_bar()
	if not boss_container:
		return
	boss_container.visible = true
	if boss_node.has_signal("boss_health_changed"):
		if not boss_node.is_connected("boss_health_changed", Callable(self, "_on_boss_health_changed")):
			boss_node.connect("boss_health_changed", Callable(self, "_on_boss_health_changed"))
	if boss_node.has_signal("boss_defeated"):
		if not boss_node.is_connected("boss_defeated", Callable(self, "_on_boss_defeated")):
			boss_node.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	var max_hp = boss_node.get("max_health") if boss_node.get("max_health") != null else 600
	var cur_hp = boss_node.get("current_health") if boss_node.get("current_health") != null else max_hp
	var phase = boss_node.get("current_phase") if boss_node.get("current_phase") != null else 1
	_on_boss_health_changed(cur_hp, max_hp, phase)

func _on_boss_health_changed(cur_hp: int, max_hp: int, phase: int) -> void:
	if not boss_container:
		_build_boss_bar()
	if not boss_container:
		return
	boss_container.visible = true
	if boss_hp_bar:
		boss_hp_bar.max_value = float(max_hp)
		boss_hp_bar.value = float(cur_hp)
	if boss_title_label:
		var phase_col = "#00ffcc" if phase == 1 else ("#ffaa00" if phase == 2 else "#ff0055")
		boss_title_label.text = "[center][b][color=#ff0055]⚠ DIAL-UP QUEEN // SERVER MATRIARCH[/color][/b]  [color=%s][PHASE %d][/color][/center]" % [phase_col, phase]
	if boss_hp_num_label:
		boss_hp_num_label.text = "%d / %d" % [max(0, cur_hp), max_hp]

func _on_boss_defeated() -> void:
	if boss_title_label:
		boss_title_label.text = "[center][b][color=#39ff14]✔ DIAL-UP QUEEN DEFEATED // 56K CARRIER SIGNAL PURGED[/color][/b][/center]"
	if boss_hp_bar:
		boss_hp_bar.value = 0.0
	if boss_hp_num_label:
		boss_hp_num_label.text = "TERMINATED"
	var t = create_tween()
	t.tween_interval(4.0)
	t.tween_callback(func():
		if boss_container:
			boss_container.visible = false
	)
	# Slice ending: record completion, show the victory card, return to the menu.
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("mark_slice_complete"):
		sm.call("mark_slice_complete")
	if player and player.has_method("set_movement_locked"):
		player.call("set_movement_locked", true)
	show_victory_card()
	var back = create_tween()
	back.tween_interval(6.0)
	back.tween_callback(func():
		if get_tree():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

func _find_pager_node(node_name: String) -> Control:
	var n = get_node_or_null("HUDOverlay/PagerBox/Margin/VBox/" + node_name)
	if not n:
		n = get_node_or_null("HUDOverlay/PagerBox/VBox/" + node_name)
	return n as Control

func _init_pager_nodes() -> void:
	# Health Bar & Label (re-anchored to bottom-center)
	hp_bar = get_node_or_null("HUDOverlay/HealthContainer/HPBar") as ProgressBar
	if not hp_bar:
		hp_bar = get_node_or_null("HUDOverlay/HPBar") as ProgressBar
	if not hp_bar:
		hp_bar = _find_pager_node("HPBar") as ProgressBar

	hp_label = get_node_or_null("HUDOverlay/HealthContainer/HPLabel")
	if not hp_label:
		hp_label = get_node_or_null("HUDOverlay/HPLabel")
	if not hp_label:
		hp_label = _find_pager_node("HPLabel")
	
	if hp_label:
		hp_label.add_theme_font_size_override("normal_font_size", 24)
		hp_label.add_theme_font_size_override("bold_font_size", 24)
		hp_label.add_theme_font_size_override("italics_font_size", 24)
		hp_label.add_theme_font_size_override("bold_italics_font_size", 24)
	
	if hp_bar and not adrenaline_bar:
		adrenaline_bar = ProgressBar.new()
		adrenaline_bar.name = "AdrenalineBar"
		adrenaline_bar.show_percentage = false
		adrenaline_bar.custom_minimum_size = Vector2(0, 4)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#ff8800")
		adrenaline_bar.add_theme_stylebox_override("fill", sb)
		var sbb = StyleBoxFlat.new()
		sbb.bg_color = Color("#221100")
		adrenaline_bar.add_theme_stylebox_override("background", sbb)
		hp_bar.get_parent().add_child(adrenaline_bar)

	xp_bar = _find_pager_node("XPBar") as ProgressBar
	level_xp_label = _find_pager_node("LevelXPLabel")
	active_tape_label = _find_pager_node("ActiveTapeLabel")
	
	for lbl in [level_xp_label, active_tape_label]:
		if lbl and lbl is RichTextLabel:
			lbl.add_theme_font_size_override("normal_font_size", 16)
			lbl.add_theme_font_size_override("bold_font_size", 16)
			lbl.add_theme_font_size_override("italics_font_size", 16)
			lbl.add_theme_font_size_override("bold_italics_font_size", 16)

	stats_label = _find_pager_node("StatsLabel")
	equip_label = _find_pager_node("EquipLabel")
	control_tip = _find_pager_node("ControlTip")
	sheet_prompt_label = _find_pager_node("SheetPromptLabel")

	# Action Bar (anchored bottom-right)
	action_bar = get_node_or_null("HUDOverlay/ActionBar") as HBoxContainer
	if action_bar:
		action_tape_icon = action_bar.find_child("TapeIcon", true, false) as ColorRect
		action_primary_icon = action_bar.find_child("PrimaryIcon", true, false) as ColorRect
		action_secondary_icon = action_bar.find_child("SecondaryIcon", true, false) as ColorRect
		action_tape_label = action_bar.find_child("TapeKey", true, false) as Label
		action_secondary_label = action_bar.find_child("SecondaryKey", true, false) as Label

	if pager_box:
		# Diegetic Retro Polish: StyleBoxFlat with thick bright neon-green border, dark semi-transparent bg
		var lcd_style = StyleBoxFlat.new()
		lcd_style.bg_color = Color(0.02, 0.08, 0.04, 0.88)
		lcd_style.border_color = Color(0.0, 1.0, 0.35, 1.0)
		lcd_style.set_border_width_all(3)
		lcd_style.set_corner_radius_all(4)
		lcd_style.content_margin_left = 14
		lcd_style.content_margin_right = 14
		lcd_style.content_margin_top = 12
		lcd_style.content_margin_bottom = 12
		pager_box.add_theme_stylebox_override("panel", lcd_style)

		pager_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		pager_box.grow_vertical = Control.GROW_DIRECTION_END
		pager_box.anchor_bottom = 0.0
		pager_box.custom_minimum_size = Vector2(0, 0)
		var vbox = pager_box.find_child("VBox", true, false)
		if vbox:
			vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			vbox.custom_minimum_size.y = 0
			vbox.add_theme_constant_override("separation", 12)
			for c in vbox.get_children():
				if c is RichTextLabel:
					c.autowrap_mode = TextServer.AUTOWRAP_OFF
					c.fit_content = true
					c.scroll_active = false
					c.custom_minimum_size.y = 0
		pager_box.reset_size()

func _ready() -> void:
	add_to_group("hud")
	_init_pager_nodes()
	_build_boss_bar()
	var existing_boss = get_tree().get_first_node_in_group("boss") if get_tree() else null
	if existing_boss:
		setup_boss_bar(existing_boss)
	player = get_node_or_null("../Player")
	if player:
		if player.has_signal("health_changed"): player.health_changed.connect(func(a,b): _refresh_hud())
		if player.has_signal("stats_changed"): player.stats_changed.connect(_refresh_hud)
		if player.has_signal("xp_changed"): player.xp_changed.connect(func(a,b,c): _refresh_hud())
		if player.has_signal("leveled_up"): player.leveled_up.connect(_on_leveled_up)
		if player.has_signal("skates_toggled"): player.skates_toggled.connect(_on_skates_toggled)
		if player.has_signal("tape_switched"): player.tape_switched.connect(_on_tape_switched)
		if player.has_signal("adrenaline_changed"): player.adrenaline_changed.connect(_on_adrenaline_changed)
		if player.has_signal("secondary_weapon_switched"): player.secondary_weapon_switched.connect(_on_secondary_weapon_switched)
		_refresh_hud()
		var sm = get_node_or_null("/root/SaveManager")
		if not sm:
			var sm_script = load("res://scripts/save_manager.gd")
			if sm_script:
				sm = sm_script.new()
				get_tree().root.add_child(sm)
		if sm:
			var do_load = false
			if sm.get("pending_load"):
				do_load = true
				sm.set("pending_load", false)
			elif sm.get("respawn_pending"):
				do_load = true
				sm.set("respawn_pending", false)
				
			if do_load and sm.has_method("has_save_data") and sm.call("has_save_data"):
				sm.call("apply_save_data_to_player", player)

		if player.has_signal("health_changed"):
			player.connect("health_changed", Callable(self, "_on_health_changed"))
		if player.has_signal("stats_changed"):
			player.connect("stats_changed", Callable(self, "_on_stats_changed"))
		if player.has_signal("xp_changed"):
			player.connect("xp_changed", Callable(self, "_on_xp_changed"))
		if player.has_signal("stat_point_spent"):
			player.connect("stat_point_spent", Callable(self, "_on_stat_point_spent"))
		if player.has_signal("player_died"):
			player.connect("player_died", Callable(self, "_on_player_died"))

	soldier_npc = get_node_or_null("../StrandedSoldierNPC") as Area2D
	if soldier_npc:
		if soldier_npc.has_signal("dialogue_opened"):
			soldier_npc.connect("dialogue_opened", Callable(self, "_on_dialogue_opened"))

	# Character Sheet Buttons
	if sheet_btn_str:
		sheet_btn_str.pressed.connect(Callable(self, "_on_spend_stat").bind("strength"))
	if sheet_btn_agi:
		sheet_btn_agi.pressed.connect(Callable(self, "_on_spend_stat").bind("agility"))
	if sheet_btn_vit:
		sheet_btn_vit.pressed.connect(Callable(self, "_on_spend_stat").bind("vitality"))
	if sheet_btn_vibe:
		sheet_btn_vibe.pressed.connect(Callable(self, "_on_spend_stat").bind("vibe"))
	if sheet_btn_close:
		sheet_btn_close.pressed.connect(Callable(self, "_on_close_sheet_pressed"))

	# Dialogue Box Buttons
	if btn_standard_choice:
		btn_standard_choice.pressed.connect(Callable(self, "_on_standard_choice_pressed"))
	if btn_vibe_choice:
		btn_vibe_choice.pressed.connect(Callable(self, "_on_vibe_choice_pressed"))
	if btn_exit_choice:
		btn_exit_choice.pressed.connect(Callable(self, "_on_exit_dialogue_pressed"))

	_setup_window_mode()
	_setup_ui_layout()

	_refresh_hud()
	_refresh_character_sheet()

func _setup_window_mode() -> void:
	# Configure game to boot in Windowed Fullscreen (Borderless Fullscreen)
	# In Godot 4, WINDOW_MODE_FULLSCREEN is borderless windowed fullscreen.
	if not Engine.is_editor_hint():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _setup_ui_layout() -> void:
	# 1. Top-Left Pager Alignment (Scaled down 30% with tight 10px padding)
	# Default pivot is (0, 0), so scaling by 0.7 cleanly keeps it anchored flush top-left.
	if pager_box:
		pager_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		pager_box.anchor_left = 0.0
		pager_box.anchor_top = 0.0
		pager_box.anchor_right = 0.0
		pager_box.anchor_bottom = 0.0
		pager_box.offset_left = 10.0
		pager_box.offset_top = 10.0
		pager_box.grow_horizontal = Control.GROW_DIRECTION_END
		pager_box.grow_vertical = Control.GROW_DIRECTION_END
		pager_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		pager_box.custom_minimum_size = Vector2(0, 0)
		pager_box.reset_size()
		pager_box.offset_right = 10.0 + pager_box.size.x
		pager_box.offset_bottom = 10.0 + pager_box.size.y
		pager_box.pivot_offset = Vector2.ZERO
		pager_box.scale = Vector2(1.0, 1.0)

	# 2. Bottom-Center Health Bar Alignment (doubled thickness, centered)
	var health_container = get_node_or_null("HUDOverlay/HealthContainer")
	if health_container:
		health_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		health_container.anchor_left = 0.5
		health_container.anchor_top = 1.0
		health_container.anchor_right = 0.5
		health_container.anchor_bottom = 1.0
		health_container.offset_left = -220.0
		health_container.offset_right = 220.0
		health_container.offset_top = -60.0
		health_container.offset_bottom = -24.0
		health_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		health_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	elif hp_bar and hp_bar.get_parent() == get_node_or_null("HUDOverlay"):
		hp_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		hp_bar.anchor_left = 0.5
		hp_bar.anchor_top = 1.0
		hp_bar.anchor_right = 0.5
		hp_bar.anchor_bottom = 1.0
		hp_bar.offset_left = -220.0
		hp_bar.offset_right = 220.0
		hp_bar.offset_top = -60.0
		hp_bar.offset_bottom = -24.0
		hp_bar.custom_minimum_size.y = 36.0
		hp_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		hp_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN

	if hp_bar:
		hp_bar.custom_minimum_size.y = 36.0
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.0, 0.95, 0.4, 1.0)
		fill_style.set_corner_radius_all(4)
		fill_style.border_width_left = 1
		fill_style.border_width_top = 1
		fill_style.border_width_right = 1
		fill_style.border_width_bottom = 1
		fill_style.border_color = Color(0.3, 1.0, 0.6, 0.9)
		hp_bar.add_theme_stylebox_override("fill", fill_style)

		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.05, 0.08, 0.06, 0.92)
		bg_style.border_color = Color(0.0, 0.6, 0.25, 0.8)
		bg_style.set_border_width_all(2)
		bg_style.set_corner_radius_all(4)
		hp_bar.add_theme_stylebox_override("background", bg_style)

	# 3. Bottom-Right Walkman Alignment (Scaled down 30% with tight 10px padding)
	# Crucial: Setting pivot_offset = walkman_box.size before applying scale = Vector2(0.7, 0.7)
	# prevents the node from shrinking up-and-left away from the corner, keeping it flush bottom-right.
	if walkman_box:
		walkman_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		walkman_box.anchor_left = 1.0
		walkman_box.anchor_top = 1.0
		walkman_box.anchor_right = 1.0
		walkman_box.anchor_bottom = 1.0
		walkman_box.offset_right = -10.0
		walkman_box.offset_bottom = -10.0
		walkman_box.offset_left = walkman_box.offset_right - (walkman_box.size.x if walkman_box.size.x > 0 else 436.0)
		walkman_box.offset_top = walkman_box.offset_bottom - (walkman_box.size.y if walkman_box.size.y > 0 else 116.0)
		walkman_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		walkman_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
		walkman_box.pivot_offset = walkman_box.size
		walkman_box.scale = Vector2(1.0, 1.0)

	# 4. Bottom-Right Action Bar Alignment (anchored bottom-right, neatly stacked)
	if action_bar:
		action_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		action_bar.anchor_left = 1.0
		action_bar.anchor_top = 1.0
		action_bar.anchor_right = 1.0
		action_bar.anchor_bottom = 1.0
		action_bar.offset_right = -10.0
		action_bar.offset_bottom = -105.0
		action_bar.offset_left = -210.0
		action_bar.offset_top = -170.0
		action_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		action_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _unhandled_input(event: InputEvent) -> void:
	# Toggle Character Sheet with 'C'
	if event.is_action_pressed("toggle_character_sheet") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C):
		toggle_character_sheet()

func _process(delta: float) -> void:
	anim_time += delta

	# Poll player status
	if player:
		if action_primary_icon and player.has_method("get_evade_cooldown"):
			var cd = player.call("get_evade_cooldown")
			action_primary_icon.color.a = 0.2 + 0.8 * (1.0 if cd <= 0.0 else 0.0)
		if action_secondary_icon and player.has_method("get_secondary_cooldown"):
			var cd = player.call("get_secondary_cooldown")
			action_secondary_icon.color.a = 0.2 + 0.8 * (1.0 if cd <= 0.0 else 0.0)
		_process_page_message(delta)

	# 1. Pulsing Equalizer Bars
	if eq_container:
		var bars = eq_container.get_children()
		for i in range(bars.size()):
			var bar = bars[i] as ColorRect
			if bar:
				var wave1 = sin(anim_time * 9.0 + i * 1.3)
				var wave2 = cos(anim_time * 5.2 + i * 0.8)
				var h = 8.0 + 28.0 * clamp(abs(wave1 * 0.6 + wave2 * 0.4), 0.05, 1.0)
				bar.custom_minimum_size.y = h

	# 2. Spinning Cassette Reels
	var new_step = int(anim_time * 6.0)
	if new_step != reel_step:
		reel_step = new_step
		var char_frame = reel_frames[reel_step % reel_frames.size()]
		if reel_l:
			reel_l.text = "( " + char_frame + " )"
		if reel_r:
			reel_r.text = "( " + char_frame + " )"

# --- HUD Callbacks ---

func _on_health_changed(cur_hp: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = cur_hp
	if hp_label:
		var cur_i = int(cur_hp)
		var max_i = int(max_hp)
		if cur_hp <= 0.0:
			hp_label.text = "[center][b]HEALTH:[/b] [color=#ff2233][b]0 / %d HP [FLATLINE][/b][/color][/center]" % max_i
			return
		var hp_color = "#00ff66"
		if cur_hp <= max_hp * 0.25:
			hp_color = "#ff2233"
		elif cur_hp <= max_hp * 0.5:
			hp_color = "#ffcc00"
		hp_label.text = "[center][b]HEALTH:[/b] [color=%s][b]%d[/b][/color] / [color=#00cc55]%d[/color] HP[/center]" % [hp_color, cur_i, max_i]

func _on_player_died() -> void:
	if hp_label:
		hp_label.text = "[center][b][color=#ff2233]⚠ CRITICAL BIO-FAILURE // FLATLINE[/color][/b][/center]"
	if control_tip:
		control_tip.text = "[color=#ff4444][b]NEURAL LINK LOST. RESTORING CLONE FROM BIO-STABILIZER...[/b][/color]"
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.set("respawn_pending", true)

func _on_xp_changed(cur_xp: int, req_xp: int, lvl: int) -> void:
	if xp_bar:
		xp_bar.max_value = float(req_xp)
		xp_bar.value = float(cur_xp)
	var pts = player.call("get_unspent_stat_points") if player and player.has_method("get_unspent_stat_points") else 0
	if level_xp_label:
		level_xp_label.text = "[b]LEVEL[/b] [color=#ffdd44][b]%d[/b][/color]  |  [b]XP:[/b] [color=#66e0ff]%d[/color] / [color=#44aacc]%d[/color]  |  [b]STAT PTS:[/b] [color=#ffdd44][b]%d[/b][/color] ([color=#ffaa00][b][C][/b][/color] Stats)" % [lvl, cur_xp, req_xp, pts]
	_refresh_character_sheet()

func _on_leveled_up(new_lvl: int, unspent_pts: int) -> void:
	page_message("[color=#ffff00][b]LEVEL %d // +%d STAT PT [C][/b][/color]" % [new_lvl, unspent_pts])
	_refresh_hud()
	_refresh_character_sheet()

func show_message(msg: String) -> void:
	if control_tip:
		control_tip.text = msg

func show_victory_card() -> void:
	var lvl = player.call("get_level") if player and player.has_method("get_level") else 1
	var vic = PanelContainer.new()
	vic.set_anchors_preset(Control.PRESET_CENTER)
	vic.anchor_left = 0.5
	vic.anchor_top = 0.5
	vic.anchor_right = 0.5
	vic.anchor_bottom = 0.5
	vic.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vic.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.08, 0.04, 0.95)
	style.border_color = Color(0.2, 1.0, 0.2, 1.0)
	style.set_border_width_all(4)
	vic.add_theme_stylebox_override("panel", style)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text = "[center][b][color=#39ff14]SIGNAL RESTORED // MALL QUARANTINE LIFTED[/color][/b]\n\n[color=#ffffff]LEVEL: %d\nSTATUS: SURVIVED[/color][/center]" % lvl
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	
	margin.add_child(lbl)
	vic.add_child(margin)
	
	var overlay = get_node_or_null("HUDOverlay")
	if overlay:
		overlay.add_child(vic)

func _on_stat_point_spent(_stat_name: String, _remaining: int) -> void:
	_refresh_hud()
	_refresh_character_sheet()

func _on_stats_changed() -> void:
	_refresh_hud()
	_refresh_character_sheet()

func _on_tape_switched(tape_name: String, buff_desc: String) -> void:
	if tape_header:
		tape_header.text = "WALKMAN // TRACK: '%s'" % tape_name
	if tape_buff_label:
		tape_buff_label.text = "BUFF: %s" % buff_desc
	_refresh_hud()
	_refresh_character_sheet()

func _on_skates_toggled(is_equipped: bool) -> void:
	if equip_label:
		if is_equipped:
			equip_label.text = "MODE: [color=#00ffcc][b][ROLLER SKATES ON][/b][/color] (+55% Speed & Grind) ([color=#ffdd44][b][K][/b][/color]: Walk)"
		else:
			equip_label.text = "MODE: [color=#ffaa44][b][8-WAY BIO WALK][/b][/color] ([color=#ffdd44][b][K][/b][/color]: Skates)"

# --- Character Sheet Logic ---

func toggle_character_sheet() -> void:
	if not character_sheet:
		return
	character_sheet.visible = not character_sheet.visible
	if player and player.has_method("set_movement_locked"):
		player.call("set_movement_locked", character_sheet.visible)
	if character_sheet.visible:
		_refresh_character_sheet()

func _on_close_sheet_pressed() -> void:
	if character_sheet:
		character_sheet.visible = false
	if player and player.has_method("set_movement_locked"):
		player.call("set_movement_locked", false)

func _on_spend_stat(stat_name: String) -> void:
	if not player:
		return
	if player.has_method("spend_stat_point"):
		var success = player.call("spend_stat_point", stat_name)
		if success:
			_refresh_hud()
			_refresh_character_sheet()

func _refresh_character_sheet() -> void:
	if not character_sheet or not player:
		return

	var lvl = player.call("get_level") if player.has_method("get_level") else 1
	var cur_xp = player.call("get_current_xp") if player.has_method("get_current_xp") else 0
	var req_xp = player.call("get_xp_to_level") if player.has_method("get_xp_to_level") else 50
	var unspent = player.call("get_unspent_stat_points") if player.has_method("get_unspent_stat_points") else 0

	if sheet_level_xp_label:
		sheet_level_xp_label.text = "LEVEL: %d  |  XP: %d / %d" % [lvl, cur_xp, req_xp]
	if sheet_points_label:
		sheet_points_label.text = "UNSPENT STAT POINTS: %d" % unspent
		sheet_points_label.modulate = Color(1.0, 0.9, 0.2) if unspent > 0 else Color(0.6, 0.6, 0.6)

	var can_spend = unspent > 0
	if sheet_btn_str: sheet_btn_str.disabled = not can_spend
	if sheet_btn_agi: sheet_btn_agi.disabled = not can_spend
	if sheet_btn_vit: sheet_btn_vit.disabled = not can_spend
	if sheet_btn_vibe: sheet_btn_vibe.disabled = not can_spend

	var base_str = player.call("get_strength") if player.has_method("get_strength") else 10
	var eff_str = player.call("get_effective_strength") if player.has_method("get_effective_strength") else 10
	var bat_dmg = 15.0 + eff_str * 2.5
	if sheet_str_label:
		sheet_str_label.text = "STRENGTH: %d (Effective: %d | Bat DMG: %.1f)" % [base_str, eff_str, bat_dmg]

	var base_agi = player.call("get_agility") if player.has_method("get_agility") else 10
	var eff_agi = player.call("get_effective_agility") if player.has_method("get_effective_agility") else 10
	var speed = player.call("get_movement_speed") if player.has_method("get_movement_speed") else 200.0
	if sheet_agi_label:
		sheet_agi_label.text = "AGILITY: %d (Effective: %d | Speed: %.0f)" % [base_agi, eff_agi, speed]

	var base_vit = player.call("get_vitality") if player.has_method("get_vitality") else 10
	var eff_vit = player.call("get_effective_vitality") if player.has_method("get_effective_vitality") else 10
	var max_hp = player.call("get_max_health") if player.has_method("get_max_health") else 100.0
	if sheet_vit_label:
		sheet_vit_label.text = "VITALITY: %d (Effective: %d | Max HP: %.0f)" % [base_vit, eff_vit, max_hp]

	var base_vibe = player.call("get_vibe") if player.has_method("get_vibe") else 10
	var eff_vibe = player.call("get_effective_vibe") if player.has_method("get_effective_vibe") else 10
	if sheet_vibe_label:
		sheet_vibe_label.text = "VIBE: %d (Effective: %d | Persuasion DC: 15)" % [base_vibe, eff_vibe]

# --- Dialogue System Logic ---

func _on_dialogue_opened(npc: Object) -> void:
	if not dialogue_box:
		return
	dialogue_box.visible = true

	var npc_name = "STRANDED SOLDIER"
	if npc and npc.has_method("get_npc_name"):
		npc_name = npc.call("get_npc_name").to_upper()
	if speaker_label:
		speaker_label.text = "RADIO COMM // %s" % npc_name

	var already_persuaded = false
	if npc and npc.has_method("get_already_persuaded"):
		already_persuaded = npc.call("get_already_persuaded")

	if already_persuaded:
		if dialogue_body_label:
			dialogue_body_label.text = "Sgt. Miller nods with calm relief:\n'Good to see you again, civilian. My squad's gone, but your words got through to me. I'm holding watch without shooting at shadows.'"
		if btn_standard_choice:
			btn_standard_choice.text = "[1] \"How are your supplies holding out?\""
		if btn_vibe_choice:
			btn_vibe_choice.text = "[2] [Vibe 15: COMPLETED] \"Hold down the fort, sergeant.\""
			btn_vibe_choice.disabled = true
	else:
		if dialogue_body_label:
			dialogue_body_label.text = "Hold your position! Biological warfare tore our division apart. Who goes there?!"
		if btn_standard_choice:
			btn_standard_choice.text = "[1] \"Who are you? What happened out here?\""
		var current_vibe = player.call("get_effective_vibe") if player and player.has_method("get_effective_vibe") else 10
		if btn_vibe_choice:
			btn_vibe_choice.text = "[2] [Vibe 15 (Current: %d)] \"The war is over, man. Put the gun down.\"" % current_vibe
			btn_vibe_choice.disabled = false

func _on_standard_choice_pressed() -> void:
	if not dialogue_body_label:
		return
	dialogue_body_label.text = "Miller lowers his weapon slightly:\n'Sgt. Miller, 4th Bio-Defense Division. A swarm of mutated beetles breached our defensive perimeter three nights ago. I'm the last one alive. High command hasn't replied to my distress beacon. If they're gone... what are we even defending?'"

func _on_vibe_choice_pressed() -> void:
	if not soldier_npc or not player or not dialogue_body_label:
		return

	var success = false
	if soldier_npc.has_method("evaluate_vibe_check"):
		success = soldier_npc.call("evaluate_vibe_check", player)

	var eff_vibe = player.call("get_effective_vibe") if player.has_method("get_effective_vibe") else 10
	var tape_name = player.get("current_tape") if player else "None"

	if success:
		dialogue_body_label.text = "[SUCCESS - VIBE CHECK PASSED (Effective Vibe: %d with Tape '%s')]\nMiller stares at you, his trembling hands dropping the rifle:\n'You're right... The radio's been dead static for weeks. We've been slaughtering bugs for a war that ended years ago. Take my rations and spare battery. I'm done shooting.'" % [eff_vibe, tape_name]
		if btn_vibe_choice:
			btn_vibe_choice.text = "[2] [Vibe 15: PASSED] \"Take care of yourself, sergeant.\""
			btn_vibe_choice.disabled = true
	else:
		dialogue_body_label.text = "[FAILED - VIBE CHECK FAILED (Effective Vibe: %d / 15)]\nMiller snaps the rifle back up, his eyes wild with paranoia:\n'Don't try to mess with my head! Sector 4 stands until headquarters issues a formal ceasefire! One more step and I open fire!'" % eff_vibe

func _on_exit_dialogue_pressed() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if player and player.has_method("set_movement_locked"):
		player.call("set_movement_locked", false)

# --- General HUD Refresh ---

func _refresh_hud() -> void:
	if not player:
		return

	var is_dead = player.call("is_dead") if player.has_method("is_dead") else false

	var cur_hp = player.get("current_health")
	var max_hp = player.get("max_health")
	if cur_hp != null and max_hp != null:
		if hp_bar:
			hp_bar.max_value = float(max_hp)
			hp_bar.value = float(cur_hp)
		if hp_label:
			var cur_i = int(cur_hp)
			var max_i = int(max_hp)
			if is_dead or cur_hp <= 0.0:
				hp_label.text = "[center][b]HEALTH:[/b] [color=#ff2233][b]0 / %d HP [FLATLINE][/b][/color][/center]" % max_i
			else:
				var hp_color = "#00ff66"
				if cur_hp <= max_hp * 0.25:
					hp_color = "#ff2233"
				elif cur_hp <= max_hp * 0.5:
					hp_color = "#ffcc00"
				hp_label.text = "[center][b]HEALTH:[/b] [color=%s][b]%d[/b][/color] / [color=#00cc55]%d[/color] HP[/center]" % [hp_color, cur_i, max_i]

	var lvl = player.call("get_level") if player.has_method("get_level") else 1
	var cur_xp = player.call("get_current_xp") if player.has_method("get_current_xp") else 0
	var req_xp = player.call("get_xp_to_level") if player.has_method("get_xp_to_level") else 50
	var unspent = player.call("get_unspent_stat_points") if player.has_method("get_unspent_stat_points") else 0

	if xp_bar:
		xp_bar.max_value = float(req_xp)
		xp_bar.value = float(cur_xp)
	if level_xp_label:
		level_xp_label.text = "[b]LEVEL[/b] [color=#ffdd44][b]%d[/b][/color]  |  [b]XP:[/b] [color=#66e0ff]%d[/color] / [color=#44aacc]%d[/color]" % [lvl, cur_xp, req_xp]

	var tape = player.get("current_tape")
	var tape_str = str(tape) if tape != null else "Bubblegum"
	if active_tape_label:
		active_tape_label.text = "[b]TAPE:[/b] [color=#00e5ff][b]%s[/b][/color]" % tape_str
	if tape_header and tape != null:
		tape_header.text = "WALKMAN // TRACK: '%s'" % tape_str

	# Information Decluttering: hide core attributes and basic stance texts from main viewport
	if stats_label:
		stats_label.visible = false
	if equip_label:
		equip_label.visible = false

	# Action Bar updates
	if action_secondary_label and player and player.has_method("get_secondary_weapon_name"):
		var sec_name = player.call("get_secondary_weapon_name")
		action_secondary_label.text = "[RMB] %s" % ("FLAME" if "Flame" in sec_name else "SEC")
	if action_tape_label and tape != null:
		action_tape_label.text = "[T] %s" % (tape_str.substr(0, 4).to_upper())

	_update_control_tip()
	if pager_box:
		pager_box.reset_size()

func _on_secondary_weapon_switched(_type: int, name_val: String) -> void:
	if action_secondary_label:
		action_secondary_label.text = "[RMB] %s" % ("FLAME" if "Flame" in name_val else "SEC")
	_update_control_tip()

func _update_control_tip() -> void:
	if not control_tip:
		control_tip = _find_pager_node("ControlTip")
	if not control_tip:
		return

	if player and player.has_method("is_dead") and player.call("is_dead"):
		control_tip.text = "[color=#ff4444][b]NEURAL LINK LOST. REBOOTING SYSTEM CLONE...[/b][/color]"
		return

	# Replaced long movement and attack strings with simple prompt
	var unspent = player.call("get_unspent_stat_points") if player and player.has_method("get_unspent_stat_points") else 0
	if unspent > 0:
		control_tip.text = "[b][color=#ffaa00][C][/color] Character Sheet[/b] [color=#ffdd44](+%d Pt)[/color]" % unspent
	else:
		control_tip.text = "[b][color=#ffaa00][C][/color] Character Sheet[/b]"

# --- Message Pager System ---

var pager_messages: Array[Dictionary] = []

func page_message(msg: String, secs: float = 3.0) -> void:
	pager_messages.append({"text": msg, "time": secs})
	if pager_messages.size() > 3:
		pager_messages.pop_front()
	_update_pager_display()

func _update_pager_display() -> void:
	if control_tip and control_tip is RichTextLabel:
		var bbcode = ""
		for m in pager_messages:
			bbcode += "[center]%s[/center]\n" % m.text
		control_tip.text = bbcode
		control_tip.add_theme_font_size_override("normal_font_size", 20)
		control_tip.add_theme_font_size_override("bold_font_size", 20)
		control_tip.add_theme_font_size_override("italics_font_size", 20)
		control_tip.add_theme_font_size_override("bold_italics_font_size", 20)
	elif control_tip and control_tip is Label:
		var t = ""
		for m in pager_messages:
			t += m.text + "\n"
		control_tip.text = t
		control_tip.add_theme_font_size_override("font_size", 20)
	
	if pager_box:
		pager_box.reset_size()

func _process_page_message(delta: float) -> void:
	if pager_messages.is_empty():
		return
	var changed = false
	for i in range(pager_messages.size() - 1, -1, -1):
		pager_messages[i].time -= delta
		if pager_messages[i].time <= 0.0:
			pager_messages.remove_at(i)
			changed = true
	if changed:
		_update_pager_display()

# --- Signal Handlers ---

func _on_adrenaline_changed(current: float, maximum: float) -> void:
	if adrenaline_bar:
		adrenaline_bar.max_value = maximum
		adrenaline_bar.value = current
