/// @description Movimiento del jugador: horizontal, salto, gravedad y colisión. Se llama una vez por Step desde obj_player.

/// @function player_update_movement
/// @description Punto único de entrada. El ORDEN importa: gravedad antes que salto, para que
///              el primer frame del salto quede exactamente en PLAYER_JUMP_FORCE.
function player_update_movement(_in) {
    player_update_crouch(_in);      // PRIMERO: decide agachado/slide antes de aplicar la física
    player_apply_horizontal(_in);
    player_apply_gravity();
    player_apply_jump(_in);
    player_move_and_collide();
}

/// @desc Decide si el jugador está agachado o deslizando. Solo actúa en el piso.
function player_update_crouch(_in) {
    // En el aire la pose se congela hasta aterrizar.
    // DECISIÓN: el retroceso de un arma levanta al jugador unos frames del suelo, y un
    // slide-jump debe conservar su pose. Si el aire borrara las banderas, ambos se cancelarían.
    if (!is_grounded) return;

    // Quiere estar bajo si aprieta "abajo", o si ya lo estaba y no cabe de pie (techo bajo).
    var _was_low   = crouching || sliding;
    var _wants_low = _in.down_held || (_was_low && !player_can_stand());

    if (!_wants_low) {
        crouching = false;
        sliding = false;
        return;
    }

    // "Abajo" corriendo inicia el slide. En el piso NO termina al frenar: la pose de
    // slide se mantiene hasta soltar "abajo" (o hasta saltar quieto, ver player_apply_jump).
    if (!sliding && abs(hsp) > PLAYER_SLIDE_MIN_SPEED) sliding = true;

    crouching = !sliding;
}


/// @desc ¿Cabe la máscara de pie en la posición actual? Se prueba sin cambiar de sprite.
/// DECISIÓN: sin esta comprobación, levantarse bajo un techo bajo dejaría la máscara
/// de pie incrustada en el tilemap y el jugador quedaría atrapado.
function player_can_stand() {
    return player_fits_mask(spr_player_run);   // todas las poses de pie comparten máscara
}

/// @desc ¿Cabe la máscara de _spr en la posición actual, sin chocar con el tilemap?
///       Se prueba sin cambiar de sprite.
/// @param {Asset.GMSprite} _spr Sprite cuya máscara se prueba.
function player_fits_mask(_spr) {
    mask_index = _spr;
    var _blocked = place_meeting(x, y, tilemap);
    mask_index = -1;               // -1 = volver a usar la máscara del sprite actual
    return !_blocked;
}


/// @desc Aceleración y fricción. Agachado o deslizando (en el piso o en el aire) no se
///       acelera y la fricción es baja: solo manda la inercia.
/// DECISIÓN: el slide-jump hereda esto, así conserva su velocidad y no se puede dirigir
/// en el aire hasta aterrizar (biblia 4.4.2: "la técnica de movimiento más rápida").
function player_apply_horizontal(_in) {
    var _low = crouching || sliding;

    if (!_low) {
        if (_in.move_x > 0 && hsp <  PLAYER_MOVE_SPEED) hsp = min(hsp + PLAYER_ACCEL,  PLAYER_MOVE_SPEED);
        if (_in.move_x < 0 && hsp > -PLAYER_MOVE_SPEED) hsp = max(hsp - PLAYER_ACCEL, -PLAYER_MOVE_SPEED);
    }

    var _fric = _low ? PLAYER_FRICTION * PLAYER_CROUCH_FRICTION_MULT : PLAYER_FRICTION;
    hsp = approach(hsp, 0, _fric);

    // Durante un slide no se gira: el cuerpo sigue mirando hacia donde iba.
    if (_in.move_x != 0 && !sliding) facing = sign(_in.move_x);
}
/// @description Gravedad lineal. El flap solo actúa al caer (vsp >= 0), así no choca con el corte de salto.
function player_apply_gravity() {
    vsp = min(vsp + PLAYER_GRAVITY, PLAYER_MAX_FALL_SPEED);

    if (hovering && vsp >= 0) {
        vsp = min(vsp, PLAYER_FLAP_MAX_FALL);
        vsp -= PLAYER_FLAP_LIFT;
    }
}
/// @desc Coyote, buffer, salto, corte único al soltar y activación del flap.
function player_apply_jump(_in) {
    coyote_timer = is_grounded ? PLAYER_COYOTE_FRAMES : max(coyote_timer - 1, 0);
    jump_buffer  = _in.jump_pressed ? PLAYER_JUMP_BUFFER_FRAMES : max(jump_buffer - 1, 0);

    var _jumped = false;
    var _can_jump = (jump_buffer > 0 && coyote_timer > 0);

    // No se salta con el techo encima estando bajo: el sprite de pie quedaría incrustado.
    if (_can_jump && (crouching || sliding) && !player_can_stand()) _can_jump = false;

    if (_can_jump) {
        vsp = PLAYER_JUMP_FORCE;
        is_grounded = false;
        coyote_timer = 0;
        jump_buffer = 0;
        jumping = true;
        _jumped = true;
        // Saltar agachado te levanta. Saltar deslizando EN MOVIMIENTO conserva la pose de
        // slide hasta aterrizar (y hsp no se toca, así que conserva toda la velocidad).
        // Saltar desde un slide ya detenido cambia a la pose de agachado.
        // DECISIÓN: se decide UNA vez, al despegar. Si se revisara en el aire, la fricción
        // frenaría el slide-jump a mitad del vuelo y cambiaría de pose sin motivo.
        // La máscara de agachado cabe: arriba ya se comprobó que cabe la de pie.
        if (sliding && abs(hsp) < PLAYER_SLIDE_STOP_SPEED) {
            sliding = false;
            crouching = true;
        } else {
            crouching = false;
        }
        state = PLAYER_STATE.JUMP;
    }

    if (!_in.jump_held) {
        if (jumping) {
            jumping = false;
            if (vsp < 0) vsp *= PLAYER_JUMP_CUT_MULT;
        }
        hovering = false;
    }

    // Flap: una pulsación NUEVA en el aire. No se aletea agachado ni deslizando (biblia P9: !crouch).
    if (!_jumped && !is_grounded && _in.jump_pressed && !crouching && !sliding) hovering = true;
    if (is_grounded) hovering = false;
}
/// @description Mueve y resuelve colisiones contra el tilemap, separado en X e Y.
function player_move_and_collide() {
    var _col_h = move_and_collide(hsp, 0, tilemap);
    if (array_length(_col_h) > 0) hsp = 0;

    if (vsp < 0) player_corner_correct();

    var _col_v = move_and_collide(0, vsp, tilemap);
    if (array_length(_col_v) > 0) {
        is_grounded = (vsp > 0);
        vsp = 0;
    } else {
        is_grounded = false;
    }
}

/// @description Si al subir la cabeza roza apenas la esquina de un tile, desplaza al jugador
///              hacia el lado libre en vez de frenarlo en seco.
/// DECISIÓN: solo corrige en X (nunca empuja hacia abajo ni hacia arriba) y solo hasta
/// PLAYER_CORNER_CORRECT_PX, para que no se sienta como un teletransporte.
function player_corner_correct() {
    if (!place_meeting(x, y + vsp, tilemap)) return;

    for (var _i = 1; _i <= PLAYER_CORNER_CORRECT_PX; _i++) {
        if (!place_meeting(x - _i, y + vsp, tilemap)) { x -= _i; return; }
        if (!place_meeting(x + _i, y + vsp, tilemap)) { x += _i; return; }
    }
}