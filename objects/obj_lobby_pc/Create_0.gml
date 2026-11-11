event_inherited(); // inicializa: user, use_slot, menu, menu_title, menu_index, nav_dir, nav_timer, image_speed

// pc_slot define qué jugador "dueño" tiene esta PC (variable de instancia puesta en el IDE).
//   INTERACT_HOST (-1) → PC del host: ajustes de partida
//   0..3            → PC del jugador N

use_slot = pc_slot; // solo el dueño puede usarla

if (pc_slot == INTERACT_HOST) {
    menu_title = "Ajustes de partida";
    menu = [
        menu_option("Puntos para ganar",   "score_to_win",      lobby_setting_text, lobby_setting_step),
        menu_option("Rondas por bloque",   "rounds_per_block",  lobby_setting_text, lobby_setting_step),
        menu_option("Máx. jugadores",      "max_players",       lobby_setting_text, lobby_setting_step),
    ];
} else {
    menu_title = "Jugador " + string(pc_slot + 1);
    menu = [
        menu_option("Color",  pc_slot, lobby_color_text, lobby_color_step),
        menu_option("Gorro",  pc_slot, lobby_hat_text,   lobby_hat_step),
    ];
}
