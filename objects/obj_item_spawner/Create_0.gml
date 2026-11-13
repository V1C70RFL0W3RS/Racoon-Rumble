// Punto donde aparecen objetos (armas, gorros...). QUÉ aparece lo elige item_choice en el editor
// (ver scr_spawn_items); el spawner no conoce ningún tipo de objeto.

// Último objeto que generó este spawner (para saber si sigue en su puesto).
current_item = noone;

// Cuenta regresiva hasta generar otro cuando el punto queda libre.
respawn_timer = ITEM_SPAWNER_RESPAWN_FRAMES;

// Resultado del sorteo en las opciones "fija/fijo". undefined = todavía no se sorteó.
locked_item = undefined;

/// Crea un objeto en este punto. Único lugar del spawner que crea objetos.
spawn_item = function() {
    var _index;
    if (spawn_choice_is_locked(item_choice)) {
        // Se sortea la primera vez y después se reutiliza el mismo resultado toda la ronda.
        if (is_undefined(locked_item)) locked_item = spawn_items_from_choice(item_choice);
        _index = locked_item;
    } else {
        _index = spawn_items_from_choice(item_choice);
    }

    current_item  = spawn_items_create(_index, x, y);
    respawn_timer = ITEM_SPAWNER_RESPAWN_FRAMES;
};

// Primer objeto de la ronda.
spawn_item();
