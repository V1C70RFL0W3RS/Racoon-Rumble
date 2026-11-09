life--;
if (life <= 0) { instance_destroy(); exit; }

// 1) Terreno: move_and_collide recorre todo el trayecto. Si choca, x,y queda
//    en el punto de contacto, así que el segmento termina en la pared.
var _hit_wall = array_length(move_and_collide(hsp, vsp, tilemap)) > 0;

// 2) Objetivos: se revisa TODO el segmento recorrido, no solo la posición final, del más
//    cercano al más lejano. Va ANTES de destruir por pared: lo cruzado en este frame cuenta.
var _dir = point_direction(0, 0, hsp, vsp);
var _t = projectile_find_hit(prev_x, prev_y, x, y, owner, hit_list);
while (_t != noone) {
    // A un jugador nunca se lo atraviesa: muere y la bala se acaba.
    if (_t.object_index == obj_player) {
        player_take_hit(_t, damage, _dir, impact);
        instance_destroy();
        exit;
    }
    holdable_take_shot(_t, _dir, impact);   // lo empuja, la detenga o no
    // ¿Sigue la bala? Primero la munición (pierce: sniper futuro, siempre atraviesa);
    // si no, la suerte del objeto (block_chance: el cadáver es un escudo imperfecto).
    if (pierce > 0) {
        pierce--;
    } else if (random(1) < _t.block_chance) {
        instance_destroy();
        exit;
    }
    // Atravesó: sigue buscando en el MISMO segmento, así un jugador detrás del
    // objeto también recibe el disparo este frame.
    array_push(hit_list, _t);
    _t = projectile_find_hit(prev_x, prev_y, x, y, owner, hit_list);
}

if (_hit_wall) {
    var _c = projectile_wall_contact(x, y, _dir, tilemap);
    fx_bullet_sparks(_c[0], _c[1], _dir);
    instance_destroy();
    exit;
}

prev_x = x;
prev_y = y;