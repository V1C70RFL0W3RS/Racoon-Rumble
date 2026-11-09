event_inherited(); // crea holder, hsp, vsp, tilemap, angle, spin
fires = true;
// Qué arma es. Si quien la crea no lo indicó, es una pistola.
if (!variable_instance_exists(id, "weapon_id")) weapon_id = WEAPON_ID.PISTOL;

// Definición constante (compartida) + estado propio de ESTA instancia.
def  = weapon_get_def(weapon_id);
ammo = def.ammo_max;
sprite_index = def.sprite;
cooldown = 0;   // frames que faltan para poder volver a disparar
dry_flash = 0;  // frames que le quedan al destello del clic vacío
chambered = true;
rack_timer = 0;
wobble_phase = random(2 * pi);   // fase del bamboleo: cada arma arranca distinta
heat = 0;            // calor del cañón (0 a 1): de él sale el humo al dejar de disparar
since_shot = 999;    // frames desde el último disparo     // frames que le quedan a la animación de recarga   // armas con needs_rack: true = lista para disparar; false = hay que recargar
empty_rest_timer = 0;   // frames quieta en el piso estando vacía (ver weapon_update_despawn)
