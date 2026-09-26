

// Qué arma es. Si quien la crea no lo indicó, es una pistola.
// (Ver nota más abajo sobre por qué usamos variable_instance_exists.)
if (!variable_instance_exists(id, "weapon_id")) weapon_id = WEAPON_ID.PISTOL;

// Definición constante (compartida) + estado propio de ESTA instancia.
def  = weapon_get_def(weapon_id);
ammo = def.ammo_max;
sprite_index = def.sprite;

// Quién la sostiene. noone = está suelta en el mundo.
holder = noone;

// Físicas manuales, mismo criterio que obj_player.
hsp = 0;
vsp = 0;
tilemap = layer_tilemap_get_id("layer_collision");
// Rotación solo VISUAL (no usamos image_angle: rotaría también la máscara de colisión).
angle = 0;   // ángulo actual con que se dibuja
spin  = 0;   // grados por frame mientras está en el aire
cooldown = 0;   // frames que faltan para poder volver a disparar
kick = 0;   // inclinación actual del arma en grados (positivo = hacia arriba)