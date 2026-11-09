life--;
if (life <= 0) { instance_destroy(); exit; }

// 1) Terreno: move_and_collide recorre todo el trayecto. Si choca, x,y queda
//    en el punto de contacto, así que el segmento termina en la pared.
var _hit_wall = array_length(move_and_collide(hsp, vsp, tilemap)) > 0;

// 2) Jugadores: se revisa TODO el segmento recorrido, no solo la posición final.
//    Va ANTES de destruir por pared: un jugador cruzado en este frame debe morir.
var _p = projectile_find_hit(prev_x, prev_y, x, y, owner);
if (_p != noone) {
    player_take_hit(_p, damage);
    instance_destroy();
    exit;
}

if (_hit_wall) {
    var _dir = point_direction(0, 0, hsp, vsp);
    var _c = projectile_wall_contact(x, y, _dir, tilemap);
    fx_bullet_sparks(_c[0], _c[1], _dir);
    instance_destroy();
    exit;
}

prev_x = x;
prev_y = y;