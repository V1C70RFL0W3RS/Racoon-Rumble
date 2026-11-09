/// @file scr_audio
/// Punto ÚNICO para reproducir sonidos. Así, cuando haya volumen configurable,
/// sonido por jugador o red, se cambia aquí y no en cada arma u objeto.

/// @desc Reproduce un efecto de sonido con una leve variación de tono, para que
///       repetirlo no suene robótico. Si el sonido es undefined no hace nada:
///       permite programar los avisos antes de tener los .wav.
/// @param {Asset.GMSound} _snd       Sonido a reproducir (o undefined).
/// @param {Real}          _pitch_var Variación máxima de tono (0.05 = ±5 %).
/// @returns {Id.Sound} Instancia del sonido, o -1 si no sonó nada.
function audio_play_sfx(_snd, _pitch_var = 0.05) {
    if (_snd == undefined) return -1;
    var _inst = audio_play_sound(_snd, 1, false);
    audio_sound_pitch(_inst, 1 + random_range(-_pitch_var, _pitch_var));
    return _inst;
}