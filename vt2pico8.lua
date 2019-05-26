local inspect = require("inspect")

local inspect = require("inspect")
local parser = require("parser")
local converter = require("converter")
local writer = require("writer")

local vt2name = arg[1]
local p8name = arg[2]

if vt2name == nil or p8name == nil then
  print("Usage: lua vt2pico8.lua vt2file p8file")
  return
end

local modules = parser.load(vt2name)
-- TODO: Check, if it was really loaded

local patterns, order = converter.convert(modules)

-- Try to read existing P8 file
local oldP8 = parser.readFile(p8name)

local newP8 = writer.writeP8(oldP8, patterns, order)

local file = io.open(p8name, "w")
file:write(newP8)
io.close(file)
--print(newP8)