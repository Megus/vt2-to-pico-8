local inspect = require("inspect")

local inspect = require("inspect")
local parser = require("parser")
local converter = require("converter")
local writer = require("writer")

local modules = parser.load("demo.vt2")
--local modules = parser.load("MyBestTrack1.vt2")
local patterns, order = converter.convert(modules)

--print(inspect(modules))

print(writer.writeP8(nil, patterns, order))
