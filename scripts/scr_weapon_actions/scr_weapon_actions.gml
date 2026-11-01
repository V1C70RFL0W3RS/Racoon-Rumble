/// @file scr_weapon_actions

/// @desc Punto de la boca del cañón en el mundo. ÚNICO lugar que lo calcula
///       (lo usan el disparo y el punto de depuración). Usa el mismo convenio
///       que weapon_draw_held: ángulo mundial + espejado con yscale = _facing.
function weapon_muzzle_x(_def, _x, _y, _angle, _facing) {
    return _x + lengthdir_x(_def.muzzle_x, _angle)
              + lengthdir_x(_def.muzzle_y * _facing, _angle - 90);
}
function weapon_muzzle_y(_def, _x, _y, _angle, _facing) {
    return _y + lengthdir_y(_def.muzzle_x, _angle)
              + lengthdir_y(_def.muzzle_y * _facing, _angle - 90);
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
    var _mx = weapon_muzzle_x(_def, _x, _y, _angle, _owner.facing);
    var _my = weapon_muzzle_y(_def, _x, _y, _angle, _owner.facing);

    // Si hay pared entre la mano y la boca, el disparo se gasta (munición,
    // cadencia, retroceso) pero la bala no se crea: nacería dentro del muro.
    // Se comprueba UNA vez por disparo, no por perdigón.
    var _blocked = collision_line(_x, _y, _mx, _my, _weapon.tilemap, true, true) != noone;

	
    var _ammo = ammo_get_def(_def.ammo_id);   // una búsqueda por disparo, no por perdigón

    if (!_blocked) {
        repeat (_def.bullets) {
            var _a = _angle + random_range(-_def.spread * 0.5, _def.spread * 0.5);
            projectile_spawn(_mx, _my, _a, _ammo, _owner, _x, _y);
        }
    }
	
    _weapon.kick = clamp(_weapon.kick + _def.kick_up + random_range(-_def.kick_jitter, _def.kick_jitter), -_def.kick_max, _def.kick_max);
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

/// TEMPORAL: punto rojo en la boca del cañón. Llamar fuera del shader de color.
function weapon_debug_muzzle(_weapon, _x, _y, _angle, _facing) {
    var _def = _weapon.def;
    draw_point_color(weapon_muzzle_x(_def, _x, _y, _angle, _facing),
                     weapon_muzzle_y(_def, _x, _y, _angle, _facing), c_red);
}