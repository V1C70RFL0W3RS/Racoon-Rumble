  lobby_scan_join();

  var _any_joined = array_length(global.match.players_joined) > 0;
  if (_any_joined && keyboard_check_pressed(vk_enter)) {
      room_goto(rm_lobby);
  }