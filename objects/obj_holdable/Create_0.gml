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
recoil_back = 0;  // px que retrocede hacia el hombro (kick lineal); solo las armas lo cambian

// Balas. shootable = las balas lo detectan (y se detienen en él, salvo munición con pierce).
// impact_mult = qué tanto lo mueve el impacto (1 = normal; menor = más pesado; 0 = no se mueve).
shootable   = false;
impact_mult = 1;
block_chance = 1;   // probabilidad (0 a 1) de DETENER la bala; si no, la deja pasar (igual la empuja)
hit_fx = HIT_FX.NONE;   // efecto visual al recibir una bala (ver fx_holdable_hit)
shield_when_held = false;   // true = las balas lo golpean aunque esté en una mano (escudo)

// Vida. -1 = indestructible (armas, cadáver). Si llega a 0 se rompe (holdable_break).
max_hp = -1;
hp     = -1;

// true = los jugadores pueden pararse encima cuando está suelto (plataforma de un solo
// sentido: se atraviesa de lado y desde abajo). Ver player_land_on_platform.
platform = false;

// > 0 = si cae sobre la cabeza de un jugador a esta velocidad (px/frame) o más, lo mata.
crush_speed = 0;

// Jugador VIVO al que pertenece este objeto como cuerpo (piezas de un ragdoll). noone = de nadie.
// Una bala o una caja que lo golpea, golpea a ese jugador (ver obj_projectile y holdable_try_crush).
body_of = noone;

// Ranura donde se PONE (EQUIP_SLOT.HEAD, BODY, FEET), o EQUIP_NONE si no se equipa. Agarrar algo
// equipable con las manos vacías lo pone en vez de llevarlo en la mano (ver scr_equipment).
equip_slot = EQUIP_NONE;
// Campos de equipo (balas que detiene, si pisotea, etc.) con sus valores por defecto: scr_equipment.
equip_fields_init(id);

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