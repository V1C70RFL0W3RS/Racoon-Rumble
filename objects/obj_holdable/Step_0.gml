// Sostenido: la posición y el dibujo los maneja quien lo lleva.
if (holder != noone) exit;

holdable_depenetrate(id);   // si nació o quedó incrustado, sale por el lado más corto

vsp += HOLDABLE_GRAVITY;
// Salvaguarda: nada agarrable supera estas velocidades, pase lo que pase.
hsp = clamp(hsp, -HOLDABLE_MAX_HSP, HOLDABLE_MAX_HSP);
vsp = clamp(vsp, -HOLDABLE_MAX_VSP, HOLDABLE_MAX_VSP);
// Horizontal: al chocar con una pared rebota, y el giro también se invierte.
var _col_h = move_and_collide(hsp, 0, tilemap);
if (array_length(_col_h) > 0) {
    hsp  = -hsp  * wall_bounce;
    spin = -spin * wall_bounce;
}
// Vertical: al bajar y chocar, aterrizó (o rebota si floor_bounce lo permite); al subir
// y chocar con un techo, solo se detiene.
var _landed = false;
var _col_v = move_and_collide(0, vsp, tilemap);
if (array_length(_col_v) > 0) {
    if (vsp > HOLDABLE_BOUNCE_MIN_SPEED && floor_bounce > 0) {
        vsp = -vsp * floor_bounce;   // rebota; sigue contando como "en el aire"
    } else {
        if (vsp > 0) {
            _landed = true;
            hsp = approach(hsp, 0, HOLDABLE_GROUND_FRICTION);
        }
        vsp = 0;
    }
}
// Fricción en el aire (Duck Game: la del suelo × 0.7). Solo si no aterrizó este frame.
if (!_landed) hsp = approach(hsp, 0, HOLDABLE_AIR_FRICTION * air_friction_mult);
// Rotación: gira en el aire; al aterrizar decide si queda de pie o acostada.
if (drives_angle) {
    // El hijo fija `angle` por su cuenta: el padre no lo toca.
} else if (!rotates) {
    // Los objetos que no giran (cajas) siempre quedan rectos, aunque los lancen con giro.
    spin  = 0;
    angle = 0;
} else if (_landed) {
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
        angle = (abs(angle) < 0.5) ? 0 : lerp(angle, 0, HOLDABLE_SETTLE_RATE);
    }
} else {
    angle += spin;
}