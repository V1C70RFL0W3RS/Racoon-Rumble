/// @file scr_equipment
/// Equipamiento: lo que el jugador lleva PUESTO en sus tres ranuras (EQUIP_SLOT: cabeza, cuerpo,
/// pies). Ver ADR-004.
///
/// DECISIÓN: puesto, un objeto NO existe como instancia: se guarda como una FICHA de datos en
/// player.equipped[slot]. Así no hay instancias invisibles que esquivar en balas, plataformas o
/// "buscar agarrable", y la ficha es lo que viajará por la red. Al caerse, la ficha vuelve a ser
/// una instancia (equip_spawn). Un objeto se puede equipar si su equip_slot != EQUIP_NONE.
///
/// Ficha: { obj, sprite, frame, slot } + los CAMPOS DE EQUIPO de equip_fields() (cuántas balas
/// detiene, si pisotea, si protege de pinchos...). Las funciones player_* se ejecutan como el jugador.

/// @desc Campos de equipo que viajan en la ficha, con su valor por defecto. ÚNICO lugar donde se
///       definen: los usan obj_holdable (Create), equip_spec_from, equip_spawn y equip_spec_make.
///       Agregar una propiedad nueva a todo el equipamiento = una línea aquí.
function equip_fields() {
    static _defaults = {
        bullet_block: 0,                    // balas que todavía detiene (puesto); 0 = ninguna
        break_cols:   [c_gray, c_dkgray],   // colores de sus pedazos al romperse (fx_armor_break)
        dent_frame:   -1,                   // cabeza: frame "abollado"; >= 0 = aguanta cajas y pisotones (se abolla)
        stomps:       false,                // pies: pisar a alguien en la cabeza lo mata
        spike_proof:  false,                // pies: se puede caminar sobre pinchos
        worn_sprite:         -1,            // pies: botas puestas, un frame por frame del cuerpo (-1 = no se dibuja)
        worn_sprite_ragdoll: -1,            // pies: botas sobre la pieza inferior del ragdoll
        worn_offset:  [0, 0]                // ajuste fino PROPIO del objeto sobre la tabla común de su
                                            // ranura (p. ej. los gorros van 1 px más atrás que el casco).
                                            // Solo en las poses derechas (ángulo 0), no en el slide.
    };
    return _defaults;
}

/// @desc Pone en una instancia los valores por defecto de los campos de equipo (obj_holdable, Create).
function equip_fields_init(_inst) {
    var _d = equip_fields();
    var _names = variable_struct_get_names(_d);
    for (var _i = 0; _i < array_length(_names); _i++) variable_instance_set(_inst, _names[_i], _d[$ _names[_i]]);
}

/// @desc Ficha nueva con los campos de equipo por defecto (para lo que no viene de una instancia,
///       como el gorro elegido en el lobby).
function equip_spec_make(_obj, _sprite, _frame, _slot) {
    var _spec = { obj: _obj, sprite: _sprite, frame: _frame, slot: _slot };
    var _d = equip_fields();
    var _names = variable_struct_get_names(_d);
    for (var _i = 0; _i < array_length(_names); _i++) _spec[$ _names[_i]] = _d[$ _names[_i]];
    return _spec;
}

/// @desc Ficha de un objeto suelto que se va a poner: copia sus campos de equipo.
function equip_spec_from(_h) {
    var _spec = { obj: _h.object_index, sprite: _h.sprite_index, frame: _h.image_index, slot: _h.equip_slot };
    var _names = variable_struct_get_names(equip_fields());
    for (var _i = 0; _i < array_length(_names); _i++) _spec[$ _names[_i]] = variable_instance_get(_h, _names[_i]);
    return _spec;
}

/// @desc ÚNICO lugar donde una ficha vuelve a ser una instancia (quieta, sin dueño). Le devuelve
///       sus campos tal como quedaron (un casco ya usado no vuelve a estar nuevo).
function equip_spawn(_spec, _x, _y) {
    var _h = instance_create_layer(_x, _y, "layer_items", _spec.obj);
    _h.sprite_index = _spec.sprite;
    _h.image_index  = _spec.frame;
    var _names = variable_struct_get_names(equip_fields());
    for (var _i = 0; _i < array_length(_names); _i++) variable_instance_set(_h, _names[_i], _spec[$ _names[_i]]);
    return _h;
}

/// @desc ¿Lo que lleva en los pies tiene esta propiedad? ("stomps", "spike_proof")
function player_feet_have(_field) {
    var _spec = equipped[EQUIP_SLOT.FEET];
    return (_spec != undefined) && _spec[$ _field];
}

/// @desc Ranuras vacías + el gorro elegido en el lobby. Se llama en el Create del jugador: los
///       jugadores se recrean en cada ronda y cada uno vuelve a empezar con SU gorro.
function player_equip_init() {
    equipped = array_create(EQUIP_SLOT.COUNT, undefined);
    player_equip_lobby_hat();
}

/// @desc Pone en la cabeza el gorro elegido en el lobby (o la deja vacía si eligió "sin gorro").
function player_equip_lobby_hat() {
    var _hat = player_get_hat_index(player_index);
    equipped[EQUIP_SLOT.HEAD] = (_hat > 0) ? hat_spec(_hat) : undefined;
}

/// @desc Se pone lo que tiene en la mano (botón de disparar con algo equipable). Lo agarra primero
///       con el botón de agarrar, como cualquier objeto: así también lo puede lanzar.
function player_equip_held() {
    var _h = held_item;
    held_item = noone;   // la mano queda libre: lo que tenía puesto antes puede pasar a ella
    _h.holder = noone;
    player_equip(_h);
    audio_play_sfx(snd_pickup);
}

/// @desc Se pone un objeto. Si ya llevaba algo en esa ranura, lo de antes pasa A LA MANO
///       (la mano tiene que estar vacía: player_equip_held la libera antes).
/// @param {Id.Instance} _h Holdable sin dueño con equip_slot != EQUIP_NONE.
function player_equip(_h) {
    var _slot = _h.equip_slot;
    var _old  = equipped[_slot];
    equipped[_slot] = equip_spec_from(_h);
    holdable_destroy(_h);

    if (_old != undefined) {
        var _o = equip_spawn(_old, x, y);   // la posición la fija player_update_held_position
        _o.holder = id;
        held_item = _o;
    }
}

/// @desc Lo que lleva en una ranura se le cae y sale volando. No hace nada si está vacía.
/// @returns {Id.Instance} El objeto que cayó, o noone.
function player_unequip_drop(_slot) {
    var _spec = equipped[_slot];
    if (_spec == undefined) return noone;
    equipped[_slot] = undefined;

    var _h = equip_spawn(_spec, player_equip_x(_slot), player_equip_y(_slot));
    var _dir = choose(-1, 1);
    holdable_eject(_h, _h.x, _h.y, facing,
                   hsp * EQUIP_DROP_INERTIA + random_range(-EQUIP_DROP_HSP_VAR, EQUIP_DROP_HSP_VAR),
                   vsp * EQUIP_DROP_INERTIA + EQUIP_DROP_POP, EQUIP_DROP_SPIN * _dir);
    return _h;
}

/// @desc Ranuras que pueden detener un golpe en cada zona del cuerpo. La cabeza (y lo que cae
///       desde arriba) solo la protege el casco; todo lo demás, solo el peto. El calzado no
///       detiene balas.
function equip_block_order(_zone) {
    static _orders = [
        [EQUIP_SLOT.HEAD],   // HIT_ZONE.HEAD
        [EQUIP_SLOT.BODY],   // HIT_ZONE.BODY
        [EQUIP_SLOT.HEAD]    // HIT_ZONE.TOP (una caja o un pisotón en la cabeza)
    ];
    return _orders[_zone];
}

/// @desc ¿Algo puesto detiene este golpe? Lo llama player_take_hit ANTES de quitar vida (de pie o
///       en ragdoll).
///         - Desde arriba (caja, pisotón): un casco (dent_frame >= 0) lo aguanta SIEMPRE y solo se
///           abolla (pasa a su frame abollado); no gasta balas ni se rompe.
///         - Bala: gasta una de sus balas; si se le acabaron, se rompe en pedazos.
/// @param {Real} _zone HIT_ZONE donde pegó.
/// @param {Real} _dir Dirección del golpe (grados), para los efectos.
/// @returns {Bool} true = el golpe se detuvo.
function player_equip_try_block(_zone, _dir) {
    var _order = equip_block_order(_zone);
    for (var _i = 0; _i < array_length(_order); _i++) {
        var _slot = _order[_i];
        var _spec = equipped[_slot];
        if (_spec == undefined) continue;
        var _px = player_equip_world_x(_slot);
        var _py = player_equip_world_y(_slot);

        if (_zone == HIT_ZONE.TOP && _spec.dent_frame >= 0) {
            _spec.frame = _spec.dent_frame;           // se abolla (y queda abollado si se cae)
            fx_bullet_sparks(_px, _py, _dir);
            audio_play_sfx(snd_bullet_wall, 0.1);      // PLACEHOLDER: snd_helmet_dent
            return true;
        }
        if (_spec.bullet_block <= 0) continue;

        _spec.bullet_block--;
        if (_spec.bullet_block <= 0) {
            equipped[_slot] = undefined;
            fx_armor_break(_px, _py, _dir, _spec);
        } else {
            fx_bullet_sparks(_px, _py, _dir);   // aguantó: solo chispas
        }
        return true;
    }
    return false;
}

/// @desc Dónde está de verdad una ranura: sobre el jugador, o en ragdoll sobre su pieza del cuerpo
///       (el jugador está invisible). Pies = pieza inferior; cabeza y cuerpo = superior.
function player_equip_world_x(_slot) {
    if (state != PLAYER_STATE.RAGDOLL) return player_equip_x(_slot);
    var _p = (_slot == EQUIP_SLOT.FEET) ? ragdoll_lower : ragdoll_upper;
    return instance_exists(_p) ? _p.x : x;
}
function player_equip_world_y(_slot) {
    if (state != PLAYER_STATE.RAGDOLL) return player_equip_y(_slot);
    var _p = (_slot == EQUIP_SLOT.FEET) ? ragdoll_lower : ragdoll_upper;
    return instance_exists(_p) ? _p.y : y;
}

/// @desc Se le cae todo lo que lleva puesto (al morir).
function player_unequip_drop_all() {
    for (var _s = 0; _s < EQUIP_SLOT.COUNT; _s++) player_unequip_drop(_s);
}

/// @desc Dónde va cada ranura en el mundo y con qué ángulo: cada una tiene su tabla por pose
///       (player_equip_table_init), porque la cabeza y el torso cambian de lugar y de ángulo
///       (en el slide el mapache va acostado). facing espeja el lado y el giro.
function player_equip_x(_slot)     { return x + facing * (player_get_equip_pose(_slot)[0] + player_equip_offset(_slot, 0)); }
function player_equip_y(_slot)     { return y + player_get_equip_pose(_slot)[1] + player_equip_offset(_slot, 1); }

/// @desc Ajuste fino del objeto puesto en esa ranura (worn_offset), eje 0 = x (hacia adelante),
///       1 = y. Solo en poses derechas: en el slide (acostado) manda la tabla común.
function player_equip_offset(_slot, _axis) {
    var _spec = equipped[_slot];
    if (_spec == undefined || player_get_equip_pose(_slot)[2] != 0) return 0;
    return _spec.worn_offset[_axis];
}
function player_equip_angle(_slot) { return player_get_equip_pose(_slot)[2] * facing; }

/// @desc Centro de la cabeza (para saber si una bala pegó en ella): la base del gorro, unos px
///       hacia adentro de la cabeza, en la dirección de la pose (en el slide, hacia el cuerpo).
function player_head_center_x() {
    return player_equip_x(EQUIP_SLOT.HEAD) + dsin(player_equip_angle(EQUIP_SLOT.HEAD)) * PLAYER_HEAD_ZONE_DEPTH;
}
function player_head_center_y() {
    return player_equip_y(EQUIP_SLOT.HEAD) + dcos(player_equip_angle(EQUIP_SLOT.HEAD)) * PLAYER_HEAD_ZONE_DEPTH;
}

/// @desc Dibuja lo que lleva puesto (sin color de jugador). Pies y cuerpo primero, cabeza encima.
///       Los pies no usan el sprite del objeto suelto: tienen uno dibujado por pose (equip_draw_feet).
function player_draw_equipment() {
    for (var _s = EQUIP_SLOT.COUNT - 1; _s >= 0; _s--) {
        var _spec = equipped[_s];
        if (_spec == undefined) continue;
        if (_s == EQUIP_SLOT.FEET) {
            equip_draw_feet(_spec, sprite_index, image_index, x, y, facing, 0);
        } else {
            draw_sprite_ext(_spec.sprite, _spec.frame, player_equip_x(_s), player_equip_y(_s),
                            facing, 1, player_equip_angle(_s), c_white, 1);
        }
    }
}

/// @desc Dibuja el calzado puesto sobre un cuerpo (jugador o pieza de ragdoll). Las botas tienen un
///       frame dibujado para cada frame del cuerpo, del mismo tamaño y con el mismo origen: se dibujan
///       con la misma escala y el mismo giro y caen justo sobre los pies (feet_frame_base).
/// @param {Struct} _spec Ficha del calzado.
/// @param {Asset.GMSprite} _body_spr Sprite del cuerpo que lo lleva.
/// @param {Real} _sub Frame actual de ese cuerpo.
function equip_draw_feet(_spec, _body_spr, _sub, _x, _y, _xscale, _angle) {
    var _base = feet_frame_base(_body_spr);
    var _spr  = (_body_spr == spr_corpse_lower) ? _spec.worn_sprite_ragdoll : _spec.worn_sprite;
    if (_base < 0 || _spr < 0) return;
    draw_sprite_ext(_spr, _base + floor(_sub), _x, _y, _xscale, 1, _angle, c_white, 1);
}

/// @desc Con botas que pisotean: si viene cayendo sobre la CABEZA de otro jugador, lo mata (como
///       una caja que le cae, HIT_ZONE.TOP: un casco lo salva) y rebota. "Sobre la cabeza" = sus
///       pies estaban arriba de la cabeza del otro al empezar el frame y ahora la alcanzan.
/// @param {Real} _b0 Su borde inferior ANTES de moverse este frame.
/// @param {Real} _fall Su velocidad vertical antes de moverse.
function player_try_stomp(_b0, _fall) {
    if (_fall < PLAYER_STOMP_MIN_FALL || !player_feet_have("stomps")) return;
    var _me  = id;
    var _hit = false;
    with (obj_player) {
        if (id == _me || !player_is_upright()) continue;
        if (_b0 > bbox_top) continue;                    // ya venía a la altura del cuerpo: no es la cabeza
        if (_me.bbox_bottom < bbox_top) continue;        // todavía no la alcanza
        if (_me.bbox_right < bbox_left || _me.bbox_left > bbox_right) continue;
        player_take_hit(id, PLAYER_MAX_HP, 270, _fall, HIT_ZONE.TOP);
        _hit = true;
    }
    if (_hit) {
        vsp = -PLAYER_STOMP_BOUNCE;
        jumping = false;   // el rebote no se corta al soltar saltar
    }
}

/// @desc ¿Toca pinchos sin botas que lo protejan? Entonces muere (de pie). En ragdoll, el cuerpo
///       tirado siempre se pincha: ver player_ragdoll_update.
function player_check_spikes() {
    if (player_feet_have("spike_proof") || !place_meeting(x, y, obj_spikes)) return false;
    player_die(90, PLAYER_SPIKE_POP);
    return true;
}
