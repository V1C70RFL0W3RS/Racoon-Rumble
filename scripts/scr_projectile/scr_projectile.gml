/// @file scr_projectile
/// @param {Real} _x Posición de aparición (la boca del cañón).
/// @param {Real} _y
/// @param {Real} _angle Dirección en grados (0 = derecha, 90 = arriba).
/// @param {Struct.AmmoDef} _ammo Tipo de bala: de aquí salen velocidad, daño y vida.
/// @param {Id.Instance} _owner Quién disparó (para no golpearse a sí mismo).
/// @param {Real} [_origin_x] Inicio del primer segmento de detección (la mano).
/// @param {Real} [_origin_y]
/// @param {Real} [_impact_mult] × _ammo.impact (WeaponDef.impact_mult). 1 = el de la munición.
function projectile_spawn(_x, _y, _angle, _ammo, _owner, _origin_x = undefined, _origin_y = undefined, _impact_mult = 1) {
    if (is_undefined(_origin_x)) _origin_x = _x;
    if (is_undefined(_origin_y)) _origin_y = _y;

    return instance_create_layer(_x, _y, "layer_effects", obj_projectile, {
        hsp:    lengthdir_x(_ammo.speed, _angle),
        vsp:    lengthdir_y(_ammo.speed, _angle),
        damage: _ammo.damage,
        life:   _ammo.life,
        impact: _ammo.impact * _impact_mult,
        object_damage: _ammo.object_damage,
        pierce: _ammo.pierce,   // se descuenta en cada objeto atravesado
        owner:  _owner,
        prev_x: _origin_x,
        prev_y: _origin_y,
        // Estela: nace en la boca del cañón y crece hasta trail_length (no atraviesa el arma).
        start_x:      _x,
        start_y:      _y,
        trail_length: _ammo.trail_length,
        trail_color:  _ammo.trail_color,
        trail_width:  _ammo.trail_width,
        trail_invert: _ammo.trail_invert
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

/// @desc Dibuja la estela de una bala (grosor trail_width), fuerte en la punta y desvanecida
///       en la cola. Mientras la bala está recién salida, la estela no pasa de la boca.
///       Con trail_invert, cada píxel toma el color CONTRARIO al del fondo (sobre blanco se ve
///       oscura, sobre negro clara): se lee sobre cualquier fondo sin leer píxeles (caro).
/// @param {Id.Instance} _b Instancia de obj_projectile.
function projectile_draw_trail(_b) {
    with (_b) {
        var _len = min(trail_length, point_distance(start_x, start_y, x, y));
        if (_len < 1) return;
        var _dir = point_direction(0, 0, hsp, vsp);
        var _tx  = x - lengthdir_x(_len, _dir);
        var _ty  = y - lengthdir_y(_len, _dir);

        if (trail_invert) {
            // resultado = fuente × (1 − fondo) + fondo × (1 − fuente):
            //   fuente blanca → invierte el fondo; fuente negra → deja el fondo igual.
            // Por eso el desvanecido va por COLOR (blanco en la punta → negro en la cola), no por
            // alpha. El alpha del destino se conserva (bm_zero, bm_one) para no dejar huecos
            // transparentes en la application_surface.
            gpu_set_blendmode_ext_sepalpha(bm_inv_dest_colour, bm_inv_src_colour, bm_zero, bm_one);
            projectile_draw_strip(_tx, _ty, x, y, _dir, trail_width, c_black, 1, c_white, 1);
            gpu_set_blendmode(bm_normal);
        } else {
            projectile_draw_strip(_tx, _ty, x, y, _dir, trail_width, trail_color, 0, trail_color, 1);
        }
    }
}

/// @desc Franja de (_tx,_ty) (cola) a (_x,_y) (punta) con degradado de color y alpha.
///       Grosor 1: una línea (más nítida que un rectángulo de 1 px); más: 2 triángulos.
function projectile_draw_strip(_tx, _ty, _x, _y, _dir, _width, _col_tail, _a_tail, _col_tip, _a_tip) {
    if (_width <= 1) {
        draw_primitive_begin(pr_linelist);
        draw_vertex_colour(_tx, _ty, _col_tail, _a_tail);
        draw_vertex_colour(_x, _y, _col_tip, _a_tip);
        draw_primitive_end();
        return;
    }
    var _nx = lengthdir_x(_width / 2, _dir + 90);
    var _ny = lengthdir_y(_width / 2, _dir + 90);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_tx + _nx, _ty + _ny, _col_tail, _a_tail);
    draw_vertex_colour(_tx - _nx, _ty - _ny, _col_tail, _a_tail);
    draw_vertex_colour(_x + _nx,  _y + _ny,  _col_tip,  _a_tip);
    draw_vertex_colour(_x - _nx,  _y - _ny,  _col_tip,  _a_tip);
    draw_primitive_end();
}

/// @desc Primer objetivo que cruza el segmento (_x1,_y1)->(_x2,_y2): un jugador vivo o un
///       holdable 'shootable' (suelto, o sostenido si es escudo: shield_when_held). Ignora al dueño de la bala y a lo que esté en _ignore
///       (lo ya atravesado por una bala con pierce). Devuelve noone si no hay ninguno.
///       "Primero" = el de menor avance a lo largo del segmento (proyección de su centro sobre
///       la dirección de la bala), no el más cercano en línea recta: así un objetivo al costado
///       de la trayectoria no le gana a uno que está delante.
/// @param {Array<Id.Instance>} _ignore
function projectile_find_hit(_x1, _y1, _x2, _y2, _owner, _ignore) {
    var _dx = _x2 - _x1;
    var _dy = _y2 - _y1;
    var _best = noone;
    var _best_t = infinity;

    with (obj_player) {
        if (id == _owner || !player_is_upright()) continue;   // en ragdoll se le pega a su cuerpo (holdables)
        // precise = true: usa la máscara real, no la caja
        if (collision_line(_x1, _y1, _x2, _y2, id, true, false) != noone) {
            var _t = (x - _x1) * _dx + (y - _y1) * _dy;
            if (_t < _best_t) { _best_t = _t; _best = id; }
        }
    }
    with (obj_holdable) {
        // Las comprobaciones baratas primero: la mayoría (armas) se descarta sin tocar colisiones.
        if (!shootable) continue;
        if (holder != noone && (!shield_when_held || holder == _owner)) continue;
        if (array_contains(_ignore, id)) continue;
        if (collision_line(_x1, _y1, _x2, _y2, id, true, false) != noone) {
            var _t = (x - _x1) * _dx + (y - _y1) * _dy;
            if (_t < _best_t) { _best_t = _t; _best = id; }
        }
    }
    return _best;
}
