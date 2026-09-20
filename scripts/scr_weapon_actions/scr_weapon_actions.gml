/// @desc Busca el arma SUELTA más cercana a un punto, dentro de WEAPON_GRAB_RADIUS.
/// @param {Real} _x
/// @param {Real} _y
/// @returns {Id.Instance} La instancia de obj_weapon, o noone si no hay ninguna.
function weapon_find_grabbable(_x, _y) {
    var _best = noone;
    var _best_dist = WEAPON_GRAB_RADIUS;

    with (obj_weapon) {
        if (holder != noone) continue; // ya la tiene alguien: no agarrable
        var _d = point_distance(x, y, _x, _y);
        if (_d < _best_dist) {
            _best_dist = _d;
            _best = id;
        }
    }
    return _best;
}

/// @desc Dibuja un arma sostenida en la mano de quien la lleva.
/// @param {Id.Instance} _weapon Instancia de obj_weapon.
/// @param {Real} _x Posición X del jugador.
/// @param {Real} _y Posición Y del jugador (sus pies).
/// @param {Real} _facing 1 = mira a la derecha, -1 = a la izquierda.
/// @param {Bool} _aim_up true = el arma apunta hacia arriba.
function weapon_draw_held(_weapon, _x, _y, _facing, _aim_up) {
    // 90 * facing: con el sprite espejado (mira a la izquierda) el giro va al revés.
    var _angle = (_aim_up ? 90 * _facing : 0) + _weapon.kick * _facing;
    draw_sprite_ext(_weapon.sprite_index, 0,
        _x + HAND_OFFSET_X * _facing, _y + HAND_OFFSET_Y,
        _facing, 1, _angle, c_white, 1);
}

/// @desc Intenta disparar un arma. Respeta cadencia y munición.
/// @param {Id.Instance} _weapon Instancia de obj_weapon.
/// @param {Real} _x Posición de la mano (agarre del arma).
/// @param {Real} _y
/// @param {Real} _angle Dirección de disparo en grados.
/// @param {Id.Instance} _owner Quién dispara.
/// @returns {Bool} true si disparó (para que quien llamó aplique el retroceso).
function weapon_try_fire(_weapon, _x, _y, _angle, _owner) {
    if (_weapon.cooldown > 0 || _weapon.ammo <= 0) return false;

    var _def = _weapon.def;

    // Las balas nacen en la boca del cañón, no en la mano.
    var _mx = _x + lengthdir_x(_def.muzzle_x, _angle);
    var _my = _y + lengthdir_y(_def.muzzle_x, _angle);

    // Escopeta: varias balas con dispersión; pistola: una, sin dispersión.
    repeat (_def.bullets) {
        var _a = _angle + random_range(-_def.spread * 0.5, _def.spread * 0.5);
        projectile_spawn(_mx, _my, _a, _def.bullet_speed, _def.damage, _def.bullet_life, _owner);
    }
    // El kick se aplica DESPUÉS del disparo: la bala sale con la orientación
    // actual, y el arma queda ya inclinada para el siguiente tiro.
    _weapon.kick = clamp(_weapon.kick + _def.kick_up + random_range(-_def.kick_jitter, _def.kick_jitter),-_def.kick_max, _def.kick_max);
    _weapon.ammo--;
    _weapon.cooldown = _def.fire_delay;
    return true;
}

/// @desc Si el arma nació con su máscara dentro de una pared, la reubica en un
///       lugar libre. Busca SOLO hacia el lado indicado (el del jugador), nunca
///       hacia la pared, para no cruzarla.
/// @param {Id.Instance} _weapon Instancia de obj_weapon.
/// @param {Real} _away Sentido que se aleja de la pared: 1 = derecha, -1 = izquierda.
function weapon_resolve_overlap(_weapon, _away) {
    with (_weapon) {
        if (!place_meeting(x, y, tilemap)) return;

        var _x0 = x;
        for (var _d = 0; _d <= WEAPON_MAX_PUSHOUT; _d++) {
            x = _x0 + _away * _d;

            // ¿Libre tal cual está?
            if (!place_meeting(x, y, tilemap)) return;

            // ¿Y espejada? (la máscara pasa al otro lado del agarre)
            image_xscale = -image_xscale;
            if (!place_meeting(x, y, tilemap)) return;
            image_xscale = -image_xscale; // tampoco: se restaura la orientación
        }

        // Sin hueco en todo el rango (caso rarísimo): se deja donde nació.
        x = _x0;
    }
}

/// @desc Ángulo real de puntería de un arma: la dirección base del jugador más
///       la inclinación (kick) actual del arma.
/// @param {Id.Instance} _weapon
/// @param {Real} _base_angle Dirección base (0 = derecha, 180 = izquierda, 90 = arriba).
/// @param {Real} _facing 1 = mira a la derecha, -1 = a la izquierda.
/// @returns {Real} Ángulo en grados.
function weapon_get_aim_angle(_weapon, _base_angle, _facing) {
    // * _facing: "hacia arriba" gira en sentido opuesto según el lado al que se mira.
    return _base_angle + _weapon.kick * _facing;
}

/// @desc Saca un arma de las manos de alguien y la deja suelta en el mundo con
///       la velocidad indicada. Único lugar donde un arma pasa de "sostenida" a "suelta".
/// @param {Id.Instance} _w Arma a soltar.
/// @param {Real} _x Posición de aparición (normalmente la mano).
/// @param {Real} _y
/// @param {Real} _facing Hacia dónde miraba quien la soltaba (1 o -1).
/// @param {Real} _hsp Velocidad horizontal inicial.
/// @param {Real} _vsp Velocidad vertical inicial.
/// @param {Real} _spin Giro en grados por frame.
function weapon_eject(_w, _x, _y, _facing, _hsp, _vsp, _spin) {
    _w.holder = noone;
    _w.image_xscale = _facing;   // conserva hacia dónde miraba
    _w.image_yscale = 1;         // siempre sale "de pie"
    _w.angle = 0;
    _w.x = _x;
    _w.y = _y;
    _w.hsp = _hsp;
    _w.vsp = _vsp;
    _w.spin = _spin;

    // DECISIÓN: se comprueba la máscara COMPLETA, no un punto (ver bug de la
    // escopeta incrustada en la pared).
    weapon_resolve_overlap(_w, -_facing);
}