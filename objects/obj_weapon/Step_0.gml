if (cooldown > 0) cooldown--;
if (dry_flash > 0) dry_flash--;
// El arma vuelve poco a poco a su posición recta (también mientras la sostienen).
if (kick != 0) kick = approach(kick, 0, def.kick_recovery);
if (recoil_back != 0) recoil_back = approach(recoil_back, 0, def.kick_back_recovery);

// Recarga: la primera mitad la corredera va atrás (rack_frame); la segunda, vuelve.
if (rack_timer > 0) rack_timer--;
image_index = (def.rack_frame >= 0 && rack_timer > def.rack_delay / 2) ? def.rack_frame : 0;

event_inherited(); // físicas del padre (si está sostenida, el padre sale solo)

weapon_update_smoke(id);

// AL FINAL: puede destruir la instancia, así que nada debe ir después.
weapon_update_despawn(id);