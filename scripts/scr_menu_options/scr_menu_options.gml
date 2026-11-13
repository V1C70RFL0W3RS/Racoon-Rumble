/// @file scr_menu_options
/// Menú de opciones reutilizable: una lista de opciones con un valor que se cambia con
/// izquierda/derecha. Las opciones son DATOS: agregar una = una línea con menu_option().
/// Lo usan los objetos que se usan (PC del host, ropero); sirve para cualquier menú "en el mundo".
///
/// El objeto que tiene el menú guarda: menu (array de opciones) y menu_title. El CURSOR (opción
/// elegida y repetición) es de cada jugador (menu_cursor), así varios usan el mismo menú a la vez.
/// En menu_title, "{jugador}" se reemplaza por el número de quien lo mira.

/// @desc Crea una opción.
/// @param {String} _label Texto de la opción.
/// @param {Any} _ctx Dato que se pasa a _get y _step (p. ej. una clave de ajuste). MENU_CTX_USER =
///        el player_index de quien lo usa (cada uno ve y cambia LO SUYO: el ropero).
/// @param {Function} _get  function(ctx) → String: el valor a mostrar.
/// @param {Function} _step function(ctx, dir, requester): cambia el valor (dir = -1 o 1).
///        requester = player_index de quien lo cambia: _step decide si tiene permiso.
function menu_option(_label, _ctx, _get, _step) {
    return { label: _label, ctx: _ctx, get: _get, step: _step };
}

/// @desc Cursor nuevo (uno por jugador, ver obj_player Create).
function menu_cursor_create() {
    return { index: 0, nav_dir: 0, nav_timer: 0 };
}
function menu_cursor_reset(_c) {
    _c.index = 0;
    _c.nav_dir = 0;
    _c.nav_timer = 0;
}

/// @desc El contexto real de una opción para quien la usa.
function menu_option_ctx(_o, _requester) {
    return (_o.ctx == MENU_CTX_USER) ? _requester : _o.ctx;
}

/// @desc Navega con el input de un jugador: arriba/abajo elige opción, izquierda/derecha cambia
///       el valor. Mantener una dirección repite (MENU_REPEAT_*). Funciona igual con teclado y
///       stick porque solo usa el estado "mantenido" del input.
/// @param {Id.Instance} _m Objeto con el menú.
/// @param {Struct} _c Cursor de quien navega (menu_cursor_create).
function menu_options_navigate(_m, _c, _in, _requester) {
    var _v = _in.down_held - _in.up_held;
    var _h = _in.move_x;
    var _code = (_v != 0) ? 10 * _v : _h;   // un código por dirección (vertical gana)
    if (_code == 0) { _c.nav_dir = 0; return; }

    var _act = false;
    if (_code != _c.nav_dir) { _c.nav_dir = _code; _c.nav_timer = MENU_REPEAT_DELAY; _act = true; }
    else if (--_c.nav_timer <= 0) { _c.nav_timer = MENU_REPEAT_RATE; _act = true; }
    if (!_act) return;

    var _n = array_length(_m.menu);
    if (_v != 0) {
        _c.index = (_c.index + _v + _n) mod _n;
    } else {
        var _o = _m.menu[_c.index];
        _o.step(menu_option_ctx(_o, _requester), _h, _requester);
    }
}

/// @desc Dibuja el menú en coordenadas de GUI: centrado en _gx, con su borde de abajo en _gy.
///       Llamar desde un evento Draw GUI.
/// @param {Struct} _c Cursor de quien lo mira.
/// @param {Real} _requester player_index de quien lo mira.
function menu_options_draw(_m, _c, _requester, _gx, _gy) {
    draw_set_font(fnt_body);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _title = string_replace(_m.menu_title, "{jugador}", string(_requester + 1));
    var _lh  = string_height("M") + 2;
    var _pad = 8;
    var _lines = [];
    for (var i = 0; i < array_length(_m.menu); i++) {
        var _o = _m.menu[i];
        array_push(_lines, _o.label + ":  < " + _o.get(menu_option_ctx(_o, _requester)) + " >");
    }
    var _w = string_width(_title);
    for (var i = 0; i < array_length(_lines); i++) _w = max(_w, string_width("> " + _lines[i]));
    _w += _pad * 2;
    var _h = _lh * (array_length(_lines) + 2) + _pad * 2;   // + título + ayuda
    var _x0 = round(_gx - _w / 2);
    var _y0 = round(_gy - _h);

    draw_set_alpha(MENU_BG_ALPHA);
    draw_rectangle_colour(_x0, _y0, _x0 + _w, _y0 + _h, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_rectangle_colour(_x0, _y0, _x0 + _w, _y0 + _h, MENU_COLOR, MENU_COLOR, MENU_COLOR, MENU_COLOR, true);

    var _y = _y0 + _pad;
    draw_text_colour(_x0 + _pad, _y, _title, MENU_COLOR, MENU_COLOR, MENU_COLOR, MENU_COLOR, 1);
    _y += _lh;
    for (var i = 0; i < array_length(_lines); i++) {
        var _sel = (i == _c.index);
        var _col = _sel ? c_white : c_gray;
        draw_text_colour(_x0 + _pad, _y, (_sel ? "> " : "  ") + _lines[i], _col, _col, _col, _col, 1);
        _y += _lh;
    }
    draw_text_colour(_x0 + _pad, _y, "Agarrar: salir", c_dkgray, c_dkgray, c_dkgray, c_dkgray, 1);
}
