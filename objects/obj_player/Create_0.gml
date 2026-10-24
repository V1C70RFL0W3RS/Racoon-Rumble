player_index = 0;
hsp = 0;
vsp = 0;
is_grounded = false;
facing = 1;
state = PLAYER_STATE.IDLE;
held_weapon = noone;
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

// TEMPORAL: afinador del hombro (ver player_debug_tune_shoulder).
shoulder_tune = false;
tune_pose     = 0;
tune_frame    = 0;
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