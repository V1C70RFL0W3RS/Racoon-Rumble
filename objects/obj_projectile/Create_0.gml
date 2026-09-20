// hsp, vsp, damage, life y owner llegan desde projectile_spawn (struct de creación).
tilemap = layer_tilemap_get_id("layer_collision");

// La bala se dibuja apuntando hacia donde vuela.
image_angle = point_direction(0, 0, hsp, vsp);