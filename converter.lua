local inspect = require("inspect")
local L = require("logger")

local M = {}


-- Convert VT2 pattern to a set of PICO-8 pattern
local function convertPattern(modules, moduleNumber, pnumber)
  local module = modules[moduleNumber]
  local src = module.patterns[pnumber]

  if #src ~= 32 and #src ~= 64 then
    L.error(L.E.wrongPatternLength, {module = moduleNumber, pattern = pnumber - 1})
    return nil
  end

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
  local curInstrument = {0, 0, 0}
  local curOrnament = {0, 0, 0}
  local curOrnamentPitch = {0, 0, 0}
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

          -- Check for ornament conflicts
          if math.fmod(i - 1, 4) ~= 0 and curOrnament[c] ~= 0 then
              error("Can't add note because of a conflict with ornament")
          end

          -- For SFX instruments, we use effect 3 for retriggering envelope on the same note
          if curPitch[c] == pitch and curInstrument[c] >= 8 then
            note.fx = 3
          end
        elseif math.fmod(i - 1, 4) == 0 then
          -- Stop ornament if R-- was put on arpeggio "border"
          curOrnament[c] = 0
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

        elseif fx == 11 and i == 1 then
          -- Pattern speed
          local speed = math.fmod(srcNote.fx, 256)
          converted[1][1].speed = speed
          converted[1][2].speed = speed
          converted[1][3].speed = speed
          converted[2][1].speed = speed
          converted[2][2].speed = speed
          converted[2][3].speed = speed
        end
      end

      -- Ornament
      if srcNote.ornament ~= nil and curPitch[c] ~= -1 then
        local ornament = srcNote.ornament
        if ornament == 0 or module.ornaments[ornament].ignore then
          curOrnament[c] = 0
        else
          curOrnament[c] = ornament
          if math.fmod(i - 1, 4) ~= 0 then
            local orn = module.ornaments[ornament]
            local notes = (i < 33) and converted[1][c].notes or converted[2][c].notes
            local ti = (i < 33) and (i - 1) or (i - 33)
            while math.fmod(ti - 1, 4) ~= 3 do
              if notes[ti].pitch == -1 or notes[ti].pitch == nil then
                notes[ti] = {
                  volume = 0,
                  instrument = curInstrument[c],
                  pitch = curPitch[c] + orn.distinct[math.fmod(ti - 1, 4) + 1]
                }
              else
                -- TODO: Detailed error
                error("Can't fit ornament " .. "ti: " .. ti .. ", " .. notes[ti].pitch)
              end

              ti = ti - 1
            end
          end
        end
        curOrnamentPitch[c] = curPitch[c]
      end
      
      -- Fill note data
      if curPitch[c] ~= -1 then
        if curOrnament[c] ~= 0 then
          local idx = math.fmod(i - 1, 4) + 1
          local ornament = module.ornaments[curOrnament[c]]
          note.pitch = curOrnamentPitch[c] + ornament.distinct[idx]
          note.fx = (ornament.speed > 1) and 7 or 6
        else
          note.pitch = curPitch[c]
        end
        note.instrument = curInstrument[c]
        note.volume = curVolume[c]
      elseif curOrnament[c] ~= 0 then
        -- Fill ornament till the end
        local idx = math.fmod(i - 1, 4) + 1
        local ornament = module.ornaments[curOrnament[c]]
        note.pitch = curOrnamentPitch[c] + ornament.distinct[idx]
        note.volume = 0
        note.instrument = curInstrument[c]
        note.fx = (ornament.speed > 1) and 7 or 6
        if idx == 4 then
          curOrnament[c] = 0
        end
    end
      
      -- Here's how we break 64-note patterns into halves
      if i < 33 then
        table.insert(converted[1][c].notes, note)
      else
        table.insert(converted[2][c].notes, note)
      end
    end
  end

  if #(converted[2][1].notes) == 0 then
    table.remove(converted, 2)
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


local function preprocessOrnaments(modules, moduleNumber)
  local module = modules[moduleNumber]
  for i = 1, #(module.ornaments) do
    local ornament = module.ornaments[i]
    if #(ornament.values) < 4 or ornament.loop ~= 1 then
      ornament.ignore = true
      if not (#ornament.values == 1 and ornament.values[1] == 0) then
        L.warning(L.W.ignoredOrnament, {module = moduleNumber, ornament = i})
      end
    else
      local distinct = {}
      table.insert(distinct, ornament.values[1])
      for c = 1, #(ornament.values) do
        if ornament.values[c] ~= distinct[#distinct] then
          table.insert(distinct, ornament.values[c])
        end
      end
      if #distinct == 4 then
        ornament.distinct = distinct
        ornament.speed = math.floor(#(ornament.values) / #distinct)
        ornament.ignore = false
      else
        ornament.ignore = true
        L.warning(L.W.ignoredOrnament, {module = moduleNumber, ornament = i})
      end
    end
  end
end


--
-- Public API
--

function M.convert(modules, existing)
  local patterns = {}
  local playOrder = {}
  local has4Channels = (#modules == 2)

  -- Preprocess ornaments
  for i = 1, #modules do
    preprocessOrnaments(modules, i)
  end

  for i = 1, #(modules[1].playOrder) do
    -- Iterate through playing order of a track
    local converted1 = convertPattern(modules, 1, modules[1].playOrder[i])
    local converted2 = nil
    if has4Channels then
      converted2 = convertPattern(modules, 2, modules[2].playOrder[i])
    end
    
    if converted1 ~= nil then
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
  end
  
  return patterns, playOrder
end

return M
