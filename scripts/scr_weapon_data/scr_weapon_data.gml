/// @file scr_weapon_data
/// Catálogo de definiciones de armas. Aquí solo viven datos CONSTANTES.
/// El estado de cada arma concreta (munición, kick) vive en obj_weapon.

/// Identificador de cada tipo de arma. Sirve como índice en global.weapon_defs.
/// NO reordenar ni borrar entradas a mitad: los índices cambiarían.
/// Agregar siempre nuevas armas ANTES de COUNT.
enum WEAPON_ID {
    PISTOL,
    SHOTGUN,
    MAGNUM,   
    SMG,      
    COUNT // truco: siempre queda con el número de armas que existen
}

/// @desc Constructor de una definición de arma. Define los valores por
///       defecto, así cada arma solo declara lo que la distingue de las demás.
function WeaponDef() constructor {
    name         = "Arma";
    sprite       = -1;   // sprite del arma (spr_weapon_*)
    ammo_max     = 6;
    fire_delay   = 15;   // frames entre disparos
	recoil       = 3;    // fuerza de retroceso al jugador (_kickForce de Duck Game, biblia 4.3.1 P8)
    bullets      = 1;    // proyectiles por disparo (escopeta > 1)
    spread       = 0;    // dispersión aleatoria de CADA bala, en grados
    muzzle_x     = 20;   // distancia desde el agarre hasta la boca del cañón, a lo largo del arma
    muzzle_y     = 0;    // desvío perpendicular de la boca (+ = hacia abajo en el sprite)
    ammo_id      = AMMO_ID.LIGHT;   // tipo de bala (ver scr_ammo_data)
    impact_mult  = 1;               // × AmmoDef.impact: ajusta el empujón por arma sin cambiar la munición
                                    // (la SMG comparte LIGHT con la pistola pero dispara mucho más seguido)
    snd_fire     = undefined;       // sonido del disparo (uno por disparo, no por perdigón)
    snd_empty    = snd_weapon_empty;  // sonido del clic vacío (el mismo para todas, salvo que un arma lo cambie)
    // Recarga manual (bombeo/cerrojo): tras CADA disparo, la siguiente pulsación del mismo
    // botón recarga en vez de disparar.
    needs_rack   = false;
    rack_delay   = 15;              // frames que tarda en recargar (no se puede disparar mientras)
    snd_rack     = undefined;       // sonido de la recarga
    rack_frame   = -1;              // frame del sprite con la corredera atrás (-1 = sin animación)
    flash_count  = 6;               // partículas del fogonazo (0 = sin fogonazo)
    // Casquillo que expulsa (con needs_rack, al recargar; si no, al disparar). shell_len 0 = ninguno.
    shell_len    = 3;               // largo en px
    shell_width  = 1;               // grosor en px
    shell_color  = SHELL_COL_BRASS;
    heat_per_shot = 0.2;           // calor (0 a 1) que suma cada disparo; más calor = más humo después
    //"kick" = cambio en la orientación del ARMA (distinto de spread).
    automatic     = false; // true = dispara mientras se mantiene el botón
    kick_up       = 0;     // grados que sube el arma en cada disparo
    kick_jitter   = 0;     // temblor aleatorio (±grados) en cada disparo
    kick_max      = 45;    // inclinación máxima permitida, en grados (arriba o abajo)
    kick_recovery = 1;     // grados por frame que el arma vuelve a la posición recta
    // Bamboleo: en cada disparo se suma una onda (seno), así una ráfaga sube y baja
    // de forma fluida en vez de solo temblar. 0 = sin bamboleo.
    kick_wobble       = 0;     // amplitud en grados por disparo
    kick_wobble_speed = 1;     // cuánto avanza la onda por disparo (radianes): más = oscila más rápido
    kick_wobble_chaos = 0;     // ± al azar sobre kick_wobble_speed en cada disparo: la onda se vuelve irregular
    // Kick LINEAL: el arma retrocede hacia el hombro (en px) al disparar y vuelve sola.
    kick_back          = 0;
    kick_back_recovery = 0.5;   // px por frame que vuelve a su lugar
}

/// @desc Construye el catálogo completo. Se llama UNA sola vez al iniciar el juego.
function weapon_data_init() {
    global.weapon_defs = array_create(WEAPON_ID.COUNT);

    var _pistol = new WeaponDef();
    _pistol.snd_fire      = snd_pistol_fire;
    _pistol.name          = "Pistola";
    _pistol.sprite        = spr_weapon_pistol;
    _pistol.flash_count   = 10;
    _pistol.heat_per_shot = 0.2;
    _pistol.ammo_max      = 8;
	_pistol.muzzle_x      = 11;
	_pistol.muzzle_y      = -3;
    _pistol.kick_up       = 4;     
    _pistol.kick_max      = 20;
    _pistol.kick_recovery = 0.5;
    _pistol.kick_back          = 2;
    _pistol.kick_back_recovery = 0.5;
    global.weapon_defs[WEAPON_ID.PISTOL] = _pistol;

    var _shotgun = new WeaponDef();
    _shotgun.snd_fire      = snd_shotgun_fire;
    _shotgun.snd_rack      = snd_shotgun_rack;
    _shotgun.name          = "Escopeta";
    _shotgun.sprite        = spr_weapon_shotgun;
    _shotgun.flash_count   = 14;
    _shotgun.heat_per_shot = 0.5;
    _shotgun.shell_len     = 4;
    _shotgun.shell_width   = 2;
    _shotgun.shell_color   = SHELL_COL_RED;
    _shotgun.ammo_max      = 2;
    _shotgun.fire_delay    = 15;   // CAMBIO: antes 30; ahora el ritmo lo pone también la recarga
    _shotgun.needs_rack    = true;
    _shotgun.rack_delay    = 15;   // disparo (15) + bombeo (15) = mismo ritmo que antes
    _shotgun.rack_frame    = 1;    // frame 1 de spr_weapon_shotgun: corredera atrás
    _shotgun.recoil        = 4;
    _shotgun.bullets       = 6;
    _shotgun.spread        = 20;
	_shotgun.muzzle_x      = 18;
	_shotgun.muzzle_y      = -2;
	_shotgun.ammo_id = AMMO_ID.PELLET;
    _shotgun.kick_up       = 12; 
    _shotgun.kick_max      = 30;
    _shotgun.kick_recovery = 0.6;
    _shotgun.kick_back          = 3;
    _shotgun.kick_back_recovery = 0.4;
    global.weapon_defs[WEAPON_ID.SHOTGUN] = _shotgun;

   
    var _magnum = new WeaponDef();
    _magnum.snd_fire      = snd_magnum_fire;
    _magnum.name          = "Magnum";
    _magnum.sprite        = spr_weapon_magnum;
    _magnum.flash_count   = 12;
    _magnum.heat_per_shot = 0.45;
    _magnum.shell_len     = 0;   // revólver: guarda los casquillos en el tambor
    _magnum.ammo_max      = 6;
    _magnum.fire_delay    = 25;
	_magnum.muzzle_x      = 17;
	_magnum.muzzle_y      = -3;
	_magnum.ammo_id = AMMO_ID.HEAVY;
    _magnum.kick_up       = 18;
    _magnum.kick_max      = 60;
    _magnum.kick_recovery = 0.4;
    _magnum.kick_back          = 3;
    _magnum.kick_back_recovery = 0.4;
    global.weapon_defs[WEAPON_ID.MAGNUM] = _magnum;

    var _smg = new WeaponDef();
    _smg.snd_fire      = snd_smg_fire;
    _smg.name          = "SMG";
    _smg.sprite        = spr_weapon_smg;
    _smg.flash_count   = 4;
    _smg.heat_per_shot = 0.07;
    _smg.shell_len     = 2;
    _smg.automatic     = true;
    _smg.ammo_max      = 30;
    _smg.fire_delay    = 6;     // CAMBIO: antes 4 (15 balas/s); ahora 10 balas/s
    _smg.recoil        = 1;
    _smg.spread        = 8;    // ±4° por bala; el descontrol grande lo da el balanceo del arma
	_smg.muzzle_x      = 12;
	_smg.muzzle_y      = -3;
    _smg.kick_up       = 1;     // sube un poco con la ráfaga
    _smg.kick_jitter   = 4;     // temblor al azar en cada disparo
    _smg.kick_wobble       = 10;    // CAMBIO: antes 6; balanceo más amplio
    _smg.kick_wobble_speed = 0.9;
    _smg.kick_wobble_chaos = 0.7;   // la onda cambia de ritmo en cada disparo: caótica, no regular
    _smg.kick_max      = 30;    // CAMBIO: antes 20; deja que el balanceo llegue más lejos
    _smg.kick_recovery = 0.6;
    _smg.kick_back          = 1;
    _smg.kick_back_recovery = 0.5;
    _smg.impact_mult        = 0.4;  // 3 × 0.4 = 1.2 por bala: la ráfaga empuja, pero no lanza el cadáver
    global.weapon_defs[WEAPON_ID.SMG] = _smg;
}

/// @desc Devuelve la definición de un arma. Único punto de acceso al catálogo.
/// @param {Real} _id Valor de WEAPON_ID.
/// @returns {Struct.WeaponDef}
function weapon_get_def(_id) {
    return global.weapon_defs[_id];
}

/// Devuelve un WEAPON_ID válido al azar (de 0 hasta COUNT-1).
function weapon_pick_random_id() {
    return irandom(WEAPON_ID.COUNT - 1);
}

/// Texto de la opción "arma al azar" en la lista weapon_choice de obj_weapon_spawner.
#macro WEAPON_CHOICE_RANDOM "Aleatoria"

/// Convierte la opción elegida en el editor (texto) en un WEAPON_ID válido.
/// Los nombres de la lista deben coincidir con WeaponDef.name; el orden no importa.
function weapon_id_from_choice(_choice) {
    if (_choice == WEAPON_CHOICE_RANDOM) return weapon_pick_random_id();

    var _defs = global.weapon_defs;
    for (var i = 0; i < array_length(_defs); i++) {
        if (_defs[i].name == _choice) return i;
    }

    // Nombre que no existe en el catálogo: se avisa y se elige una al azar
    // para que el juego no se caiga.
    show_debug_message("weapon_id_from_choice: arma desconocida '" + string(_choice) + "', se usa una aleatoria.");
    return weapon_pick_random_id();
}