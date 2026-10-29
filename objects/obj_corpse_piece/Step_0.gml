corpse_apply_frame();   // sprite e imagen según piece_frame (se fija aquí por el Creation Code)

var _g = corpse_grip_get(piece_frame);
grip_x = _g[0];
grip_y = _g[1];

if (DEBUG_TOOLS) corpse_debug_check("inicio");    // TEMPORAL

event_inherited();

