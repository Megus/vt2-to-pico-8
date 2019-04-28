local inspect = require("inspect")

local M = {}

--
-- Utility functions
--

-- Trim string (used to cut CR/LF symbols from the string)
local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Convert a character to a number
local function charToNum(char)
  if char == "." then return 0 end
  local num = string.byte(char) - 48
  if num > 9 then
    num = num - 7
  end
  return num
end



--
-- Parser functions
--

-- Read file
local function readVT2(filename)
  -- TODO: Handle errors
  local vtFile = io.open(filename, "r")
  local vtLines = {}
  local str
  repeat
    local str = vtFile:read("*line")
    if str ~= nil then
      table.insert(vtLines, str)
    end
  until str == nil
  
  io.close(vtFile)
  return vtLines
end

-- Parse the list of integers with a loop mark
local function parseLoopedIntList(str)
  local list = {}
  local loop = 1
  local pos = 1
  str = trim(str) .. ","
  for v in string.gmatch(str, "(%w+),") do
    if string.sub(v, 1, 1) == "L" then
      v = string.sub(v, 2)
      loop = pos
    end
    table.insert(list, tonumber(v))
    pos = pos + 1
  end
  return list, loop
end

-- Parse module meta data (name, speed, etc)
local function parseModuleMeta(vtm, module, idx)
  local str

  repeat
    idx = idx + 1
    str = trim(vtm[idx])
    
    if string.len(str) ~= 0 then
      local match = string.gmatch(str, "(%w+)=(.*)")
      local k, v = match()
      if k == "IntFreq" then
        module.intFreq = tonumber(v)
      elseif k == "Speed" then
        module.speed = tonumber(v)
      elseif k == "PlayOrder" then
        module.playOrder, module.playLoop = parseLoopedIntList(v)
        for i = 1, #module.playOrder do
          module.playOrder[i] = module.playOrder[i] + 1
        end
      else
        module.meta[k] = v
      end
    end
  until string.len(str) == 0
  
  return idx
end

-- Parse ornament
local function parseOrnament(vtm, module, idx)
  local number = tonumber(string.match(vtm[idx], "(%d+)"))
  idx = idx + 1
  local ornament, loop = parseLoopedIntList(vtm[idx])
  module.ornaments[number] = {
    loop = loop,
    values = ornament,
  }
  return idx
end

-- Parse a single note from a pattern
local function parseNote(str, channel, curSample, curOrnament, curVolume)
  local note = {}
  local pitches = {C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11}

  -- Pitch
  local pitchStr = string.sub(str, 1, 1)
  if pitchStr ~= "-" then
    if pitchStr == "R" then
      note.pitch = -1
    else
      local pitch = pitches[pitchStr]
      if string.sub(str, 2, 2) == "#" then
        pitch = pitch + 1
      end

      local octave = tonumber(string.sub(str, 3, 3))
      if octave == nil then
        print(str)
      end
      pitch = pitch + octave * 12
  
      note.pitch = pitch  
    end
  end

  -- Sample
  local sample = charToNum(string.sub(str, 5, 5))
  if sample ~= 0 then
    curSample[channel] = sample
    note.sample = sample
  end

  -- Envelope
  local envelope = charToNum(string.sub(str, 6, 6))
  if envelope ~= 0 and envelope ~= 15 then
    note.envelope = envelope
  end

  -- Ornament
  local ornament = charToNum(string.sub(str, 7, 7))
  if ornament == 0 then
    if string.sub(str, 6, 6) ~= "." then
      curOrnament[channel] = 0
      note.ornament = 0
    end
  else
    curOrnament[channel] = charToNum(string.sub(str, 7, 7))
    note.ornament = curOrnament[channel]
  end

  -- Volume
  local volume = charToNum(string.sub(str, 8, 8))
  if volume > 0 then
    curVolume[channel] = volume
    note.volume = volume
  end

  -- FX
  local fx = charToNum(string.sub(str, 10, 10)) * 0x1000 +
  charToNum(string.sub(str, 11, 11)) * 0x100 +
  charToNum(string.sub(str, 12, 12)) * 0x10 +
  charToNum(string.sub(str, 13, 13))
  if fx ~= 0 then
    note.fx = fx
  end

  if note.pitch ~= nil then
    note.sample = curSample[channel]
    note.ornament = curOrnament[channel]
    note.volume = curVolume[channel]
  end

  return note
end

-- Parse a pattern
local function parsePattern(vtm, module, idx)
  local number = tonumber(string.match(vtm[idx], "(%d+)")) + 1
  local str
  local pattern = {}

  local curSample = {1, 1, 1}
  local curOrnament = {0, 0, 0}
  local curVolume = {15, 15, 15}
  local noiseOffset = 0

  repeat
    idx = idx + 1
    str = trim(vtm[idx])
    local row = {}

    if string.len(str) ~= 0 then
      table.insert(row, parseNote(string.sub(str, 9, 21), 1, curSample, curOrnament, curVolume))
      table.insert(row, parseNote(string.sub(str, 23, 35), 2, curSample, curOrnament, curVolume))
      table.insert(row, parseNote(string.sub(str, 37), 3, curSample, curOrnament, curVolume))
      
      noiseOffset = charToNum(string.sub(str, 6, 6)) * 0x10 + charToNum(string.sub(str, 7, 7))
      table.insert(row, noiseOffset)

      table.insert(pattern, row)
    end
  until string.len(str) == 0

  module.patterns[number] = pattern
  
  return idx
end

-- Parse VT2 module as a list of string
local function parseVT2(vtm)
  local modules = {}
  local idx = 1
  local module = nil
  
  while idx <= #vtm do
    local str = trim(vtm[idx])
    
    if string.len ~= 0 then
      if str == "[Module]" then
        if module ~= nil then
          table.insert(modules, module)
        end
        module = {
          meta = {},
          speed = 0,
          intFreq = 0,
          playOrder = {},
          playLoop = 0,
          samples = {},
          ornaments = {},
          patterns = {}
        }
        idx = parseModuleMeta(vtm, module, idx)
      elseif string.sub(str, 1, 4) == "[Sam" then
        -- We ignore samples
      elseif string.sub(str, 1, 4) == "[Orn" then
        idx = parseOrnament(vtm, module, idx)
      elseif string.sub(str, 1, 4) == "[Pat" then
        idx = parsePattern(vtm, module, idx)
      end
    end
    
    idx = idx + 1
  end
  
  if module ~= nil then
    table.insert(modules, module)
  end
  
  return modules
end



--
-- Public API
--

-- Load VT2 module from a file
function M.load(filename)
  local vtm = readVT2(filename)
  return parseVT2(vtm)
end

return M
