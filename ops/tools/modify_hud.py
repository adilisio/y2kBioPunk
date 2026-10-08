with open('scripts/hud.gd', 'r') as f:
    text = f.read()

# Action bar overlap
text = text.replace('action_bar.offset_bottom = -105.0', 'action_bar.offset_bottom = -138.0')
text = text.replace('action_bar.offset_top = -170.0', 'action_bar.offset_top = -203.0')

# Health bar styling
import re
new_hp_style = '''		hp_bar.custom_minimum_size.y = 36.0
		
		# Inner fill with subtle 2-px scanline pattern using a generated texture
		var img = Image.create(2, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.95, 0.4, 0.9))
		img.set_pixel(0, 2, Color(0.0, 0.8, 0.3, 0.7))
		img.set_pixel(1, 2, Color(0.0, 0.8, 0.3, 0.7))
		img.set_pixel(0, 3, Color(0.0, 0.8, 0.3, 0.7))
		img.set_pixel(1, 3, Color(0.0, 0.8, 0.3, 0.7))
		var scanline_tex = ImageTexture.create_from_image(img)
		
		var fill_style = StyleBoxTexture.new()
		fill_style.texture = scanline_tex
		fill_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		fill_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		hp_bar.add_theme_stylebox_override("fill", fill_style)

		# Dark translucent panel, 2 px green border
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.05, 0.08, 0.06, 0.85)
		bg_style.border_color = Color(0.0, 1.0, 0.4, 1.0)
		bg_style.set_border_width_all(2)
		bg_style.set_corner_radius_all(4)
		hp_bar.add_theme_stylebox_override("background", bg_style)'''

text = re.sub(r'hp_bar\.custom_minimum_size\.y = 36\.0.*?hp_bar\.add_theme_stylebox_override\("background", bg_style\)', new_hp_style, text, flags=re.DOTALL)

with open('scripts/hud.gd', 'w') as f:
    f.write(text)
