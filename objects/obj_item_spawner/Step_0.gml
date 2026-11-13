// El punto está "ocupado" si mi objeto existe, nadie lo sostiene y sigue cerca.
// (Un gorro que alguien se puso deja de existir como instancia: cuenta como libre.)
var _occupied = instance_exists(current_item)
    && current_item.holder == noone
    && point_distance(x, y, current_item.x, current_item.y) <= ITEM_SPAWNER_CHECK_RADIUS;

if (_occupied) {
    // Mientras esté ahí, el contador se mantiene lleno.
    respawn_timer = ITEM_SPAWNER_RESPAWN_FRAMES;
} else {
    // Agarrado o alejado: cuenta regresiva y genera otro.
    respawn_timer--;
    if (respawn_timer <= 0) spawn_item();
}
