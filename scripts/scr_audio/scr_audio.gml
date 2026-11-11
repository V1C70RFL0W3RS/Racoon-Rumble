/// @file scr_audio
/// Punto ÚNICO para reproducir sonidos. Así, cuando haya sonido por jugador, posicional
/// o en red, se cambia aquí y no en cada arma u objeto.
///
/// Reglas de mezcla (ver guia_audio.md en el Project):
///  - Lo FRECUENTE suena bajo; lo raro e importante (muerte, escopeta) suena fuerte. El nivel
///    de cada sonido viene ya fijado en su .wav: aquí no se compensa.
///  - Variar tono y volumen en cada reproducción reduce la fatiga por repetición.
///  - Limitar copias simultáneas evita que el volumen se dispare y se sature.

/// @desc Prepara el estado del audio. Se llama UNA vez en el Create de obj_game_manager,
///       después de settings_init.
function audio_init() {
    global.sfx_last_played = {};   // ms en que sonó por última vez cada sonido
    global.sfx_voices      = {};   // instancias vivas de cada sonido (para limitar copias)
}

/// @desc Reproduce un efecto de sonido.
///       - Si el MISMO sonido sonó hace menos de SFX_MIN_GAP_MS, no suena (6 perdigones
///         contra una pared = un solo golpe).
///       - Si ya hay SFX_MAX_VOICES copias sonando, corta la más vieja.
///       - Varía un poco tono y volumen para que repetirlo no canse.
///       - Si _snd es un ARRAY de sonidos, elige uno al azar (variantes del mismo evento).
///       - Si es undefined no hace nada (permite programar avisos antes de tener el .wav).
/// @param {Asset.GMSound|Array} _snd Sonido, o array de variantes, o undefined.
/// @param {Real} [_pitch_var] Variación máxima de tono (0.05 = ±5 %).
/// @param {Real} [_priority] Prioridad del canal: si se acaban los canales, se cortan
///        primero los de menor prioridad (la muerte usa SFX_PRIORITY_HIGH).
/// @returns {Id.Sound} Instancia del sonido, o -1 si no sonó nada.
function audio_play_sfx(_snd, _pitch_var = 0.05, _priority = SFX_PRIORITY_NORMAL) {
    if (_snd == undefined) return -1;
    if (is_array(_snd)) _snd = _snd[irandom(array_length(_snd) - 1)];

    var _key  = string(_snd);
    var _last = global.sfx_last_played[$ _key];
    if (_last != undefined && current_time - _last < SFX_MIN_GAP_MS) return -1;
    global.sfx_last_played[$ _key] = current_time;

    // Copias vivas de este sonido: se descartan las que ya terminaron; si sobran, la más vieja se corta.
    var _voices = global.sfx_voices[$ _key] ?? [];
    for (var i = array_length(_voices) - 1; i >= 0; i--) {
        if (!audio_is_playing(_voices[i])) array_delete(_voices, i, 1);
    }
    if (array_length(_voices) >= SFX_MAX_VOICES) {
        audio_stop_sound(_voices[0]);
        array_delete(_voices, 0, 1);
    }

    var _gain = global.settings.sfx_volume * random_range(1 - SFX_GAIN_VAR, 1);
    var _inst = audio_play_sound(_snd, _priority, false, _gain, 0,
                                 1 + random_range(-_pitch_var, _pitch_var));
    array_push(_voices, _inst);
    global.sfx_voices[$ _key] = _voices;
    return _inst;
}
