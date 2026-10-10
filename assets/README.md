# Assets

Everything in here is a **placeholder**. The game runs without any of these files:
if a sound is missing, `AudioManager` silently skips it.

## sounds/

All `.wav` files were synthesised from scratch by a script (no third-party
recordings), so they are free to use, but they are rough. Replace any of them
with a final sound **using the same file name**. `.wav` is expected. If you
switch to `.mp3`/`.ogg`, change the extension in `Sfx` (`lib/core/utils/audio_manager.dart`).

| File            | Used for                                          |
|-----------------|---------------------------------------------------|
| `ambience.wav`  | looping background drone (menu + rooms)            |
| `knock.wav`     | a single knock (played 3× for KNOCK KNOCK KNOCK)   |
| `heartbeat.wav` | door unlock, mirror event                          |
| `click.wav`     | tapping objects, keypad buttons                    |
| `tick.wav`      | Room 02 clock                                      |
| `drawer.wav`    | drawer open/close                                  |
| `lock.wav`      | lock / unlock mechanism                            |
| `creak.wav`     | door swinging open                                 |
| `switch.wav`    | lamp switch                                        |
| `horror.wav`    | horror stinger (shadow, mirror)                    |
| `chime.wav`     | midnight strike                                    |
| `paper.wav`     | reading notes                                      |
| `key.wav`       | picking up a key                                   |
| `buzz.wav`      | phone vibrating                                    |
| `glitch.wav`    | short glitch effect                                |
| `steps.wav`     | footsteps walking past (Room 04)                   |
| `breath.wav`    | shaky breathing (hiding, hints, candles going out) |
| `static.wav`    | radio static (Room 05)                             |
| `ignite.wav`    | lighting a candle (Room 03)                        |
| `musicbox.wav`  | the lullaby, looping (Room 06)                     |
| `bell_a.wav` … `bell_d.wav` | the four servants' bells (Room 08)     |
| `plate.wav`     | setting a plate (Room 09)                          |
| `scrape.wav`    | chairs dragged back (Room 09)                      |
| `scribble.wav`  | a pen on paper (Room 10)                           |

The files for rooms 06–10 come from `tool/sounds/synth_sounds.py`
(`python3 tool/sounds/synth_sounds.py` rewrites them).

Royalty-free sources for final sounds:
- https://freesound.org (filter by **CC0** licence)
- https://pixabay.com/sound-effects/
- https://sonniss.com/gameaudiogdc (free GDC bundles)

## images/

Empty. All objects are drawn with `CustomPainter`. Final art can go here later.

## fonts/

Empty. The game uses the system serif font (Georgia on iOS, Noto Serif on
Android). A good free horror-friendly font: "IM Fell English" or "Cormorant"
(Google Fonts, OFL licence). See the commented block in `pubspec.yaml`.
