// Base de TODO objeto que se puede agarrar, soltar y lanzar (armas, piezas
// de cadáver, y a futuro cajas o equipamiento). Aquí vive solo lo que todos
// comparten; lo propio de cada tipo va en el hijo.

// Quién lo sostiene. noone = está suelto en el mundo.
holder = noone;

// Físicas manuales, mismo criterio que obj_player.
hsp = 0;
vsp = 0;
tilemap = layer_tilemap_get_id("layer_collision");

// Rotación solo VISUAL (no usamos image_angle: rotaría también la máscara de colisión).
angle = 0;   // ángulo actual con que se dibuja
spin  = 0;   // grados por frame mientras está en el aire

image_speed = 0;   // el frame lo elige quien lo dibuja, no la animación automática

// Color de jugador con que se tiñe. -1 = sin teñir. (Guarda: puede llegar por struct.)
if (!variable_instance_exists(id, "color_index")) color_index = -1;

rotates = true;   // false en objetos que no giran (cajas): siempre rectos
fires   = false;  // true solo en las armas
kick    = 0;      // inclinación visual en grados; solo las armas la cambian

// Cómo se dibuja mientras alguien lo sostiene (lo actualiza player_update_held_position).
// Algunos objetos, como las mitades del cadáver, lo necesitan para ubicar su punto de unión.
held_angle  = 0;
held_facing = 1;

// Punto por donde la mano sujeta el objeto, en px respecto del origen. Las armas
// tienen el origen EN el agarre, así que se quedan en (0, 0).
grip_x = 0;
grip_y = 0;

// true = el propio objeto decide su ángulo cada frame (las mitades del cadáver). Las físicas
// de giro del padre (spin, aterrizar de pie o acostado) no se aplican.
drives_angle = false;

// Parámetros de físicas que cada hijo puede cambiar. Estos valores dejan a las armas igual que antes.
air_friction_mult = 1;                 // 1 = fricción normal en el aire; menor = vuela más lejos
wall_bounce       = HOLDABLE_WALL_BOUNCE; // fracción de velocidad que conserva al chocar de lado
floor_bounce      = 0;                 // 0 = se posa sin rebotar; mayor = rebota contra el piso