event_inherited(); // inicializa: users, max_users, use_slot, menu, menu_title, image_speed

// Ropero del lobby: cada jugador cambia SU color y SU gorro. Lo pueden usar todos a la vez; cada
// uno ve su propio menú sobre la cabeza (MENU_CTX_USER = el jugador que lo usa).
// Frame 0 = cerrado, frame 1 = abierto (mientras alguien lo usa).
max_users  = MAX_PLAYERS;
use_slot   = INTERACT_ANYONE;
menu_title = "Ropero - Jugador {jugador}";
menu = [
    menu_option("Color", MENU_CTX_USER, lobby_color_text, lobby_color_step),
    menu_option("Gorro", MENU_CTX_USER, lobby_hat_text,   lobby_hat_step),
];
