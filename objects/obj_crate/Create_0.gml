event_inherited();
// Caja de madera: se agarra, se lanza, sirve de plataforma y de escudo, y se rompe a balazos.
// Todo es por banderas del padre (ADR-003): ni las balas ni el jugador saben que existe "la caja".

rotates     = false;              // siempre recta, aunque la lancen con giro
wall_bounce = CRATE_WALL_BOUNCE;
air_friction_mult = CRATE_AIR_FRICTION_MULT;   // el aire la frena poco: al lanzarla llega lejos
grip_x      = CRATE_GRIP_X;       // la mano la toma de un costado: queda adelante del jugador
grip_y      = CRATE_GRIP_Y;

shootable        = true;              // las balas la detectan...
block_chance     = 1;                 // ...y siempre se detienen en ella
impact_mult      = CRATE_IMPACT_MULT; // pesada: un disparo la mueve poco
shield_when_held = true;              // en la mano también recibe las balas (escudo)
hit_fx           = HIT_FX.WOOD;       // astillas al recibir un disparo y al romperse

max_hp = CRATE_HP;
hp     = max_hp;
image_index = 0;   // frame 0 = entera; holdable_damage lo cambia según la vida

platform    = true;               // los jugadores (y otras cajas) pueden pararse encima
crush_speed = CRATE_CRUSH_SPEED;  // cayendo rápido sobre una cabeza, mata
