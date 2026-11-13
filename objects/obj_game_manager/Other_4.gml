/// @description Room Start Event

var _spawn_points = [];
with (obj_spawn_point) array_push(_spawn_points, id);

array_shuffle_ext(_spawn_points);

var _participants = match_current_participants();
if (instance_exists(obj_lobby_tube)) {
    // Lobby con tubo: todos llegan por él, de a uno y en ragdoll (scr_lobby, LLEGADA POR EL TUBO).
    for (var i = 0; i < array_length(_participants); i++) lobby_tube_enqueue(_participants[i]);
} else if (array_length(_spawn_points) > 0) {
    for (var i = 0; i < array_length(_participants); i++) {
        var _sp = _spawn_points[i mod array_length(_spawn_points)];
        try {
            // DECISIÓN: player_index va en el struct, así ya existe en el Create (lo necesita el
            // equipamiento para ponerle el gorro del lobby).
            instance_create_layer(_sp.x, _sp.y, "layer_players", obj_player,
                                  { player_index: _participants[i] });
        } catch (_err) {
            debug_create_error = string(_err.message);
        }
    }
}

// Casquillos: un solo controlador por room de juego (ver scr_fx, CASQUILLOS).
if (layer_exists("layer_effects")) instance_create_layer(0, 0, "layer_effects", obj_fx_shells);
