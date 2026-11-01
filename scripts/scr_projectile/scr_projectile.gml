/// @file scr_projectile
/// @param {Real} _x Posición de aparición (la boca del cañón).
/// @param {Real} _y
/// @param {Real} _angle Dirección en grados (0 = derecha, 90 = arriba).
/// @param {Struct.AmmoDef} _ammo Tipo de bala: de aquí salen velocidad, daño y vida.
/// @param {Id.Instance} _owner Quién disparó (para no golpearse a sí mismo).
/// @param {Real} [_origin_x] Inicio del primer segmento de detección (la mano).
/// @param {Real} [_origin_y]
function projectile_spawn(_x, _y, _angle, _ammo, _owner, _origin_x = undefined, _origin_y = undefined) {
    if (is_undefined(_origin_x)) _origin_x = _x;
    if (is_undefined(_origin_y)) _origin_y = _y;

    return instance_create_layer(_x, _y, "layer_effects", obj_projectile, {
        hsp:    lengthdir_x(_ammo.speed, _angle),
        vsp:    lengthdir_y(_ammo.speed, _angle),
        damage: _ammo.damage,
        life:   _ammo.life,
        owner:  _owner,
        prev_x: _origin_x,
        prev_y: _origin_y
    });
}

/// @desc Jugador vivo más cercano que cruza el segmento (_x1,_y1)->(_x2,_y2).
///       Ignora al dueño de la bala. Devuelve noone si no hay ninguno.
function projectile_find_hit(_x1, _y1, _x2, _y2, _owner) {
    var _best = noone;
    var _best_dist = infinity;
    with (obj_player) {
        if (id == _owner || state == PLAYER_STATE.DEAD) continue;
        // precise = true: usa la máscara real, no la caja
        if (collision_line(_x1, _y1, _x2, _y2, id, true, false) != noone) {
            var _d = point_distance(_x1, _y1, x, y);
            if (_d < _best_dist) { _best_dist = _d; _best = id; }
        }
    }
    return _best;
}