/// @file scr_hats
/// Catálogo de gorros. Todos los gorros viven en UN sprite (spr_hats): el índice del gorro ES su
/// frame. Frame 0 = sin gorro (vacío). Puestos se dibujan con scr_equipment; sueltos son obj_hat.
/// Agregar un gorro = dibujar un frame nuevo en spr_hats + una línea en hats_init().

/// @desc Crea el catálogo. Se llama UNA vez en el Create de obj_game_manager.
function hats_init() {
    global.hats = [
        "Sin gorro",       // 0
        "Gorra",           // 1
        "Sombrero",        // 2
        "Corona",          // 3
        "Gorro de lana"    // 4
    ];
}

function hat_count() { return array_length(global.hats); }

function hat_get_name(_index) { return global.hats[_index mod hat_count()]; }

/// @desc Ficha de equipamiento de un gorro (ver scr_equipment). Lo que se lleva puesto se guarda
///       como datos; al caerse se convierte en un obj_hat con este frame.
function hat_spec(_index) {
    var _spec = equip_spec_make(obj_hat, spr_hats, _index, EQUIP_SLOT.HEAD);   // un gorro no detiene balas
    _spec.worn_offset = [HAT_WORN_DX, HAT_WORN_DY];   // los gorros van un poco distinto que el casco
    return _spec;
}

/// @desc Gorro elegido por un jugador. Vive en global.match (como el color) porque los
///       jugadores se recrean en cada ronda y deben conservarlo.
function player_get_hat_index(_player_index) {
    return global.match.players_joined[_player_index].hat_index;
}
