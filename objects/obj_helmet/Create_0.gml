event_inherited();
// Casco: va en la cabeza y detiene UNA bala (después se rompe). Lo que cae desde arriba (cajas,
// pisotones) no lo rompe: se abolla (frame 1) y lo sigue aguantando. Ver scr_equipment.
equip_slot        = EQUIP_SLOT.HEAD;
bullet_block      = ARMOR_BULLET_BLOCK;
dent_frame        = HELMET_FRAME_DENTED;
break_cols        = [HELMET_COL_A, HELMET_COL_B];
grip_x            = 0;
grip_y            = HAT_GRIP_Y;
air_friction_mult = HAT_AIR_FRICTION_MULT;
