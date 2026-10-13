/// @desc Devuelve el sprite del cuerpo según el estado.
function player_get_sprite(_state) {
    switch (_state) {
        case PLAYER_STATE.RUN:   return spr_player_run;
        case PLAYER_STATE.JUMP:
        case PLAYER_STATE.FALL:  return spr_player_jump;
        case PLAYER_STATE.SLIDE: return spr_player_slide;
        // IDLE, HURT y DEAD: la pose quieta es el frame 0 de spr_player_run.
        default:                 return spr_player_run;
    }
}

/// @desc Elige sprite y frame del jugador. Se llama desde el Step (no desde el
///       Draw) para que la máscara de colisión cambie junto con el sprite.
function player_update_animation() {
    var _spr = player_get_sprite(state);
    if (sprite_index != _spr) {
        sprite_index = _spr;
        anim_time = 0;
    }

    switch (state) {
        case PLAYER_STATE.RUN:
            // DECISIÓN: el frame 0 es la pose quieta, así que el ciclo usa los
            // frames 1..N-1. Cuanto más rápido corre, más rápido avanza.
            anim_time += abs(hsp) * PLAYER_RUN_ANIM_RATE;
            image_index = 1 + (floor(anim_time) mod (sprite_get_number(sprite_index) - 1));
            break;

        case PLAYER_STATE.JUMP:
            // Frame 0 = despegue (unos pocos steps), frame 1 = subida.
            anim_time++;
            image_index = (anim_time < PLAYER_JUMP_START_FRAMES) ? 0 : 1;
            break;

        case PLAYER_STATE.FALL:
            image_index = 2; // caída
            break;

        default:
            image_index = 0;
            break;
    }
}


/// @desc Dirección BASE de apuntado, sin kick: 0 = derecha, 90 = arriba, 180 = izquierda.
function player_get_base_aim_angle() {
    if (aim_up) return 90;
    return (facing == 1) ? 0 : 180;
}


/// @desc Ángulo mundial del brazo, y del arma que sostiene: dirección base + kick.
///       Sin arma, el brazo cuelga (270).
function player_get_arm_angle() {
    if (held_weapon == noone) return 270;
    return weapon_get_aim_angle(held_weapon, player_get_base_aim_angle(), facing);
}

/// @desc Posición X de la mano (agarre del arma) para un ángulo de brazo dado.
function player_hand_x(_angle) {
    return player_shoulder_x() + lengthdir_x(PLAYER_ARM_LENGTH, _angle);
}

/// @desc Posición Y de la mano (agarre del arma) para un ángulo de brazo dado.
function player_hand_y(_angle) {
    return player_shoulder_y() + lengthdir_y(PLAYER_ARM_LENGTH, _angle);
}
/// @desc Dibuja el brazo en el hombro con el ángulo dado. Debe llamarse con el shader
///       de color activo (entre palette_apply y palette_reset).
function player_draw_arm(_angle) {
    // Se guarda en la instancia para que la depuración reutilice la posición.
    shoulder_x = player_shoulder_x();
    shoulder_y = player_shoulder_y();

    draw_sprite_ext(spr_player_arm, 0, shoulder_x, shoulder_y, 1, facing, _angle, c_white, 1);
}

/// @desc TEMPORAL: punto rojo en el hombro y amarillo en la mano, para afinar
///       PLAYER_SHOULDER_X/Y y PLAYER_ARM_LENGTH. Es una primitiva: se llama FUERA
///       del shader (después de palette_reset). Borrar al terminar de afinar.
function player_debug_arm(_angle) {
    draw_point_color(shoulder_x, shoulder_y, c_red);
    draw_point_color(player_hand_x(_angle), player_hand_y(_angle), c_yellow);
}

/// @desc TEMPORAL: punto rojo en el hombro para afinar PLAYER_SHOULDER_X/Y.
///       Es una primitiva: se llama FUERA del shader (después de palette_reset).
///       Borrar al terminar de afinar.
function player_debug_shoulder() {
    draw_point_color(shoulder_x, shoulder_y, c_red);
}


/// @desc Crea la tabla de ajustes del hombro por frame, relativos a PLAYER_SHOULDER_X/Y.
///       Cada entrada es [dx, dy]: dx hacia adelante (positivo), dy hacia abajo (positivo).
///       Llamar UNA vez al arrancar (obj_game_manager, Create). Los ceros son de partida:
///       se completan mirando cada frame en el editor de sprites (ver abajo).
function player_shoulder_table_init() {
    global.shoulder_offset_zero = [0, 0];

    // spr_player_run: 6 frames (el 0 es la pose quieta, el ciclo usa 1..5)
    global.shoulder_offsets_run = [
        [0,  0],   // 0: quieto (referencia)
        [0, -2],   // 1
        [0, -1],   // 2
        [0,  0],   // 3
        [0, -2],   // 4
        [0, -1]    // 5
    ];

    // spr_player_jump: 3 frames (despegue, subida, caída)
    global.shoulder_offsets_jump = [
        [0, 0], [0, 0], [0, 0]
    ];
}

/// @desc Ajuste [dx, dy] del hombro para el frame actual. Devuelve una referencia a la
///       entrada de la tabla (no crea arrays nuevos: se llama varias veces por frame).
function player_get_shoulder_offset() {
    switch (sprite_index) {
        case spr_player_run:  return global.shoulder_offsets_run[image_index];
        case spr_player_jump: return global.shoulder_offsets_jump[image_index];
        default:              return global.shoulder_offset_zero;
    }
}

/// @desc Posición X del hombro en el mundo. facing espeja el lado al mirar a la izquierda.
function player_shoulder_x() {
    var _o = player_get_shoulder_offset();
    return x + facing * (PLAYER_SHOULDER_X + _o[0]);
}

/// @desc Posición Y del hombro en el mundo.
function player_shoulder_y() {
    var _o = player_get_shoulder_offset();
    return y + PLAYER_SHOULDER_Y + _o[1];
}
