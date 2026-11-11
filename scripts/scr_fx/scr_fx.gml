/// @file scr_fx
/// Efectos visuales con el sistema de partículas de GameMaker. ÚNICO lugar que los crea.
/// DECISIÓN: partículas en vez de un objeto por humito: no son instancias, no corren
/// Step ni colisiones, y cientos cuestan casi nada (importante en celular).

/// Efecto que suelta un holdable cuando lo golpea una bala (bandera hit_fx de obj_holdable).
/// Agregar un tipo = un valor aquí + un case en fx_holdable_hit (y en fx_holdable_break si se rompe).
enum HIT_FX { NONE, FUR, WOOD }

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

/// @desc Efecto (visual y sonido) de un holdable al recibir una bala, según su bandera hit_fx.
///       Lo llama holdable_take_shot. Las cajas agregarán aquí sus astillas.
/// @param {Id.Instance} _h Holdable golpeado.
/// @param {Real} _dir Dirección de la bala (grados).
function fx_holdable_hit(_h, _dir) {
    switch (_h.hit_fx) {
        case HIT_FX.FUR:
            fx_fur(_h.x, _h.y, _dir, FX_FUR_HIT_SPREAD, _h.color_index, FX_FUR_HIT_COUNT);
            break;
        case HIT_FX.WOOD:
            fx_splinters(_h.x, _h.y, _dir, FX_SPLINTER_HIT_SPREAD, FX_SPLINTER_HIT_COUNT);
            audio_play_sfx(snd_wood_hit, 0.1);
            break;
    }
}

/// @desc Efecto de un holdable al ROMPERSE, según su bandera hit_fx. Lo llama holdable_break.
function fx_holdable_break(_h, _dir) {
    switch (_h.hit_fx) {
        case HIT_FX.WOOD:
            fx_splinters(_h.x, _h.y, _dir, 180, FX_SPLINTER_BREAK_COUNT);   // en todas direcciones
            fx_smoke_puff(_h.x, _h.y);
            audio_play_sfx(snd_wood_break);
            break;
    }
}

// =============================================================================
// RESTOS (casquillos, pelo, y a futuro astillas)
// DECISIÓN: no son partículas, porque las partículas de GameMaker NO chocan con el mapa
// (el pelo atravesaba pisos y paredes). Tampoco son instancias: viven como structs en el
// arreglo `debris` de UN obj_fx_shells por room (lo crea obj_game_manager en Room Start).
// Chocan con tilemap_get_at_pixel (un punto, muy barato) y los que reposan no calculan nada.
// Cada resto lleva SUS parámetros de física: un solo update y un solo draw para todos.
// =============================================================================

/// @desc Crea un resto con la física de un casquillo. Quien lo crea cambia los campos
///       que necesite (ver fx_fur) y lo entrega a fx_debris_add.
function fx_debris_make(_x, _y, _hsp, _vsp, _len, _wid, _col) {
    return {
        x: _x, y: _y, hsp: _hsp, vsp: _vsp,
        angle: random(360),
        spin:  random_range(-25, 25),
        rest:  false,
        life:  SHELL_LIFE,
        fade:  SHELL_FADE,        // últimos frames en que se desvanece
        len: _len, wid: _wid, col: _col,
        // Física (valores de casquillo):
        grav:       SHELL_GRAVITY,
        max_fall:   SHELL_MAX_FALL,
        drag:       0,            // fracción de velocidad que pierde por frame en el aire
        bounce:     SHELL_BOUNCE,
        friction:   SHELL_FRICTION,
        rest_speed: SHELL_REST_SPEED,  // cayendo más lento que esto, se queda en el piso
        sway:       0,            // vaivén horizontal (px/frame); 0 = no se mece
        sway_rate:  0,            // grados de fase por frame
        phase:      random(360)
    };
}

/// @desc Agrega un resto al controlador de la room. Sin obj_fx_shells (menú) no hace nada.
function fx_debris_add(_d) {
    with (obj_fx_shells) {
        if (array_length(debris) >= FX_DEBRIS_MAX) array_delete(debris, 0, 1);   // el más viejo
        array_push(debris, _d);
    }
}

/// @desc Expulsa un casquillo desde la mano: hacia arriba y atrás, girando.
/// @param {Real} _x
/// @param {Real} _y
/// @param {Real} _facing 1 = mira a la derecha (el casquillo sale hacia la izquierda).
/// @param {Struct.WeaponDef} _def De aquí salen largo, grosor y color.
function fx_shell_spawn(_x, _y, _facing, _def) {
    if (_def.shell_len <= 0) return;
    fx_debris_add(fx_debris_make(_x, _y - 2,
        -_facing * random_range(0.8, 2), -random_range(1.5, 3),
        _def.shell_len, _def.shell_width, _def.shell_color));
}

/// @desc Mechones de pelo del color de un jugador, en un abanico alrededor de _dir. Salen
///       disparados, el aire los frena, caen despacio meciéndose y se quedan en el piso.
/// @param {Real} _x
/// @param {Real} _y
/// @param {Real} _dir Hacia dónde salen (la dirección de la bala).
/// @param {Real} _spread ± grados del abanico (180 = en todas direcciones).
/// @param {Real} _color_index Índice de paleta del jugador.
/// @param {Real} _count Cantidad de mechones.
function fx_fur(_x, _y, _dir, _spread, _color_index, _count) {
    var _c = global.player_palette[max(0, _color_index) mod array_length(global.player_palette)];
    repeat (_count) {
        var _a = _dir + random_range(-_spread, _spread);
        var _s = random_range(FX_FUR_SPEED_MIN, FX_FUR_SPEED_MAX);
        var _d = fx_debris_make(_x, _y, lengthdir_x(_s, _a), lengthdir_y(_s, _a),
                                FX_FUR_LEN, 1, merge_colour(_c.mid, _c.light, random(1)));
        _d.spin       = random_range(-FX_FUR_SPIN, FX_FUR_SPIN);
        _d.life       = irandom_range(FX_FUR_LIFE_MIN, FX_FUR_LIFE_MAX);
        _d.fade       = FX_FUR_FADE;
        _d.grav       = FX_FUR_GRAVITY;
        _d.drag       = FX_FUR_DRAG;
        _d.bounce     = 0;
        _d.rest_speed = infinity;   // no rebota: se posa al primer contacto
        _d.sway       = FX_FUR_SWAY;
        _d.sway_rate  = random_range(FX_FUR_SWAY_RATE * 0.7, FX_FUR_SWAY_RATE * 1.3);
        fx_debris_add(_d);
    }
}

/// @desc Astillas de madera: restos con física de casquillo (rebotan y se quedan en el piso).
/// @param {Real} _dir Hacia dónde salen (la dirección de la bala).
/// @param {Real} _spread ± grados del abanico (180 = en todas direcciones).
function fx_splinters(_x, _y, _dir, _spread, _count) {
    repeat (_count) {
        var _a = _dir + random_range(-_spread, _spread);
        var _s = random_range(FX_SPLINTER_SPEED_MIN, FX_SPLINTER_SPEED_MAX);
        var _d = fx_debris_make(_x, _y, lengthdir_x(_s, _a), lengthdir_y(_s, _a) - FX_SPLINTER_LIFT,
                                irandom_range(2, 4), 1, choose(FX_WOOD_COL_LIGHT, FX_WOOD_COL_DARK));
        _d.life = FX_SPLINTER_LIFE;
        fx_debris_add(_d);
    }
}

/// @desc Físicas de todos los restos. Llamar desde el Step de obj_fx_shells.
function fx_debris_update() {
    for (var i = array_length(debris) - 1; i >= 0; i--) {   // al revés: se puede borrar
        var _s = debris[i];
        _s.life--;
        if (_s.life <= 0) { array_delete(debris, i, 1); continue; }
        if (_s.rest) continue;   // en reposo no cuesta nada

        // Gravedad, y después el aire. Con drag > 0 hay velocidad terminal (cae parejo).
        _s.vsp += _s.grav;
        if (_s.drag > 0) {
            _s.hsp *= 1 - _s.drag;
            _s.vsp *= 1 - _s.drag;
        }
        _s.vsp = min(_s.vsp, _s.max_fall);

        // El vaivén se suma al movimiento horizontal, así también choca con las paredes.
        var _sx = 0;
        if (_s.sway != 0) {
            _sx = _s.sway * dsin(_s.phase);
            _s.phase += _s.sway_rate;
        }

        var _nx = _s.x + _s.hsp + _sx;
        if (tilemap_get_at_pixel(tilemap, _nx, _s.y) != 0) {
            _s.hsp  = -_s.hsp * _s.bounce;
            _s.spin = -_s.spin;
        } else {
            _s.x = _nx;
        }

        var _ny = _s.y + _s.vsp;
        if (tilemap_get_at_pixel(tilemap, _s.x, _ny) != 0) {
            if (_s.vsp > _s.rest_speed) {
                _s.vsp   = -_s.vsp * _s.bounce;
                _s.hsp  *= _s.friction;
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

/// @desc Dibuja todos los restos (una línea cada uno). Llamar desde el Draw de obj_fx_shells.
function fx_debris_draw() {
    for (var i = 0; i < array_length(debris); i++) {
        var _s  = debris[i];
        var _hx = lengthdir_x(_s.len / 2, _s.angle);
        var _hy = lengthdir_y(_s.len / 2, _s.angle);
        draw_set_alpha(min(1, _s.life / _s.fade));
        draw_line_width_colour(_s.x - _hx, _s.y - _hy, _s.x + _hx, _s.y + _hy, _s.wid, _s.col, _s.col);
    }
    draw_set_alpha(1);
}
