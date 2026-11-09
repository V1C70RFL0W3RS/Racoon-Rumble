/// @file scr_fx
/// Efectos visuales con el sistema de partículas de GameMaker. ÚNICO lugar que los crea.
/// DECISIÓN: partículas en vez de un objeto por humito: no son instancias, no corren
/// Step ni colisiones, y cientos cuestan casi nada (importante en celular).

/// @desc Crea los TIPOS de partícula (son globales y duran todo el juego).
///       Se llama UNA vez en el Create de obj_game_manager.
function fx_init() {
    global.fx_system = -1;   // el sistema se crea al usarlo (ver fx_get_system)

    var _t = part_type_create();
    part_type_shape(_t, pt_shape_square);
    part_type_size(_t, 0.04, 0.07, -0.001, 0);
    part_type_colour2(_t, c_ltgray, c_gray);
    part_type_alpha2(_t, 0.9, 0);
    part_type_speed(_t, 0.2, 0.6, -0.01, 0);
    part_type_direction(_t, 45, 135, 0, 0);
    part_type_gravity(_t, 0.01, 90);   // sube despacio
    part_type_life(_t, 20, 35);
    global.fx_smoke = _t;

    // Chispas de bala contra pared: rápidas, frenan en seco y caen.
    var _s = part_type_create();
    part_type_shape(_s, pt_shape_square);
    part_type_size(_s, 0.02, 0.035, 0, 0);
    part_type_colour3(_s, c_white, c_yellow, c_orange);
    part_type_alpha2(_s, 1, 0);
    part_type_speed(_s, 1, 2.5, -0.1, 0);
    part_type_gravity(_s, 0.15, 270);
    part_type_life(_s, 8, 16);
    global.fx_spark = _s;

    // Fogonazo: muy corto (3-6 frames), sale hacia adelante y frena en seco.
    var _m = part_type_create();
    part_type_shape(_m, pt_shape_square);
    part_type_size(_m, 0.03, 0.05, -0.004, 0);
    part_type_colour3(_m, c_white, c_yellow, c_orange);
    part_type_alpha2(_m, 1, 0.3);
    part_type_speed(_m, 0.5, 2.5, -0.25, 0);
    part_type_life(_m, 3, 6);
    global.fx_muzzle = _m;

    // Humo del cañón: volutas finas que suben despacio y se mecen.
    var _b = part_type_create();
    part_type_shape(_b, pt_shape_square);
    part_type_size(_b, 0.02, 0.035, 0.0006, 0);
    part_type_colour2(_b, c_ltgray, c_gray);
    part_type_alpha3(_b, 0, 0.6, 0);
    part_type_speed(_b, 0.15, 0.35, 0, 0);
    part_type_direction(_b, 80, 100, 0, 6);   // el último valor hace que se mezan
    part_type_life(_b, 30, 50);
    global.fx_barrel_smoke = _b;
}

/// @desc Devuelve el sistema de partículas de la room actual, creándolo si hace falta.
///       DECISIÓN: se crea al usarlo porque el sistema se pierde al cambiar de room;
///       así ningún efecto falla en una room recién cargada.
function fx_get_system() {
    if (!part_system_exists(global.fx_system)) {
        global.fx_system = layer_exists("layer_effects")
            ? part_system_create_layer("layer_effects", false)
            : part_system_create();
    }
    return global.fx_system;
}

/// @desc Bocanada de humo en un punto (arma que desaparece, etc.).
function fx_smoke_puff(_x, _y) {
    part_particles_create(fx_get_system(), _x, _y, global.fx_smoke, FX_SMOKE_COUNT);
}

/// @desc Chispas donde una bala choca con una pared. Saltan hacia atrás, en un
///       abanico alrededor de la dirección opuesta a la bala.
/// @param {Real} _x
/// @param {Real} _y
/// @param {Real} _dir Dirección en que viajaba la bala (grados).
function fx_bullet_sparks(_x, _y, _dir) {
    var _back = _dir + 180;
    part_type_direction(global.fx_spark, _back - FX_SPARK_SPREAD, _back + FX_SPARK_SPREAD, 0, 0);
    part_particles_create(fx_get_system(), _x, _y, global.fx_spark, FX_SPARK_COUNT);
}

/// @desc Fogonazo en la boca del cañón: partículas hacia adelante, en un cono estrecho.
/// @param {Real} _x Boca del cañón.
/// @param {Real} _y
/// @param {Real} _dir Dirección del disparo (grados).
/// @param {Real} _count Partículas (cada arma define el tamaño de su fogonazo).
function fx_muzzle_flash(_x, _y, _dir, _count) {
    if (_count <= 0) return;
    part_type_direction(global.fx_muzzle, _dir - FX_MUZZLE_SPREAD, _dir + FX_MUZZLE_SPREAD, 0, 0);
    part_particles_create(fx_get_system(), _x, _y, global.fx_muzzle, _count);
}


/// @desc Una voluta de humo de cañón (ver weapon_update_smoke).
function fx_barrel_smoke(_x, _y) {
    part_particles_create(fx_get_system(), _x, _y, global.fx_barrel_smoke, 1);
}

// =============================================================================
// CASQUILLOS
// DECISIÓN: no son instancias. Viven en el arreglo `shells` de UN obj_fx_shells por
// room (lo crea obj_game_manager en Room Start). Chocan con tilemap_get_at_pixel
// (un punto, muy barato) y los que ya reposan no calculan nada: solo se dibujan.
// =============================================================================

/// @desc Expulsa un casquillo desde la mano: hacia arriba y atrás, girando.
///       Si la room no tiene obj_fx_shells (menú, lobby sin efectos) no hace nada.
/// @param {Real} _x
/// @param {Real} _y
/// @param {Real} _facing 1 = mira a la derecha (el casquillo sale hacia la izquierda).
/// @param {Struct.WeaponDef} _def De aquí salen largo, grosor y color.
function fx_shell_spawn(_x, _y, _facing, _def) {
    if (_def.shell_len <= 0) return;
    with (obj_fx_shells) {
        if (array_length(shells) >= SHELL_MAX) array_delete(shells, 0, 1);   // el más viejo
        array_push(shells, {
            x: _x, y: _y - 2,
            hsp: -_facing * random_range(0.8, 2),
            vsp: -random_range(1.5, 3),
            angle: random(360),
            spin:  random_range(-25, 25),
            rest:  false,
            life:  SHELL_LIFE,
            len:   _def.shell_len,
            wid:   _def.shell_width,
            col:   _def.shell_color
        });
    }
}

/// @desc Físicas de todos los casquillos. Llamar desde el Step de obj_fx_shells.
function fx_shells_update() {
    for (var i = array_length(shells) - 1; i >= 0; i--) {   // al revés: se puede borrar
        var _s = shells[i];
        _s.life--;
        if (_s.life <= 0) { array_delete(shells, i, 1); continue; }
        if (_s.rest) continue;   // en reposo no cuesta nada

        _s.vsp = min(_s.vsp + SHELL_GRAVITY, SHELL_MAX_FALL);

        var _nx = _s.x + _s.hsp;
        if (tilemap_get_at_pixel(tilemap, _nx, _s.y) != 0) {
            _s.hsp  = -_s.hsp * SHELL_BOUNCE;
            _s.spin = -_s.spin;
        } else {
            _s.x = _nx;
        }

        var _ny = _s.y + _s.vsp;
        if (tilemap_get_at_pixel(tilemap, _s.x, _ny) != 0) {
            if (_s.vsp > SHELL_REST_SPEED) {
                _s.vsp   = -_s.vsp * SHELL_BOUNCE;
                _s.hsp  *= SHELL_FRICTION;
                _s.spin *= 0.5;
            } else if (_s.vsp > 0) {
                // Se queda acostado: el ángulo se lleva a 0 o 180, el más cercano.
                _s.rest = true;
                _s.vsp = 0;
                _s.hsp = 0;
                _s.angle = (abs(angle_difference(_s.angle, 0)) < 90) ? 0 : 180;
            } else {
                _s.vsp = 0;   // techo
            }
        } else {
            _s.y = _ny;
        }

        _s.angle += _s.spin;
    }
}

/// @desc Dibuja todos los casquillos. Llamar desde el Draw de obj_fx_shells.
function fx_shells_draw() {
    for (var i = 0; i < array_length(shells); i++) {
        var _s  = shells[i];
        var _hx = lengthdir_x(_s.len / 2, _s.angle);
        var _hy = lengthdir_y(_s.len / 2, _s.angle);
        draw_set_alpha(min(1, _s.life / SHELL_FADE));
        draw_line_width_colour(_s.x - _hx, _s.y - _hy, _s.x + _hx, _s.y + _hy, _s.wid, _s.col, _s.col);
    }
    draw_set_alpha(1);
}
