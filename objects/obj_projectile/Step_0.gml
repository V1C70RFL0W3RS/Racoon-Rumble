life--;
if (life <= 0) { instance_destroy(); exit; }

// 1) Terreno: move_and_collide recorre todo el trayecto del frame.
var _hit = move_and_collide(hsp, vsp, tilemap);
if (array_length(_hit) > 0) { instance_destroy(); exit; }

// 2) Jugadores: no golpea a quien disparó ni a los que ya están muertos
//    (siguen existiendo, ocultos, hasta reaparecer).
var _p = instance_place(x, y, obj_player);
if (_p != noone && _p != owner && _p.state != PLAYER_STATE.DEAD) {
    player_take_hit(_p, damage);
    instance_destroy();
}