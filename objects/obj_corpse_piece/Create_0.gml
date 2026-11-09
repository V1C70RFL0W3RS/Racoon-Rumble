event_inherited();
// Qué pieza es: 0 = superior viva, 1 = inferior, 2 = superior muerta.
if (!variable_instance_exists(id, "piece_frame")) piece_frame = 0;

partner = noone;   // la otra mitad; lo asigna corpse_spawn después de crear las dos

drives_angle = true;   // el ángulo lo decide la pareja (corpse_pair_update), no el giro del padre
air_friction_mult = CORPSE_AIR_FRICTION_MULT;
wall_bounce       = CORPSE_BOUNCE;
floor_bounce      = CORPSE_BOUNCE;
shootable         = true;                 // las balas lo empujan y se detienen en él
impact_mult       = CORPSE_IMPACT_MULT;
block_chance      = CORPSE_BLOCK_CHANCE;  // escudo imperfecto: parte de las balas lo atraviesa