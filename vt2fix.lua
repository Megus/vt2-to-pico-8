local inp = io.open("_modules/nic29-main.vt2", "r")
local outp = io.open("_modules/nic29-main-fixed.vt2", "w")

local volmap = {
  ["."] = ".",
  ["1"] = "9",
  ["2"] = "9",
  ["3"] = "9",
  ["4"] = "A",
  ["5"] = "A",
  ["6"] = "B",
  ["7"] = "B",
  ["8"] = "C",
  ["9"] = "C",
  ["A"] = "D",
  ["B"] = "D",
  ["C"] = "E",
  ["D"] = "E",
  ["E"] = "F",
  ["F"] = "F",
}

local str
local isPattern = false
repeat
  local str = inp:read("*line")
  if str ~= nil then
    if str:len() == 1 then
      isPattern = false
    elseif isPattern == true then
      local volA = volmap[str:sub(16, 16)]
      local volB = volmap[str:sub(30, 30)]
      local volC = volmap[str:sub(44, 44)]
      local nstr = str:sub(1, 15) .. volA .. str:sub(17, 29) .. volB .. str:sub(31, 43) .. volC .. str:sub(45)
      str = nstr
    elseif string.sub(str, 1, 4) == "[Pat" then
      isPattern = true
    end
    outp:write(str.."\n")
  end
until str == nil

io.close(inp)
io.close(outp)
