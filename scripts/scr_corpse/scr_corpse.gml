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


/// @desc Crea las dos piezas de un cuerpo (cadáver o ragdoll), ensambladas por su punto de unión,
///       y la cintura invisible que las une. ÚNICO lugar donde se crean piezas, igual que
///       projectile_spawn con las balas. La velocidad la decide quien llama (muerte o ragdoll).
/// @param {Real} _hsp Velocidad horizontal con que nace el cuerpo entero.
/// @param {Real} _vsp Velocidad vertical.
/// @param {Real} [_tumble] Volteo: la parte de arriba sale con +_tumble y la de abajo con -_tumble
///        (px/frame). Hace que el cuerpo gire al nacer, sin cambiar hacia dónde va en conjunto.
/// @param {Id.Instance} [_body_of] Jugador VIVO dueño del cuerpo (modo ragdoll). noone = cadáver.
/// @returns {Struct} { upper, lower }: las dos piezas.
function corpse_spawn(_x, _y, _facing, _hsp, _vsp, _color_index, _tumble = 0, _body_of = noone) {
    // Parte superior: frame 2 = muerta (sin pupila), frame 0 = viva (ragdoll). Frame 1 = inferior.
    var _frames  = [(_body_of != noone) ? 0 : 2, 1];
    var _tumbles = [_tumble, -_tumble];
    var _pieces  = [noone, noone];

    // La cintura (punto de unión) queda a esta altura respecto de los pies del jugador.
    var _jx = _x;
    var _jy = _y + CORPSE_SPAWN_JOINT_Y;

    for (var _i = 0; _i < 2; _i++) {
        // Cada pieza nace con SU punto de unión en la cintura.
        var _j  = corpse_joint_get(_frames[_i]);
        var _px = _jx - _j[0] * _facing;
        var _py = _jy - _j[1];
        var _p = instance_create_layer(_px, _py, "layer_items", obj_corpse_piece,
                                       { piece_frame: _frames[_i], color_index: _color_index });

        // DECISIÓN: la velocidad va DESPUÉS de crear la pieza, porque el Create
        // de obj_holdable la pone en cero.
        _p.image_xscale = _facing;
        _p.body_of = _body_of;
        _p.hsp = _hsp + _tumbles[_i];
        _p.vsp = _vsp;
        with (_p) corpse_apply_frame();   // sprite ya puesto: así su máscara existe desde ahora
        _pieces[_i] = _p;
    }

    // Se enlazan DESPUÉS de crear las dos: la primera no puede conocer a la segunda antes.
    _pieces[0].partner = _pieces[1];
    _pieces[1].partner = _pieces[0];
    _pieces[0].rig = corpse_rig_create(_jx, _jy, _hsp, _vsp);   // la cintura vive en la superior

    // Si el cuerpo nació con alguna pieza dentro del mapa (pegado a una pared o con los pies
    // en el piso), se desplaza el CONJUNTO por el camino más corto: arriba, a un lado o en
    // diagonal. Se mueven las dos piezas (y la cintura) a la vez para que no se separen.
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
                _pieces[0].rig.jx += _ox; _pieces[0].rig.jy += _oy;
                _found = true;
            }
        }
    }

    return { upper: _pieces[0], lower: _pieces[1] };
}

/// @desc Cintura de un cuerpo + los "cuerpos de trabajo" del solucionador. Se crea UNA vez por
///       cuerpo (corpse_spawn) y se reutiliza cada frame: sin asignaciones por frame.
function corpse_rig_create(_jx, _jy, _hsp, _vsp) {
    return {
        jx: _jx, jy: _jy, jvx: _hsp, jvy: _vsp,   // cintura: posición y velocidad
        bu: { x: 0, y: 0, vx: 0, vy: 0, im: 1 },   // parte superior
        bj: { x: 0, y: 0, vx: 0, vy: 0, im: 1 },   // cintura
        bw: { x: 0, y: 0, vx: 0, vy: 0, im: 1 }    // parte inferior
    };
}

/// @desc Dibuja sobre una pieza de ragdoll lo que su dueño lleva puesto: el chaleco (cuerpo) en la
///       parte superior, el calzado (pies) en la inferior. El gorro no: se cae al tirarse. Gira con
///       la pieza (mismo convenio que holdable_held_x: escala y luego giro).
function corpse_draw_worn(_p, _x, _y, _xscale, _angle) {
    var _owner = _p.body_of;
    if (!instance_exists(_owner)) return;
    var _lower = (_p.piece_frame == 1);
    var _spec  = _owner.equipped[_lower ? EQUIP_SLOT.FEET : EQUIP_SLOT.BODY];
    if (_spec == undefined) return;

    // Botas: se pintan los pies de la pieza, igual que sobre el jugador.
    if (_lower) {
        equip_draw_feet(_spec, _p.sprite_index, _p.image_index, _x, _y, _xscale, _angle);
        return;
    }
    var _ox = CORPSE_WORN_BODY_X * _xscale;
    var _oy = CORPSE_WORN_BODY_Y;
    draw_sprite_ext(_spec.sprite, _spec.frame,
                    _x + _ox * dcos(_angle) + _oy * dsin(_angle),
                    _y - _ox * dsin(_angle) + _oy * dcos(_angle),
                    _xscale, 1, _angle, c_white, 1);
}

/// @desc El cuerpo de un ragdoll pasa a ser un cadáver: deja de tener dueño y la parte superior
///       cierra los ojos (frame muerto). Las piezas siguen donde están, con su velocidad.
function corpse_pair_kill(_upper, _lower) {
    if (instance_exists(_lower)) _lower.body_of = noone;
    if (instance_exists(_upper)) {
        _upper.body_of = noone;
        _upper.piece_frame = 2;
        with (_upper) corpse_apply_frame();
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

/// @desc Resuelve el cuerpo UNA vez por frame, como Duck Game (biblia 4.4.5): tres puntos (parte
///       superior, cintura invisible e inferior) unidos por dos varillas de largo fijo, con
///       impulsos correctores. Cada pieza saca SU ángulo de la dirección cintura -> pieza, así
///       las dos mitades se doblan y se mueven por separado. Se llama desde la parte superior,
///       en su Begin Step, antes de que ninguna se mueva.
/// @param {Id.Instance} _u Parte superior (guarda la cintura en `rig`).
/// @param {Id.Instance} _w Parte inferior.
function corpse_pair_update(_u, _w) {
    var _r = _u.rig;

    // Hacia dónde miran las dos: manda quien las sostiene; si nadie, la superior.
    var _xs = _u.image_xscale;
    if (_u.holder != noone)      _xs = _u.holder.facing;
    else if (_w.holder != noone) _xs = _w.holder.facing;
    _u.image_xscale = _xs;
    _w.image_xscale = _xs;

    // Vectores de reposo: de la cintura al origen de cada pieza (salen de la tabla de puntos de
    // unión). Sus largos son los de las varillas.
    var _ju  = global.corpse_joint[0];
    var _jl  = global.corpse_joint[1];
    var _rux = -_ju[0] * _xs;
    var _ruy = -_ju[1];
    var _rwx = -_jl[0] * _xs;
    var _rwy = -_jl[1];
    var _lu  = point_distance(0, 0, _rux, _ruy);
    var _lw  = point_distance(0, 0, _rwx, _rwy);
    // Distancia entre las dos piezas con el cuerpo derecho. La "columna" tira suavemente hacia
    // ella (el cuerpo se dobla al moverse, pero se endereza al quedar quieto) y nunca se permite
    // menos de _dmin (la cintura no se pliega del todo).
    var _drest = point_distance(_rux, _ruy, _rwx, _rwy);
    var _dmin  = _drest * CORPSE_FOLD_MIN;

    var _uh = (_u.holder != noone);
    var _wh = (_w.holder != noone);

    // Salvaguarda (biblia 4.4.5 C): si algo se separó demasiado, se reensambla sin velocidad
    // alrededor de la pieza sostenida (o de la superior).
    var _limit = (_lu + _lw) * CORPSE_SNAP_FACTOR;
    if (point_distance(_u.x, _u.y, _w.x, _w.y) > _limit
        || point_distance(_u.x, _u.y, _r.jx, _r.jy) > _limit) {
        if (_uh || !_wh) {
            _r.jx = _u.x - _rux; _r.jy = _u.y - _ruy;
            _w.x = _r.jx + _rwx; _w.y = _r.jy + _rwy;
        } else {
            _r.jx = _w.x - _rwx; _r.jy = _w.y - _rwy;
            _u.x = _r.jx + _rux; _u.y = _r.jy + _ruy;
        }
        _u.hsp = 0; _u.vsp = 0;
        _w.hsp = 0; _w.vsp = 0;
        _r.jvx = 0; _r.jvy = 0;
    }

    // Se cargan los tres cuerpos de trabajo. La pieza en una mano es un punto fijo (masa
    // infinita: im = 0) que se mueve con quien la lleva.
    var _bu = _r.bu;
    var _bj = _r.bj;
    var _bw = _r.bw;
    _bu.x = _u.x; _bu.y = _u.y; _bu.im = _uh ? 0 : 1;
    _bu.vx = _uh ? _u.holder.hsp : _u.hsp;
    _bu.vy = _uh ? _u.holder.vsp : _u.vsp;
    _bw.x = _w.x; _bw.y = _w.y; _bw.im = _wh ? 0 : 1;
    _bw.vx = _wh ? _w.holder.hsp : _w.hsp;
    _bw.vy = _wh ? _w.holder.vsp : _w.vsp;
    _bj.x = _r.jx; _bj.y = _r.jy; _bj.im = CORPSE_JOINT_INV_MASS;
    _bj.vx = _r.jvx;
    _bj.vy = _r.jvy + HOLDABLE_GRAVITY;   // la cintura también cae (las piezas lo hacen en su Step)

    // Varias pasadas: cada varilla corregida desarma un poco la otra.
    repeat (CORPSE_SOLVER_PASSES) {
        corpse_rod_solve(_bu, _bj, _lu,    false);
        corpse_rod_solve(_bj, _bw, _lw,    false);
        corpse_rod_solve(_bu, _bw, _drest, false, CORPSE_SPINE_STIFFNESS);   // columna: elástica
        corpse_rod_solve(_bu, _bw, _dmin,  true);                            // tope: rígido
    }

    if (!_uh) { _u.hsp = _bu.vx; _u.vsp = _bu.vy; }
    if (!_wh) { _w.hsp = _bw.vx; _w.vsp = _bw.vy; }

    // La cintura no tiene Step: se mueve aquí. Choca con el mapa por ejes, como un círculo de
    // radio CORPSE_JOINT_RADIUS (se prueba el borde hacia donde va, un punto: barato). El radio
    // es la distancia del centro de una pieza tirada al piso: así la cintura queda a la altura de
    // las piezas y el cuerpo tirado queda plano, en vez de doblarse en V hacia adentro del suelo.
    var _tm = _u.tilemap;
    if (tilemap_get_at_pixel(_tm, _r.jx, _r.jy) != 0) {
        // Ya está dentro del mapa (no debería pasar): se mueve libre para que las varillas la saquen.
        _r.jx += _bj.vx;
        _r.jy += _bj.vy;
    } else {
        var _rx = CORPSE_JOINT_RADIUS * sign(_bj.vx);
        var _ry = CORPSE_JOINT_RADIUS * sign(_bj.vy);
        if (tilemap_get_at_pixel(_tm, _r.jx + _bj.vx + _rx, _r.jy) == 0) _r.jx += _bj.vx; else _bj.vx = 0;
        if (tilemap_get_at_pixel(_tm, _r.jx, _r.jy + _bj.vy + _ry) == 0) _r.jy += _bj.vy; else _bj.vy = 0;
    }
    _r.jvx = _bj.vx * CORPSE_JOINT_DAMPING;
    _r.jvy = _bj.vy * CORPSE_JOINT_DAMPING;

    // El ángulo NO se simula: sale de la dirección cintura -> pieza (donde estará al moverse),
    // medida contra la de reposo. Cada pieza tiene el suyo.
    _u.angle = point_direction(_r.jx, _r.jy, _bu.x + _bu.vx, _bu.y + _bu.vy) - point_direction(0, 0, _rux, _ruy);
    _w.angle = point_direction(_r.jx, _r.jy, _bw.x + _bw.vx, _bw.y + _bw.vy) - point_direction(0, 0, _rwx, _rwy);
}

/// @desc Una varilla entre dos cuerpos de trabajo (Ragdoll.Solve de Duck Game): un impulso que
///       anula la velocidad relativa a lo largo de la varilla y corrige el error de largo, en un
///       solo paso. Se reparte según la masa inversa (im) de cada uno.
/// @param {Bool} _min_only true = solo empuja si están MÁS CERCA que _len (tope para no plegarse).
/// @param {Real} [_k] Rigidez 0..1: 1 = varilla (corrige todo el error); menos = resorte suave.
function corpse_rod_solve(_a, _b, _len, _min_only, _k = 1) {
    var _im = _a.im + _b.im;
    if (_im <= 0) return;
    var _dx = _b.x - _a.x;
    var _dy = _b.y - _a.y;
    var _d  = point_distance(0, 0, _dx, _dy);
    if (_d < 0.001) return;
    var _nx = _dx / _d;
    var _ny = _dy / _d;

    // Error de largo que habría DESPUÉS de moverse con estas velocidades.
    var _err = _d + (_b.vx - _a.vx) * _nx + (_b.vy - _a.vy) * _ny - _len;
    if (_min_only && _err >= 0) return;

    var _imp = _err / _im * _k;
    _a.vx += _nx * _imp * _a.im;
    _a.vy += _ny * _imp * _a.im;
    _b.vx -= _nx * _imp * _b.im;
    _b.vy -= _ny * _imp * _b.im;
}

/// @desc Largo de la varilla cintura -> origen de una pieza (según su frame lógico).
function corpse_rod_length(_frame) {
    var _j = corpse_joint_get(_frame);
    return point_distance(0, 0, _j[0], _j[1]);
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