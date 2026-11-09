// hsp, vsp, damage, life y owner llegan desde projectile_spawn (struct de creación).
tilemap = layer_tilemap_get_id("layer_collision");

// Objetos que esta bala ya atravesó (solo crece con munición que tiene pierce):
// sin esto, la bala volvería a golpear la misma pieza en el frame siguiente.
hit_list = [];

// La bala se dibuja apuntando hacia donde vuela.
image_angle = point_direction(0, 0, hsp, vsp);