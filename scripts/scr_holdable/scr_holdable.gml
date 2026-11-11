/// @desc Busca el objeto agarrable SUELTO más cercano a un punto, dentro de HOLDABLE_GRAB_RADIUS.
/// @returns {Id.Instance} Instancia de cualquier hijo de obj_holdable, o noone.
function holdable_find_grabbable(_x, _y) {
    var _best = noone;
    var _best_dist = HOLDABLE_GRAB_RADIUS;

    with (obj_holdable) {   // incluye a todos sus hijos (armas, piezas, cajas...)
        if (holder != noone) continue; // ya lo tiene alguien: no agarrable
        var _d = point_distance(x, y, _x, _y);
        if (_d < _best_dist) {
            _best_dist = _d;
            _best = id;
        }
    }
    return _best;
}

/// @desc ÚNICO lugar donde se dibuja un holdable (suelto o en la mano). Si tiene
///       color_index >= 0 lo tiñe con el color de ese jugador.
function holdable_draw(_h, _x, _y, _xscale, _yscale, _angle) {
    var _tinted = (_h.color_index >= 0);
    if (_tinted) palette_apply(_h.color_index);
    draw_sprite_ext(_h.sprite_index, _h.image_index, _x, _y, _xscale, _yscale, _angle, c_white, _h.image_alpha);
    if (_tinted) palette_reset();
}

/// @desc Dibuja un holdable sostenido: su punto de sujeción cae en la mano.
function holdable_draw_held(_h, _x, _y, _facing, _angle) {
    var _ox = holdable_held_x(_h, _x, _facing, _angle);
    var _oy = holdable_held_y(_h, _y, _facing, _angle);
    if (_h.drives_angle)  holdable_draw(_h, _ox, _oy, _facing, 1, _h.angle);
    else if (_h.rotates)  holdable_draw(_h, _ox, _oy, 1, _facing, _angle);
    else                  holdable_draw(_h, _ox, _oy, _facing, 1, 0);
}
/// @desc Si el objeto nació con su máscara dentro de una pared, lo reubica en un
///       lugar libre, buscando SOLO hacia el lado indicado (nunca hacia la pared).
function holdable_resolve_overlap(_h, _away) {
    with (_h) {
        if (!place_meeting(x, y, tilemap)) return;

        var _x0 = x;
        for (var _d = 0; _d <= HOLDABLE_OVERLAP_PUSHOUT; _d++) {
            x = _x0 + _away * _d;
            if (!place_meeting(x, y, tilemap)) return;

            image_xscale = -image_xscale;
            if (!place_meeting(x, y, tilemap)) return;
            image_xscale = -image_xscale;
        }
        x = _x0;
    }
}

/// @desc Saca un objeto de las manos de alguien y lo deja suelto con la velocidad
///       indicada. Único lugar donde un holdable pasa de "sostenido" a "suelto".
function holdable_eject(_h, _x, _y, _facing, _hsp, _vsp, _spin) {
    _h.holder = noone;
    _h.image_xscale = _facing;
    _h.image_yscale = 1;
    _h.angle = 0;
    _h.x = _x;
    _h.y = _y;
    _h.hsp = _hsp;
    _h.vsp = _vsp;
    _h.spin = _spin;

    // DECISIÓN: se comprueba la máscara COMPLETA, no un punto (ver bug de la
    // escopeta incrustada en la pared, Fase 2).
    holdable_resolve_overlap(_h, -_facing);
}

/// @desc Dónde queda el ORIGEN de un holdable sostenido para que su punto de sujeción
///       caiga en la mano. Mismo convenio que el dibujo: escala y luego giro.
function holdable_held_x(_h, _hand_x, _facing, _angle) {
    if (_h.drives_angle) return _hand_x - (_h.grip_x * _facing * dcos(_h.angle) + _h.grip_y * dsin(_h.angle));
    if (!_h.rotates) return _hand_x - _h.grip_x * _facing;
    return _hand_x - (_h.grip_x * dcos(_angle) + _h.grip_y * _facing * dsin(_angle));
}

function holdable_held_y(_h, _hand_y, _facing, _angle) {
    if (_h.drives_angle) return _hand_y - (-_h.grip_x * _facing * dsin(_h.angle) + _h.grip_y * dcos(_h.angle));
    if (!_h.rotates) return _hand_y - _h.grip_y;
    return _hand_y - (-_h.grip_x * dsin(_angle) + _h.grip_y * _facing * dcos(_angle));
}

/// @desc Si un holdable está incrustado en el mapa, lo saca por el lado donde menos tiene que
///       moverse (arriba, derecha o izquierda). move_and_collide NO libera a un objeto ya
///       incrustado: solo frena los movimientos nuevos.
function holdable_depenetrate(_h) {
    with (_h) {
        if (!place_meeting(x, y, tilemap)) return;

        var _x0 = x;
        var _y0 = y;
        for (var _d = 1; _d <= HOLDABLE_MAX_PUSHOUT; _d++) {
            // Se prueba cada distancia en los tres sentidos antes de pasar a la siguiente:
            // gana el desplazamiento MÁS CORTO, sea cual sea su dirección.
            if (!place_meeting(_x0, _y0 - _d, tilemap)) { y = _y0 - _d; return; }
            if (!place_meeting(_x0 + _d, _y0, tilemap)) { x = _x0 + _d; return; }
            if (!place_meeting(_x0 - _d, _y0, tilemap)) { x = _x0 - _d; return; }
        }
    }
}

/// @desc Un holdable 'shootable' recibe un disparo. ÚNICO punto de entrada de una bala a un
///       objeto (como player_take_hit con jugadores): empuja, muestra el efecto y quita vida.
///       Suelto, lo empuja en la dirección de la bala; en una mano (escudo) no lo mueve, porque
///       lo controla quien lo lleva. Los topes HOLDABLE_MAX_* los aplica el Step del holdable.
/// @param {Id.Instance} _h Holdable golpeado.
/// @param {Real} _dir Dirección de la bala (grados).
/// @param {Real} _power Empujón de la munición (AmmoDef.impact), en px/frame.
/// @param {Real} [_damage] Vida que le quita (AmmoDef.object_damage). Solo afecta a destructibles.
function holdable_take_shot(_h, _dir, _power, _damage = 0) {
    with (_h) {
        if (holder == noone) {
            var _k = _power * impact_mult;
            hsp += lengthdir_x(_k, _dir);
            vsp += lengthdir_y(_k, _dir);
        }
        fx_holdable_hit(id, _dir);   // pelo, astillas... según la bandera hit_fx
        if (hp >= 0) holdable_damage(id, _damage, _dir);   // -1 = indestructible
    }
}

/// @desc Quita vida a un holdable destructible. Si su sprite tiene varios frames, muestra el
///       daño (frame 0 = entero, el último = casi roto). Al llegar a 0, se rompe.
/// @param {Id.Instance} _h
/// @param {Real} _damage
/// @param {Real} _dir Dirección del golpe (hacia dónde salen los restos al romperse).
function holdable_damage(_h, _damage, _dir) {
    with (_h) {
        hp = max(0, hp - _damage);
        if (hp <= 0) { holdable_break(id, _dir); return; }
        var _n = sprite_get_number(sprite_index);
        if (_n > 1) image_index = min(_n - 1, floor((1 - hp / max_hp) * _n));
    }
}

/// @desc Rompe un holdable: efecto de rotura según hit_fx y lo destruye.
function holdable_break(_h, _dir) {
    fx_holdable_break(_h, _dir);
    holdable_destroy(_h);
}

/// @desc ÚNICO lugar donde se destruye un holdable que podría estar en una mano: primero se lo
///       quita a quien lo sostiene, para que no quede apuntando a una instancia que ya no existe.
function holdable_destroy(_h) {
    if (_h.holder != noone && instance_exists(_h.holder)) _h.holder.held_item = noone;
    instance_destroy(_h);
}


// =============================================================================
// PLATAFORMAS (holdables con `platform`, p. ej. cajas)
// De un solo sentido: solo se aterriza en ellas al BAJAR, así que de lado o desde abajo
// se atraviesan. Las usan el jugador (player_land_on_platform) y los holdables (su Step),
// así las cajas se apilan y un arma puede quedar encima de una caja.
// DECISIÓN: no son parte del tilemap porque se mueven, se agarran y se rompen.
// =============================================================================

/// @desc Distancia del origen al borde INFERIOR de la máscara, ejecutado como la instancia.
///       Se lee del sprite y no de bbox_bottom, que se redondea y haría temblar a quien
///       está parado sobre una plataforma. Respeta image_yscale (un arma acostada, espejada).
function mask_bottom_offset() {
    var _m = (mask_index >= 0) ? mask_index : sprite_index;
    var _o = sprite_get_yoffset(_m);
    return (image_yscale >= 0) ? (sprite_get_bbox_bottom(_m) - _o) * image_yscale
                               : (sprite_get_bbox_top(_m)    - _o) * image_yscale;
}

/// @desc Plataforma cuya tapa cruzó un borde inferior este frame: estaba ENCIMA (_b0) y ahora
///       está a su altura o más abajo (_b1). Si cruzó varias, la más alta.
/// @param {Real} _l bbox_left de quien cae.
/// @param {Real} _r bbox_right de quien cae.
/// @param {Real} _b0 Borde inferior ANTES de moverse este frame.
/// @param {Real} _b1 Borde inferior DESPUÉS.
/// @param {Id.Instance} _self Quien cae (una caja no aterriza sobre sí misma).
/// @returns {Id.Instance} La plataforma, o noone. Pararse encima = borde inferior en su bbox_top - 1.
function platform_find_below(_l, _r, _b0, _b1, _self) {
    var _best = noone;
    var _best_top = infinity;
    with (obj_holdable) {
        if (!platform || holder != noone || id == _self) continue;   // descarte barato primero
        if (_r < bbox_left || _l > bbox_right) continue;             // no está debajo
        var _surf = bbox_top - 1;                                    // donde queda el borde inferior
        if (_b0 <= _surf + 0.01 && _b1 >= _surf && bbox_top < _best_top) {
            _best_top = bbox_top;
            _best = id;
        }
    }
    return _best;
}

/// @desc Si un holdable que aplasta (crush_speed > 0) cae sobre la CABEZA de un jugador lo bastante
///       rápido, lo mata. "Por arriba" = su borde inferior venía por encima de la cabeza del
///       jugador al empezar el frame; así una caja que cae al lado, o que lo atraviesa de
///       costado, no mata. Ejecutar como el holdable.
/// @param {Real} _fall Velocidad vertical con que se movió este frame (antes de aterrizar).
/// @param {Real} _b0 Su borde inferior antes de moverse.
function holdable_try_crush(_fall, _b0) {
    if (crush_speed <= 0 || _fall < crush_speed) return;
    var _h = id;
    var _crushed = false;
    with (obj_player) {
        if (state == PLAYER_STATE.DEAD) continue;
        if (_b0 > bbox_top) continue;                   // ya estaba a la altura del cuerpo: no es la cabeza
        if (!place_meeting(x, y, _h)) continue;
        player_take_hit(id, PLAYER_MAX_HP, 270, _fall);   // el cadáver sale hacia abajo
        _crushed = true;
    }
    // Rebota en la cabeza: un saltito hacia arriba (sigue cayendo después con la gravedad).
    if (_crushed) vsp = -HOLDABLE_CRUSH_BOUNCE;
}
