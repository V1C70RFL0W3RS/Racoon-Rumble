  if (keyboard_check_pressed(vk_enter)) {
      match_settings_init(
          MATCH_DEFAULT_SCORE_TO_WIN,
          MATCH_DEFAULT_ROUNDS_PER_BLOCK,
          [rm_sandbox, rm_sandbox_2] // TEMPORAL: pool fijo, hasta el Paso 4 (elegir mapas en la UI)
      );
      match_start();
  }