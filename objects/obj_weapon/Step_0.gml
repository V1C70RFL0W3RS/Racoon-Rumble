if (cooldown > 0) cooldown--;
// El arma vuelve poco a poco a su posición recta (también mientras la sostienen).
if (kick != 0) kick = approach(kick, 0, def.kick_recovery);

event_inherited(); // físicas del padre (si está sostenida, el padre sale solo)