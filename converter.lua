local inspect = require("inspect")

local M = {}

-- Convert VT2 pattern to a set of PICO-8 pattern
local function convertPattern(module, pnumber)
  local src = module.patterns[pnumber]
  local converted = {
    {
      {speed = module.speed, notes = {}},
      {speed = module.speed, notes = {}},
      {speed = module.speed, notes = {}}
    },
    {
      {speed = module.speed, notes = {}},
      {speed = module.speed, notes = {}},
      {speed = module.speed, notes = {}}
    },
  }
  
  -- TODO: Check, if the whole pattern can be compressed
  local curPitch = {-1, -1, -1}
  local curInstrument = {-1, -1, -1}
  local curVolume = {7, 7, 7}
  
  for i = 1, #src do
    for c = 1, 3 do
      local srcNote = src[i][c]
      local note = {}

      -- Instrument
      if srcNote.sample ~= nil then
        local sample = srcNote.sample
        if sample == 8 then -- Convert sample 8 to a triangle wave
          sample = 0
        elseif sample >= 10 and sample <= 17 then -- SFX instruments 0-7
          sample = sample - 2
        elseif sample >= 18 and sample <= 25 then -- Drums with drop effect
          sample = sample - 18
          note.fx = 3
        elseif not (sample > 0 and sample <= 7) then -- All other samples become triangle
          sample = 0
        end

        -- For convenience we convert 8/A/C/E AY envelopes to matching PICO-8 waves
        -- We do it only for pure waves, not for SFX instruments
        local envelope = srcNote.envelope
        if envelope ~= nil then
          if sample < 8 then
            if envelope == 10 or envelope == 14 then
              sample = 0
            elseif envelope == 8 or envelope == 12 then
              sample = 2
            end
          end
          -- To use fade out/fade in effects in PICO-8 we use envelopes 1/2/3 and D
          if envelope >= 1 and envelope <= 3 then
            note.fx = 5
          elseif envelope == 13 then
            note.fx = 4
          end
        end

        curInstrument[c] = sample
      end
      
      -- Pitch
      if srcNote.pitch ~= nil then
        local pitch = srcNote.pitch
        if pitch ~= -1 then
          -- Convert pitch to PICO-8 range and limit
          pitch = pitch - 24
          if pitch < 0 then pitch = 0 end
          if pitch > 60 then pitch = 60 end

          -- For SFX instruments, we use effect 3 for retriggering envelope on the same note
          if curPitch[c] == pitch and curInstrument[c] >= 8 then
            note.fx = 3
          end
        end
        curPitch[c] = pitch
      else
        -- Shut channel if the previous note was a drum
        if i ~= 1 and src[i - 1].sample ~= nil and src[i - 1][c].sample >= 18 and src[i - 1][c].sample <= 25 then
          curPitch[c] = -1
        end
      end
      
      -- Volume
      if srcNote.volume ~= nil then
        curVolume[c] = math.floor(srcNote.volume / 2)
        if curVolume[c] == 0 then curVolume[c] = 1 end
      end

      -- FX
      if srcNote.fx ~= nil then
        local fx = math.floor(srcNote.fx / 4096)

        if fx == 3 then
          -- Portamento
          note.fx = 1
        elseif fx == 6 then
          -- "Tremolo", used to "imitate" fade out/fade it

        elseif fx == 11 then
          -- Pattern speed

        end
      end
      
      -- Fill note data
      if curPitch[c] ~= -1 then
        note.pitch = curPitch[c]
        note.instrument = curInstrument[c]
        note.volume = curVolume[c]
      end
      
      -- Here's how we break 64-note patterns into halves
      if i < 33 then
        table.insert(converted[1][c].notes, note)
      else
        table.insert(converted[2][c].notes, note)
      end
    end
  end
  
  return converted
end

-- Add pattern to a pattern set (with checking for duplicates)
local function addPattern(pattern, existingPatterns)
  -- Check if it's an empty pattern
  local hasNoNotes = true
  for i = 1, #pattern.notes do
    if pattern.notes[i].pitch ~= nil then
      hasNoNotes = false
      break
    end
  end

  if hasNoNotes then return -1 end

  -- Check for duplicates
  for i = 1, #existingPatterns do
    local foundMatch = true
    if existingPatterns[i].speed ~= pattern.speed then break end
    for j = 1, #(pattern.notes) do
      local note1, note2
      note1 = pattern.notes[j]
      note2 = existingPatterns[i].notes[j]

      if note1.pitch ~= note2.pitch or note1.instrument ~= note2.instrument or note1.volume ~= note2.volume or note1.fx ~= note2.fx then
        foundMatch = false
        break
      end
    end

    if foundMatch then
      return i
    end
  end

  table.insert(existingPatterns, pattern)
  return #existingPatterns
end


--
-- Public API
--

function M.convert(modules, existing)
  local patterns = {}
  local playOrder = {}
  local has4Channels = (#modules == 2)
  
  for i = 1, #(modules[1].playOrder) do
    -- Iterate through playing order of a track
    local converted1 = convertPattern(modules[1], modules[1].playOrder[i])
    local converted2 = nil
    if has4Channels then
      converted2 = convertPattern(modules[2], modules[2].playOrder[i])
    end
    
    for j = 1, #converted1 do
      local order = {}
      local ptns = converted1[j]
      table.insert(order, addPattern(ptns[1], patterns))
      table.insert(order, addPattern(ptns[2], patterns))
      table.insert(order, addPattern(ptns[3], patterns))
      if has4Channels and j <= #converted2 then
        table.insert(order, addPattern(converted2[j][1], patterns))
      else
        table.insert(order, -1)
      end
      table.insert(playOrder, order)
    end
  end
  
  return patterns, playOrder
end

return M
