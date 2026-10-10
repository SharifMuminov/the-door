import 'l_text.dart';

/// Interface text (menus, buttons, dialogs). Story text lives in GameData.
abstract final class UiText {
  // Splash & language
  static const headphones = LText(
    'HEADPHONES RECOMMENDED',
    'QULOQCHIN TAVSIYA ETILADI',
  );
  static const playInDark = LText('Play in the dark.', 'Qorong‘ida o‘ynang.');

  // Menu
  static const tagline = LText(
    'Some doors should never be opened.',
    'Ba’zi eshiklarni hech qachon ochmaslik kerak.',
  );
  static const play = LText('PLAY', 'O‘YNASH');
  static const resume = LText('CONTINUE', 'DAVOM ETISH');
  static const settings = LText('SETTINGS', 'SOZLAMALAR');
  static const endings = LText('ENDINGS', 'FINALLAR');

  // Settings
  static const sound = LText('SOUND', 'OVOZ');
  static const vibration = LText('VIBRATION', 'TEBRANISH');
  static const language = LText('LANGUAGE', 'TIL');
  static const on = LText('ON', 'YONIQ');
  static const off = LText('OFF', 'O‘CHIQ');
  static const close = LText('CLOSE', 'YOPISH');

  // Game
  static const room = LText('ROOM', 'XONA');
  static const pause = LText('Pause', 'Pauza');
  static const hint = LText('Hint', 'Maslahat');
  static const paused = LText('PAUSED', 'PAUZA');
  static const pausedBody = LText(
    'The room will wait.\nYour progress is saved.',
    'Xona sizni kutadi.\nProgress saqlangan.',
  );
  static const keepPlaying = LText('RESUME', 'DAVOM ETISH');
  static const leaveRoom = LText('LEAVE THE ROOM', 'XONADAN CHIQISH');
  static const stepBack = LText('STEP BACK', 'CHEKINISH');
  static const stepOut = LText('STEP OUT', 'CHIQISH');
  static const emptySlot = LText('Empty slot', 'Bo‘sh joy');
  static const knock = LText('KNOCK', 'TAQ');

  // Phone
  static const noService = LText('NO SERVICE', 'ALOQA YO‘Q');
  static const messages = LText(' messages', ' ta xabar');

  // Ending
  static const theEnd = LText('THE END', 'TAMOM');
  static const back = LText('RETURN', 'QAYTISH');
}
