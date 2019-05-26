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

local function p8Writer(oldP8, patterns, playOrder)
  local p8

  if oldP8 ~= nil then
    p8 = ""
    local stopIdx = 0
    for i, v in ipairs(oldP8) do
      p8 = p8 .. v .. "\n"
      if i == stopIdx then break end
      if v == "__sfx__" then
        stopIdx = i + 8
      end
    end

  else
    p8 = "pico-8 cartridge // http://www.pico-8.com\nversion 16\n__sfx__\n"
    
    local emptySfx = "010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    
    -- Add empty sfx for custom instruments
    for i = 1, 8 do
      p8 = p8 .. emptySfx .. "\n"
    end
  end
  
  for i = 1, #patterns do
    local pattern = patterns[i]
    local sfx = "01"
    sfx = sfx .. byte2hex(pattern.speed * 3) .. "0000"
    --sfx = sfx .. byte2hex(pattern.speed) .. "0000"
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
    
    sfx = sfx .. "\n"
    p8 = p8 .. sfx
  end

  p8 = p8 .. "\n__music__\n"
  for i = 1, #playOrder do
    p8 = p8 .. "00 "
    for j = 1, 4 do
      local order = playOrder[i][j]
      if order == -1 then
        order = 64
      else
        order = order + 7
      end
      p8 = p8 .. byte2hex(order)
    end
    p8 = p8 .. "\n"
  end
  
  return p8
end

function M.writeP8(oldP8, patterns, playOrder)
  --return debugWriter(patterns, playOrder)
  return p8Writer(oldP8, patterns, playOrder)
end

return M