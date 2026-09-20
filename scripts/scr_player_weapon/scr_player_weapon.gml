/// @desc Punto de entrada: agarra o tira según el estado actual. Un solo botón.
/// @param {Struct} _in Struct devuelto por get_player_input().
function player_update_weapon(_in) {
    if (!_in.grab_pressed) return;

    if (held_weapon == noone) player_grab_weapon();
    else                      player_release_weapon(_in);
}


/// @desc Toma el arma suelta más cercana, si hay alguna al alcance.
function player_grab_weapon() {
    var _w = weapon_find_grabbable(x, y + HAND_OFFSET_Y);
    if (_w == noone) return;

    _w.holder = id;
    held_weapon = _w;
}

/// @desc Suelta el arma. Mirando arriba la lanza hacia arriba; en movimiento la
///       lanza hacia adelante; quieto, la lanza suavemente.
/// @param {Struct} _in Input del frame actual.
function player_release_weapon(_in) {
    var _w = held_weapon;
    held_weapon = noone;

    // El arma nace en la MANO (no en los pies) para que se vea el arco.
    var _hx = x + HAND_OFFSET_X * facing;
    var _hy = y + HAND_OFFSET_Y;

    if (_in.up_held) {
        weapon_eject(_w, _hx, _hy, facing, hsp, -WEAPON_THROW_UP_SPEED, -WEAPON_THROW_SPIN * facing);
    } else if (abs(hsp) > WEAPON_THROW_MIN_SPEED) {
        weapon_eject(_w, _hx, _hy, facing, hsp + sign(hsp) * WEAPON_THROW_SPEED,
                     WEAPON_THROW_LIFT, -WEAPON_THROW_SPIN * sign(hsp));
    } else {
        weapon_eject(_w, _hx, _hy, facing, facing * WEAPON_DROP_SPEED,
                     WEAPON_DROP_LIFT, -WEAPON_DROP_SPIN * facing);
    }
}
/// @desc Intenta disparar el arma sostenida. Aplica el retroceso al jugador.
/// @param {Struct} _in Input del frame.
function player_try_fire(_in) {
    if (held_weapon == noone) return;

    // Automática: alcanza con mantener el botón. Semiautomática: un clic por disparo.
    var _wants_fire = held_weapon.def.automatic ? _in.fire_held : _in.fire_pressed;
    if (!_wants_fire) return;

    // Dirección base (3 direcciones por ahora) y dirección real con el kick del arma.
    var _base = _in.up_held ? 90 : (facing == 1 ? 0 : 180);
    var _aim  = weapon_get_aim_angle(held_weapon, _base, facing);

    var _hand_x = x + HAND_OFFSET_X * facing;
    var _hand_y = y + HAND_OFFSET_Y;

    if (weapon_try_fire(held_weapon, _hand_x, _hand_y, _aim, id)) {
        // El retroceso usa la dirección BASE, no la del kick, para que el
        // jugador no se sacuda de forma errática.
        var _recoil = held_weapon.def.recoil;
        hsp -= lengthdir_x(_recoil, _base);
        vsp -= lengthdir_y(_recoil, _base);
    }
}