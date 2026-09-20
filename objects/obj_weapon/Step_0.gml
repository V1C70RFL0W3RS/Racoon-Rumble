if (cooldown > 0) cooldown--;
// El arma vuelve poco a poco a su posición recta (también mientras la sostienen).
if (kick != 0) kick = approach(kick, 0, def.kick_recovery);

// Sostenida: la posición y el dibujo los maneja el jugador.
if (holder != noone) exit;

vsp += GRAVITY;

// Horizontal: al chocar con una pared rebota, y el giro también se invierte.
var _col_h = move_and_collide(hsp, 0, tilemap);
if (array_length(_col_h) > 0) {
    hsp  = -hsp  * WEAPON_WALL_BOUNCE;
    spin = -spin * WEAPON_WALL_BOUNCE;
}

// Vertical: al bajar y chocar, aterrizó; en el piso la fricción la frena.
var _landed = false;
var _col_v = move_and_collide(0, vsp, tilemap);
if (array_length(_col_v) > 0) {
    if (vsp > 0) {
        _landed = true;
        hsp = approach(hsp, 0, WEAPON_GROUND_FRICTION);
    }
    vsp = 0;
}

// Rotación: gira en el aire; al aterrizar decide si queda de pie o acostada.
if (_landed) {
    spin = 0;

    if (angle != 0) {
        // Ángulo normalizado a 0..360 (en GML, mod conserva el signo del dividendo).
        var _a = angle mod 360;
        if (_a < 0) _a += 360;

        if (_a >= 90 && _a < 270) {
            // ACOSTADA: girar 180° == espejar en X e Y. Al espejar la escala también
            // se espeja la máscara, así sprite y colisión siguen coincidiendo.
            image_xscale = -image_xscale;
            image_yscale = -image_yscale;
            angle = _a - 180;

            // La máscara espejada puede quedar incrustada en el piso: se sube
            // hasta que quede libre (tope de 32 px por seguridad).
            var _n = 0;
            while (place_meeting(x, y, tilemap) && _n < 32) { y -= 1; _n++; }
        } else {
            // DE PIE: se conserva la escala; solo se lleva el ángulo al rango -90..90.
            angle = (_a < 90) ? _a : _a - 360;
        }

        // El resto se endereza suavemente hacia 0.
        angle = (abs(angle) < 0.5) ? 0 : lerp(angle, 0, WEAPON_SETTLE_RATE);
    }
} else {
    angle += spin;
}