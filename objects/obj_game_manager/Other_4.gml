/// @description Room Start Event

var _spawn_points = [];
with (obj_spawn_point) array_push(_spawn_points, id);

array_shuffle_ext(_spawn_points);

var _participants = match_current_participants();
if (array_length(_spawn_points) > 0) {
    for (var i = 0; i < array_length(_participants); i++) {
        var _sp = _spawn_points[i mod array_length(_spawn_points)];
        try {
            var _p = instance_create_layer(_sp.x, _sp.y, "layer_players", obj_player);
            _p.player_index = _participants[i];
        } catch (_err) {
            debug_create_error = string(_err.message);
        }
    }
}
// TEMPORAL: armas de prueba del Paso 2 de la Fase 2, borrar al implementar el pickup.
// Por ahora sigue corriendo en cualquier room con spawn points (incluida rm_lobby);
// cuando lleguemos al Paso 3 (spawners de armas reales) esto se acota a los mapas.
var _sp = instance_find(obj_spawn_point, 0);
if (_sp != noone) {
    instance_create_layer(_sp.x + 60,  _sp.y - 40, "layer_items", obj_weapon, { weapon_id: WEAPON_ID.PISTOL });
    instance_create_layer(_sp.x + 120, _sp.y - 40, "layer_items", obj_weapon, { weapon_id: WEAPON_ID.SHOTGUN });
    instance_create_layer(_sp.x + 180, _sp.y - 40, "layer_items", obj_weapon, { weapon_id: WEAPON_ID.MAGNUM });
    instance_create_layer(_sp.x + 240, _sp.y - 40, "layer_items", obj_weapon, { weapon_id: WEAPON_ID.SMG });
}