weapon_data_init();
player_palette_init();
player_shoulder_table_init();
global.match = {}; // se va completando a medida que avanza cada fase del flujo
lobby_reset();
room_goto(rm_menu);

// Ventana inicial: 4x la vista base (1280x720). Solo afecta a PC.
if (os_type == os_windows) {
    window_set_size(CAMERA_VIEW_W * 4, CAMERA_VIEW_H * 4);
    window_center();
}