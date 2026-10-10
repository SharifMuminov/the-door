import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/settings_cubit.dart';
import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';
import '../../core/l10n/l_text.dart';
import '../../core/l10n/ui_text.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/fade_route.dart';
import '../../core/utils/game_storage.dart';
import '../../core/utils/haptics.dart';
import '../data/game_data.dart';
import '../logic/game_controller.dart';
import '../logic/game_effect.dart';
import '../logic/game_state.dart';
import '../models/game_object.dart';
import '../models/inventory_item.dart';
import '../models/level.dart';
import '../widgets/choice_dialog.dart';
import '../widgets/clue_dialog.dart';
import '../widgets/dialogue_overlay.dart';
import '../widgets/hide_overlay.dart';
import '../widgets/horror_overlay.dart';
import '../widgets/inventory_bar.dart';
import '../widgets/keypad_dialog.dart';
import '../widgets/level_intro.dart';
import '../widgets/room_view.dart';
import 'ending_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.startLevel, this.fresh = false});

  final int startLevel;

  /// True for PLAY: wipes saved progress before Room 01.
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final controller = GameController(
          storage: context.read<GameStorage>(),
          startLevel: startLevel,
        );
        unawaited(controller.start(level: startLevel, fresh: fresh));
        return controller;
      },
      child: const _GameView(),
    );
  }
}

/// Renders the room and plays every [GameEffect] the controller sends.
class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  final _fx = GlobalKey<HorrorOverlayState>();
  late final GameController _game = context.read<GameController>();
  late final AudioManager _audio = context.read<AudioManager>();
  late final Haptics _haptics = context.read<Haptics>();
  StreamSubscription<GameEffect>? _effects;

  LText? _message;
  int _messageId = 0;
  int _knockSeq = 0;
  bool _mirrorApparition = false;
  bool _passing = false;
  bool _doorOpen = false;
  bool _transitioning = false;
  int? _introLevel;
  double _blackout = 0;
  Duration _blackoutSpeed = GameTimings.blackout;

  /// Extra darkness for a moment (the guest sitting down).
  double _lightsGone = 0;

  /// The bells: which one is swinging, and a counter to swing it again.
  ObjectId? _ringing;
  int _ringSeq = 0;
  bool _tunePlaying = false;
  List<ObjectId>? _queuedTune;

  /// Non-null while a dialog is open; completes when it closes.
  Completer<void>? _dialog;

  bool get _canInteract =>
      _dialog == null &&
      !_transitioning &&
      _introLevel == null &&
      !_tunePlaying;

  static const _bellSounds = {
    ObjectId.bellA: Sfx.bellA,
    ObjectId.bellB: Sfx.bellB,
    ObjectId.bellC: Sfx.bellC,
    ObjectId.bellD: Sfx.bellD,
  };

  @override
  void initState() {
    super.initState();
    _effects = _game.effects.listen(_onEffect);
    _introLevel = _game.state.currentLevel;
    unawaited(_audio.startAmbience(volume: .55));
  }

  @override
  void dispose() {
    unawaited(_effects?.cancel());
    unawaited(_audio.stopLoop());
    super.dispose();
  }

  // ================================================================ input

  void _onObjectTap(ObjectId id) {
    if (_canInteract) _game.interact(id);
  }

  void _onItemTap(ItemId id) {
    if (_canInteract) _game.inspectItem(id);
  }

  void _onHint() {
    if (_canInteract) _game.requestHint();
  }

  void _introDone() {
    if (!mounted) return;
    setState(() => _introLevel = null);
    _game.beginLevel();
  }

  Future<void> _pause() async {
    if (_dialog != null || _transitioning) return;
    final leave = await _openDialog(
      () => showChoiceDialog<bool>(
        context,
        title: UiText.paused,
        body: UiText.pausedBody,
        options: const [
          ChoiceDialogOption(UiText.keepPlaying, false),
          ChoiceDialogOption(UiText.leaveRoom, true, danger: true),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // ================================================================ effects

  void _onEffect(GameEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case MessageEffect(:final text):
        setState(() {
          _message = text;
          _messageId++;
        });
      case SoundEffect(:final sfx, :final volume):
        unawaited(_audio.play(sfx, volume: volume));
      case LoopEffect(:final sfx, :final volume):
        unawaited(
          sfx == null
              ? _audio.stopLoop()
              : _audio.startLoop(sfx, volume: volume),
        );
      case ClueEffect(:final clue):
        unawaited(_openDialog(() => showClueDialog(context, clue)));
      case KeypadEffect(:final puzzle):
        unawaited(
          _openDialog(
            () => showKeypadDialog(
              context,
              puzzle: puzzle,
              onSubmit: (code) => _game.submitCode(code, id: puzzle.id),
            ),
          ),
        );
      case PatternEffect(:final bells):
        unawaited(_playTune(bells));
      case BellEffect(:final bell):
        _ring(bell);
      case ChoiceEffect(:final choice):
        unawaited(_openChoice(choice));
      case HorrorEffect(:final kind):
        unawaited(_horror(kind));
      case DoorOpenEffect():
        unawaited(_openDoor());
      case EndingEffect(:final ending):
        unawaited(_end(ending));
    }
  }

  /// Opens one dialog at a time; double taps can't stack them.
  Future<R?> _openDialog<R>(Future<R> Function() show) async {
    if (_dialog != null || !mounted) return null;
    final done = Completer<void>();
    setState(() => _dialog = done);
    try {
      return await show();
    } finally {
      done.complete();
      if (mounted) setState(() => _dialog = null);
    }
  }

  Future<void> _openChoice(Choice choice) async {
    final picked = await _openDialog(
      () => showChoiceDialog<ChoiceAction>(
        context,
        title: choice.title,
        body: choice.body,
        options: [
          for (final o in choice.options)
            ChoiceDialogOption(o.label, o.action, danger: o.danger),
        ],
      ),
    );
    final action = picked ?? choice.dismissAction;
    if (action != null && mounted) _game.choose(action);
  }

  Future<void> _horror(HorrorKind kind) async {
    final fx = _fx.currentState;
    switch (kind) {
      case HorrorKind.lampShadow:
        unawaited(_audio.play(Sfx.lampSwitch));
        unawaited(_haptics.heavy());
        fx?.flash(AppColors.bone, strength: .7);
        await _wait(140);
        unawaited(_audio.play(Sfx.horror, volume: .9));
        fx?.shadow();
        await _wait(450);
        _fx.currentState?.flicker();
      case HorrorKind.lampFlicker:
        unawaited(_audio.play(Sfx.lampSwitch));
        fx?.flicker();
      case HorrorKind.wrongCode:
        fx?.flash(AppColors.blood, strength: .45);
        fx?.shake(3);
        unawaited(_audio.play(Sfx.knock, volume: .35));
        unawaited(_haptics.medium());
      case HorrorKind.knock:
        await _knock(heavy: false);
      case HorrorKind.heavyKnock:
        await _knock(heavy: true);
      case HorrorKind.midnight:
        unawaited(_audio.play(Sfx.chime));
        unawaited(_haptics.heavy());
        fx?.flicker();
        await _wait(1200);
        _fx.currentState?.flicker();
      case HorrorKind.mirrorApparition:
        setState(() => _mirrorApparition = true);
        unawaited(_audio.play(Sfx.horror));
        unawaited(_audio.play(Sfx.heartbeat));
        unawaited(_haptics.horror());
        fx?.shake(9);
        fx?.flash(AppColors.bloodDeep, strength: .5);
        await _wait(850);
        if (!mounted) return;
        setState(() => _mirrorApparition = false);
        _fx.currentState?.glitch();
        await _wait(500);
        unawaited(_audio.play(Sfx.heartbeat, volume: .7));
      case HorrorKind.glitch:
        unawaited(_audio.play(Sfx.glitch, volume: .6));
        unawaited(_haptics.light());
        fx?.glitch();
      case HorrorKind.silence:
        _audio.silence(const Duration(seconds: 6));
      case HorrorKind.candlesOut:
        unawaited(_audio.play(Sfx.breath, volume: .8));
        unawaited(_haptics.medium());
        fx?.flicker();
      case HorrorKind.bulbFlicker:
        unawaited(_audio.play(Sfx.lampSwitch, volume: .5));
        fx?.flicker();
        await _wait(1300);
        unawaited(_audio.play(Sfx.lampSwitch, volume: .4));
        _fx.currentState?.flicker();
      case HorrorKind.lightsOut:
        unawaited(_audio.play(Sfx.lampSwitch, volume: .7));
        unawaited(_haptics.heavy());
        await _wait(500);
        unawaited(_audio.play(Sfx.steps, volume: .7));
      case HorrorKind.passBy:
        setState(() => _passing = true);
        unawaited(_audio.play(Sfx.steps));
        unawaited(_audio.play(Sfx.heartbeat, volume: .8));
        unawaited(_haptics.medium());
        await _wait(GameTimings.passBy.inMilliseconds - 200);
        if (mounted) setState(() => _passing = false);
      case HorrorKind.caught:
        unawaited(_audio.play(Sfx.horror));
        unawaited(_haptics.horror());
        fx?.eyes();
        fx?.shake(8);
        await _wait(700);
        _fx.currentState?.flash(AppColors.bone, strength: .35);
      case HorrorKind.radioScream:
        unawaited(_audio.play(Sfx.radioStatic));
        unawaited(_audio.play(Sfx.horror, volume: .8));
        unawaited(_haptics.horror());
        fx?.glitch();
        fx?.flash(AppColors.blood, strength: .5);
        fx?.shake(7);
      case HorrorKind.musicStops:
        unawaited(_haptics.light());
        fx?.flicker();
      case HorrorKind.dollCaught:
        unawaited(_audio.play(Sfx.horror));
        unawaited(_haptics.horror());
        fx?.eyes();
        fx?.shake(8);
        fx?.flash(AppColors.blood, strength: .4);
      case HorrorKind.impostor:
        unawaited(_audio.play(Sfx.horror));
        unawaited(_audio.play(Sfx.glitch, volume: .8));
        unawaited(_haptics.horror());
        fx?.glitch();
        fx?.shake(10);
        fx?.flash(AppColors.bloodDeep, strength: .6);
        await _wait(450);
        _fx.currentState?.glitch();
        await _wait(700);
        unawaited(_audio.play(Sfx.heartbeat, volume: .8));
      case HorrorKind.wrongBell:
        unawaited(_audio.play(Sfx.steps, volume: .8));
        unawaited(_haptics.heavy());
        fx?.flicker();
        await _wait(1000);
        unawaited(_audio.play(Sfx.knock));
        unawaited(_haptics.heavy());
        if (mounted) setState(() => _knockSeq++);
        _fx.currentState?.shake(5);
      case HorrorKind.footsteps:
        unawaited(_audio.play(Sfx.steps, volume: .6));
        unawaited(_haptics.medium());
      case HorrorKind.guestSits:
        unawaited(_audio.play(Sfx.scrape));
        unawaited(_haptics.heavy());
        fx?.flicker();
        await _wait(350);
        if (!mounted) return;
        setState(() => _lightsGone = .93);
        unawaited(_audio.play(Sfx.horror, volume: .9));
        _fx.currentState
          ?..eyes()
          ..shake(7);
        await _wait(900);
        unawaited(_audio.play(Sfx.plate));
        await _wait(150);
        unawaited(_audio.play(Sfx.plate, volume: .7));
        await _wait(600);
        if (mounted) setState(() => _lightsGone = 0);
      case HorrorKind.handwriting:
        unawaited(_audio.play(Sfx.scribble));
        await _wait(1000);
        unawaited(_audio.play(Sfx.glitch, volume: .5));
        unawaited(_haptics.light());
        _fx.currentState?.glitch();
    }
  }

  /// Rings one bell: it swings, and it sounds.
  void _ring(ObjectId bell) {
    if (!mounted) return;
    setState(() {
      _ringing = bell;
      _ringSeq++;
    });
    final sound = _bellSounds[bell];
    if (sound != null) unawaited(_audio.play(sound, volume: .9));
    unawaited(_haptics.light());
  }

  /// Plays the bell tune once nothing covers the room, then lets the
  /// player answer. Taps are ignored while it plays.
  Future<void> _playTune(List<ObjectId> bells) async {
    if (_tunePlaying) {
      _queuedTune = bells;
      return;
    }
    setState(() => _tunePlaying = true);
    while (_dialog != null || _introLevel != null) {
      await (_dialog?.future ?? _wait(300));
      if (!mounted) return;
    }
    await _wait(700);
    for (final bell in bells) {
      if (!mounted) return;
      _ring(bell);
      await _wait(GameTimings.bellInterval.inMilliseconds);
    }
    await _wait(250);
    if (!mounted) return;
    setState(() => _tunePlaying = false);
    final next = _queuedTune;
    _queuedTune = null;
    if (next != null) {
      unawaited(_playTune(next));
    } else {
      _game.patternShown();
    }
  }

  Future<void> _knock({required bool heavy}) async {
    final word = context.tr(UiText.knock);
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _knockSeq++);
      unawaited(_audio.play(Sfx.knock, volume: heavy ? 1 : .75));
      unawaited(heavy ? _haptics.heavy() : _haptics.medium());
      _fx.currentState
        ?..shake(heavy ? 4 : 1.5)
        ..word(word, i);
      await _wait(GameTimings.knockInterval.inMilliseconds);
    }
  }

  /// The door swings open, then the next room.
  Future<void> _openDoor() async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    await _dialog?.future;
    await _wait(250);
    if (!mounted) return;

    unawaited(_audio.play(Sfx.lock));
    unawaited(_haptics.medium());
    await _wait(350);
    if (!mounted) return;
    unawaited(_audio.play(Sfx.creak, volume: .8));
    unawaited(_audio.play(Sfx.heartbeat));
    setState(() => _doorOpen = true);
    await _wait(900);
    unawaited(_audio.play(Sfx.heartbeat, volume: .8));
    await _wait(GameTimings.afterDoorOpens.inMilliseconds - 900);
    if (!mounted) return;

    setState(() {
      _blackoutSpeed = GameTimings.blackout;
      _blackout = 1;
    });
    await _wait(GameTimings.blackout.inMilliseconds + 200);
    if (!mounted) return;

    await _game.goToNextLevel();
    if (!mounted) return;
    setState(() {
      _doorOpen = false;
      _passing = false;
      _ringing = null;
      _lightsGone = 0;
      _introLevel = _game.state.currentLevel;
      _blackoutSpeed = Duration.zero;
      _blackout = 0;
      _transitioning = false;
    });
  }

  Future<void> _end(GameEnding ending) async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    await _dialog?.future;
    if (!mounted) return;

    if (ending == GameEnding.bad) {
      unawaited(_audio.play(Sfx.lock, volume: .8));
      await _wait(300);
      if (!mounted) return;
      unawaited(_audio.play(Sfx.creak));
      setState(() => _doorOpen = true);
      await _wait(750);
      if (!mounted) return;
      // Hard cut: no light, no sound.
      unawaited(_audio.stopAmbience());
      unawaited(_haptics.horror());
      setState(() {
        _blackoutSpeed = Duration.zero;
        _blackout = 1;
      });
      await _wait(1800);
    } else {
      unawaited(_audio.play(Sfx.lock));
      unawaited(_haptics.medium());
      await _wait(900);
      _audio.silence(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _blackoutSpeed = const Duration(milliseconds: 2600);
        _blackout = 1;
      });
      await _wait(3000);
      unawaited(_audio.stopAmbience());
    }

    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        FadeRoute<void>(
          builder: (_) => EndingScreen(ending: ending),
          duration: const Duration(milliseconds: 400),
        ),
      ),
    );
  }

  Future<void> _wait(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// How dark the room is right now, on top of its own shadows.
  double _darkness(Level level, GameState s) {
    final room = switch (level.kind) {
      RoomKind.rule => s.lampOn ? .4 : 0.0,
      RoomKind.candles =>
        (s.puzzles[level.doorPuzzle.id]?.solved ?? false)
            ? 0.0
            : (.45 - .15 * s.litCandles.length).clamp(0.0, 1.0),
      RoomKind.hide => s.lightsOut ? .94 : 0.0,
      RoomKind.lullaby => s.stillness ? .5 : 0.0,
      _ => 0.0,
    };
    return room > _lightsGone ? room : _lightsGone;
  }

  // ================================================================ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_pause());
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: BlocBuilder<GameController, GameState>(
          builder: (context, state) {
            final level = GameData.level(state.currentLevel);
            final intro = _introLevel;
            final message = _message;
            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    _TopBar(
                      code: context.tr(level.code),
                      hintReady: state.hintReady,
                      onPause: _pause,
                      onHint: _onHint,
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          HorrorOverlay(
                            key: _fx,
                            darkness: _darkness(level, state),
                            child: RoomView(
                              level: level,
                              state: state,
                              interactive: _canInteract,
                              doorOpen: _doorOpen,
                              knockSeq: _knockSeq,
                              mirrorApparition: _mirrorApparition,
                              ringing: _ringing,
                              ringSeq: _ringSeq,
                              onObjectTap: _onObjectTap,
                            ),
                          ),
                          if (state.hidden)
                            HideOverlay(
                              passing: _passing,
                              onStepOut: _game.stepOut,
                            ),
                          DialogueOverlay(
                            message: message == null
                                ? null
                                : context.tr(message),
                            messageId: _messageId,
                          ),
                        ],
                      ),
                    ),
                    InventoryBar(items: state.inventory, onItemTap: _onItemTap),
                  ],
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _blackout,
                    duration: _blackoutSpeed,
                    child: const ColoredBox(color: AppColors.black),
                  ),
                ),
                if (intro != null)
                  LevelIntro(
                    key: ValueKey(intro),
                    level: GameData.level(intro),
                    onDone: _introDone,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.code,
    required this.hintReady,
    required this.onPause,
    required this.onHint,
  });

  final String code;
  final bool hintReady;
  final VoidCallback onPause;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              _BarButton(
                label: context.tr(UiText.pause),
                onTap: onPause,
                child: const Icon(
                  Icons.pause,
                  size: 20,
                  color: AppColors.smoke,
                ),
              ),
              Expanded(
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: AppText.label,
                ),
              ),
              _BarButton(
                label: context.tr(UiText.hint),
                onTap: onHint,
                child: _HintIcon(ready: hintReady),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 56, height: 48, child: Center(child: child)),
      ),
    );
  }
}

/// An eye. When the player seems stuck it slowly glows red.
class _HintIcon extends StatefulWidget {
  const _HintIcon({required this.ready});

  final bool ready;

  @override
  State<_HintIcon> createState() => _HintIconState();
}

class _HintIconState extends State<_HintIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_HintIcon old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.ready && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.ready && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Icon(
          Icons.visibility_outlined,
          size: 20,
          color: Color.lerp(AppColors.smoke, AppColors.bloodLight, t),
          shadows: [
            if (t > 0)
              Shadow(
                color: AppColors.bloodLight.withValues(alpha: .6 * t),
                blurRadius: 12,
              ),
          ],
        );
      },
    );
  }
}
