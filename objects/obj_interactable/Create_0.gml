// Base de todo lo que se USA (no se agarra): PCs del lobby; a futuro botones, máquinas...
// Ver scr_interact. Lo propio de cada tipo va en el hijo (como en obj_holdable, ADR-003).

user     = noone;            // jugador que lo está usando; noone = libre
use_slot = INTERACT_ANYONE;  // quién puede usarlo: INTERACT_ANYONE, INTERACT_HOST o 0..3

// Menú de opciones (ver scr_menu_options). El hijo lo llena.
menu       = [];
menu_title = "";
menu_index = 0;
nav_dir    = 0;   // dirección que se está manteniendo (para repetir)
nav_timer  = 0;

image_speed = 0;   // frame 0 = libre, frame 1 = en uso (lo cambian interact_begin/end)
