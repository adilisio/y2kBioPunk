import re

with open('scenes/main_menu.tscn', 'r') as f:
    text = f.read()

text = text.replace('type="ColorRect"', 'type="TextureRect"', 1)
text = text.replace('color = Color(0.06, 0.08, 0.1, 1)\n', 'texture = ExtResource("1_menu_bg")\nexpand_mode = 1\nstretch_mode = 6\n')
text = '[ext_resource type="Texture2D" uid="uid://new_uid_here" path="res://sprites/menu_bg.jpg" id="1_menu_bg"]\n\n' + text

text = re.sub(r'(TitleLabel.*?font_size = )\d+', r'\g<1>72', text, flags=re.DOTALL)
text = text.replace('Y2K RETRO-FUTURE ISOMETRIC ARPG', 'VERTICAL SLICE 1.1 // FLOODED MALL')

btn_style = '''theme_override_styles/normal = SubResource("StyleBoxFlat_Btn")
theme_override_styles/hover = SubResource("StyleBoxFlat_BtnHover")
'''
text = text.replace('text = "NEW GAME"', btn_style + 'text = "NEW GAME"')
text = text.replace('text = "CONTINUE"', btn_style + 'text = "CONTINUE"')
text = text.replace('text = "EXIT GAME"', btn_style + 'text = "EXIT GAME"')

style_res = '''
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_Btn"]
bg_color = Color(0, 0, 0, 0.6)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0, 1, 1, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_BtnHover"]
bg_color = Color(0.2, 0.2, 0.2, 0.6)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.5, 1, 1, 1)

'''
text = text.replace('[node name="MainMenu" type="MenuController"]', style_res + '[node name="MainMenu" type="MenuController"]')

hint_node = '''[node name="HintLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -400.0
offset_top = -65.0
offset_right = 400.0
offset_bottom = -40.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(0.8, 0.9, 1, 0.8)
theme_override_font_sizes/font_size = 14
text = "WASD move  ·  LMB swing  ·  SPACE jump  ·  K skates  ·  SHIFT evade  ·  T tape  ·  C stats"
horizontal_alignment = 1

'''
text = text.replace('[node name="FooterLabel"', hint_node + '[node name="FooterLabel"')

with open('scenes/main_menu.tscn', 'w') as f:
    f.write(text)
