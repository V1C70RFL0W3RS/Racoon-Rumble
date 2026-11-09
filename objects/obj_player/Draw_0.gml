// --- obj_player → Draw Event ---
var _color = player_get_color_index(player_index);
var _ang   = player_get_arm_angle(); // un solo ángulo para brazo y arma

// 1. Cuerpo (con color)
palette_apply(_color);
draw_sprite_ext(sprite_index, image_index, x, y, facing, 1, 0, c_white, 1);
palette_reset();

// 2. Arma (sin color), en la mano
if (held_item != noone) {
    holdable_draw_held(held_item, player_hand_x(_ang), player_hand_y(_ang), facing, _ang);
}

// 2b. Destello del clic vacío (solo armas)
if (held_item != noone && held_item.fires) {
    weapon_draw_dry_flash(held_item, player_hand_x(_ang), player_hand_y(_ang), _ang, facing);
}

// 3. Brazo (con color), encima del arma
palette_apply(_color);
player_draw_arm(_ang);
palette_reset();

// 4. Puntitos de munición (accesibilidad), fuera del shader
player_draw_ammo_pips();

if (DEBUG_TOOLS) player_debug_arm(_ang);          // TEMPORAL
if (DEBUG_TOOLS) corpse_debug_draw_joint();       // TEMPORAL
if (DEBUG_TOOLS && held_item != noone && held_item.fires) {
    weapon_debug_muzzle(held_item, player_hand_x(_ang), player_hand_y(_ang), _ang, facing);   // TEMPORAL
}