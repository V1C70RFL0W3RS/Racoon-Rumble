/// @file scr_weapon_data
/// Catálogo de definiciones de armas. Aquí solo viven datos CONSTANTES.
/// El estado de cada arma concreta (munición, kick) vive en obj_weapon.

/// Identificador de cada tipo de arma. Sirve como índice en global.weapon_defs.
/// NO reordenar ni borrar entradas a mitad: los índices cambiarían.
/// Agregar siempre nuevas armas ANTES de COUNT.
enum WEAPON_ID {
    PISTOL,
    SHOTGUN,
    MAGNUM,   // NUEVO
    SMG,      // NUEVO
    COUNT // truco: siempre queda con el número de armas que existen
}

/// @desc Constructor de una definición de arma. Define los valores por
///       defecto, así cada arma solo declara lo que la distingue de las demás.
function WeaponDef() constructor {
    name         = "Arma";
    sprite       = -1;   // sprite del arma (spr_weapon_*)
    damage       = 1;    // 1 = muerte de un golpe (pilar de diseño de DuckGame)
    ammo_max     = 6;
    fire_delay   = 15;   // frames entre disparos
    recoil       = 2;    // empuje al jugador al disparar
    bullet_speed = 12;
    bullets      = 1;    // proyectiles por disparo (escopeta > 1)
    spread       = 0;    // dispersión aleatoria de CADA bala, en grados
    muzzle_x     = 20;   // distancia desde el agarre hasta la boca del cañón
    bullet_life  = 45;   // frames que vive una bala antes de desaparecer sola

    // NUEVO: "kick" = cambio en la orientación del ARMA (distinto de spread).
    automatic     = false; // true = dispara mientras se mantiene el botón
    kick_up       = 0;     // grados que sube el arma en cada disparo
    kick_jitter   = 0;     // temblor aleatorio (±grados) en cada disparo
    kick_max      = 45;    // inclinación máxima permitida, en grados (arriba o abajo)
    kick_recovery = 1;     // grados por frame que el arma vuelve a la posición recta
}

/// @desc Construye el catálogo completo. Se llama UNA sola vez al iniciar el juego.
function weapon_data_init() {
    global.weapon_defs = array_create(WEAPON_ID.COUNT);

    var _pistol = new WeaponDef();
    _pistol.name          = "Pistola";
    _pistol.sprite        = spr_weapon_gun_1;
    _pistol.ammo_max      = 8;
    _pistol.muzzle_x      = 22;
    _pistol.kick_up       = 4;     // NUEVO: un golpecito leve
    _pistol.kick_max      = 20;
    _pistol.kick_recovery = 0.5;
    global.weapon_defs[WEAPON_ID.PISTOL] = _pistol;

    var _shotgun = new WeaponDef();
    _shotgun.name          = "Escopeta";
    _shotgun.sprite        = spr_weapon_gun_2;
    _shotgun.ammo_max      = 2;
    _shotgun.fire_delay    = 30;
    _shotgun.recoil        = 6;
    _shotgun.bullets       = 6;
    _shotgun.spread        = 20;
    _shotgun.muzzle_x      = 70;
    _shotgun.kick_up       = 12;   // NUEVO: patada fuerte, se recupera rápido
    _shotgun.kick_max      = 30;
    _shotgun.kick_recovery = 0.6;
    global.weapon_defs[WEAPON_ID.SHOTGUN] = _shotgun;

    // NUEVO — estilo revólver: sube más con cada disparo y baja despacio.
    var _magnum = new WeaponDef();
    _magnum.name          = "Magnum";
    _magnum.sprite        = spr_weapon_gun_1;   // TEMPORAL: sprite prestado de la pistola
    _magnum.ammo_max      = 6;
    _magnum.fire_delay    = 25;
    _magnum.recoil        = 3;
    _magnum.bullet_speed  = 16;
    _magnum.muzzle_x      = 22;
    _magnum.kick_up       = 18;
    _magnum.kick_max      = 60;
    _magnum.kick_recovery = 0.4;
    global.weapon_defs[WEAPON_ID.MAGNUM] = _magnum;

    // NUEVO — estilo automática: tiembla arriba y abajo, las balas salen desparejas.
    var _smg = new WeaponDef();
    _smg.name          = "SMG";
    _smg.sprite        = spr_weapon_gun_1;      // TEMPORAL: sprite prestado de la pistola
    _smg.automatic     = true;
    _smg.ammo_max      = 30;
    _smg.fire_delay    = 4;
    _smg.recoil        = 0.6;
    _smg.bullet_speed  = 14;
    _smg.bullet_life   = 40;
    _smg.muzzle_x      = 22;
    _smg.kick_jitter   = 4;
    _smg.kick_max      = 15;
    _smg.kick_recovery = 0.6;
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