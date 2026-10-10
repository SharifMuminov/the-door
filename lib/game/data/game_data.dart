import 'package:flutter/material.dart';

import '../../core/l10n/l_text.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import '../models/puzzle.dart';

/// All static content of the game: rooms, clues, items and the lines
/// whispered when the player touches things — in every language.
///
/// The story, for whoever edits it: a house where something waits behind
/// a door it cannot open by itself. It took ELIAS (1948), MARTA (1961) and
/// ANNA (1979) — always on the night of 9 April, at 3:17. Anna's baby
/// survived. The player is that child, grown up, and has been here before:
/// forty-one times. Every rule on every note is in the player's own
/// handwriting. The last door is not the way out; it is the way in.
abstract final class GameData {
  static const levels = <Level>[
    _room1,
    _room2,
    _room3,
    _room4,
    _room5,
    _room6,
    _room7,
    _room8,
    _room9,
    _room10,
    _room11,
  ];

  static int get levelCount => levels.length;

  static Level level(int number) => levels[number.clamp(1, levelCount) - 1];

  static Clue clue(ClueId id) => clues[id]!;

  static InventoryItem item(ItemId id) => items[id]!;

  // ------------------------------------------------------------ labels

  static const _door = LText('Door', 'Eshik');
  static const _note = LText('Note', 'Eslatma');
  static const _clock = LText('Clock', 'Soat');
  static const _table = LText('Table', 'Stol');
  static const _doorPuzzleTitle = LText('THE DOOR', 'ESHIK');

  // ------------------------------------------------------------ ROOM 01

  static const _room1 = Level(
    number: 1,
    kind: RoomKind.rule,
    title: LText('THE RULE', 'QOIDA'),
    epigraph: LText(
      'You don’t remember falling asleep here.',
      'Bu yerda qanday uxlab qolganingizni eslamaysiz.',
    ),
    note: ClueId.firstRule,
    clockMinutes: 23 * 60 + 47,
    wallTint: Color(0xFF2A1C14),
    doorLight: Color(0xFFB98A5A),
    lockedMessage: LText(
      'The keypad waits for three numbers.',
      'Klaviatura uchta raqamni kutmoqda.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.doorCode,
      title: _doorPuzzleTitle,
      description: LText('Three digits.', 'Uchta raqam.'),
      type: PuzzleType.keypad,
      solution: '317',
    ),
    objects: [
      GameObject(
        id: ObjectId.clock,
        label: _clock,
        placement: ObjectPlacement(x: .83, y: .5, width: .17, aspectRatio: 1),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .19,
          y: .43,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .32, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.table,
        label: _table,
        placement: ObjectPlacement(x: .17, y: 0, width: .3, aspectRatio: .62),
      ),
      GameObject(
        id: ObjectId.drawer,
        label: LText('Drawer', 'Tortma'),
        tapSound: null,
        placement: ObjectPlacement(x: .83, y: 0, width: .26, aspectRatio: .85),
      ),
      GameObject(
        id: ObjectId.lamp,
        label: LText('Lamp', 'Chiroq'),
        tapSound: null,
        placement: ObjectPlacement(
          x: .12,
          y: .172,
          width: .12,
          aspectRatio: 1.8,
        ),
      ),
    ],
  );

  // ------------------------------------------------------------ ROOM 02

  static const _room2 = Level(
    number: 2,
    kind: RoomKind.mirror,
    title: LText("DON'T LOOK", 'QARAMA'),
    epigraph: LText(
      'Every clock in this house has stopped. Except one.',
      'Bu uydagi barcha soatlar to‘xtagan. Bittasidan boshqa.',
    ),
    note: ClueId.ruleTwo,
    clockMinutes: 23 * 60 + 52,
    wallTint: Color(0xFF1A1C22),
    doorLight: Color(0xFF8E9AA6),
    lockedMessage: LText(
      'Locked. A small, old keyhole.',
      'Qulflangan. Kichkina, eski kalit teshigi.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.mirrorLock,
      title: _doorPuzzleTitle,
      description: LText('An old keyhole.', 'Eski kalit teshigi.'),
      type: PuzzleType.keyItem,
      solution: 'paintingKey',
    ),
    objects: [
      GameObject(
        id: ObjectId.clock,
        label: _clock,
        placement: ObjectPlacement(x: .5, y: .7, width: .14, aspectRatio: 1),
      ),
      GameObject(
        id: ObjectId.mirror,
        label: LText('Mirror', 'Ko‘zgu'),
        placement: ObjectPlacement(
          x: .17,
          y: .15,
          width: .24,
          aspectRatio: 1.75,
        ),
      ),
      GameObject(
        id: ObjectId.painting,
        label: LText('Painting', 'Rasm'),
        placement: ObjectPlacement(
          x: .83,
          y: .32,
          width: .22,
          aspectRatio: 1.25,
        ),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(x: .83, y: .1, width: .13, aspectRatio: 1.2),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.chair,
        label: LText('Chair', 'Stul'),
        placement: ObjectPlacement(
          x: .2,
          y: -.13,
          width: .2,
          aspectRatio: 1.45,
        ),
      ),
    ],
  );

  // ------------------------------------------------------------ ROOM 03

  static const _room3 = Level(
    number: 3,
    kind: RoomKind.candles,
    title: LText('THE CANDLES', 'SHAMLAR'),
    epigraph: LText(
      'Someone lived here once. More than one.',
      'Bir paytlar bu yerda kimdir yashagan. Bir kishi emas.',
    ),
    note: ClueId.ruleThree,
    wallTint: Color(0xFF241A10),
    doorLight: Color(0xFFC08A4A),
    lockedMessage: LText(
      'It will not open in the dark.',
      'Qorong‘ida u ochilmaydi.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.candleOrder,
      title: _doorPuzzleTitle,
      description: LText(
        'Light, in the right order.',
        'Yorug‘lik, to‘g‘ri tartibda.',
      ),
      type: PuzzleType.sequence,
      // ELIAS (1948) → MARTA (1961) → ANNA (1979)
      solution: 'candleB,candleA,candleC',
    ),
    objects: [
      GameObject(
        id: ObjectId.photo,
        label: LText('Photograph', 'Surat'),
        placement: ObjectPlacement(
          x: .83,
          y: .42,
          width: .17,
          aspectRatio: 1.25,
        ),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .17,
          y: .45,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.candleA,
        label: LText('Candle', 'Sham'),
        tapSound: null,
        placement: ObjectPlacement(x: .12, y: 0, width: .13, aspectRatio: 3),
      ),
      GameObject(
        id: ObjectId.candleC,
        label: LText('Candle', 'Sham'),
        tapSound: null,
        placement: ObjectPlacement(x: .9, y: 0, width: .13, aspectRatio: 3),
      ),
      GameObject(
        id: ObjectId.candleB,
        label: LText('Candle', 'Sham'),
        tapSound: null,
        placement: ObjectPlacement(x: .7, y: -.18, width: .15, aspectRatio: 3),
      ),
    ],
  );

  /// The name carved into each candle.
  static const candleNames = <ObjectId, String>{
    ObjectId.candleA: 'MARTA',
    ObjectId.candleB: 'ELIAS',
    ObjectId.candleC: 'ANNA',
  };

  // ------------------------------------------------------------ ROOM 04

  static const _room4 = Level(
    number: 4,
    kind: RoomKind.hide,
    title: LText('HIDE', 'YASHIRIN'),
    epigraph: LText('It does not walk like a person.', 'U odamdek yurmaydi.'),
    note: ClueId.ruleFour,
    wallTint: Color(0xFF16181A),
    doorLight: Color(0xFF9AA0A0),
    lockedMessage: LText(
      'Locked. The keyhole is full of dust.',
      'Qulflangan. Kalit teshigi changga to‘lgan.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.ironLock,
      title: _doorPuzzleTitle,
      description: LText('An iron lock.', 'Temir qulf.'),
      type: PuzzleType.keyItem,
      solution: 'ironKey',
    ),
    objects: [
      GameObject(
        id: ObjectId.wardrobe,
        label: LText('Wardrobe', 'Shkaf'),
        tapSound: null,
        placement: ObjectPlacement(x: .17, y: 0, width: .3, aspectRatio: 2),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .84,
          y: .45,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.bulb,
        label: LText('Light bulb', 'Lampochka'),
        placement: ObjectPlacement(x: .5, y: .74, width: .09, aspectRatio: 1.5),
      ),
      GameObject(
        id: ObjectId.chair,
        label: LText('Chair', 'Stul'),
        placement: ObjectPlacement(
          x: .83,
          y: -.12,
          width: .2,
          aspectRatio: 1.45,
        ),
      ),
      GameObject(
        id: ObjectId.floorKey,
        label: LText('Key', 'Kalit'),
        tapSound: null,
        placement: ObjectPlacement(x: .56, y: -.2, width: .12, aspectRatio: .5),
      ),
    ],
  );

  // ------------------------------------------------------------ ROOM 05

  static const _room5 = Level(
    number: 5,
    kind: RoomKind.radio,
    title: LText("DON'T ANSWER", 'JAVOB BERMA'),
    epigraph: LText(
      'It has learned how she sounded.',
      'U ayolning ovozini o‘rganib olgan.',
    ),
    note: ClueId.ruleFive,
    wallTint: Color(0xFF1E1A14),
    doorLight: Color(0xFFB0905A),
    lockedMessage: LText(
      'The keypad wants three numbers again.',
      'Klaviatura yana uchta raqam so‘rayapti.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.radioCode,
      title: _doorPuzzleTitle,
      description: LText('Three digits.', 'Uchta raqam.'),
      type: PuzzleType.keypad,
      solution: '409',
    ),
    objects: [
      GameObject(
        id: ObjectId.calendar,
        label: LText('Calendar', 'Taqvim'),
        placement: ObjectPlacement(
          x: .17,
          y: .38,
          width: .17,
          aspectRatio: 1.35,
        ),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(x: .17, y: .1, width: .13, aspectRatio: 1.2),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .32, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.table,
        label: _table,
        placement: ObjectPlacement(x: .83, y: 0, width: .3, aspectRatio: .62),
      ),
      GameObject(
        id: ObjectId.radio,
        label: LText('Radio', 'Radio'),
        tapSound: null,
        placement: ObjectPlacement(
          x: .83,
          y: .172,
          width: .22,
          aspectRatio: .72,
        ),
      ),
    ],
  );

  // ------------------------------------------------------------ ROOM 06

  static const _room6 = Level(
    number: 6,
    kind: RoomKind.lullaby,
    title: LText('THE LULLABY', 'ALLA'),
    epigraph: LText(
      'You know this song. You don’t know why.',
      'Bu qo‘shiqni bilasiz. Qayerdan — bilmaysiz.',
    ),
    note: ClueId.ruleSix,
    wallTint: Color(0xFF261A1E),
    doorLight: Color(0xFFB79A8A),
    lockedMessage: LText(
      'Locked. A tiny keyhole, like a toy’s.',
      'Qulflangan. O‘yinchoqnikidek mitti kalit teshigi.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.dollLock,
      title: _doorPuzzleTitle,
      description: LText('A tiny keyhole.', 'Mitti kalit teshigi.'),
      type: PuzzleType.keyItem,
      solution: 'dollKey',
    ),
    objects: [
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .17,
          y: .42,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.drawer,
        label: LText('Dresser', 'Komod'),
        placement: ObjectPlacement(x: .83, y: 0, width: .28, aspectRatio: .8),
      ),
      GameObject(
        id: ObjectId.musicBox,
        label: LText('Music box', 'Musiqa qutisi'),
        tapSound: null,
        placement: ObjectPlacement(
          x: .77,
          y: .212,
          width: .12,
          aspectRatio: .95,
        ),
      ),
      GameObject(
        id: ObjectId.cradle,
        label: LText('Cradle', 'Beshik'),
        placement: ObjectPlacement(
          x: .2,
          y: -.08,
          width: .33,
          aspectRatio: .74,
        ),
      ),
      GameObject(
        id: ObjectId.doll,
        label: LText('Doll', 'Qo‘g‘irchoq'),
        tapSound: null,
        placement: ObjectPlacement(
          x: .9,
          y: .212,
          width: .09,
          aspectRatio: 1.5,
        ),
      ),
    ],
  );

  /// Where the doll is: it comes a little closer every time the music stops.
  static const dollSpots = [
    ObjectPlacement(x: .9, y: .212, width: .09, aspectRatio: 1.5),
    ObjectPlacement(x: .68, y: -.07, width: .12, aspectRatio: 1.5),
    ObjectPlacement(x: .5, y: -.36, width: .16, aspectRatio: 1.5),
  ];

  // ------------------------------------------------------------ ROOM 07

  static const _room7 = Level(
    number: 7,
    kind: RoomKind.portraits,
    title: LText('THE PORTRAITS', 'PORTRETLAR'),
    epigraph: LText(
      'The family is still here. Most of it.',
      'Oila hali ham shu yerda. Deyarli hammasi.',
    ),
    note: ClueId.ruleSeven,
    wallTint: Color(0xFF1E1B15),
    doorLight: Color(0xFFA89878),
    lockedMessage: LText(
      'Locked. An old brass keyhole.',
      'Qulflangan. Eski jez kalit teshigi.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.portraitLock,
      title: _doorPuzzleTitle,
      description: LText('A brass keyhole.', 'Jez kalit teshigi.'),
      type: PuzzleType.keyItem,
      solution: 'portraitKey',
    ),
    objects: [
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .16,
          y: .06,
          width: .12,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.portraitElias,
        label: LText('Portrait of Elias', 'Elias portreti'),
        tapSound: null,
        placement: ObjectPlacement(x: .16, y: .3, width: .23, aspectRatio: 1.4),
      ),
      GameObject(
        id: ObjectId.portraitMarta,
        label: LText('Portrait of Marta', 'Marta portreti'),
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: .69, width: .21, aspectRatio: 1.4),
      ),
      GameObject(
        id: ObjectId.portraitAnna,
        label: LText('Portrait of Anna', 'Anna portreti'),
        tapSound: null,
        placement: ObjectPlacement(x: .84, y: .3, width: .23, aspectRatio: 1.4),
      ),
      GameObject(
        id: ObjectId.emptyFrame,
        label: LText('Empty frame', 'Bo‘sh ramka'),
        placement: ObjectPlacement(
          x: .83,
          y: -.17,
          width: .22,
          aspectRatio: 1.15,
        ),
      ),
    ],
  );

  /// Name plates under the portraits.
  static const portraitPlates = <ObjectId, String>{
    ObjectId.portraitElias: 'ELIAS · 1948',
    ObjectId.portraitMarta: 'MARTA · 1961',
    ObjectId.portraitAnna: 'ANNA · 1979',
  };

  /// What each of them says when asked. Exactly one of them lies.
  /// Only one reading fits: Marta is not Marta; the key is behind Elias.
  static const portraitWords = <ObjectId, LText>{
    ObjectId.portraitElias: LText(
      '“Marta is not Marta anymore.\nDo not listen to her.”',
      '“Marta endi Marta emas.\nUning gapiga kirma.”',
    ),
    ObjectId.portraitMarta: LText(
      '“The key is behind Anna, dear.\nLook behind Anna.”',
      '“Kalit Annaning ortida, azizim.\nAnnaning ortiga qara.”',
    ),
    ObjectId.portraitAnna: LText(
      '“It is behind my father.\nBehind Elias.”',
      '“U otamning ortida.\nEliasning ortida.”',
    ),
  };

  // ------------------------------------------------------------ ROOM 08

  static const _room8 = Level(
    number: 8,
    kind: RoomKind.bells,
    title: LText('THE BELLS', 'QO‘NG‘IROQLAR'),
    epigraph: LText(
      'Every room in this house had a bell. Someone is still ringing them.',
      'Bu uyning har bir xonasida qo‘ng‘iroq bo‘lgan. Kimdir ularni hali ham chalyapti.',
    ),
    note: ClueId.ruleEight,
    wallTint: Color(0xFF1C1814),
    doorLight: Color(0xFFB08A50),
    lockedMessage: LText(
      'Bolted from the other side.',
      'Narigi tomondan zulfinlangan.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.bellPattern,
      title: _doorPuzzleTitle,
      description: LText('Answer the bells.', 'Qo‘ng‘iroqlarga javob ber.'),
      type: PuzzleType.sequence,
      // Rounds of three, four and five bells, always starting the same way.
      solution: 'bellC,bellA,bellD,bellB,bellA',
    ),
    objects: [
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(x: .17, y: .3, width: .13, aspectRatio: 1.2),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.coat,
        label: LText('Coat', 'Palto'),
        placement: ObjectPlacement(x: .85, y: 0, width: .2, aspectRatio: 2.5),
      ),
      GameObject(
        id: ObjectId.bellA,
        label: LText('Bell', 'Qo‘ng‘iroq'),
        tapSound: null,
        placement: ObjectPlacement(x: .2, y: .68, width: .2, aspectRatio: 1.05),
      ),
      GameObject(
        id: ObjectId.bellB,
        label: LText('Bell', 'Qo‘ng‘iroq'),
        tapSound: null,
        placement: ObjectPlacement(x: .4, y: .68, width: .2, aspectRatio: 1.05),
      ),
      GameObject(
        id: ObjectId.bellC,
        label: LText('Bell', 'Qo‘ng‘iroq'),
        tapSound: null,
        placement: ObjectPlacement(x: .6, y: .68, width: .2, aspectRatio: 1.05),
      ),
      GameObject(
        id: ObjectId.bellD,
        label: LText('Bell', 'Qo‘ng‘iroq'),
        tapSound: null,
        placement: ObjectPlacement(x: .8, y: .68, width: .2, aspectRatio: 1.05),
      ),
    ],
  );

  /// The room each bell was rung from — the rooms the player has walked
  /// through, and the ones still ahead.
  static const bellRooms = <ObjectId, LText>{
    ObjectId.bellA: LText('NURSERY', 'BOLALAR'),
    ObjectId.bellB: LText('GALLERY', 'GALEREYA'),
    ObjectId.bellC: LText('DINING', 'OVQATXONA'),
    ObjectId.bellD: LText('STUDY', 'KABINET'),
  };

  // ------------------------------------------------------------ ROOM 09

  static const _room9 = Level(
    number: 9,
    kind: RoomKind.dinner,
    title: LText('THE DINNER', 'KECHKI OVQAT'),
    epigraph: LText(
      'They have been waiting for you to sit down.',
      'Ular sizning o‘tirishingizni kutishyapti.',
    ),
    note: ClueId.ruleNine,
    clockMinutes: 3 * 60 + 16,
    wallTint: Color(0xFF241814),
    doorLight: Color(0xFFC09060),
    lockedMessage: LText(
      'The door will not open on an empty table.',
      'Dasturxon bo‘sh ekan, eshik ochilmaydi.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.dinnerTable,
      title: _doorPuzzleTitle,
      description: LText('Set the table.', 'Dasturxon tuzang.'),
      type: PuzzleType.arrangement,
      // Elias, Marta, Anna — and the card with no name. Never the guest.
      solution: 'seatA,seatB,seatD,seatE',
    ),
    objects: [
      GameObject(
        id: ObjectId.clock,
        label: _clock,
        placement: ObjectPlacement(x: .17, y: .42, width: .16, aspectRatio: 1),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .83,
          y: .42,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.diningTable,
        label: LText('Dining table', 'Ovqat stoli'),
        placement: ObjectPlacement(
          x: .5,
          y: -.44,
          width: .98,
          aspectRatio: .37,
        ),
      ),
      GameObject(
        id: ObjectId.seatA,
        label: _place,
        tapSound: null,
        placement: ObjectPlacement(
          x: .12,
          y: -.235,
          width: .17,
          aspectRatio: .82,
        ),
      ),
      GameObject(
        id: ObjectId.seatB,
        label: _place,
        tapSound: null,
        placement: ObjectPlacement(
          x: .31,
          y: -.235,
          width: .17,
          aspectRatio: .82,
        ),
      ),
      GameObject(
        id: ObjectId.seatC,
        label: _place,
        tapSound: null,
        placement: ObjectPlacement(
          x: .5,
          y: -.235,
          width: .17,
          aspectRatio: .82,
        ),
      ),
      GameObject(
        id: ObjectId.seatD,
        label: _place,
        tapSound: null,
        placement: ObjectPlacement(
          x: .69,
          y: -.235,
          width: .17,
          aspectRatio: .82,
        ),
      ),
      GameObject(
        id: ObjectId.seatE,
        label: _place,
        tapSound: null,
        placement: ObjectPlacement(
          x: .88,
          y: -.235,
          width: .17,
          aspectRatio: .82,
        ),
      ),
    ],
  );

  static const _place = LText('Place at the table', 'Stoldagi joy');

  /// The name card at each place. One is blank; one is for the guest.
  static const seatCards = <ObjectId, LText>{
    ObjectId.seatA: LText('ELIAS', 'ELIAS'),
    ObjectId.seatB: LText('MARTA', 'MARTA'),
    ObjectId.seatC: LText('GUEST', 'MEHMON'),
    ObjectId.seatD: LText('ANNA', 'ANNA'),
    ObjectId.seatE: LText('', ''),
  };
  static const guestSeat = ObjectId.seatC;
  static const blankSeat = ObjectId.seatE;

  // ------------------------------------------------------------ ROOM 10

  static const _room10 = Level(
    number: 10,
    kind: RoomKind.study,
    title: LText('THE HANDWRITING', 'DASTXAT'),
    epigraph: LText(
      'You have been here before.',
      'Siz bu yerda avval ham bo‘lgansiz.',
    ),
    note: ClueId.ruleTen,
    wallTint: Color(0xFF1A1A1E),
    doorLight: Color(0xFF9C9488),
    lockedMessage: LText(
      'Locked. Ink has dried inside the keyhole.',
      'Qulflangan. Kalit teshigida siyoh qotib qolgan.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.studyLock,
      title: _doorPuzzleTitle,
      description: LText('A small keyhole.', 'Kichik kalit teshigi.'),
      type: PuzzleType.keyItem,
      solution: 'studyKey',
    ),
    sidePuzzles: [
      Puzzle(
        id: PuzzleId.diaryLock,
        title: LText('THE DIARY', 'KUNDALIK'),
        description: LText('Two small dials.', 'Ikkita kichik g‘ildirakcha.'),
        type: PuzzleType.keypad,
        // 20 on the wall + 15 on the desk + 6 under the floor.
        solution: '41',
      ),
    ],
    objects: [
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .17,
          y: .55,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.tally,
        label: LText('Scratches', 'Tirnalgan izlar'),
        placement: ObjectPlacement(
          x: .17,
          y: .17,
          width: .28,
          aspectRatio: .66,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .3, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.desk,
        label: LText('Desk', 'Yozuv stoli'),
        placement: ObjectPlacement(x: .81, y: 0, width: .36, aspectRatio: .6),
      ),
      GameObject(
        id: ObjectId.diary,
        label: LText('Diary', 'Kundalik'),
        tapSound: null,
        placement: ObjectPlacement(x: .75, y: .2, width: .13, aspectRatio: .62),
      ),
      GameObject(
        id: ObjectId.inkwell,
        label: LText('Inkwell', 'Siyohdon'),
        tapSound: null,
        placement: ObjectPlacement(x: .9, y: .2, width: .07, aspectRatio: 1.6),
      ),
      GameObject(
        id: ObjectId.floorboard,
        label: LText('Floorboard', 'Pol taxtasi'),
        tapSound: null,
        placement: ObjectPlacement(
          x: .27,
          y: -.32,
          width: .28,
          aspectRatio: .34,
        ),
      ),
    ],
  );

  // ------------------------------------------------------------ ROOM 11

  static const _room11 = Level(
    number: 11,
    kind: RoomKind.knock,
    title: LText('THE KNOCK', 'TAQILLATISH'),
    epigraph: LText(
      '3:17. Someone is at the door.',
      '3:17. Eshik oldida kimdir bor.',
    ),
    note: ClueId.finalRule,
    clockMinutes: 3 * 60 + 17,
    wallTint: Color(0xFF221214),
    doorLight: Color(0xFFA0563E),
    lockedMessage: LText(
      'Locked. Cold to the touch.',
      'Qulflangan. Ushlasangiz sovuq.',
    ),
    doorPuzzle: Puzzle(
      id: PuzzleId.finalLock,
      title: _doorPuzzleTitle,
      description: LText('The last door.', 'Oxirgi eshik.'),
      type: PuzzleType.keyItem,
      solution: 'key',
    ),
    objects: [
      GameObject(
        id: ObjectId.window,
        label: LText('Window', 'Deraza'),
        placement: ObjectPlacement(x: .17, y: .3, width: .26, aspectRatio: 1.3),
      ),
      GameObject(
        id: ObjectId.note,
        label: _note,
        tapSound: null,
        placement: ObjectPlacement(
          x: .18,
          y: .08,
          width: .13,
          aspectRatio: 1.2,
        ),
      ),
      GameObject(
        id: ObjectId.door,
        label: _door,
        tapSound: null,
        placement: ObjectPlacement(x: .5, y: 0, width: .32, aspectRatio: 2.1),
      ),
      GameObject(
        id: ObjectId.table,
        label: _table,
        placement: ObjectPlacement(x: .83, y: 0, width: .3, aspectRatio: .62),
      ),
      GameObject(
        id: ObjectId.phone,
        label: LText('Phone', 'Telefon'),
        placement: ObjectPlacement(
          x: .76,
          y: .172,
          width: .1,
          aspectRatio: 1.6,
        ),
      ),
      GameObject(
        id: ObjectId.clock,
        label: LText('Small clock', 'Kichik soat'),
        style: ObjectStyle.tabletop,
        placement: ObjectPlacement(
          x: .9,
          y: .172,
          width: .11,
          aspectRatio: 1.15,
        ),
      ),
    ],
  );

  // ------------------------------------------------------------ CLUES

  static const clues = <ClueId, Clue>{
    ClueId.firstRule: Clue(
      id: ClueId.firstRule,
      title: LText('THE FIRST RULE', 'BIRINCHI QOIDA'),
      lines: [LText('DO NOT TURN ON\nTHE LIGHT.', 'CHIROQNI\nYOQMA.')],
    ),
    ClueId.doorRemembers: Clue(
      id: ClueId.doorRemembers,
      title: LText('TORN PAGE', 'YIRTIQ VARAQ'),
      lines: [
        LText('THE DOOR REMEMBERS.', 'ESHIK ESLAYDI.'),
        LText('3 - 1 - 7', '3 - 1 - 7'),
      ],
    ),
    ClueId.ruleTwo: Clue(
      id: ClueId.ruleTwo,
      title: LText('RULE TWO', 'IKKINCHI QOIDA'),
      lines: [
        LText('WHEN THE CLOCK STRIKES 12,', 'SOAT 12 NI URGANDA,'),
        LText('DO NOT LOOK INTO\nTHE MIRROR.', 'KO‘ZGUGA\nQARAMA.'),
      ],
    ),
    ClueId.mirrorReflection: Clue(
      id: ClueId.mirrorReflection,
      title: LText('THE MIRROR', 'KO‘ZGU'),
      style: ClueStyle.plain,
      lines: [
        LText(
          'The room in the glass is almost the same.',
          'Oynadagi xona deyarli bir xil.',
        ),
        LText('Almost.', 'Deyarli.'),
        LText(
          'In the reflection, the painting behind you hangs crooked.',
          'Aksda orqangizdagi rasm qiyshiq osilib turibdi.',
        ),
        LText(
          'Something small glints behind its frame.',
          'Ramkasi ortida nimadir yaltirayapti.',
        ),
      ],
    ),
    ClueId.ruleThree: Clue(
      id: ClueId.ruleThree,
      title: LText('RULE THREE', 'UCHINCHI QOIDA'),
      lines: [
        LText('LIGHT THE CANDLES', 'SHAMLARNI'),
        LText('IN THE ORDER\nTHEY LEFT.', 'ULAR KETGAN\nTARTIBDA YOQ.'),
      ],
    ),
    ClueId.photoBack: Clue(
      id: ClueId.photoBack,
      title: LText('BACK OF THE PHOTOGRAPH', 'SURAT ORQASI'),
      lines: [
        LText('They left us:', 'Ular bizni tark etdi:'),
        LText('MARTA — 1961', 'MARTA — 1961'),
        LText('ELIAS — 1948', 'ELIAS — 1948'),
        LText('ANNA — 1979', 'ANNA — 1979'),
        LText(
          'We never left the house.',
          'Biz bu uydan hech qachon ketmaganmiz.',
        ),
      ],
    ),
    ClueId.ruleFour: Clue(
      id: ClueId.ruleFour,
      title: LText('RULE FOUR', 'TO‘RTINCHI QOIDA'),
      lines: [
        LText('WHEN THE LIGHT GOES OUT,', 'CHIROQ O‘CHGANDA,'),
        LText('HIDE.', 'YASHIRIN.'),
      ],
    ),
    ClueId.ruleFive: Clue(
      id: ClueId.ruleFive,
      title: LText('RULE FIVE', 'BESHINCHI QOIDA'),
      lines: [
        LText('IF IT CALLS FOR YOU,', 'AGAR U SENI CHAQIRSA,'),
        LText('DO NOT ANSWER.', 'JAVOB BERMA.'),
      ],
    ),
    // Discovered through whispers, never shown as a dialog.
    ClueId.radioNumbers: Clue(
      id: ClueId.radioNumbers,
      title: LText('THE RADIO', 'RADIO'),
      style: ClueStyle.plain,
      lines: [LText('Four. Zero. Nine.', 'To‘rt. Nol. To‘qqiz.')],
    ),
    ClueId.calendar: Clue(
      id: ClueId.calendar,
      title: LText('THE CALENDAR', 'TAQVIM'),
      style: ClueStyle.plain,
      lines: [LText('April 9.', '9-aprel.')],
    ),
    ClueId.ruleSix: Clue(
      id: ClueId.ruleSix,
      title: LText('RULE SIX', 'OLTINCHI QOIDA'),
      lines: [
        LText('WHEN THE MUSIC STOPS,', 'MUSIQA TO‘XTAGANDA,'),
        LText('DO NOT MOVE.', 'QIMIRLAMA.'),
      ],
    ),
    ClueId.ruleSeven: Clue(
      id: ClueId.ruleSeven,
      title: LText('RULE SEVEN', 'YETTINCHI QOIDA'),
      lines: [
        LText('THE DEAD DO NOT LIE.', 'O‘LIKLAR\nYOLG‘ON GAPIRMAYDI.'),
        LText('ONE OF THEM\nIS NOT DEAD.', 'ULARDAN BIRI\nO‘LIK EMAS.'),
      ],
    ),
    ClueId.ruleEight: Clue(
      id: ClueId.ruleEight,
      title: LText('RULE EIGHT', 'SAKKIZINCHI QOIDA'),
      lines: [
        LText(
          'WHEN THE BELLS RING,\nRING THEM BACK.',
          'QO‘NG‘IROQLAR CHALINSA,\nULARGA JAVOB QAYTAR.',
        ),
        LText('IN THE SAME ORDER.', 'XUDDI SHU TARTIBDA.'),
        LText(
          'IT COMES WHEN\nNO ONE ANSWERS.',
          'HECH KIM JAVOB BERMASA,\nU KELADI.',
        ),
      ],
    ),
    ClueId.ruleNine: Clue(
      id: ClueId.ruleNine,
      title: LText('RULE NINE', 'TO‘QQIZINCHI QOIDA'),
      lines: [
        LText(
          'SET A PLACE FOR\nEVERYONE IN THIS HOUSE.',
          'BU UYDAGI HAR BIR KISHIGA\nJOY HOZIRLA.',
        ),
        LText('NEVER FOR THE GUEST.', 'MEHMONGA — HECH QACHON.'),
      ],
    ),
    ClueId.ruleTen: Clue(
      id: ClueId.ruleTen,
      title: LText('RULE TEN', 'O‘NINCHI QOIDA'),
      lines: [
        LText('COUNT THE MARKS.', 'IZLARNI SANA.'),
        LText('EVERY LAST ONE.', 'BIRORTASINI QOLDIRMA.'),
      ],
    ),
    // Counted through whispers, never shown as a dialog.
    ClueId.marksWall: Clue(
      id: ClueId.marksWall,
      title: LText('THE WALL', 'DEVOR'),
      style: ClueStyle.plain,
      lines: [LText('Twenty marks.', 'Yigirmata iz.')],
    ),
    ClueId.marksDesk: Clue(
      id: ClueId.marksDesk,
      title: LText('THE DESK', 'STOL'),
      style: ClueStyle.plain,
      lines: [LText('Fifteen marks.', 'O‘n beshta iz.')],
    ),
    ClueId.marksFloor: Clue(
      id: ClueId.marksFloor,
      title: LText('THE FLOOR', 'POL'),
      style: ClueStyle.plain,
      lines: [LText('Six marks.', 'Oltita iz.')],
    ),
    ClueId.diaryPages: Clue(
      id: ClueId.diaryPages,
      title: LText('THE DIARY', 'KUNDALIK'),
      lines: [
        LText('NIGHT 41.', '41-TUN.'),
        LText(
          'I write the rules down so the next one will remember. '
              'The next one is always me.',
          'Qoidalarni keyingisi eslab qolsin deb yozib qo‘yaman. '
              'Keyingisi — har doim menman.',
        ),
        LText(
          'The last door is not a way out. It is the way in — for it.',
          'Oxirgi eshik — chiqish yo‘li emas. U — uning kirish yo‘li.',
        ),
        LText(
          'If you are reading this, I opened it again.',
          'Buni o‘qiyotgan bo‘lsang, demak, men uni yana ochibman.',
        ),
        LText('Don’t.', 'Ochma.'),
      ],
    ),
    ClueId.finalRule: Clue(
      id: ClueId.finalRule,
      title: LText('FINAL RULE', 'SO‘NGGI QOIDA'),
      lines: [
        LText('WHEN SOMEONE KNOCKS,', 'KIMDIR TAQILLATSA,'),
        LText('DO NOT OPEN\nTHE DOOR.', 'ESHIKNI\nOCHMA.'),
      ],
    ),
    ClueId.phoneMessages: Clue(
      id: ClueId.phoneMessages,
      title: LText('UNKNOWN', 'NOMA’LUM'),
      style: ClueStyle.phone,
      lines: [
        LText("DON'T TRUST THE DOOR.", 'ESHIKKA ISHONMA.'),
        LText('THE KEY IS UNDER THE CLOCK.', 'KALIT SOAT TAGIDA.'),
        LText(
          'I HAVE BEEN WHERE YOU ARE.\n41 TIMES.',
          'MEN SEN TURGAN JOYDA\n41 MARTA BO‘LGANMAN.',
        ),
      ],
    ),
    ClueId.windowTruth: Clue(
      id: ClueId.windowTruth,
      title: LText('THE WINDOW', 'DERAZA'),
      style: ClueStyle.plain,
      lines: [
        LText(
          'Your breath fogs the black glass.',
          'Nafasingiz qora oynani terlatadi.',
        ),
        LText(
          'Letters surface in the mist — written from this side.',
          'Bug‘ ichida harflar paydo bo‘ladi — bu tomondan yozilgan.',
        ),
        LText('IT CANNOT OPEN THE DOOR.', 'U ESHIKNI OCHA OLMAYDI.'),
        LText('ONLY YOU CAN.', 'FAQAT SEN OCHA OLASAN.'),
      ],
    ),
  };

  /// Written in the fogged window of the last room.
  static const windowWriting = LText('ONLY\nYOU', 'FAQAT\nSEN');

  /// Month and year on the calendar of the radio room.
  static const calendarMonth = LText('APRIL', 'APREL');
  static const calendarYear = '1979';

  // ------------------------------------------------------------ ITEMS

  static const items = <ItemId, InventoryItem>{
    ItemId.drawerCode: InventoryItem(
      id: ItemId.drawerCode,
      name: LText('Torn page', 'Yirtiq varaq'),
      description: LText('THE DOOR REMEMBERS.', 'ESHIK ESLAYDI.'),
      icon: Icons.description_outlined,
      clue: ClueId.doorRemembers,
    ),
    ItemId.paintingKey: InventoryItem(
      id: ItemId.paintingKey,
      name: LText('Small key', 'Kichik kalit'),
      description: LText(
        'It was taped behind the painting. It is warm.',
        'U rasm orqasiga yopishtirilgan edi. Iliq.',
      ),
      icon: Icons.key_outlined,
    ),
    ItemId.ironKey: InventoryItem(
      id: ItemId.ironKey,
      name: LText('Iron key', 'Temir kalit'),
      description: LText(
        'Still warm from its hand.',
        'Hali ham uning qo‘lidan iliq.',
      ),
      icon: Icons.key_outlined,
    ),
    ItemId.dollKey: InventoryItem(
      id: ItemId.dollKey,
      name: LText('Small brass key', 'Kichik jez kalit'),
      description: LText(
        'It was in the doll’s hands. It is warm, like a hand.',
        'U qo‘g‘irchoqning qo‘lida edi. Xuddi qo‘ldek iliq.',
      ),
      icon: Icons.key_outlined,
    ),
    ItemId.portraitKey: InventoryItem(
      id: ItemId.portraitKey,
      name: LText('Elias’s key', 'Eliasning kaliti'),
      description: LText(
        'It hung behind his portrait, waiting for someone.',
        'U uning portreti ortida kimnidir kutib osilib turgan.',
      ),
      icon: Icons.key_outlined,
    ),
    ItemId.diary: InventoryItem(
      id: ItemId.diary,
      name: LText('Diary', 'Kundalik'),
      description: LText(
        'Your handwriting. Every page.',
        'Sizning dastxatingiz. Har bir sahifada.',
      ),
      icon: Icons.menu_book_outlined,
      clue: ClueId.diaryPages,
    ),
    ItemId.studyKey: InventoryItem(
      id: ItemId.studyKey,
      name: LText('Ink-stained key', 'Siyoh dog‘li kalit'),
      description: LText(
        'It fell from between the diary’s last pages.',
        'U kundalikning so‘nggi sahifalari orasidan tushdi.',
      ),
      icon: Icons.key_outlined,
    ),
    ItemId.key: InventoryItem(
      id: ItemId.key,
      name: LText('Heavy key', 'Og‘ir kalit'),
      description: LText(
        'It fits the last door. Both ways.',
        'U oxirgi eshikka mos. Ikki tomonga ham.',
      ),
      icon: Icons.vpn_key_outlined,
    ),
  };
}

/// Short whispered lines. Kept here so the controller stays readable.
abstract final class Lines {
  // The rule
  static const lampPromptTitle = LText('THE LAMP', 'CHIROQ');
  static const lampPrompt = LText(
    'Your finger finds the switch.\nIt is colder than it should be.',
    'Barmog‘ingiz tugmani topadi.\nU bo‘lishi kerakidan sovuqroq.',
  );
  static const lampTurnOn = LText('TURN IT ON', 'YOQISH');
  static const lampLeave = LText('LEAVE IT', 'TEGMASLIK');
  static const lampOn = LText(
    'Something moved when the light came on.',
    'Chiroq yonganda nimadir qimirladi.',
  );
  static const lampAgain = LText(
    'The light makes the room darker.',
    'Yorug‘lik xonani yanada qorong‘i qiladi.',
  );
  static const lampOff = LText(
    'Click. The dark settles back where it was.',
    'Chiq. Qorong‘ilik yana o‘z joyiga qaytdi.',
  );
  static const lampLeft = LText('You leave it.', 'Unga tegmaysiz.');
  static const drawerClosed = LText(
    'You close it. Something inside shifts.',
    'Uni yopasiz. Ichida nimadir siljidi.',
  );
  static const drawerAgain = LText(
    'Empty now. Scratched into the wood: AGAIN.',
    'Endi bo‘sh. Yog‘ochga tirnab yozilgan: YANA.',
  );
  static const drawerEmpty = LText('Empty.', 'Bo‘sh.');
  static const clock1 = LText(
    '11:47. The second hand is not moving.',
    '11:47. Soniya mili qimirlamayapti.',
  );
  static const clock1Again = LText(
    'Still 11:47. You are sure it was 11:47 before.',
    'Hamon 11:47. Avval ham 11:47 edi, aniq eslaysiz.',
  );
  static const table1 = LText(
    'Scratches in the wood, in groups of five. Someone was counting.',
    'Yog‘ochda beshtadan tirnalgan izlar. Kimdir nimanidir sanagan.',
  );
  static const table1Again = LText(
    'You stop counting at forty. There are more.',
    'Qirqqa yetganda sanashni to‘xtatasiz. Yana bor.',
  );

  // The mirror
  static const clockRunning = LText(
    'The hands move faster than they should.',
    'Millar bo‘lishi kerakidan tezroq yurmoqda.',
  );
  static const clockMidnight = LText(
    'Midnight. The clock has stopped.',
    'Yarim tun. Soat to‘xtadi.',
  );
  static const midnight = LText(
    'The clock strikes twelve.',
    'Soat o‘n ikkini urdi.',
  );
  static const mirrorAfter = LText('You looked.', 'Siz qaradingiz.');
  static const mirrorAgain = LText("Don't.", 'Qarama.');
  static const paintingPlain = LText(
    'A portrait. The face has been scratched out.',
    'Portret. Yuzi tirnab o‘chirilgan.',
  );
  static const paintingPlainAgain = LText(
    'The scratches go both ways. From the inside, too.',
    'Tirnalgan izlar ikki tomonlama. Ichkaridan ham.',
  );
  static const paintingKey = LText(
    'You lift the painting. A small key is taped to the back.',
    'Rasmni ko‘tarasiz. Orqasiga kichik kalit yopishtirilgan.',
  );
  static const paintingEmpty = LText(
    'Nothing else behind it.',
    'Ortida boshqa hech narsa yo‘q.',
  );
  static const chair = LText(
    'The chair faces the mirror. Someone sat here, waiting.',
    'Stul ko‘zguga qaragan. Kimdir shu yerda o‘tirib kutgan.',
  );
  static const chairAgain = LText(
    'The seat is still warm.',
    'O‘rindiq hali ham iliq.',
  );
  static const doorOpens = LText('The key turns.', 'Kalit buraldi.');

  // The candles
  static const candleCarved = LText(
    'Carved into the wax: ',
    'Mumga o‘yib yozilgan: ',
  );
  static const candleBurning = LText(
    'It is already burning.',
    'U allaqachon yonmoqda.',
  );
  static const candlesOut = LText(
    'All the flames die at once. Not like that.',
    'Hamma alanga birdan o‘chdi. Bunday emas.',
  );
  static const candlesSolved = LText(
    'Behind the door, a lock turns by itself.',
    'Eshik ortida qulf o‘z-o‘zidan buraldi.',
  );
  static const candleDoorOpen = LText(
    'The door is open now.',
    'Endi eshik ochiq.',
  );
  static const photoAgain = LText(
    'Three faces. One of them is looking at you.',
    'Uchta yuz. Ulardan biri sizga qarab turibdi.',
  );

  // Hide
  static const wardrobeHide = LText(
    'You squeeze inside and pull the doors shut.',
    'Ichkariga kirib, eshiklarni yopib olasiz.',
  );
  static const bulb = LText(
    'It hums. It does not want to stay on.',
    'Lampochka g‘o‘ng‘illaydi. U uzoq yonib turmaydi.',
  );
  static const chair4 = LText(
    'Someone sat here, facing the wardrobe.',
    'Kimdir shu yerda shkafga qarab o‘tirgan.',
  );
  static const itLeft = LText(
    'It left something on the floor where it stood.',
    'U turgan joyida polda nimadir qoldirdi.',
  );
  static const itSawYou = LText('It saw you.', 'U sizni ko‘rdi.');
  static const ironKey = LText(
    'An iron key. Still warm from its hand.',
    'Temir kalit. Hali ham uning qo‘lidan iliq.',
  );

  // The radio
  static const radioStatic = LText(
    'Static. Under it, something breathing.',
    'Shovqin. Uning ostida nimadir nafas olayapti.',
  );
  static const radioNumbers = LText(
    'A calm voice reads numbers: “…four… zero… nine…”',
    'Sokin ovoz raqamlarni o‘qiydi: “…to‘rt… nol… to‘qqiz…”',
  );
  static const radioBreathing = LText(
    'Only breathing now.',
    'Endi faqat nafas ovozi.',
  );
  static const callerTitle = LText('THE RADIO', 'RADIO');
  static const callerBody = LText(
    'A woman’s voice, very close:\n“Sweetheart? It’s Mama. Answer me.”',
    'Juda yaqindan ayol ovozi:\n“Jonim? Bu men, onang. Javob ber.”',
  );
  static const answer = LText('ANSWER', 'JAVOB BERISH');
  static const staySilent = LText('STAY SILENT', 'JIM TURISH');
  static const answered = LText(
    'Now it knows your voice.',
    'Endi u ovozingizni taniydi.',
  );
  static const stayedSilent = LText(
    'It waits. Then it starts reading numbers again.',
    'U kutdi. Keyin yana raqamlarni o‘qiy boshladi.',
  );
  static const calendar = LText(
    'APRIL 1979. One day is circled in red: the 9th.',
    'APREL 1979. Bir kun qizil bilan aylantirilgan: 9-kun.',
  );
  static const table5 = LText(
    'Fingerprints in the dust. Small ones.',
    'Changda barmoq izlari. Kichkina izlar.',
  );

  // The lullaby
  static const musicWind = LText(
    'You wind it. A lullaby begins — you know the words. You don’t know how.',
    'Uni burab qo‘yasiz. Alla boshlanadi — so‘zlarini bilasiz. '
        'Qayerdan — bilmaysiz.',
  );
  static const musicByItself = LText(
    'The music box begins to play by itself.',
    'Musiqa qutisi o‘z-o‘zidan chala boshladi.',
  );
  static const musicPlaying = LText(
    'Somewhere in the house, someone hums along.',
    'Uyning qayeridadir kimdir unga jo‘r bo‘lib xirgoyi qilyapti.',
  );
  static const musicWoundDown = LText(
    'It has wound down. Wait.',
    'U to‘xtab qoldi. Kuting.',
  );
  static const musicStops = LText('The music stops.', 'Musiqa to‘xtadi.');
  static const dollWaiting = LText(
    'Its hands are clasped around something. It is waiting for the music.',
    'Qo‘llari nimanidir mahkam qisib turibdi. U musiqani kutyapti.',
  );
  static const dollFinger = LText(
    'You pry one cold finger loose.',
    'Muzdek barmoqlaridan birini ochasiz.',
  );
  static const dollFingerAgain = LText(
    'Another finger. Keep going.',
    'Yana bittasi. Davom eting.',
  );
  static const dollKey = LText(
    'Its hands fall open. A small brass key.',
    'Qo‘llari ochilib ketdi. Kichik jez kalit.',
  );
  static const dollSmiling = LText(
    'It is smiling now. It wasn’t before.',
    'U endi jilmayib turibdi. Avval unday emasdi.',
  );
  static const sawYouMove = LText(
    'It saw you move.',
    'U qimirlaganingizni ko‘rdi.',
  );
  static const handsClosed = LText(
    'It saw you move. Its hands are clasped again.',
    'U qimirlaganingizni ko‘rdi. Qo‘llari yana qisildi.',
  );
  static const cradle = LText(
    'An empty cradle. A brass plate: 9 APRIL 1979 · 3:17.',
    'Bo‘sh beshik. Jez lavhada: 9 APREL 1979 · 3:17.',
  );
  static const cradleAgain = LText(
    'It rocks gently, as if someone has only just left it.',
    'U sekin tebranmoqda — go‘yo kimdir uni hozirgina tark etgandek.',
  );
  static const dresser = LText(
    'Tiny clothes, folded neatly. Never worn.',
    'Taxlab qo‘yilgan mitti kiyimlar. Hech kiyilmagan.',
  );
  static const dresserAgain = LText(
    'A name was sewn into every collar. The thread has been pulled out.',
    'Har bir yoqaga ism tikilgan edi. Iplari sug‘urib olingan.',
  );

  // The portraits
  static const lookBehind = LText('LOOK BEHIND IT', 'ORTIGA QARASH');
  static const leavePortrait = LText('STEP BACK', 'CHEKINISH');
  static const notMarta = LText('That was not Marta.', 'Bu Marta emas edi.');
  static const stillWatching = LText(
    'Don’t. It is still watching you.',
    'Tegmang. U hali ham sizni kuzatyapti.',
  );
  static const eliasKey = LText(
    'Behind Elias, a key hangs on a nail.',
    'Elias ortida, mixda kalit osilib turibdi.',
  );
  static const annaSorry = LText(
    'Behind the frame, pencilled on the wallpaper: I’M SORRY, MY LOVE.',
    'Ramka ortida, devor qog‘oziga qalamda yozilgan: KECHIR, JONIM.',
  );
  static const emptyFrame = LText(
    'An empty frame, leaning against the wall. The nameplate has been '
        'scratched off.',
    'Devorga suyab qo‘yilgan bo‘sh ramka. Nom lavhasi tirnab o‘chirilgan.',
  );
  static const emptyFrameAgain = LText(
    'It is the only frame without dust. It is waiting for someone.',
    'Changsiz yagona ramka — shu. U kimnidir kutyapti.',
  );

  // The bells
  static const bellsWait = LText(
    'Not yet. Listen first.',
    'Hali emas. Avval tinglang.',
  );
  static const bellsAgain = LText(
    'Silence. Then they ring again — longer.',
    'Jimlik. Keyin ular yana chalinadi — uzunroq.',
  );
  static const bellsWrong = LText(
    'Wrong bell. Something starts down the stairs.',
    'Noto‘g‘ri qo‘ng‘iroq. Nimadir zinadan tusha boshladi.',
  );
  static const bellsUnanswered = LText(
    'Nobody answered. Footsteps, coming closer.',
    'Hech kim javob bermadi. Qadam tovushlari yaqinlashmoqda.',
  );
  static const bellsSolved = LText(
    'The last bell fades. Behind the door, a bolt slides back.',
    'So‘nggi qo‘ng‘iroq tindi. Eshik ortida zulfin surildi.',
  );
  static const bellsQuiet = LText(
    'It hangs still. It has said everything it had to say.',
    'U qimirlamay osilib turibdi. Aytadiganini aytib bo‘ldi.',
  );
  static const coat = LText(
    'A man’s coat. In the pocket, a train ticket for the morning of '
        '10 April 1948. Never used.',
    'Erkak paltosi. Cho‘ntagida — 1948-yil 10-aprel tonggi poyezdiga '
        'chipta. Ishlatilmagan.',
  );
  static const coatAgain = LText(
    'He never made it to the morning.',
    'U tongga yetib bormagan.',
  );

  // The dinner
  static LText placeSet(LText name) => LText(
    'You set a place for ${name.en}.',
    '${name.uz} uchun joy hozirlaysiz.',
  );
  static const blankCard = LText(
    'A card with no name. Its chair is the only one without dust.',
    'Ismsiz kartochka. Uning stuli — changsiz yagona stul.',
  );
  static const guestCard = LText(
    'GUEST, in red ink. The chair is already pulled out.',
    'Qizil siyohda: MEHMON. Stul allaqachon surib qo‘yilgan.',
  );
  static const plateTaken = LText(
    'You take the plate away.',
    'Likopchani olib qo‘yasiz.',
  );
  static const guestSits = LText(
    'The guest’s chair scrapes back. Something sits down.',
    'Mehmonning stuli g‘ichirlab surildi. Nimadir o‘tirdi.',
  );
  static const platesBroken = LText(
    'When the light returns, every plate lies broken on the floor.',
    'Yorug‘lik qaytganda, barcha likopchalar polda sinib yotardi.',
  );
  static const dinnerSolved = LText(
    'Four chairs scrape back at once. Somewhere, a lock turns.',
    'To‘rtta stul birdaniga g‘ichirladi. Qayerdadir qulf buraldi.',
  );
  static const dinnerServed = LText(
    'Everyone is seated. They are waiting for you.',
    'Hamma o‘tirdi. Ular sizni kutishyapti.',
  );
  static const dinnerClock = LText(
    '3:16. One minute left.',
    '3:16. Bir daqiqa qoldi.',
  );
  static const dinnerTable = LText(
    'Five places. Five cards. Dust on everything.',
    'Beshta joy. Beshta kartochka. Hamma yoqda chang.',
  );

  // The study
  static const marksWall = LText(
    'Marks scratched into the wallpaper, in groups of five. Twenty.',
    'Devor qog‘oziga beshtalab tirnalgan izlar. Yigirmata.',
  );
  static const marksDesk = LText(
    'Cut into the desk with a knife: fifteen more.',
    'Stolga pichoq bilan o‘yilgan: yana o‘n beshta.',
  );
  static const marksFloor = LText(
    'A loose board. Underneath: six more marks — and the knife that made them.',
    'Bo‘sh taxta. Tagida yana oltita iz — va ularni o‘ygan pichoq.',
  );
  static const diaryOpens = LText(
    'Click. The diary falls open. Something slips out from between the pages.',
    'Chiq. Kundalik ochilib ketdi. Sahifalar orasidan nimadir sirg‘alib '
        'tushdi.',
  );
  static const inkwell = LText(
    'An inkwell and a pen. The ink is still wet.',
    'Siyohdon va qalam. Siyoh hali qurimagan.',
  );
  static const handwriting = LText(
    'You write a word to test the pen. It is the same handwriting as every '
        'note in this house.',
    'Qalamni sinash uchun bir so‘z yozasiz. Bu — uydagi barcha '
        'eslatmalardagi dastxatning aynan o‘zi.',
  );
  static const handwritingAgain = LText(
    'Yours. It was always yours.',
    'Sizniki. U doim sizniki bo‘lgan.',
  );

  // The knock
  static const phoneDead = LText(
    'The screen is dark. No signal.',
    'Ekran qorong‘i. Signal yo‘q.',
  );
  static const clockStopped = LText(
    'A small clock. Stopped at 3:17.',
    'Kichkina soat. 3:17 da to‘xtagan.',
  );
  static const clockKey = LText(
    'You lift the clock. Underneath — a key.',
    'Soatni ko‘tarasiz. Tagida — kalit.',
  );
  static const clockAfter = LText(
    'The clock is ticking now. Backwards.',
    'Endi soat yurmoqda. Orqaga.',
  );
  static const table6 = LText(
    'Two cups. One of them is still warm.',
    'Ikki piyola. Bittasi hali ham iliq.',
  );
  static const window = LText(
    'Black glass. No street. No sky. Only your breath on it.',
    'Qora oyna. Ko‘cha yo‘q. Osmon yo‘q. Faqat nafasingiz izi.',
  );
  static const windowAfter = LText(
    'The letters are fading.',
    'Harflar o‘chib bormoqda.',
  );
  static const doorBreathing = LText(
    'Locked. Something on the other side is breathing.',
    'Qulflangan. Narigi tomonda nimadir nafas olmoqda.',
  );
  static const stepBack = LText(
    'You step back. The knocking gets louder.',
    'Orqaga chekinasiz. Taqillatish kuchayadi.',
  );
  static const doorChoiceTitle = LText('THE DOOR', 'ESHIK');
  static const doorChoiceKnocking = LText(
    'The key fits.\nSomeone is still knocking.',
    'Kalit mos keldi.\nKimdir hamon taqillatmoqda.',
  );
  static const doorChoiceKnown = LText(
    'The key fits both ways.\nIt is waiting for you to decide.',
    'Kalit ikki tomonga ham buraladi.\nU sizning qaroringizni kutmoqda.',
  );
  static const openIt = LText('OPEN IT', 'OCHISH');
  static const lockIt = LText('LOCK IT', 'QULFLASH');
  static const stepBackOption = LText('STEP BACK', 'CHEKINISH');
}
