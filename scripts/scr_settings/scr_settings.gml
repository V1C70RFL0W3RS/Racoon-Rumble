/// @file scr_settings
/// Ajustes del jugador (accesibilidad, opciones). ÚNICO lugar donde viven.
/// Hoy solo están en memoria; cuando exista el menú de opciones se guardarán en un
/// archivo (el pendiente de "ajustes persistentes", p. ej. la escala de la GUI).

/// @desc Crea global.settings con sus valores por defecto. Se llama UNA vez,
///       primero que nada, en el Create de obj_game_manager.
function settings_init() {
    global.settings = {
        show_ammo_pips: true,   // accesibilidad: puntitos de munición sobre el jugador
        sfx_volume:     1,      // volumen de los efectos de sonido (0 a 1)
    };
}