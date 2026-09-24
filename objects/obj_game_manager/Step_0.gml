// TEMPORAL: hasta que el Paso 2 meta los estados LOBBY/COUNTDOWN en scr_match,
// match_update() no debe correr si la partida todavía no arrancó (global.match
// vacío mientras estamos en rm_menu/rm_lobby).
if (variable_struct_exists(global.match, "state")) {
    match_update();
}