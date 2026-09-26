// El punto está "ocupado" si mi arma existe, nadie la sostiene y sigue cerca.
var _occupied = instance_exists(current_weapon)
    && current_weapon.holder == noone
    && point_distance(x, y, current_weapon.x, current_weapon.y) <= WEAPON_SPAWNER_CHECK_RADIUS;

if (_occupied) {
    // Mientras esté ahí, el contador se mantiene lleno.
    respawn_timer = WEAPON_SPAWNER_RESPAWN_FRAMES;
} else {
    // Agarrada o alejada: cuenta regresiva y genera otra.
    respawn_timer--;
    if (respawn_timer <= 0) spawn_weapon();
}