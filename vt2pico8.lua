local inspect = require("inspect")
local parser = require("parser")
local converter = require("converter")
local logger = require("logger")
local writer = require("writer")

local vt2name = arg[1]
local p8name = arg[2]

print("\nVortex Tracker 2 to PICO-8 music converter v1.0 by Roman \"Megus\" Petrov\n")

if vt2name == nil or p8name == nil then
  print("Usage: lua vt2pico8.lua vt2file p8file")
  return
end

local modules = parser.load(vt2name)
-- TODO: Check, if it was really loaded
print("Converting " .. vt2name .. "...")

local patterns, order = converter.convert(modules)
local errorLog = logger.errorLog()
local warningLog = logger.warningLog()

if warningLog ~= "" then
  print("\nWarnings:\n\n" .. warningLog .. "\nThese warnings are just for your information, you don't have to change anything in the module\n")
end

if errorLog ~= "" then
  print("\nFatal errors:\n\n" .. errorLog .. "\nFix these errors and try to convert again, P8 file is not saved\n")
end

-- Try to read existing P8 file
if errorLog == "" then
  local successString = "Saved " .. p8name
  local oldP8 = parser.readFile(p8name)
  if oldP8 ~= nil then
    successString = "Updated " .. p8name
  end
  local newP8 = writer.writeP8(oldP8, patterns, order)
  local file = io.open(p8name, "w")
  file:write(newP8)
  io.close(file)
  --print(newP8)
  print(successString .. "\n")
end
