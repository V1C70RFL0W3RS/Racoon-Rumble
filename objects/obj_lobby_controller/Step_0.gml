if (keyboard_check_pressed(vk_enter)) {
    // Los ajustes salen de la PC del host (global.match.lobby_settings).
    var _s = global.match.lobby_settings;
    match_settings_init(_s.score_to_win, _s.rounds_per_block, match_scan_maps());
    match_start();
}