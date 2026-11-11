/// @file scr_ui_draw
/// Funciones reutilizables para dibujar texto de UI en Draw GUI.
/// Todo texto de este juego pasa por acá — evita repetir
/// draw_set_font/draw_set_halign sueltos en cada objeto de UI.

/// @desc Dibuja una línea centrada horizontalmente, a una fracción de la
///       altura real de pantalla (0 = arriba, 1 = abajo). Restaura los
///       valores de dibujo por defecto al terminar.
function ui_draw_centered(_font, _text, _y_frac, _color = c_white) {
    draw_set_font(_font);
    draw_set_halign(fa_center);
    draw_set_color(_color);
    draw_text(display_get_gui_width() / 2, display_get_gui_height() * _y_frac, _text);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
}

/// @desc Título grande (cuenta regresiva, "GANADOR", nombres de pantalla).
function ui_draw_title(_text, _y_frac = 0.15, _color = c_white) {
    ui_draw_centered(fnt_title, _text, _y_frac, _color);
}

/// @desc Texto de cuerpo (instrucciones, una línea suelta de puntaje).
function ui_draw_body(_text, _y_frac, _color = c_white) {
    ui_draw_centered(fnt_body, _text, _y_frac, _color);
}

/// @desc Varias líneas de cuerpo, una debajo de otra, separadas por
///       _line_height px (interlineado fijo: no depende del tamaño de
///       pantalla, depende del tamaño de la fuente).
function ui_draw_body_list(_lines, _y_start_frac, _line_height = 24, _color = c_white) {
    draw_set_font(fnt_body);
    draw_set_halign(fa_center);
    draw_set_color(_color);

    var _cx = display_get_gui_width() / 2;
    var _y  = display_get_gui_height() * _y_start_frac;

    for (var i = 0; i < array_length(_lines); i++) {
        draw_text(_cx, _y + i * _line_height, _lines[i]);
    }

    draw_set_color(c_white);
    draw_set_halign(fa_left);
}


// =============================================================================
// DEPURACIÓN
// =============================================================================

/// @desc Dibuja un punto de depuración visible en el mundo: un cuadro de
///       (2 * DEBUG_DOT_HALF + 1) px. Un solo píxel casi no se ve a 320x180.
///       Es una primitiva: llamar FUERA del shader de color.
/// @param {Real}     _x
/// @param {Real}     _y
/// @param {Constant.Color} _col
function debug_draw_dot(_x, _y, _col) {
    draw_rectangle_color(_x - DEBUG_DOT_HALF, _y - DEBUG_DOT_HALF,
                         _x + DEBUG_DOT_HALF, _y + DEBUG_DOT_HALF, _col, _col, _col, _col, false);
}


/// @desc Coordenadas del mundo → GUI (la GUI va a tamaño real de pantalla, la vista no).
function world_to_gui_x(_x) {
    var _c = view_camera[0];
    return (_x - camera_get_view_x(_c)) * display_get_gui_width() / camera_get_view_width(_c);
}
function world_to_gui_y(_y) {
    var _c = view_camera[0];
    return (_y - camera_get_view_y(_c)) * display_get_gui_height() / camera_get_view_height(_c);
}

/// @desc Aviso corto centrado en _gx con su borde de abajo en _gy (GUI). P. ej. "Agarrar: usar".
function ui_draw_hint_at(_text, _gx, _gy) {
    draw_set_font(fnt_body);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text_colour(_gx + 1, _gy + 1, _text, c_black, c_black, c_black, c_black, 1);
    draw_text_colour(_gx, _gy, _text, MENU_COLOR, MENU_COLOR, MENU_COLOR, MENU_COLOR, 1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
