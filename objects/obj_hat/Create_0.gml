event_inherited();
// Gorro suelto (los puestos son una ficha de datos en el jugador: scr_equipment).
// El frame de spr_hats es el gorro; lo fija equip_spawn al crearlo.
equip_slot        = EQUIP_SLOT.HEAD;   // agarrarlo = ponérselo (player_grab_item)
grip_x            = 0;
grip_y            = HAT_GRIP_Y;
air_friction_mult = HAT_AIR_FRICTION_MULT;
worn_offset       = [HAT_WORN_DX, HAT_WORN_DY];   // puesto: ajuste propio sobre la tabla de la cabeza
