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
        prev_y: _origin_y,
        // Estela: nace en la boca del cañón y crece hasta trail_length (no atraviesa el arma).
        start_x:      _x,
        start_y:      _y,
        trail_length: _ammo.trail_length,
        trail_color:  _ammo.trail_color,
        trail_width:  _ammo.trail_width
    });
}

/// @desc Punto exacto donde la bala tocó la pared. move_and_collide la detiene cuando el
///       BORDE de su máscara toca el muro, pero x,y es el CENTRO: el muro queda unos px más
///       adelante. Se avanza de a 1 px desde el centro hasta encontrarlo.
/// @param {Real} _x Posición de la bala (ya detenida por move_and_collide).
/// @param {Real} _y
/// @param {Real} _dir Dirección en que viajaba (grados).
/// @param {Id.TileMapElement} _tilemap
/// @returns {Array<Real>} [x, y] del contacto (o la posición original si no lo encuentra).
function projectile_wall_contact(_x, _y, _dir, _tilemap) {
    var _dx = lengthdir_x(1, _dir);
    var _dy = lengthdir_y(1, _dir);
    for (var i = 0; i <= PROJECTILE_CONTACT_SEARCH; i++) {
        var _px = _x + _dx * i;
        var _py = _y + _dy * i;
        // Se devuelve el último píxel LIBRE, para que las chispas no nazcan dentro del muro.
        if (collision_point(_px, _py, _tilemap, false, false) != noone) return [_px - _dx, _py - _dy];
    }
    return [_x, _y];
}

/// @desc Dibuja la estela de una bala (grosor trail_width), opaca en la punta y transparente
///       en la cola. Mientras la bala está recién salida, la estela no pasa de la boca.
/// @param {Id.Instance} _b Instancia de obj_projectile.
function projectile_draw_trail(_b) {
    with (_b) {
        var _len = min(trail_length, point_distance(start_x, start_y, x, y));
        if (_len < 1) return;
        var _dir = point_direction(0, 0, hsp, vsp);
        var _tx  = x - lengthdir_x(_len, _dir);
        var _ty  = y - lengthdir_y(_len, _dir);
        if (trail_width <= 1) {
            // 1 px: una línea (más nítida que un rectángulo de 1 px)
            draw_primitive_begin(pr_linelist);
            draw_vertex_colour(_tx, _ty, trail_color, 0);
            draw_vertex_colour(x, y, trail_color, 1);
            draw_primitive_end();
        } else {
            // Más gruesa: un rectángulo de 2 triángulos, con el mismo degradado.
            var _nx = lengthdir_x(trail_width / 2, _dir + 90);
            var _ny = lengthdir_y(trail_width / 2, _dir + 90);
            draw_primitive_begin(pr_trianglestrip);
            draw_vertex_colour(_tx + _nx, _ty + _ny, trail_color, 0);
            draw_vertex_colour(_tx - _nx, _ty - _ny, trail_color, 0);
            draw_vertex_colour(x + _nx,  y + _ny,  trail_color, 1);
            draw_vertex_colour(x - _nx,  y - _ny,  trail_color, 1);
            draw_primitive_end();
        }
    }
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