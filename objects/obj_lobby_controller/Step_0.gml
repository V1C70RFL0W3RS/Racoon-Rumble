// Unirse ya estando en el lobby: el jugador nuevo llega por el tubo, como todos.
var _new = lobby_scan_join();
for (var i = 0; i < array_length(_new); i++) lobby_tube_enqueue(_new[i]);

// TEMPORAL (hasta el sofá de la Parte 6.3): ENTER empieza la partida.
if (keyboard_check_pressed(vk_enter)) {
    // Los ajustes salen de la PC del host (global.match.lobby_settings).
    var _s = global.match.lobby_settings;
    match_settings_init(_s.score_to_win, _s.rounds_per_block, match_scan_maps());
    match_start();
}
