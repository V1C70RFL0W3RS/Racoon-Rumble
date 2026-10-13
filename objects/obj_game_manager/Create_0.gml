weapon_data_init();
player_palette_init();
player_shoulder_table_init();
global.match = {}; // se va completando a medida que avanza cada fase del flujo
lobby_reset();
room_goto(rm_menu);