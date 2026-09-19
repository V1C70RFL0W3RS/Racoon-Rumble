/// @description obj_room_controller → Create Event

var _active_players = MAX_PLAYERS; // por ahora fijo, después vendrá del menú de selección
var _spawn_points = [];
with (obj_spawn_point) array_push(_spawn_points, id);

for (var i = 0; i < _active_players; i++) {
    var _sp = _spawn_points[i mod array_length(_spawn_points)];
    var _p = instance_create_layer(_sp.x, _sp.y, "layer_players", obj_player);
    _p.player_index = i;
}