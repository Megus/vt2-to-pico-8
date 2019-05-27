# vt2-to-pico-8

Vortex Tracker to PICO-8 music converter

Usage:

```lua vt2pico8.lua vt2file p8file```

.P8 file may exist, in this case converter will overwrite only sound and music data, but will keep the first 8 patterns (which can be used for custom instruments). It lets you keep working on the track and check it regularly in PICO-8.

## Instructions

Use 128Hz frame rate to match PICO-8 speed.

You can use normal or Turbo Sound modules. The converter will take first 4 channels of a Turbo Sound module.

Valid notes: C-2 – C-7.

You can use tempo change effect (B), but only on the first pattern row. The channel doesn't matter.

You can use portamento effect (3), but the parameters will be ignored, because PICO-8 doesn't have effect parameters.

Для эффектов fade out/fade in PICO-8 используйте огибающие 1/2/3 и D соответственно

Для чистых волн PICO-8 в VT2 используются сэмплы 1-8, где 1-7 — соответствие по номерам в PICO-8, а 8 — это нулевая волна (треугольник). Так сделано для тех, кто уже запомнил номера всех волн PICO-8.

Можно использовать огибающие 8/A/C/E, они будут сконвертированы в чистые волны PICO-8. Если при этом используется сэмпл для бочек — они тоже будут корректно сконвертированы в бочку PICO-8 на чистой волне.

Для кастомных инструментов: инструменты A, B, C, D, E, F, G, H

Для бочки на чистых волнах PICO-8: инструменты I, J, K, L, M, N, O, P

Можно использовать орнаменты, но в них должно быть строго 4 ноты. Ноты можно повторять, т.е. и 0, 4, 7, 12, и 0, 0, 4, 4, 7, 7, 12, 12 — подходящие орнаменты. «Медленные» орнаменты будут сконвертированы с эффектом 7, быстрое — с эффектом 6.
