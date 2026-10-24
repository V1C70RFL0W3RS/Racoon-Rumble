/// @desc Devuelve el sprite del cuerpo según el estado.
function player_get_sprite(_state) {
    switch (_state) {
        case PLAYER_STATE.RUN:    return spr_player_run;
        case PLAYER_STATE.JUMP:
        case PLAYER_STATE.FALL:   return spr_player_jump;
        case PLAYER_STATE.CROUCH: return spr_player_crouch;
        case PLAYER_STATE.SLIDE:  return spr_player_slide;
        // IDLE, HURT y DEAD: la pose quieta es el frame 0 de spr_player_run.
        default:                  return spr_player_run;
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
            // IDLE, CROUCH y SLIDE: un solo frame.
            image_index = 0;
            break;
    }
}


/// @desc Dirección BASE de apuntado, sin kick: 0 = derecha, 90 = arriba, 180 = izquierda.
///       arm_raise (0 a 1) levanta el brazo hacia 90 de forma gradual: el arma toca una
///       pared deslizando, o el jugador aletea con un arma en la mano.
function player_get_base_aim_angle() {
    if (aim_up) return 90;
    var _base = sliding ? player_get_slide_aim_angle() : ((facing == 1) ? 0 : 180);
    return lerp(_base, 90, arm_raise);
}
/// @desc Ángulo base del brazo al deslizar, SIN levantar. PLAYER_SLIDE_AIM_DEG es relativo
///       a hacia dónde mira: 0 = de frente, positivo = hacia arriba. Mirando a la izquierda
///       se espeja (180 - ángulo).
function player_get_slide_aim_angle() {
    return (facing == 1) ? PLAYER_SLIDE_AIM_DEG : 180 - PLAYER_SLIDE_AIM_DEG;
}

/// @desc Actualiza arm_raise una vez por Step. Con un arma en la mano, el brazo sube si
///       el jugador aletea, o si desliza y el arma está por tocar una pared. Se llama desde
///       el Step, no desde getters, porque hace una colisión y los getters se llaman varias
///       veces por frame.
function player_update_arm_raise() {
    var _target = 0;

    if (held_weapon != noone) {
        if (hovering) {
            _target = 1;
        } else if (sliding) {
            // DECISIÓN: se prueba SIEMPRE con el ángulo de slide sin levantar. Si se probara
            // con el brazo ya levantado, éste "liberaría" la pared, volvería a bajar y parpadearía.
            var _ang = player_get_slide_aim_angle();
            var _len = PLAYER_ARM_LENGTH + held_weapon.def.muzzle_x + PLAYER_ARM_WALL_MARGIN;
            var _sx  = player_shoulder_x();
            var _sy  = player_shoulder_y();

            var _blocked = (collision_line(_sx, _sy, _sx + lengthdir_x(_len, _ang),
                                           _sy + lengthdir_y(_len, _ang), tilemap, false, true) != noone);
            if (_blocked) _target = 1;
        }
    }

    arm_raise = approach(arm_raise, _target, PLAYER_ARM_RAISE_SPEED);
}
/// @desc Ángulo mundial del brazo, y del arma que sostiene: dirección base + kick.
///       Sin arma, el brazo cuelga (270), salvo aleteando (arriba) o deslizando (su propia pose).
function player_get_arm_angle() {
    // TEMPORAL: el afinador puede forzar un ángulo distinto en cada pose y frame.
    if (shoulder_tune) {
        var _forced = tune_angles[tune_pose][tune_frame];
        if (_forced != undefined) return _forced;
    }

    if (held_weapon == noone) {
        if (hovering) return 90;
        if (sliding)  return (facing == 1) ? PLAYER_SLIDE_ARM_FREE_DEG : 180 - PLAYER_SLIDE_ARM_FREE_DEG;
        return 270;
    }
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


// =============================================================================
// HOMBRO: tabla de ajustes por sprite y frame
// =============================================================================

/// @desc Crea la tabla de ajustes del hombro por frame, relativos a PLAYER_SHOULDER_X/Y.
///       Cada entrada es [dx, dy]: dx hacia adelante (positivo), dy hacia abajo (positivo).
///       Llamar UNA vez al arrancar (obj_game_manager, Create). Se afinan en vivo con
///       player_debug_tune_shoulder y se copian aquí con la tecla P.
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
        [0,  0],   // 0: despegue
        [1, -1],   // 1: subida
        [0, -2]    // 2: caída
    ];

    // spr_player_crouch y spr_player_slide: 1 frame cada uno.
    global.shoulder_offsets_crouch = [ [ 1, 4] ];
    global.shoulder_offsets_slide  = [ [-1, 7] ];
}

/// @desc Tabla de hombros de un sprite (un [dx, dy] por frame), o undefined si no tiene.
///       Único lugar que relaciona cada sprite con su tabla.
function player_get_shoulder_table(_spr) {
    switch (_spr) {
        case spr_player_run:    return global.shoulder_offsets_run;
        case spr_player_jump:   return global.shoulder_offsets_jump;
        case spr_player_crouch: return global.shoulder_offsets_crouch;
        case spr_player_slide:  return global.shoulder_offsets_slide;
    }
    return undefined;
}

/// @desc Ajuste [dx, dy] del hombro para el frame actual. Devuelve una referencia a la
///       entrada de la tabla (no crea arrays nuevos: se llama varias veces por frame).
function player_get_shoulder_offset() {
    var _t = player_get_shoulder_table(sprite_index);
    return (_t == undefined) ? global.shoulder_offset_zero : _t[image_index];
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


// =============================================================================
// TEMPORAL: depuración y afinador del hombro. Borrar toda esta sección al terminar.
// =============================================================================

/// @desc TEMPORAL: punto rojo en el hombro y amarillo en la mano, para afinar
///       PLAYER_SHOULDER_X/Y y PLAYER_ARM_LENGTH. Es una primitiva: se llama FUERA
///       del shader (después de palette_reset).
function player_debug_arm(_angle) {
    draw_point_color(shoulder_x, shoulder_y, c_red);
    draw_point_color(player_hand_x(_angle), player_hand_y(_angle), c_yellow);
}

/// @desc TEMPORAL: punto rojo en el hombro para afinar PLAYER_SHOULDER_X/Y.
///       Es una primitiva: se llama FUERA del shader (después de palette_reset).
function player_debug_shoulder() {
    draw_point_color(shoulder_x, shoulder_y, c_red);
}

/// @desc TEMPORAL: afinador del hombro en vivo. Solo lo maneja el jugador 1.
///       F1 activa/desactiva, F2 cambia de sprite, F3 cambia de frame,
///       I/K mueven el hombro arriba/abajo, J/L atrás/adelante (según hacia dónde mira),
///       U/O rotan el brazo +/- 15° (con Shift, de a 1°). El ángulo se recuerda POR pose y frame.
///       H devuelve ESTA pose y frame al ángulo automático. P imprime las tablas en la consola.
function player_debug_tune_shoulder() {
    if (player_index != 0) return;

    if (keyboard_check_pressed(vk_f1)) shoulder_tune = !shoulder_tune;
    if (!shoulder_tune) return;

    static _poses = [spr_player_run, spr_player_jump, spr_player_crouch, spr_player_slide];

    if (keyboard_check_pressed(vk_f2)) { tune_pose = (tune_pose + 1) mod array_length(_poses); tune_frame = 0; }
    var _spr = _poses[tune_pose];
    if (keyboard_check_pressed(vk_f3)) tune_frame = (tune_frame + 1) mod sprite_get_number(_spr);

    // La pose se fuerza DESPUÉS de player_update_animation, así que este Step manda sobre la animación.
    sprite_index = _spr;
    image_index  = tune_frame;

    // Mover el hombro.
    var _dx = keyboard_check_pressed(ord("L")) - keyboard_check_pressed(ord("J"));
    var _dy = keyboard_check_pressed(ord("K")) - keyboard_check_pressed(ord("I"));
    if (_dx != 0 || _dy != 0) {
        var _t = player_get_shoulder_table(_spr);
        var _o = _t[tune_frame];
        player_debug_set_shoulder(_spr, tune_frame, _o[0] + _dx, _o[1] + _dy);
    }

    // Rotar el brazo de ESTA pose y frame. Ángulo mundial: 0 = derecha, 90 = arriba, 180 = izquierda, 270 = abajo.
    var _rot = keyboard_check_pressed(ord("U")) - keyboard_check_pressed(ord("O"));
    if (_rot != 0) {
        var _step = keyboard_check(vk_shift) ? 1 : 15;
        // Parte del ángulo que tiene ahora (forzado o automático).
        var _new = (player_get_arm_angle() + _rot * _step) mod 360;
        if (_new < 0) _new += 360;   // en GML, mod conserva el signo del dividendo
        tune_angles[tune_pose][tune_frame] = _new;
        show_debug_message("brazo (pose " + string(tune_pose) + ", frame " + string(tune_frame) + "): " + string(_new) + " grados");
    }
    if (keyboard_check_pressed(ord("H"))) tune_angles[tune_pose][tune_frame] = undefined;

    if (keyboard_check_pressed(ord("P"))) {
        show_debug_message("---- tablas del hombro ----");
        show_debug_message("run:    " + string(global.shoulder_offsets_run));
        show_debug_message("jump:   " + string(global.shoulder_offsets_jump));
        show_debug_message("crouch: " + string(global.shoulder_offsets_crouch));
        show_debug_message("slide:  " + string(global.shoulder_offsets_slide));

        // Ángulos forzados con U/O: solo se imprimen los poses y frames donde giraste el brazo.
        for (var _p = 0; _p < array_length(_poses); _p++) {
            for (var _f = 0; _f < sprite_get_number(_poses[_p]); _f++) {
                var _a = tune_angles[_p][_f];
                if (_a != undefined) {
                    show_debug_message("angulo brazo: " + sprite_get_name(_poses[_p]) + " frame " + string(_f) + " = " + string(_a));
                }
            }
        }
    }
}
/// @desc TEMPORAL: escribe un ajuste en la tabla global del sprite. Se asigna un array
///       nuevo directamente en la variable global, sin depender de cómo GML comparte arrays.
function player_debug_set_shoulder(_spr, _frame, _dx, _dy) {
    switch (_spr) {
        case spr_player_run:    global.shoulder_offsets_run[_frame]    = [_dx, _dy]; break;
        case spr_player_jump:   global.shoulder_offsets_jump[_frame]   = [_dx, _dy]; break;
        case spr_player_crouch: global.shoulder_offsets_crouch[_frame] = [_dx, _dy]; break;
        case spr_player_slide:  global.shoulder_offsets_slide[_frame]  = [_dx, _dy]; break;
    }
}