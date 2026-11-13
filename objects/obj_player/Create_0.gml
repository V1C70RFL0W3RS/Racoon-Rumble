// Llega por el struct de instance_create_layer (obj_game_manager, Room Start). Guarda por si no.
if (!variable_instance_exists(id, "player_index")) player_index = 0;
hsp = 0;
vsp = 0;
is_grounded = false;
standing_on = noone;        // plataforma (caja) sobre la que está parado; noone = piso o aire
platform_drop_timer = 0;    // > 0 = está bajándose de una plataforma: no aterriza en ninguna
facing = 1;
state = PLAYER_STATE.IDLE;
held_item = noone;
using = noone;   // objeto que está usando (PC del host, ropero...); mientras tanto no se mueve
menu_cursor = menu_cursor_create();   // su cursor en el menú del objeto que usa (scr_menu_options)
tilemap = layer_tilemap_get_id("layer_collision");
aim_up = false;
hp = PLAYER_MAX_HP;
image_speed = 0;  // DECISIÓN: el frame lo elige player_update_animation(), no el motor
anim_time   = 0;  // contador propio de la animación actual
coyote_timer = 0;
jump_buffer  = 0;
jumping  = false;   // true desde que salta hasta que suelta el botón (para el corte único)
hovering = false;   // true mientras aletea
crouching = false;   // agachado y casi quieto
sliding   = false;   // deslizando (agachado con inercia)
arm_raise = 0;   // 0 = brazo en su ángulo normal, 1 = levantado del todo porque el arma toca una pared
ammo_pips_timer = 0;   // frames que les quedan a los puntitos de munición (accesibilidad)

// Ragdoll (scr_player_ragdoll): las dos piezas que son su cuerpo mientras está tirado.
ragdoll_upper       = noone;
ragdoll_lower       = noone;
ragdoll_cooldown    = 0;   // frames que faltan para poder entrar o salir otra vez
ragdoll_crawl_timer = 0;   // frames que faltan para el próximo tirón de arrastre

// Equipamiento (scr_equipment): una ficha por ranura (cabeza, cuerpo, pies). Empieza con el gorro del lobby.
player_equip_init();

// TEMPORAL: afinador del hombro (ver player_debug_tune_shoulder).
shoulder_tune = false;
tune_pose     = 0;
tune_frame    = 0;
// Ángulo forzado del brazo, uno por pose y frame: [pose][frame]. undefined = automático.
tune_angles = [
    array_create(8, undefined),   // run
    array_create(8, undefined),   // jump
    array_create(8, undefined),   // crouch
    array_create(8, undefined)    // slide
];