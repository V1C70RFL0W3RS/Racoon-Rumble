/// @desc Único punto de creación de proyectiles. Si algún día se usa un pool
///       de balas, solo cambia esta función.
/// @param {Real} _x Posición de aparición (la boca del cañón).
/// @param {Real} _y
/// @param {Real} _angle Dirección en grados (0 = derecha, 90 = arriba).
/// @param {Real} _speed Píxeles por frame.
/// @param {Real} _damage
/// @param {Real} _life Frames de vida.
/// @param {Id.Instance} _owner Quién disparó (para no golpearse a sí mismo).
/// @returns {Id.Instance}
function projectile_spawn(_x, _y, _angle, _speed, _damage, _life, _owner) {
    // Las variables del struct existen ANTES del evento Create del proyectil.
    return instance_create_layer(_x, _y, "layer_effects", obj_projectile, {
        hsp:    lengthdir_x(_speed, _angle),
        vsp:    lengthdir_y(_speed, _angle),
        damage: _damage,
        life:   _life,
        owner:  _owner
    });
}