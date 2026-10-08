import re
with open('scenes/main_menu.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(' uid="uid://new_uid_here"', '')

with open('scenes/main_menu.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
