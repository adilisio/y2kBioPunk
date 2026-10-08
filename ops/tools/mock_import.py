import uuid
import re

with open('icon.svg.import', 'r') as f:
    text = f.read()

new_uid = 'uid://' + uuid.uuid4().hex[:12]

text = text.replace('icon.svg-218a8f2b3041327d8a5756f3a245f83b', 'menu_bg.jpg-dummy')
text = text.replace('icon.svg', 'sprites/menu_bg.jpg')
text = text.replace('uid="uid://dylmxiaee2dd4"', f'uid="{new_uid}"')
text = text.replace('compress/mode=0', 'compress/mode=1')

with open('sprites/menu_bg.jpg.import', 'w') as f:
    f.write(text)

with open('scenes/main_menu.tscn', 'r', encoding='utf-8') as f:
    scene = f.read()

scene = re.sub(r'uid="uid://[^"]+" path="res://sprites/menu_bg.jpg"', f'uid="{new_uid}" path="res://sprites/menu_bg.jpg"', scene)

with open('scenes/main_menu.tscn', 'w', encoding='utf-8') as f:
    f.write(scene)
