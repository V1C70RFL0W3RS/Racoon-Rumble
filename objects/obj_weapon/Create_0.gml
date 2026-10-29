event_inherited(); // crea holder, hsp, vsp, tilemap, angle, spin
fires = true;
// Qué arma es. Si quien la crea no lo indicó, es una pistola.
if (!variable_instance_exists(id, "weapon_id")) weapon_id = WEAPON_ID.PISTOL;

// Definición constante (compartida) + estado propio de ESTA instancia.
def  = weapon_get_def(weapon_id);
ammo = def.ammo_max;
sprite_index = def.sprite;
cooldown = 0;   // frames que faltan para poder volver a disparar
