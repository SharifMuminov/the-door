import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every sound the game can play. Files live in `assets/sounds/`.
enum Sfx {
  click,
  knock,
  heartbeat,
  drawer,
  lock,
  creak,
  horror,
  lampSwitch('switch'),
  tick,
  chime,
  paper,
  key,
  buzz,
  glitch,
  steps,
  breath,
  radioStatic('static'),
  ignite,
  musicBox('musicbox'),
  bellA('bell_a'),
  bellB('bell_b'),
  bellC('bell_c'),
  bellD('bell_d'),
  plate,
  scribble,
  scrape;

  const Sfx([this._file]);

  final String? _file;

  /// Path relative to `assets/`, as `AssetSource` expects.
  String get asset => 'sounds/${_file ?? name}.wav';
}

/// Plays ambience, one looping effect (the music box) and one-shot effects.
///
/// Never throws: if the platform has no audio, or a file is missing from
/// `assets/sounds/`, the call is silently skipped.
class AudioManager {
  AudioManager({bool enabled = true}) : _enabled = enabled;

  static const _ambienceAsset = 'sounds/ambience.wav';
  static const _poolSize = 6;

  bool _enabled;
  bool _ready = false;

  /// True while the app is in the background: nothing new starts.
  bool _suspended = false;
  Set<String> _available = const {};

  AudioPlayer? _ambience;
  double _ambienceVolume = 0.5;
  bool _ambienceWanted = false;
  Timer? _duckTimer;

  AudioPlayer? _loop;
  Sfx? _loopWanted;
  double _loopVolume = 1;

  final List<AudioPlayer> _pool = [];
  int _next = 0;

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (value) {
      if (_ambienceWanted) unawaited(startAmbience(volume: _ambienceVolume));
      final loop = _loopWanted;
      if (loop != null) unawaited(startLoop(loop, volume: _loopVolume));
    } else {
      unawaited(
        _safe(() async {
          await _ambience?.stop();
          await _loop?.stop();
        }),
      );
      for (final p in _pool) {
        unawaited(_safe(p.stop));
      }
    }
  }

  /// Reads the asset manifest so missing files can be skipped up front.
  Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/sounds/'))
          .map((a) => a.substring('assets/'.length))
          .toSet();
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      _ready = true;
    } catch (e) {
      debugPrint('AudioManager: audio unavailable ($e)');
    }
  }

  Future<void> play(Sfx sfx, {double volume = 1}) async {
    if (_suspended || !_canPlay(sfx.asset)) return;
    await _safe(() async {
      if (_pool.length < _poolSize) {
        final fresh = AudioPlayer();
        _pool.add(fresh);
        await fresh.setReleaseMode(ReleaseMode.stop);
      }
      final player = _pool[_next % _pool.length];
      _next++;
      await player.stop();
      await player.play(AssetSource(sfx.asset), volume: volume);
    });
  }

  Future<void> startAmbience({double volume = 0.5}) async {
    _ambienceWanted = true;
    _ambienceVolume = volume;
    if (_suspended || !_canPlay(_ambienceAsset)) return;
    await _safe(() async {
      final player = _ambience ??= AudioPlayer();
      if (player.state == PlayerState.playing) {
        await player.setVolume(volume);
        return;
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(_ambienceAsset), volume: volume);
    });
  }

  Future<void> stopAmbience() async {
    _ambienceWanted = false;
    _duckTimer?.cancel();
    await _safe(() async {
      await _ambience?.stop();
    });
  }

  /// Starts [sfx] looping from the beginning, replacing any other loop.
  Future<void> startLoop(Sfx sfx, {double volume = 1}) async {
    _loopWanted = sfx;
    _loopVolume = volume;
    if (_suspended || !_canPlay(sfx.asset)) return;
    await _safe(() async {
      final player = _loop ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(sfx.asset), volume: volume);
    });
  }

  Future<void> stopLoop() async {
    _loopWanted = null;
    await _safe(() async {
      await _loop?.stop();
    });
  }

  /// Sudden silence: drops the ambience for [duration], then brings it back.
  void silence(Duration duration) {
    if (_ambience == null) return;
    _duckTimer?.cancel();
    unawaited(
      _safe(() async {
        await _ambience?.setVolume(0);
      }),
    );
    _duckTimer = Timer(duration, () {
      if (_enabled && _ambienceWanted) {
        unawaited(
          _safe(() async {
            await _ambience?.setVolume(_ambienceVolume);
          }),
        );
      }
    });
  }

  /// Called when the app goes to the background.
  Future<void> pauseAll() async {
    _suspended = true;
    await _safe(() async {
      await _ambience?.pause();
      await _loop?.pause();
    });
    for (final p in _pool) {
      await _safe(p.stop);
    }
  }

  /// Called when the app comes back to the foreground.
  Future<void> resumeAll() async {
    _suspended = false;
    if (!_enabled) return;
    final ambience = _ambience;
    if (_ambienceWanted) {
      if (ambience?.state == PlayerState.paused) {
        await _safe(ambience!.resume);
      } else {
        await startAmbience(volume: _ambienceVolume);
      }
    }
    // Something may have asked for a loop while the app was away.
    final loop = _loopWanted;
    final player = _loop;
    if (loop == null) return;
    if (player?.state == PlayerState.paused) {
      await _safe(player!.resume);
    } else {
      await startLoop(loop, volume: _loopVolume);
    }
  }

  Future<void> dispose() async {
    _duckTimer?.cancel();
    await _safe(() async {
      await _ambience?.dispose();
      await _loop?.dispose();
    });
    for (final p in _pool) {
      await _safe(p.dispose);
    }
    _pool.clear();
  }

  bool _canPlay(String asset) =>
      _enabled && _ready && _available.contains(asset);

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('AudioManager: $e');
    }
  }
}
