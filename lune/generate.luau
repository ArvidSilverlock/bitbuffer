local Snippet = require("./Snippet.luau")
local fs = require("@lune/fs")

local luau = Snippet.new([[--!native
--!optimize 2
--!strict

-- stylua: ignore start
---@diagnostic disable: undefined-type

local function readu24(b: buffer, offset: number)
	return buffer.readu8(b, offset) + buffer.readu16(b, offset + 1) * 256
end

local function writeu24(b: buffer, offset: number, value: number)
	buffer.writeu8(b, offset, value)
	buffer.writeu16(b, offset + 1, value // 256)
end

--- @class bitbuffer
local bitbuffer = {}
]])

local typescript = Snippet.new([[type write<T> = (b: buffer, byte: number, bit: number, value: T) => void
type read<T> = (b: buffer, byte: number, bit: number) => T
]])

local editors = require("./editors/init.luau")
local main = require("./bitbuffer/init.luau")

main(luau, typescript)
-- editors(luau, typescript)

luau:Push("return bitbuffer")
typescript:Push("declare const bitbuffer: bitbuffer;\nexport = bitbuffer")

fs.writeFile("./src/init.luau", tostring(luau))
fs.writeFile("./src/index.d.ts", tostring(typescript))

-- require("./test.luau")
