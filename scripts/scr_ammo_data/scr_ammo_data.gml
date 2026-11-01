/// @file scr_ammo_data
/// Catálogo de tipos de munición (la bala, no el arma). Solo datos CONSTANTES.
/// Misma regla que WEAPON_ID: agregar siempre ANTES de COUNT, nunca reordenar.

enum AMMO_ID {
    LIGHT,    // pistola y SMG
    HEAVY,    // magnum
    PELLET,   // perdigón de escopeta
    COUNT
}

/// @desc Definición de un tipo de bala. Cada tipo declara solo lo que lo distingue.
function AmmoDef() constructor {
    name   = "Munición";
    speed  = 20;    // píxeles por frame
    range  = 300;   // alcance en PÍXELES (lo que importa al diseñar)
    damage = 1;     // 1 = muerte de un golpe (pilar de diseño de Duck Game)
    life   = 0;     // frames de vida: se DERIVA de range/speed, no tocar a mano
}

/// @desc Construye el catálogo de munición. Se llama UNA vez al iniciar el juego.
function ammo_data_init() {
    global.ammo_defs = array_create(AMMO_ID.COUNT);

    // Valores PROVISIONALES: se afinan a ojo en el Paso 4.
    var _light = new AmmoDef();
    _light.name  = "Ligera";
    _light.speed = 20;
    _light.range = 400;
    global.ammo_defs[AMMO_ID.LIGHT] = _light;

    var _heavy = new AmmoDef();
    _heavy.name  = "Pesada";
    _heavy.speed = 24;
    _heavy.range = 500;
    global.ammo_defs[AMMO_ID.HEAVY] = _heavy;

    var _pellet = new AmmoDef();
    _pellet.name  = "Perdigón";
    _pellet.speed = 20;
    _pellet.range = 150;     // escopeta: corto alcance
    global.ammo_defs[AMMO_ID.PELLET] = _pellet;

    // La vida en frames sale siempre del alcance y la velocidad.
    for (var i = 0; i < AMMO_ID.COUNT; i++) {
        var _a = global.ammo_defs[i];
        _a.life = ceil(_a.range / _a.speed);
    }
}

/// @desc Devuelve la definición de una munición. Único punto de acceso al catálogo.
/// @param {Real} _id Valor de AMMO_ID.
/// @returns {Struct.AmmoDef}
function ammo_get_def(_id) {
    return global.ammo_defs[_id];
}