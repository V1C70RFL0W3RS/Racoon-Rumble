// Base de todo lo que se USA (no se agarra): PC del host, ropero; a futuro botones, máquinas...
// Ver scr_interact. Lo propio de cada tipo va en el hijo (como en obj_holdable, ADR-003).

users     = [];               // jugadores que lo están usando ahora
max_users = 1;                // cuántos a la vez (el ropero: todos)
use_slot  = INTERACT_ANYONE;  // quién puede usarlo: INTERACT_ANYONE, INTERACT_HOST o 0..7

// Menú de opciones (ver scr_menu_options). El hijo lo llena. El cursor es de cada jugador.
menu       = [];
menu_title = "";

image_speed = 0;   // frame 0 = libre, frame 1 = en uso (lo cambian interact_begin/end)
