function player_palette_init() {
    global.player_palette = [
        palette_entry("Gris",     make_color_rgb(114, 109, 103)), // el color original
        palette_entry("Rojo",     make_color_rgb(200,  50,  50)),
        palette_entry("Amarillo", make_color_rgb(215, 170,  30)),
        palette_entry("Verde",    make_color_rgb( 60, 150,  70)),
        palette_entry("Azul",     make_color_rgb( 55, 100, 200)),
        palette_entry("Blanco",   make_color_rgb(190, 190, 190)),
        palette_entry("Naranja",  make_color_rgb(215, 115,  35)),
        palette_entry("Violeta",  make_color_rgb(130,  70, 180))
    ];
    global.u_player_mid   = shader_get_uniform(sh_player_tint, "u_mid");
    global.u_player_light = shader_get_uniform(sh_player_tint, "u_light");
}

function palette_entry(_name, _mid) {
    // DECISIÓN: el tono claro se deriva del medio (agregar un color = una línea).
    var _light = merge_color(_mid, c_white, 0.4);
    return {
        name: _name,
        mr: color_get_red(_mid)     / 255, mg: color_get_green(_mid)     / 255, mb: color_get_blue(_mid)     / 255,
        lr: color_get_red(_light)   / 255, lg: color_get_green(_light)   / 255, lb: color_get_blue(_light)   / 255
    };
}

function palette_apply(_index) {
    var _c = global.player_palette[_index mod array_length(global.player_palette)];
    shader_set(sh_player_tint);
    shader_set_uniform_f(global.u_player_mid,   _c.mr, _c.mg, _c.mb);
    shader_set_uniform_f(global.u_player_light, _c.lr, _c.lg, _c.lb);
}

function palette_reset() {
    shader_reset();
}

/// @desc Devuelve el primer color de la paleta que ningún jugador unido usa todavía.
///       Si hay más jugadores que colores, devuelve el 0 (se repite).
function palette_first_free_index() {
    var _joined = global.match.players_joined;
    var _count  = array_length(global.player_palette);

    for (var c = 0; c < _count; c++) {
        var _taken = false;
        for (var i = 0; i < array_length(_joined); i++) {
            if (_joined[i].color_index == c) { _taken = true; break; }
        }
        if (!_taken) return c;
    }
    return 0;
}

/// @desc Índice de paleta del jugador dado. El color vive en global.match (no en
///       obj_player) porque los jugadores se recrean en cada ronda y deben conservarlo.
function player_get_color_index(_player_index) {
    return global.match.players_joined[_player_index].color_index;
}