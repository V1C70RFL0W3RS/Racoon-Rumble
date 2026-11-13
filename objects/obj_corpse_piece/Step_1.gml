// La pareja se resuelve UNA vez, desde la parte superior, antes de que ninguna se mueva.
if (piece_frame != 1 && partner != noone && instance_exists(partner) && is_struct(rig)) {
    corpse_pair_update(id, partner);
}