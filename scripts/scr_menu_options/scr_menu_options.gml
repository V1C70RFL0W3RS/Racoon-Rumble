/// @file scr_menu_options
/// Menú de opciones reutilizable: una lista de opciones con un valor que se cambia con
/// izquierda/derecha. Las opciones son DATOS: agregar una = una línea con menu_option().
/// Lo usan las PCs del lobby; sirve para cualquier menú "en el mundo".
///
/// El objeto que tiene el menú guarda: menu (array de opciones), menu_index, nav_dir, nav_timer
/// y menu_title.

/// @desc Crea una opción.
/// @param {String} _label Texto de la opción.
/// @param {Any} _ctx Dato que se pasa a _get y _step (p. ej. el slot del jugador o una clave).
/// @param {Function} _get  function(ctx) → String: el valor a mostrar.
/// @param {Function} _step function(ctx, dir, requester): cambia el valor (dir = -1 o 1).
///        requester = player_index de quien lo cambia: _step decide si tiene permiso.
function menu_option(_label, _ctx, _get, _step) {
    return { label: _label, ctx: _ctx, get: _get, step: _step };
}

/// @desc Navega con el input de un jugador: arriba/abajo elige opción, izquierda/derecha cambia
///       el valor. Mantener una dirección repite (MENU_REPEAT_*). Funciona igual con teclado y
///       stick porque solo usa el estado "mantenido" del input.
function menu_options_navigate(_m, _in, _requester) {
    with (_m) {
        var _v = _in.down_held - _in.up_held;
        var _h = _in.move_x;
        var _code = (_v != 0) ? 10 * _v : _h;   // un código por dirección (vertical gana)
        if (_code == 0) { nav_dir = 0; return; }

        var _act = false;
        if (_code != nav_dir) { nav_dir = _code; nav_timer = MENU_REPEAT_DELAY; _act = true; }
        else if (--nav_timer <= 0) { nav_timer = MENU_REPEAT_RATE; _act = true; }
        if (!_act) return;

        var _n = array_length(menu);
        if (_v != 0) {
            menu_index = (menu_index + _v + _n) mod _n;
        } else {
            var _o = menu[menu_index];
            _o.step(_o.ctx, _h, _requester);
        }
    }
}

/// @desc Dibuja el menú en coordenadas de GUI: centrado en _gx, con su borde de abajo en _gy.
///       Llamar desde un evento Draw GUI.
function menu_options_draw(_m, _gx, _gy) {
    draw_set_font(fnt_body);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _lh  = string_height("M") + 2;
    var _pad = 8;
    var _lines = [];
    for (var i = 0; i < array_length(_m.menu); i++) {
        var _o = _m.menu[i];
        array_push(_lines, _o.label + ":  < " + _o.get(_o.ctx) + " >");
    }
    var _w = string_width(_m.menu_title);
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
    draw_text_colour(_x0 + _pad, _y, _m.menu_title, MENU_COLOR, MENU_COLOR, MENU_COLOR, MENU_COLOR, 1);
    _y += _lh;
    for (var i = 0; i < array_length(_lines); i++) {
        var _sel = (i == _m.menu_index);
        var _c = _sel ? c_white : c_gray;
        draw_text_colour(_x0 + _pad, _y, (_sel ? "> " : "  ") + _lines[i], _c, _c, _c, _c, 1);
        _y += _lh;
    }
    draw_text_colour(_x0 + _pad, _y, "Agarrar: salir", c_dkgray, c_dkgray, c_dkgray, c_dkgray, 1);
}
