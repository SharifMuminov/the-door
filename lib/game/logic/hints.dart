import '../../core/l10n/l_text.dart';
import '../data/game_data.dart';
import '../models/clue.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import 'game_state.dart';

/// Picks a small nudge for where the player is right now.
/// Hints never give the answer away outright, only the next step.
LText hintFor(Level level, GameState s) {
  if (!s.knows(level.note)) return _readTheNote;

  final puzzleSolved = s.puzzles[level.doorPuzzle.id]?.solved ?? false;
  switch (level.kind) {
    case RoomKind.rule:
      if (!s.has(ItemId.drawerCode)) return _drawer;
      return _rememberCode;

    case RoomKind.mirror:
      if (!s.has(ItemId.paintingKey)) {
        if (!s.midnightPassed && !s.knows(ClueId.mirrorReflection)) {
          return _mirrorBeforeMidnight;
        }
        return _behindPainting;
      }
      return _useKey;

    case RoomKind.candles:
      if (puzzleSolved) return _doorIsOpen;
      if (!s.knows(ClueId.photoBack)) return _photoBack;
      return _candleOrder;

    case RoomKind.hide:
      if (s.has(ItemId.ironKey)) return _useKey;
      if (s.keyRevealed) return _leftOnFloor;
      return _hideInWardrobe;

    case RoomKind.radio:
      if (!s.knows(ClueId.radioNumbers) && !s.knows(ClueId.calendar)) {
        return _turnTheDial;
      }
      return _radioCode;

    case RoomKind.lullaby:
      if (s.has(ItemId.dollKey)) return _useKey;
      if (!s.musicWound) return _windMusicBox;
      if (s.dollFingers == 0) return _dollHolds;
      return _freeze;

    case RoomKind.portraits:
      if (s.has(ItemId.portraitKey)) return _useKey;
      final asked = GameData.portraitWords.keys
          .where((p) => s.timesTouched(p) > 0)
          .length;
      if (asked < GameData.portraitWords.length) return _askThemAll;
      return _onlyOneLies;

    case RoomKind.bells:
      if (puzzleSolved) return _doorIsOpen;
      if (s.bellRound == 0) return _listenToBells;
      return _longerEachTime;

    case RoomKind.dinner:
      if (puzzleSolved) return _doorIsOpen;
      const family = {ObjectId.seatA, ObjectId.seatB, ObjectId.seatD};
      if (!s.setPlaces.containsAll(family)) return _theDeadToo;
      return _cardWithoutName;

    case RoomKind.study:
      if (s.has(ItemId.studyKey)) return _useKey;
      final counted = [
        ClueId.marksWall,
        ClueId.marksDesk,
        ClueId.marksFloor,
      ].every(s.knows);
      if (!counted) return _findTheMarks;
      return _addThemUp;

    case RoomKind.knock:
      if (!s.knockingStarted) return _wait;
      if (!s.knows(ClueId.phoneMessages)) return _phone;
      if (!s.has(ItemId.key)) return _underClock;
      if (!s.knows(ClueId.windowTruth)) return _window;
      return _dontGiveIt;
  }
}

const _readTheNote = LText(
  'There is a note in this room. Read it first.',
  'Bu xonada eslatma bor. Avval uni o‘qing.',
);
const _drawer = LText(
  'Rooms like this keep their secrets in drawers.',
  'Bunday xonalar sirlarini tortmalarda saqlaydi.',
);
const _rememberCode = LText(
  'The door remembers three numbers. Now you do too.',
  'Eshik uchta raqamni eslaydi. Endi siz ham.',
);
const _mirrorBeforeMidnight = LText(
  'Before twelve, the mirror is safe. Look closely.',
  'O‘n ikkigacha ko‘zgu xavfsiz. Diqqat bilan qarang.',
);
const _behindPainting = LText(
  'Something is hidden behind the painting.',
  'Rasm ortida nimadir yashiringan.',
);
const _useKey = LText('The key fits the door.', 'Kalit eshikka mos keladi.');
const _doorIsOpen = LText('The door is open now.', 'Endi eshik ochiq.');
const _photoBack = LText(
  'The photograph has writing on the back.',
  'Suratning orqasida yozuv bor.',
);
const _candleOrder = LText(
  'The one who left first. Then the next. Then the last.',
  'Avval birinchi ketgan. Keyin keyingisi. Oxirida — so‘nggisi.',
);
const _hideInWardrobe = LText(
  'When the bulb starts to flicker, get into the wardrobe.',
  'Lampochka miltillay boshlaganda, shkafga kiring.',
);
const _leftOnFloor = LText(
  'It left something on the floor.',
  'U polda nimadir qoldirdi.',
);
const _turnTheDial = LText(
  'The radio still works. Keep turning the dial.',
  'Radio hali ishlaydi. Murvatni burashda davom eting.',
);
const _radioCode = LText(
  'Four. Zero. Nine. The calendar agrees.',
  'To‘rt. Nol. To‘qqiz. Taqvim ham shuni aytadi.',
);
const _windMusicBox = LText(
  'The music box. Wind it — and watch the doll.',
  'Musiqa qutisi. Uni burang — va qo‘g‘irchoqni kuzating.',
);
const _dollHolds = LText(
  'The doll is holding something. Only the music loosens its grip.',
  'Qo‘g‘irchoq nimanidir ushlab turibdi. Faqat musiqa uning changalini '
      'bo‘shatadi.',
);
const _freeze = LText(
  'Work while the music plays. When it stops, touch nothing.',
  'Musiqa chalinayotganda harakat qiling. To‘xtasa — hech narsaga tegmang.',
);
const _askThemAll = LText(
  'Ask each of them. Listen to what they say about each other.',
  'Har biridan so‘rang. Ular bir-biri haqida nima deyishini tinglang.',
);
const _onlyOneLies = LText(
  'Only one of them lies. Only one story fits.',
  'Ulardan faqat bittasi yolg‘on gapiradi. Faqat bitta hikoya to‘g‘ri keladi.',
);
const _listenToBells = LText(
  'Wait for the bells. Then ring them back, in the same order.',
  'Qo‘ng‘iroqlarni kuting. Keyin ularni xuddi shu tartibda qayta chaling.',
);
const _longerEachTime = LText(
  'Each time the tune is one bell longer. It always starts the same way.',
  'Har safar kuy bitta qo‘ng‘iroqqa uzayadi. U doim bir xil boshlanadi.',
);
const _theDeadToo = LText(
  'Everyone in this house. The dead never left it.',
  'Bu uydagi hamma. O‘liklar uni hech qachon tark etmagan.',
);
const _cardWithoutName = LText(
  'One card has no name. Who else is in this house?',
  'Bitta kartochkada ism yo‘q. Bu uyda yana kim bor?',
);
const _findTheMarks = LText(
  'Marks on the wall. On the desk. And under your feet.',
  'Devorda izlar bor. Stolda ham. Oyog‘ingiz ostida ham.',
);
const _addThemUp = LText(
  'Add them all up. The diary has two dials.',
  'Hammasini qo‘shing. Kundalikda ikkita g‘ildirakcha bor.',
);
const _wait = LText('Wait. Something is coming.', 'Kuting. Nimadir kelyapti.');
const _phone = LText(
  'Someone is trying to reach you. The phone.',
  'Kimdir siz bilan bog‘lanmoqchi. Telefon.',
);
const _underClock = LText('Under the clock.', 'Soat tagida.');
const _window = LText(
  'Before you choose, look out of the window.',
  'Tanlashdan oldin derazaga qarang.',
);
const _dontGiveIt = LText(
  'You know what it wants. Do not give it that.',
  'U nimani xohlashini bilasiz. Unga buni bermang.',
);
