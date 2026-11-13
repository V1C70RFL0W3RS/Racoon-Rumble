/// @file scr_spawn_items
/// Catálogo de lo que puede aparecer en un obj_item_spawner: armas, gorros y equipo (casco,
/// chaleco, botas). Cada entrada sabe crearse a sí misma, así el spawner no conoce
/// ningún tipo de objeto.
///
/// Las opciones del spawner (variable item_choice, lista en el editor) son TEXTO:
///   - el nombre de un objeto del catálogo ("Pistola", "Corona"...): siempre ese;
///   - una opción aleatoria de global.spawn_choices ("Aleatoria", "Gorro aleatorio fijo"...): sortea
///     dentro de un grupo, en cada aparición o una sola vez por ronda ("fija/fijo").
/// Agregar algo nuevo = una entrada aquí + su texto en la lista del editor de obj_item_spawner.

/// @desc Arma el catálogo. Llamar UNA vez en el Create de obj_game_manager, después de
///       weapon_data_init y hats_init (los lee).
function spawn_items_init() {
    global.spawn_items = [];   // { name, group, make: function(_x, _y) -> instancia }

    // Armas: una entrada por cada WeaponDef, con su nombre.
    for (var _i = 0; _i < WEAPON_ID.COUNT; _i++) {
        spawn_items_add(weapon_get_def(_i).name, SPAWN_GROUP.WEAPON, method({ weapon: _i }, function(_x, _y) {
            return instance_create_layer(_x, _y, "layer_items", obj_weapon, { weapon_id: weapon });
        }));
    }

    // Gorros: todos menos el 0 ("Sin gorro").
    for (var _h = 1; _h < hat_count(); _h++) {
        spawn_items_add(hat_get_name(_h), SPAWN_GROUP.HAT, method({ hat: _h }, function(_x, _y) {
            return equip_spawn(hat_spec(hat), _x, _y);
        }));
    }

    // Equipo: casco y chaleco detienen una bala y se rompen; las botas pisan cabezas y pinchos.
    spawn_items_add("Casco",   SPAWN_GROUP.EQUIPMENT, function(_x, _y) { return instance_create_layer(_x, _y, "layer_items", obj_helmet); });
    spawn_items_add("Chaleco", SPAWN_GROUP.EQUIPMENT, function(_x, _y) { return instance_create_layer(_x, _y, "layer_items", obj_vest); });
    spawn_items_add("Botas",   SPAWN_GROUP.EQUIPMENT, function(_x, _y) { return instance_create_layer(_x, _y, "layer_items", obj_boots); });

    // Opciones aleatorias del editor: texto → { grupo, fija }. "fija" = se sortea una vez por ronda.
    global.spawn_choices = {};
    global.spawn_choices[$ "Aleatoria"]            = { group: SPAWN_GROUP.WEAPON, locked: false };
    global.spawn_choices[$ "Aleatoria fija"]       = { group: SPAWN_GROUP.WEAPON, locked: true  };
    global.spawn_choices[$ "Gorro aleatorio"]      = { group: SPAWN_GROUP.HAT,    locked: false };
    global.spawn_choices[$ "Gorro aleatorio fijo"] = { group: SPAWN_GROUP.HAT,    locked: true  };
    global.spawn_choices[$ "Equipo aleatorio"]      = { group: SPAWN_GROUP.EQUIPMENT, locked: false };
    global.spawn_choices[$ "Equipo aleatorio fijo"] = { group: SPAWN_GROUP.EQUIPMENT, locked: true  };
}

function spawn_items_add(_name, _group, _make) {
    array_push(global.spawn_items, { name: _name, group: _group, make: _make });
}

/// @desc Índice al azar de un objeto del grupo, o -1 si el grupo está vacío.
function spawn_items_pick_random(_group) {
    var _pool = [];
    for (var _i = 0; _i < array_length(global.spawn_items); _i++) {
        if (global.spawn_items[_i].group == _group) array_push(_pool, _i);
    }
    return (array_length(_pool) > 0) ? _pool[irandom(array_length(_pool) - 1)] : -1;
}

/// @desc ¿La opción se sortea una sola vez por ronda? (lo recuerda el spawner)
function spawn_choice_is_locked(_choice) {
    var _c = global.spawn_choices[$ _choice];
    return !is_undefined(_c) && _c.locked;
}

/// @desc Convierte una opción del editor (texto) en un índice del catálogo.
function spawn_items_from_choice(_choice) {
    var _c = global.spawn_choices[$ _choice];
    if (!is_undefined(_c)) return spawn_items_pick_random(_c.group);

    for (var _i = 0; _i < array_length(global.spawn_items); _i++) {
        if (global.spawn_items[_i].name == _choice) return _i;
    }

    // Texto que no existe: se avisa y se usa un arma al azar para que el juego no se caiga.
    show_debug_message("spawn_items_from_choice: opción desconocida '" + string(_choice) + "', se usa un arma al azar.");
    return spawn_items_pick_random(SPAWN_GROUP.WEAPON);
}

/// @desc ÚNICO lugar donde un spawner crea un objeto.
function spawn_items_create(_index, _x, _y) {
    return global.spawn_items[_index].make(_x, _y);
}
