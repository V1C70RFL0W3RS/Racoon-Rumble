// La capa GUI (texto, botones) se dibuja al tamaño REAL de la pantalla,
// no a los 640x360 del juego, así el texto sale nítido en cualquier
// ventana o en fullscreen. Se revisa cada Step porque el tamaño puede
// cambiar en cualquier momento (fullscreen, resize, rotar el celular).
var _win_w = window_get_width();
var _win_h = window_get_height();
if (display_get_gui_width() != _win_w || display_get_gui_height() != _win_h) {
    display_set_gui_size(_win_w, _win_h);
}

// TEMPORAL: hasta que el Paso 2 meta los estados LOBBY/COUNTDOWN en scr_match,
// match_update() no debe correr si la partida todavía no arrancó (global.match
// vacío mientras estamos en rm_menu/rm_lobby).
if (variable_struct_exists(global.match, "state")) {
    match_update();
}