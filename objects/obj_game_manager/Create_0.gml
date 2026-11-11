settings_init();      // PRIMERO: ajustes del jugador (otros sistemas pueden leerlos)
audio_init();         // después de los ajustes: el audio lee el volumen
player_palette_init(); // ANTES de fx_init: los efectos pueden leer los colores de jugador
hats_init();          // catálogo de gorros (ver scr_hats)
fx_init();            // tipos de partículas (humo, pelo, etc.)
weapon_data_init();
ammo_data_init();
player_shoulder_table_init();
global.match = {}; // se va completando a medida que avanza cada fase del flujo
lobby_reset();
room_goto(rm_menu);

// Ventana inicial: 4x la vista base (1280x720). Solo afecta a PC.
if (os_type == os_windows) {
    window_set_size(CAMERA_VIEW_W * 4, CAMERA_VIEW_H * 4);
    window_center();
}

corpse_joint_init();