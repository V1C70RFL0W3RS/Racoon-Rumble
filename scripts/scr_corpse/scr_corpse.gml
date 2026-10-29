/// @desc Tabla de puntos de unión: [dx, dy] en px respecto del origen de cada sprite.
///       Índice 0 = parte superior, 1 = inferior. Llamar UNA vez al arrancar
///       (obj_game_manager, Create). Se afina en vivo con corpse_debug_tune_joint.
function corpse_joint_init() {
    global.corpse_joint = [ [0, 3], [-3, -7] ];
    global.corpse_grip  = [ [0, 0], [0, 0] ];   // punto de sujeción [dx, dy]; 0 = superior, 1 = inferior

    // TEMPORAL: estado del afinador.
    global.corpse_tune_on    = false;
    global.corpse_tune_piece = 0;
    global.corpse_tune_mode  = 0;   // 0 = punto de unión, 1 = punto de sujeción
}

/// @desc Punto de sujeción [dx, dy] de una pieza según su frame lógico.
function corpse_grip_get(_frame) {
    return global.corpse_grip[(_frame == 1) ? 1 : 0];
}

/// @desc Punto de unión [dx, dy] de una pieza según su frame lógico.
function corpse_joint_get(_frame) {
    return global.corpse_joint[(_frame == 1) ? 1 : 0];
}


/// @desc Crea las dos piezas de un cadáver, ensambladas por su punto de unión. ÚNICO
///       lugar donde se crean piezas, igual que projectile_spawn con las balas.
function corpse_spawn(_x, _y, _facing, _hsp, _vsp, _color_index) {
    // Frame 2 = parte superior muerta (sin pupila); frame 1 = parte inferior.
    var _frames = [2, 1];
    var _pieces = [noone, noone];

    // DECISIÓN: la velocidad se calcula UNA vez y la comparten las dos piezas.
    var _h = _hsp * CORPSE_INERTIA;
    var _v = _vsp + CORPSE_POP_SPEED;

    for (var _i = 0; _i < 2; _i++) {
        // Cada pieza nace con SU punto de unión en el mismo lugar del mundo.
        var _j  = corpse_joint_get(_frames[_i]);
        var _px = _x - _j[0] * _facing;
        var _py = _y + CORPSE_SPAWN_JOINT_Y - _j[1];
        var _p = instance_create_layer(_px, _py, "layer_items", obj_corpse_piece,
                                       { piece_frame: _frames[_i], color_index: _color_index });

        // DECISIÓN: la velocidad va DESPUÉS de crear la pieza, porque el Create
        // de obj_holdable la pone en cero.
        _p.image_xscale = _facing;
        _p.hsp = _h;
        _p.vsp = _v;
        with (_p) corpse_apply_frame();   // sprite ya puesto: así su máscara existe desde ahora
        _pieces[_i] = _p;
    }

    // Se enlazan DESPUÉS de crear las dos: la primera no puede conocer a la segunda antes.
    _pieces[0].partner = _pieces[1];
    _pieces[1].partner = _pieces[0];

    // Si el cadáver nació con alguna pieza dentro del mapa (pegado a una pared o con los pies
    // en el piso), se desplaza el CONJUNTO por el camino más corto: arriba, a un lado o en
    // diagonal. Se mueven las dos piezas a la vez para que no se separen.
    var _k = 0;
    var _found = corpse_pair_free(_pieces[0], _pieces[1], 0, 0);
    for (var _d = 1; _d <= CORPSE_SPAWN_PUSHOUT && !_found; _d++) {
        for (_k = 0; _k < 5 && !_found; _k++) {
            var _ox = 0;
            var _oy = 0;
            switch (_k) {
                case 0: _oy = -_d; break;                  // arriba
                case 1: _ox =  _d; break;                  // derecha
                case 2: _ox = -_d; break;                  // izquierda
                case 3: _ox =  _d; _oy = -_d; break;       // arriba-derecha
                case 4: _ox = -_d; _oy = -_d; break;       // arriba-izquierda
            }
            if (corpse_pair_free(_pieces[0], _pieces[1], _ox, _oy)) {
                _pieces[0].x += _ox; _pieces[0].y += _oy;
                _pieces[1].x += _ox; _pieces[1].y += _oy;
                _found = true;
            }
        }
    }
}

// =============================================================================
// TEMPORAL: afinador del punto de unión. Borrar esta sección al terminar.
// =============================================================================


/// @desc TEMPORAL: F5 activa, F6 cambia de pieza, F7 cambia entre punto de UNIÓN y de
///       SUJECIÓN, Numpad 4/6/8/2 lo mueven (1 px), P imprime las tablas.
function corpse_debug_tune_joint() {
    if (player_index != 0) return;

    if (keyboard_check_pressed(vk_f5)) global.corpse_tune_on = !global.corpse_tune_on;
    if (!global.corpse_tune_on) return;

    if (keyboard_check_pressed(vk_f6)) global.corpse_tune_piece = 1 - global.corpse_tune_piece;
    if (keyboard_check_pressed(vk_f7)) global.corpse_tune_mode  = 1 - global.corpse_tune_mode;

    var _i  = global.corpse_tune_piece;
    var _dx = keyboard_check_pressed(vk_numpad6) - keyboard_check_pressed(vk_numpad4);
    var _dy = keyboard_check_pressed(vk_numpad2) - keyboard_check_pressed(vk_numpad8);
    if (global.corpse_tune_mode == 0) {
        global.corpse_joint[_i][0] += _dx;
        global.corpse_joint[_i][1] += _dy;
    } else {
        global.corpse_grip[_i][0] += _dx;
        global.corpse_grip[_i][1] += _dy;
    }

    if (keyboard_check_pressed(ord("P"))) {
        show_debug_message("corpse_joint (superior, inferior): " + string(global.corpse_joint));
        show_debug_message("corpse_grip  (superior, inferior): " + string(global.corpse_grip));
    }
}
/// @desc TEMPORAL: dibuja las dos mitades ensambladas a 4x en el centro de la vista.
///       Punto rojo = unión; punto verde = sujeción de cada pieza. Llamar FUERA del shader.
function corpse_debug_draw_joint() {
    if (player_index != 0 || !global.corpse_tune_on) return;

    var _s  = 4;
    var _cx = camera_get_view_x(view_camera[0]) + camera_get_view_width(view_camera[0]) * 0.5;
    var _cy = camera_get_view_y(view_camera[0]) + camera_get_view_height(view_camera[0]) * 0.5;
    var _ju = global.corpse_joint[0];
    var _jl = global.corpse_joint[1];
    var _gu = global.corpse_grip[0];
    var _gl = global.corpse_grip[1];

    draw_sprite_ext(spr_corpse_lower, 0, _cx - _jl[0] * _s, _cy - _jl[1] * _s, _s, _s, 0, c_white, 1);
    draw_sprite_ext(spr_corpse_upper, 0, _cx - _ju[0] * _s, _cy - _ju[1] * _s, _s, _s, 0, c_white, 1);
    draw_circle_color(_cx, _cy, 2, c_red, c_red, false);   // punto de unión

    // Sujeción de cada pieza: origen de la pieza + su punto de sujeción.
    draw_circle_color(_cx + (_gu[0] - _ju[0]) * _s, _cy + (_gu[1] - _ju[1]) * _s, 2, c_lime, c_lime, false);
    draw_circle_color(_cx + (_gl[0] - _jl[0]) * _s, _cy + (_gl[1] - _jl[1]) * _s, 2, c_aqua, c_aqua, false);

    draw_text(_cx - 70, _cy + 70, ((global.corpse_tune_mode == 0) ? "UNION" : "SUJECION")
              + " | pieza: " + ((global.corpse_tune_piece == 0) ? "superior" : "inferior"));
}

/// @desc TEMPORAL: avisa si algún valor de la pieza dejó de ser un número válido, o si la
///       velocidad se dispara. Dice EN QUÉ PUNTO del Step lo detectó.
function corpse_debug_check(_label) {
    var _vals = [x, y, hsp, vsp, angle, spin, image_xscale, image_yscale, grip_x, grip_y];
    var _bad = (abs(hsp) > 40 || abs(vsp) > 40);
    for (var _i = 0; _i < array_length(_vals); _i++) {
        if (is_nan(_vals[_i]) || is_infinity(_vals[_i])) _bad = true;
    }
    if (!_bad) return;

    var _ph = (partner != noone && instance_exists(partner)) ? string(partner.holder) : "-";
    show_debug_message("CORPSE INVALIDO en '" + _label + "': pieza=" + string(piece_frame)
        + " x=" + string(x) + " y=" + string(y)
        + " hsp=" + string(hsp) + " vsp=" + string(vsp)
        + " angle=" + string(angle) + " spin=" + string(spin)
        + " xscale=" + string(image_xscale) + " yscale=" + string(image_yscale)
        + " holder=" + string(holder) + " partner.holder=" + _ph);
}

/// @desc Resuelve la pareja del cadáver UNA vez por frame, como Duck Game (biblia 4.4.5): una
///       varilla de longitud fija entre las dos piezas, y el ángulo sale de su dirección.
///       Se llama desde la parte superior, en su Begin Step, antes de que ninguna se mueva.
/// @param {Id.Instance} _u Parte superior.
/// @param {Id.Instance} _w Parte inferior.
function corpse_pair_update(_u, _w) {
    // Hacia dónde miran las dos: manda quien las sostiene; si nadie, la superior.
    var _xs = _u.image_xscale;
    if (_u.holder != noone)      _xs = _u.holder.facing;
    else if (_w.holder != noone) _xs = _w.holder.facing;
    _u.image_xscale = _xs;
    _w.image_xscale = _xs;

    // Vector de reposo: de la superior a la inferior cuando están ensambladas (sale de los
    // puntos de unión de la tabla). Su longitud es la de la varilla.
    var _ju = global.corpse_joint[0];
    var _jl = global.corpse_joint[1];
    var _rx = (_ju[0] - _jl[0]) * _xs;
    var _ry = _ju[1] - _jl[1];
    var _len = point_distance(0, 0, _rx, _ry);
    if (_len < 0.001) return;   // tabla sin separación: no hay varilla que resolver

    var _dx = _w.x - _u.x;
    var _dy = _w.y - _u.y;
    var _d  = point_distance(0, 0, _dx, _dy);

    // Salvaguarda (biblia 4.4.5 C): si se separaron demasiado, se reencuentran sin velocidad.
    if (_d > _len * CORPSE_SNAP_FACTOR) {
        if (_u.holder == noone) { _u.x = _w.x - _rx; _u.y = _w.y - _ry; }
        else                    { _w.x = _u.x + _rx; _w.y = _u.y + _ry; }
        _u.hsp = 0; _u.vsp = 0;
        _w.hsp = 0; _w.vsp = 0;
        _dx = _w.x - _u.x;
        _dy = _w.y - _u.y;
        _d  = point_distance(0, 0, _dx, _dy);
    }

    // Dirección de una a otra. Si coinciden en el mismo punto, se usa la de reposo.
    if (_d < 0.001) { _dx = _rx; _dy = _ry; _d = _len; }
    var _nx = _dx / _d;
    var _ny = _dy / _d;

    // La pieza en una mano es el punto fijo: no se corrige, y cuenta con la velocidad de quien
    // la lleva. (Duck Game reparte la corrección a medias; así la que cuelga recibe toda.)
    var _uh = (_u.holder != noone);
    var _wh = (_w.holder != noone);
    var _uvx = _uh ? _u.holder.hsp : _u.hsp;
    var _uvy = _uh ? _u.holder.vsp : _u.vsp;
    var _wvx = _wh ? _w.holder.hsp : _w.hsp;
    var _wvy = _wh ? _w.holder.vsp : _w.vsp;

    // Impulso corrector (Ragdoll.Solve): anula la velocidad relativa a lo largo de la varilla
    // y corrige el error de distancia, todo en un solo paso.
    var _rel = (_wvx - _uvx) * _nx + (_wvy - _uvy) * _ny;
    var _err = _d - _len;
    var _imu = _uh ? 0 : 1;
    var _imw = _wh ? 0 : 1;
    if (_imu + _imw > 0) {
        var _imp = (_rel + _err) / (_imu + _imw);
        _u.hsp += _nx * _imp * _imu;
        _u.vsp += _ny * _imp * _imu;
        _w.hsp -= _nx * _imp * _imw;
        _w.vsp -= _ny * _imp * _imw;
    }

    // El ángulo NO se simula: sale de la dirección entre las dos piezas, medida contra la
    // dirección que tienen ensambladas. Las dos usan el mismo, así que ambas giran.
    var _a = point_direction(_u.x, _u.y, _w.x, _w.y) - point_direction(0, 0, _rx, _ry);
    _u.angle = _a;
    _w.angle = _a;
}

/// @desc Distancia entre los orígenes de las dos piezas cuando están ensambladas.
function corpse_rest_length() {
    var _ju = global.corpse_joint[0];
    var _jl = global.corpse_joint[1];
    return point_distance(0, 0, _ju[0] - _jl[0], _ju[1] - _jl[1]);
}

/// @desc Fija sprite e imagen de la pieza según su frame lógico: 0 = superior viva,
///       1 = inferior, 2 = superior muerta. Ejecutar como la pieza.
function corpse_apply_frame() {
    sprite_index = (piece_frame == 1) ? spr_corpse_lower : spr_corpse_upper;
    image_index  = (piece_frame == 2) ? 1 : 0;
}

/// @desc ¿Quedan las dos piezas libres del mapa si se las desplaza (_ox, _oy)? Se prueba con la
///       máscara de CADA pieza, por eso se hace dentro de ellas (with).
function corpse_pair_free(_a, _b, _ox, _oy) {
    var _free = true;
    with (_a) { if (place_meeting(x + _ox, y + _oy, tilemap)) _free = false; }
    with (_b) { if (place_meeting(x + _ox, y + _oy, tilemap)) _free = false; }
    return _free;
}