/// @file scr_player_ragdoll
/// Modo ragdoll: el jugador se tira al piso y "se hace el muerto". Su cuerpo ES un cadáver de
/// dos piezas (corpse_spawn con dueño, ver scr_corpse): misma física, y los demás lo agarran y
/// lo lanzan igual que a un cadáver. No hay física nueva.
///
/// Mientras dura, el jugador queda invisible y SIGUE a sus piezas: para la cámara, la ronda y
/// (a futuro) la red, sigue siendo un jugador vivo. Una bala o una caja que golpea una pieza
/// golpea al jugador (bandera body_of): ver obj_projectile y holdable_try_crush.
///
/// Todas las funciones se ejecutan como el jugador.

/// @desc ¿Puede tirarse al piso ahora?
function player_ragdoll_can_enter() {
    return state != PLAYER_STATE.DEAD && state != PLAYER_STATE.RAGDOLL
        && using == noone && ragdoll_cooldown <= 0;
}

/// @desc Se tira al piso: suelta lo que tenía y su cuerpo pasa a ser una pareja de piezas.
function player_ragdoll_enter() {
    player_drop_item(0, 0, 0);   // lo que tenía en la mano cae, como al agacharse
    // Se le cae el gorro (va ANTES de cambiar de estado: sale de la cabeza con la pose actual).
    // Para recuperarlo hay que levantarse y agarrarlo. Cuerpo y pies siguen puestos.
    player_unequip_drop(EQUIP_SLOT.HEAD);

    // El cuerpo hereda TODA la velocidad del jugador: tirarse en pleno salto sigue el arco del
    // salto en vez de caer recto. El volteo adelanta la cabeza, así gira en el aire.
    var _pair = corpse_spawn(x, y, facing, hsp * RAGDOLL_INERTIA, vsp,
                             player_get_color_index(player_index), hsp * RAGDOLL_TUMBLE, id);
    ragdoll_upper = _pair.upper;
    ragdoll_lower = _pair.lower;

    state   = PLAYER_STATE.RAGDOLL;
    visible = false;   // el cuerpo lo dibujan las piezas; con visible = false no corre el Draw
    hsp = 0;
    vsp = 0;
    crouching = false;
    sliding   = false;
    hovering  = false;
    jumping   = false;
    arm_raise = 0;
    ragdoll_cooldown    = RAGDOLL_COOLDOWN_FRAMES;
    ragdoll_crawl_timer = 0;
}

/// @desc Un frame en ragdoll: seguir al cuerpo, arrastrarse o sacudirse, y levantarse saltando.
/// @param {Struct} _in Input del frame.
function player_ragdoll_update(_in) {
    // Sin cuerpo (no debería pasar): se levanta donde está para no quedar en un estado roto.
    if (!instance_exists(ragdoll_upper) || !instance_exists(ragdoll_lower)) {
        player_ragdoll_exit();
        return;
    }

    player_ragdoll_follow();
    if (y > room_height + ROOM_FALL_KILL_MARGIN) { player_die(); return; }
    // El cuerpo tirado sobre pinchos se pincha (las botas solo protegen los pies al estar de pie).
    var _spiked = false;
    with (ragdoll_upper) if (place_meeting(x, y, obj_spikes)) _spiked = true;
    with (ragdoll_lower) if (place_meeting(x, y, obj_spikes)) _spiked = true;
    if (_spiked) { player_die(90, PLAYER_SPIKE_POP); return; }

    var _u = ragdoll_upper;
    var _w = ragdoll_lower;
    var _held = (_u.holder != noone || _w.holder != noone);

    if (ragdoll_crawl_timer > 0) ragdoll_crawl_timer--;
    if (_in.move_x != 0 && ragdoll_crawl_timer <= 0) {
        if (_held) {
            // Atrapado: solo se sacude la pieza que cuelga, que gira sola alrededor de la
            // cintura. La sostenida es un punto fijo (corpse_pair_update): quien la lleva NO se mueve.
            var _free = (_u.holder == noone) ? _u : _w;
            _free.hsp += _in.move_x * RAGDOLL_STRUGGLE_IMPULSE;
            _free.vsp -= RAGDOLL_STRUGGLE_IMPULSE * 0.5;
            ragdoll_crawl_timer = RAGDOLL_STRUGGLE_INTERVAL;
        } else if (player_ragdoll_on_ground()) {
            // Arrastrarse a saltitos: las dos piezas reciben el MISMO empujón horizontal (si una
            // recibiera más, el cuerpo giraría y daría un "cabezazo" contra el piso). La que va
            // adelante en la dirección del movimiento salta apenas más alto que la de atrás: así
            // la cintura se dobla un poco en cada saltito, sin importar si va la cabeza o los pies.
            var _lead  = (sign(_u.x - _w.x) == -_in.move_x) ? _w : _u;
            var _trail = (_lead == _u) ? _w : _u;
            _lead.hsp  += _in.move_x * RAGDOLL_CRAWL_IMPULSE;
            _trail.hsp += _in.move_x * RAGDOLL_CRAWL_IMPULSE;
            _lead.vsp   = RAGDOLL_CRAWL_HOP_LEAD;
            _trail.vsp  = RAGDOLL_CRAWL_HOP_TRAIL;
            ragdoll_crawl_timer = RAGDOLL_CRAWL_INTERVAL;
        }
    }

    // DECISIÓN: saltar solo levanta con el cuerpo APOYADO. Atrapado en una mano o volando por el
    // aire no se puede: se levanta cuando lo sueltan o lo lanzan, y cae al piso.
    if (_in.jump_pressed && !_held && ragdoll_cooldown <= 0 && player_ragdoll_on_ground()) {
        player_ragdoll_exit();
    }
}

/// @desc El jugador (invisible) se ubica sobre su cuerpo: al medio de las dos piezas y con los
///       pies (su origen) bajo la más baja. Así la cámara lo sigue sin saber nada del ragdoll.
function player_ragdoll_follow() {
    x = (ragdoll_upper.x + ragdoll_lower.x) * 0.5;
    y = max(ragdoll_upper.bbox_bottom, ragdoll_lower.bbox_bottom) + 1;
}

/// @desc ¿Alguna pieza está apoyada en el mapa o sobre una plataforma (caja)? Para arrastrarse y
///       para levantarse hace falta un piso.
function player_ragdoll_on_ground() {
    return corpse_piece_on_ground(ragdoll_upper) || corpse_piece_on_ground(ragdoll_lower);
}

/// @desc ¿Esta pieza tiene piso justo debajo? DECISIÓN: no se usa "vsp == 0", porque también
///       vale 0 al chocar con un techo, y saltando contra uno el jugador se levantaría en el aire.
function corpse_piece_on_ground(_p) {
    with (_p) {
        if (place_meeting(x, y + 1, tilemap)) return true;
        var _b = y + mask_bottom_offset();
        return platform_find_below(bbox_left, bbox_right, _b, _b + 1, id) != noone;
    }
    return false;
}

/// @desc Se levanta: vuelve a ser visible donde está su cuerpo, y las piezas desaparecen.
function player_ragdoll_exit() {
    if (instance_exists(ragdoll_upper) && instance_exists(ragdoll_lower)) {
        player_ragdoll_follow();
        facing = (ragdoll_upper.image_xscale < 0) ? -1 : 1;
        holdable_destroy(ragdoll_upper);
        holdable_destroy(ragdoll_lower);
    }
    ragdoll_upper = noone;
    ragdoll_lower = noone;

    // Máscara de pie ANTES de desincrustar: el cuerpo tirado ocupa menos que el jugador parado.
    sprite_index = spr_player_run;
    image_index  = 0;
    instance_depenetrate(id, HOLDABLE_MAX_PUSHOUT);

    state       = PLAYER_STATE.FALL;
    visible     = true;
    is_grounded = false;
    hsp = 0;
    vsp = RAGDOLL_GETUP_HOP;
    ragdoll_cooldown = RAGDOLL_COOLDOWN_FRAMES;
}

/// @desc Muere estando en ragdoll (lo llama player_die). No se crea otro cadáver: el cuerpo que
///       ya existe pasa a estar muerto. Si cayó fuera del mapa, desaparece (como de pie).
/// @param {Real} _dir Dirección del golpe (grados).
/// @param {Real} _power Empujón del golpe. 0 = muerte sin golpe (caída).
function player_ragdoll_die(_dir, _power) {
    var _u = ragdoll_upper;
    var _w = ragdoll_lower;
    ragdoll_upper = noone;
    ragdoll_lower = noone;
    if (!instance_exists(_u) || !instance_exists(_w)) return;

    if (_u.y >= room_height) {
        holdable_destroy(_u);
        holdable_destroy(_w);
        return;
    }
    var _spread = (_power > 0) ? FX_FUR_DEATH_SPREAD : 180;
    fx_fur(_u.x, _u.y, _dir, _spread, player_get_color_index(player_index), FX_FUR_DEATH_COUNT);
    corpse_pair_kill(_u, _w);
}
