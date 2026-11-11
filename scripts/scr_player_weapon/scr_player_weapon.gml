/// @desc Punto de entrada: agarra o tira según el estado actual. Un solo botón.
/// @param {Struct} _in Struct devuelto por get_player_input().
function player_update_item(_in) {
    if (!_in.grab_pressed) return;

    if (held_item == noone) {
        // Con las manos vacías, usar algo cercano (PC del lobby) tiene prioridad sobre agarrar.
        var _it = interact_find(id);
        if (_it != noone) interact_begin(_it, id);
        else              player_grab_item();
    } else {
        player_release_item(_in);
    }
}


/// @desc Toma el arma suelta más cercana, si hay alguna al alcance.
function player_grab_item() {
    // Se busca a la altura del pecho (el hombro): HAND_OFFSET ya no se usa.
    var _w = holdable_find_grabbable(x, y + PLAYER_SHOULDER_Y);
    if (_w == noone) return;

    _w.holder = id;
    held_item = _w;
    audio_play_sfx(snd_pickup);
    if (_w.fires) ammo_pips_timer = AMMO_PIPS_SHOW_FRAMES;   // al agarrar, se ve cuánta tiene
}

/// @desc Suelta el arma. Agachado o deslizando la deja caer de la mano; mirando
///       arriba la lanza hacia arriba (en diagonal si se mueve); en movimiento la lanza
///       hacia adelante; quieto, la lanza suavemente.
/// @param {Struct} _in Input del frame actual.
function player_release_item(_in) {
    // DECISIÓN: el ángulo y la mano se leen ANTES de soltar. Sin arma,
    // player_get_arm_angle() devuelve el brazo colgando (270) y el arma
    // "saltaría" de lugar en el instante de soltarla.
    var _ang = player_get_arm_angle();
    var _hx  = player_hand_x(_ang);
    var _hy  = player_hand_y(_ang);

    var _w = held_item;
    held_item = noone;

    if (crouching || sliding) {
        // Agachado o deslizando, el arma cae de la mano: sin impulso ni giro.
        // DECISIÓN: va antes que "arriba" para que agachado nunca la lance.
        holdable_eject(_w, _hx, _hy, facing, 0, 0, 0);
    } else if (_in.up_held && abs(hsp) > HOLDABLE_THROW_MIN_SPEED) {
        // Mirando arriba EN MOVIMIENTO: en diagonal (45°) hacia donde corre.
        var _dir = (hsp > 0) ? 45 : 135;
        holdable_eject(_w, _hx, _hy, facing, lengthdir_x(HOLDABLE_THROW_DIAG_SPEED, _dir),
                     lengthdir_y(HOLDABLE_THROW_DIAG_SPEED, _dir), -HOLDABLE_THROW_SPIN * sign(hsp));
    } else if (_in.up_held) {
        // Mirando arriba QUIETO: recto hacia arriba, sin velocidad horizontal (biblia 4.4.4).
        holdable_eject(_w, _hx, _hy, facing, 0, -HOLDABLE_THROW_UP_SPEED, -HOLDABLE_THROW_SPIN * facing);
    } else if (abs(hsp) > HOLDABLE_THROW_MIN_SPEED) {
        // CAMBIO: velocidad ABSOLUTA, ya no se le suma hsp. Con la gravedad nueva volaría demasiado lejos.
        holdable_eject(_w, _hx, _hy, facing, sign(hsp) * HOLDABLE_THROW_SPEED,
                     HOLDABLE_THROW_LIFT, -HOLDABLE_THROW_SPIN * sign(hsp));
    } else {
        holdable_eject(_w, _hx, _hy, facing, facing * HOLDABLE_DROP_SPEED,
                     HOLDABLE_DROP_LIFT, -HOLDABLE_DROP_SPIN * facing);
    }
}

/// @desc Intenta disparar el arma sostenida. Aplica el retroceso al jugador.
/// @param {Struct} _in Input del frame.
function player_try_fire(_in) {
    if (held_item == noone) return;
	if (!held_item.fires) return;   // solo las armas disparan

    // Automática: alcanza con mantener el botón. Semiautomática: un clic por disparo.
    var _wants_fire = held_item.def.automatic ? _in.fire_held : _in.fire_pressed;
    if (!_wants_fire) return;
    ammo_pips_timer = AMMO_PIPS_SHOW_FRAMES;   // también con el clic vacío

    // aim_up ya se actualizó en este Step (antes de llamar a esta función).
    var _base = player_get_base_aim_angle();  // dirección base, sin kick
    var _aim  = player_get_arm_angle();       // dirección real, con el kick del arma

    // Las balas salen desde la mano, la misma donde se dibuja el arma.
    if (weapon_try_fire(held_item, player_hand_x(_aim), player_hand_y(_aim), _aim, id)) {
        // CAMBIO: las 3 líneas viejas del retroceso (_recoil, hsp -=, vsp -=) se reemplazan por esta llamada.
        // Usa la dirección BASE, no la del kick, para que el jugador no se sacuda de forma errática.
        player_apply_kick(held_item.def.recoil, _base);
    }
}

/// @desc Retroceso al jugador, como Duck Game (biblia 4.3.1 P8): el empuje horizontal
///       REEMPLAZA a hsp si va en contra o es mayor (no se suma), y el vertical suma
///       el componente del cañón menos un tercio de la fuerza hacia arriba.
/// @param {Real} _force Fuerza de retroceso del arma (def.recoil).
/// @param {Real} _angle Dirección BASE del apuntado, sin kick (0 derecha, 90 arriba).
function player_apply_kick(_force, _angle) {
    var _kx = -lengthdir_x(_force, _angle);
    var _ky = -lengthdir_y(_force, _angle);

    // DECISIÓN: se ignora el horizontal si apunta recto arriba o abajo (_kx casi 0).
    if (abs(_kx) > 0.001 && (sign(hsp) != sign(_kx) || abs(_kx) > abs(hsp))) hsp = _kx;

    vsp += _ky - _force * WEAPON_KICK_LIFT;

    // Disparar agachado inicia un slide hacia atrás (biblia 4.4.3), siempre que el
    // retroceso tenga componente horizontal. Apuntando recto arriba _kx es ~0 y no hay
    // nada que deslizar. DECISIÓN: no se mira la velocidad resultante, porque armas de
    // retroceso bajo (SMG, kick 1) nunca superarían PLAYER_SLIDE_MIN_SPEED.
    if (crouching && abs(_kx) > 0.001) sliding = true;
}

/// @desc Lleva lo que sostiene el jugador a su mano. Sin esto, un objeto en la mano
///       se queda en el lugar donde se agarró (solo se dibujaba en la mano), y cualquier
///       cosa que dependa de su posición (la otra mitad de un cadáver colgando, por
///       ejemplo) no se enteraría de que se movió.
function player_update_held_position() {
    if (held_item == noone) return;
    var _ang = player_get_arm_angle();
    var _hx  = player_hand_x(_ang);
    var _hy  = player_hand_y(_ang);

    // Se guarda cómo se dibuja, por si el objeto lo necesita (ver corpse_joint_x).
    held_item.held_angle  = _ang;
    held_item.held_facing = facing;
    held_item.x = holdable_held_x(held_item, _hx, facing, _ang);
    held_item.y = holdable_held_y(held_item, _hy, facing, _ang);
}