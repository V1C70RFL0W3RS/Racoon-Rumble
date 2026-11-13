event_inherited(); // inicializa: users, max_users, use_slot, menu, menu_title, image_speed

// PC del host: los ajustes de la partida. Solo el host la usa, de a uno. (El color y el gorro de
// cada jugador se cambian en el ropero: obj_wardrobe.)
use_slot   = INTERACT_HOST;
menu_title = "Ajustes de partida";
menu = [
    menu_option("Puntos para ganar", "score_to_win",     lobby_setting_text, lobby_setting_step),
    menu_option("Rondas por bloque", "rounds_per_block", lobby_setting_text, lobby_setting_step),
    menu_option("Máx. jugadores",    "max_players",      lobby_setting_text, lobby_setting_step),
];
