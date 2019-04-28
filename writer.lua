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

function M.writeP8(oldP8, patterns, playOrder)
    return debugWriter(patterns, playOrder)
end

return M