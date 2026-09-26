// Último arma que generó este spawner (para saber si sigue en su puesto).
current_weapon = noone;

// Cuenta regresiva hasta generar otra arma cuando el punto queda libre.
respawn_timer = WEAPON_SPAWNER_RESPAWN_FRAMES;

// Arma decidida por el sorteo en modo "Aleatoria fija". undefined = todavía no se sorteó.
locked_weapon_id = undefined;

/// Crea un arma en este punto. Único lugar del spawner que crea armas.
spawn_weapon = function() {
    var _id;

    if (weapon_choice == WEAPON_CHOICE_RANDOM_LOCKED) {
        // Se sortea la primera vez y después se reutiliza el mismo resultado.
        if (is_undefined(locked_weapon_id)) locked_weapon_id = weapon_pick_random_id();
        _id = locked_weapon_id;
    } else {
        // "Aleatoria" sortea de nuevo en cada respawn; el resto es un arma fija.
        _id = weapon_id_from_choice(weapon_choice);
    }

    current_weapon = instance_create_layer(x, y, "layer_items", obj_weapon, { weapon_id: _id });
    respawn_timer = WEAPON_SPAWNER_RESPAWN_FRAMES;
};

// Primera arma de la ronda.
spawn_weapon();