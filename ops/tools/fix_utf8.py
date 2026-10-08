import re
with open('scenes/main_menu.tscn', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

text = re.sub(r'text = \"[^\n]+stats\"', 'text = "WASD move  ·  LMB swing  ·  SPACE jump  ·  K skates  ·  SHIFT evade  ·  T tape  ·  C stats"', text)

# I should also fix the other files I touched to be utf-8 just in case, though they didn't have special characters, wait, mall_greybox_builder has `->` which is ascii, but let's just make sure.

with open('scenes/main_menu.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
