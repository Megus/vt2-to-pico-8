# Vortex Tracker to PICO-8 music converter

This is a tool to convert music written with [Vortex Tracker 2](https://bitbucket.org/ivanpirog/vortextracker/downloads/) to [PICO-8 fantasy console](https://www.lexaloffle.com/pico-8.php).

Usage:

```lua vt2pico8.lua vt2file p8file [-append]```

.P8 file may exist, in this case converter will overwrite only sound and music data, but will keep the first 8 SFX (for SFX instruments). It lets you keep working on the track in VT2, but also check it regularly in PICO-8.

`-append` option allows you to append new patterns to a .P8 file without overwriting existing patterns. It is useful when you fine-tune patterns after converting and then continue working on a track in VT2.

If any known error is found during converting, the converter will stop and show the list of problems.

## Instructions

You can convert regular (for a single AY/YM chip) or Turbo Sound modules (for 2 AY/YM chips). The converter will take the first 4 channels of a Turbo Sound module and ignore the other two channels.

Use should set 120Hz frame rate in VT2 to match PICO-8 speed.

Valid notes: C-2 – C-7.

### Waves and SFX instruments

The converter allows you to use both basic PICO-8 waves and SFX instruments (when first 8 SFX are used as instruments).  It _always_ keeps the first 8 SFX in PICO-8 cartridge for instruments.

- For basic PICO-8 waves use VT2 samples 1-8, where sample 8 stands for wave 0 in PICO-8 (it's done this way because VT sample numbers start with 1).
- For SFX instruments, use VT2 samples A-H.
- PICO-8 allows you to make basic kick drum sounds with effect 3 (drop), so VT2 samples I-P are converted as kicks with different waveforms.
- You can use AY envelopes 8/C and A/E and they will be converted to waves 2 (saw) and 0 (triangle) correspondingly. The envelope period value is ignored, the converter uses only note. If you use kick samples (I-P) with envelope, they will be converted correctly.

### Ornaments

PICO-8 doesn't have ornaments, but it has the arpeggio effect (6 and 7). Arpeggios are quite limited on PICO-8: it arpeggiates 4 notes placed on SFX rows 0-3, 4-7... You have to remember it while writing music for PICO-8 in VT2!

Ornaments must be looped and have exactly 4 notes. You can duplicate ornament rows to make slower arpeggios, e.g. both 0, 4, 7, 12 and 0, 0, 4, 4, 7, 7, 12, 12 ornaments are valid. Ornaments with duplicated rows will be converted with effect 7 (slow arpeggio) instead of 6 (fast arpeggio). Invalid ornaments (not looped, with more or less notes) are ignored.

### Effects

- You can use tempo change effect (B) to set SFX speed. Always put it on the first pattern row. The channel doesn't matter.
- VT2 portamento effect (3) is converted to PICO-8 slide effect (1). Parameters are ignored, because PICO-8 doesn't have effect parameters.
- AY/YM envelopes 1/2/3 and D are converted to PICO-8 fade out (5) and fade in (4) effects.

PICO-8 vibrato effect doesn't have a VT2 counterpart, so you will have to add vibrato manually after converting.

## Contact author

In case you have any questions or find any bugs, feel free to contact me by [email](mailto:megus.sugem@gmail.com) or [Twitter](https://twitter.com/sugem).