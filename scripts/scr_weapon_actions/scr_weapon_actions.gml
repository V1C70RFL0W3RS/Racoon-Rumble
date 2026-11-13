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
    if (_weapon.cooldown > 0) return false;
    if (_weapon.ammo <= 0) {
        weapon_dry_fire(_weapon);
        return false;   // sin balas no hay retroceso al jugador
    }
    // DECISIÓN: sin balas no se recarga (clic vacío, arriba): bombear un arma vacía no
    // tendría sentido y así el jugador se entera antes de que está vacía.
    if (_weapon.def.needs_rack && !_weapon.chambered) {
        weapon_rack(_weapon, _x, _y, _owner.facing);
        return false;   // recargar no dispara ni empuja al jugador
    }

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
        fx_muzzle_flash(_mx, _my, _angle, _def.flash_count);   // UNO por disparo, no por perdigón
        repeat (_def.bullets) {
            var _a = _angle + random_range(-_def.spread * 0.5, _def.spread * 0.5);
            projectile_spawn(_mx, _my, _a, _ammo, _owner, _x, _y, _def.impact_mult);
        }
    }
    audio_play_sfx(_def.snd_fire);   // suena aunque la pared se coma la bala: el disparo sí ocurrió
	
    var _wobble = sin(_weapon.wobble_phase) * _def.kick_wobble;
    _weapon.wobble_phase += _def.kick_wobble_speed + random_range(-_def.kick_wobble_chaos, _def.kick_wobble_chaos);
    _weapon.kick = clamp(_weapon.kick + _def.kick_up + _wobble + random_range(-_def.kick_jitter, _def.kick_jitter),
                         -_def.kick_max, _def.kick_max);
    _weapon.recoil_back = _def.kick_back;   // kick lineal: retrocede hacia el hombro
    _weapon.heat = min(1, _weapon.heat + _def.heat_per_shot);
    _weapon.since_shot = 0;
    // Las armas con recarga manual expulsan el casquillo al recargar, no al disparar.
    if (!_def.needs_rack) fx_shell_spawn(_x, _y, _owner.facing, _def);
    _weapon.ammo--;
    _weapon.cooldown = _def.fire_delay;
    if (_def.needs_rack) _weapon.chambered = false;   // la próxima pulsación recarga
    return true;
}
/// @desc Recarga manual (bombeo o cerrojo) de un arma con needs_rack. Usa el mismo botón
///       que disparar. Si el arma tiene rack_frame, la corredera se ve ir y volver.
/// @param {Id.Instance} _weapon Instancia de obj_weapon.
/// @param {Real} _x Mano (por donde sale el cartucho).
/// @param {Real} _y
/// @param {Real} _facing
function weapon_rack(_weapon, _x, _y, _facing) {
    var _def = _weapon.def;
    fx_shell_spawn(_x, _y, _facing, _def);   // bombear expulsa el cartucho disparado
    _weapon.chambered = true;
    _weapon.cooldown  = _def.rack_delay;
    _weapon.rack_timer = _def.rack_delay;
    audio_play_sfx(_def.snd_rack);
}

/// @desc Clic vacío: el arma no tiene balas. Avisa con un tirón, un destello gris en
///       la boca del cañón y un sonido. Usa la cadencia propia WEAPON_DRY_FIRE_DELAY
///       para que una automática no haga clic en cada frame.
/// @param {Id.Instance} _weapon Instancia de obj_weapon.
function weapon_dry_fire(_weapon) {
    var _def = _weapon.def;
    _weapon.cooldown  = WEAPON_DRY_FIRE_DELAY;
    _weapon.dry_flash = WEAPON_DRY_FLASH_FRAMES;
    // DECISIÓN: el tirón reutiliza el kick (ya se recupera solo en el Step del arma).
    _weapon.kick = clamp(_weapon.kick + WEAPON_DRY_KICK, -_def.kick_max, _def.kick_max);
    audio_play_sfx(_def.snd_empty);
}

/// @desc Dibuja el destello del clic vacío en la boca del cañón, si está activo.
///       Llamar con el arma en la mano, fuera del shader de color.
function weapon_draw_dry_flash(_weapon, _x, _y, _angle, _facing) {
    if (_weapon.dry_flash <= 0) return;
    var _def = _weapon.def;
    var _a = _weapon.dry_flash / WEAPON_DRY_FLASH_FRAMES;   // se desvanece
    draw_set_alpha(_a);
    draw_circle_color(weapon_muzzle_x(_def, _x, _y, _angle, _facing),
                      weapon_muzzle_y(_def, _x, _y, _angle, _facing), 2, c_ltgray, c_gray, false);
    draw_set_alpha(1);
}

/// @desc Un arma VACÍA, suelta y quieta en el piso, se desvanece y desaparece con humo.
///       Si alguien la agarra antes, se cancela. Una vez que empezó a desvanecerse ya no
///       importa si la empujan: termina igual.
///       DECISIÓN: el spawner no necesita saber nada; si su arma deja de existir, el punto
///       queda libre y su cuenta regresiva genera otra (ver obj_item_spawner).
/// @param {Id.Instance} _w Instancia de obj_weapon.
function weapon_update_despawn(_w) {
    with (_w) {
        if (ammo > 0 || holder != noone) {
            empty_rest_timer = 0;
            image_alpha = 1;
            return;
        }

        var _fading  = (empty_rest_timer > WEAPON_EMPTY_DESPAWN_DELAY);
        var _resting = (hsp == 0 && vsp == 0 && place_meeting(x, y + 1, tilemap));
        if (!_fading && !_resting) {
            empty_rest_timer = 0;   // todavía cae o se desliza: no cuenta
            return;
        }

        empty_rest_timer++;
        var _f = empty_rest_timer - WEAPON_EMPTY_DESPAWN_DELAY;
        if (_f > 0) image_alpha = 1 - _f / WEAPON_DESPAWN_FADE_FRAMES;
        if (_f >= WEAPON_DESPAWN_FADE_FRAMES) {
            fx_smoke_puff((bbox_left + bbox_right) / 2, (bbox_top + bbox_bottom) / 2);
            instance_destroy();
        }
    }
}

/// @desc Humo del cañón: cuando el arma deja de disparar y está caliente, la boca suelta
///       humo al azar; cuanto más calor, más seguido. El calor baja solo.
/// @param {Id.Instance} _w Instancia de obj_weapon.
function weapon_update_smoke(_w) {
    with (_w) {
        since_shot++;
        if (heat <= 0) return;
        heat = max(0, heat - WEAPON_HEAT_DECAY);

        if (since_shot < WEAPON_SMOKE_DELAY || heat < WEAPON_SMOKE_MIN) return;
        if (random(1) >= heat * WEAPON_SMOKE_RATE) return;

        // En la mano se usa la boca del cañón; suelta, el centro del arma.
        var _sx, _sy;
        if (holder != noone) {
            _sx = weapon_muzzle_x(def, x, y, held_angle, held_facing);
            _sy = weapon_muzzle_y(def, x, y, held_angle, held_facing);
        } else {
            _sx = (bbox_left + bbox_right) / 2;
            _sy = (bbox_top + bbox_bottom) / 2;
        }
        fx_barrel_smoke(_sx, _sy);
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

/// TEMPORAL: punto rojo en la boca del cañón. Llamar fuera del shader de color.
function weapon_debug_muzzle(_weapon, _x, _y, _angle, _facing) {
    var _def = _weapon.def;
    debug_draw_dot(weapon_muzzle_x(_def, _x, _y, _angle, _facing),
                   weapon_muzzle_y(_def, _x, _y, _angle, _facing), c_red);
}