local inspect = require("inspect")

local M = {}

local function debugOrder(patterns, order)
  local res = ""
  local pitches = {
    "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"
  }

  for i = 1, 32 do
    if i < 11 then
      res = res .. "0" .. (i - 1) .. " "
    else
      res = res .. (i - 1) .. " "
    end

    for c = 1, #order do

      if order[c] == -1 then
        res = res .. "___ ___   "
      else
        local note = patterns[order[c]].notes[i]
        if note.pitch ~= nil then
          local octave = math.floor(note.pitch / 12)
          local pitch = note.pitch - octave * 12 + 1
          res = res .. pitches[pitch] .. octave .. " " .. note.instrument .. note.volume
          if note.fx ~= nil then
            res = res .. note.fx
          else
            res = res .. "."
          end

          res = res .. "   "
        else
          res = res .. "... ...   "
        end
      end
    end
    res = res .. "\n"
  end

  return res
end

local function debugWriter(patterns, playOrder)
  local res = ""
  for i = 1, #playOrder do
    res = res .. debugOrder(patterns, playOrder[i]) .. "\n\n"
  end

  res = res .. inspect(playOrder)
  return res
end

local function byte2hex(byte)
  return string.format("%02x", byte)
end

local function nibble2hex(nibble)
  return string.format("%1x", nibble)
end

local function p8Writer(oldP8, patterns, playOrder, append)
  local tP8 = {}
  local tMusic = {}
  local tSfx = {}

  if oldP8 ~= nil then
    -- Read old P8 file
    local target = tP8

    for i, v in ipairs(oldP8) do
      if v == "__sfx__" then
        target = tSfx
      elseif v == "__music__" then
        target = tMusic
      elseif target == tP8 or string.len(v) ~= 0 then
        table.insert(target, v)
      end
    end

    if not append then
      -- Clean orders and patterns if we don't append
      tMusic = {}
      while #tSfx > 8 do
        table.remove(tSfx)
      end
    end
  else
    -- Create new P8 file
    table.insert(tP8, "pico-8 cartridge // http://www.pico-8.com")
    table.insert(tP8, "version 18")

    local emptySfx = "010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

    -- Add empty sfx for custom instruments
    for i = 1, 8 do
      table.insert(tSfx, emptySfx)
    end
  end

  local sfxOffset = #tSfx

  for i = 1, #patterns do
    local pattern = patterns[i]
    local sfx = "01"
    sfx = sfx .. byte2hex(pattern.speed) .. "0000"
    for c = 1, 32 do
      local note = pattern.notes[c]

      local pitch = note.pitch
      local volume = note.volume
      local fx = note.fx
      local instrument = note.instrument

      if pitch == nil then
        pitch = 0
        volume = 0
        instrument = 0
      end

      if fx == nil then fx = 0 end

      sfx = sfx .. byte2hex(pitch) .. nibble2hex(instrument) .. nibble2hex(volume) .. nibble2hex(fx)
    end

    table.insert(tSfx, sfx)
  end

  for i = 1, #playOrder do
    local music = "00 "
    for j = 1, 4 do
      local order = playOrder[i][j]
      if order == -1 then
        order = 64
      else
        order = order + sfxOffset - 1
      end
      music = music .. byte2hex(order)
    end
    table.insert(tMusic, music)
  end

  local p8 = ""
  for _, v in ipairs(tP8) do p8 = p8 .. v .. "\n" end
  p8 = p8 .. "__sfx__\n"
  for _, v in ipairs(tSfx) do p8 = p8 .. v .. "\n" end
  p8 = p8 .. "__music__\n"
  for _, v in ipairs(tMusic) do p8 = p8 .. v .. "\n" end

  return p8
end

function M.writeP8(oldP8, patterns, playOrder, append)
  --return debugWriter(patterns, playOrder)
  return p8Writer(oldP8, patterns, playOrder, append)
end

return M