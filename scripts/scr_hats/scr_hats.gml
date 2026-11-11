/// @file scr_hats
/// Catálogo de gorros y su dibujo. Todos los gorros viven en UN sprite (spr_hats): el índice
/// del gorro ES su frame. Frame 0 = sin gorro (vacío).
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

/// @desc Dibuja un gorro con su base en (_x, _y). _xscale = hacia dónde mira (1 o -1).
function hat_draw(_index, _x, _y, _xscale) {
    if (_index <= 0) return;   // 0 = sin gorro
    draw_sprite_ext(spr_hats, _index, _x, _y, _xscale, 1, 0, c_white, 1);
}

/// @desc Gorro elegido por un jugador. Vive en global.match (como el color) porque los
///       jugadores se recrean en cada ronda y deben conservarlo.
function player_get_hat_index(_player_index) {
    return global.match.players_joined[_player_index].hat_index;
}

/// @desc Dónde va la base del gorro (la coronilla). Sale del HOMBRO, que ya sigue el rebote
///       de cada frame con su tabla (player_shoulder_table_init): así el gorro acompaña la
///       cabeza al correr, agacharse o deslizar sin una tabla propia. Ejecutar como el jugador.
function player_hat_x() { return player_shoulder_x() + facing * PLAYER_HAT_DX; }
function player_hat_y() { return player_shoulder_y() + PLAYER_HAT_DY; }
