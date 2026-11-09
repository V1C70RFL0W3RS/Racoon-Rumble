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

/// @desc Un holdable 'shootable' recibe un disparo: lo empuja en la dirección de la bala.
///       ÚNICO punto de entrada de una bala a un objeto (como player_take_hit con jugadores):
///       aquí se sumará el daño de las cajas que se rompen cuando existan.
///       Los topes HOLDABLE_MAX_* los aplica el Step del holdable, no hace falta repetirlos.
/// @param {Id.Instance} _h Holdable golpeado.
/// @param {Real} _dir Dirección de la bala (grados).
/// @param {Real} _power Empujón de la munición (AmmoDef.impact), en px/frame.
function holdable_take_shot(_h, _dir, _power) {
    with (_h) {
        if (holder != noone) return;   // en una mano: lo controla quien lo lleva
        var _k = _power * impact_mult;
        hsp += lengthdir_x(_k, _dir);
        vsp += lengthdir_y(_k, _dir);
    }
}
