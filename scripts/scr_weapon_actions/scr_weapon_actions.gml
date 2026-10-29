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