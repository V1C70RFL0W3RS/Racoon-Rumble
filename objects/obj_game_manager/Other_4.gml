/// @description Room Start Event

var _spawn_points = [];
with (obj_spawn_point) array_push(_spawn_points, id);

if (array_length(_spawn_points) > 0) {
    for (var i = 0; i < MAX_PLAYERS; i++) {
        var _sp = _spawn_points[i mod array_length(_spawn_points)];
        try {
            var _p = instance_create_layer(_sp.x, _sp.y, "layer_players", obj_player);
            _p.player_index = i;
        } catch (_err) {
            debug_create_error = string(_err.message);
        }
    }
}