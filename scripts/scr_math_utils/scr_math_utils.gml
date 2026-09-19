/// @description Interpola un valor hacia un objetivo, a pasos fijos.
/// @param {real} val
/// @param {real} target
/// @param {real} step
function approach(val, target, step) {
    if (val < target) {
        return min(val + step, target);
    } else {
        return max(val - step, target);
    }
}