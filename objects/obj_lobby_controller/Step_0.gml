if (keyboard_check_pressed(vk_enter)) {
    match_settings_init(
        MATCH_DEFAULT_SCORE_TO_WIN,
        MATCH_DEFAULT_ROUNDS_PER_BLOCK,
        match_scan_maps()
    );
    match_start();
}