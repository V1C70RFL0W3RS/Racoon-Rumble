event_inherited();
// Botas: van en los pies. Pisar a alguien en la cabeza lo mata (como una caja que le cae) y se
// puede caminar sobre pinchos. Puestas se dibujan con spr_boots_worn (un frame por pose del cuerpo).
equip_slot        = EQUIP_SLOT.FEET;
stomps            = true;
spike_proof       = true;
worn_sprite         = spr_boots_worn;
worn_sprite_ragdoll = spr_boots_worn_corpse;
break_cols        = [BOOTS_COL, BOOTS_COL_DARK];
grip_x            = 0;
grip_y            = HAT_GRIP_Y;
rotates           = false;   // caen de pie
