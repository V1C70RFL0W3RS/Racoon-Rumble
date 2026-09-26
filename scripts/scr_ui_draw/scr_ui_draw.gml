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