local Snippet = require("./Snippet.luau")
local fs = require("@lune/fs")

local luau = Snippet.new()
local typescript = Snippet.new()

local editors = require("./editors/init.luau")
local main = require("./bitbuffer/init.luau")

typescript:Push([[type write<T> = (b: buffer, byte: number, bit: number, value: T) => void
type read<T> = (b: buffer, byte: number, bit: number) => T
]])

-- stylua: ignore start
luau:Push([[--!native
--!optimize 2
--!strict

-- stylua: ignore start
---@diagnostic disable: undefined-type

local function readu24(b: buffer, offset: number)
	return buffer.readu8(b, offset) + buffer.readu16(b, offset + 1) * 0x100
end

local function writeu24(b: buffer, offset: number, value: number)
	buffer.writeu8(b, offset, value)
	buffer.writeu16(b, offset + 1, value // 0x100)
end

local bit32_extract = bit32.extract
local bit32_replace = bit32.replace

--- @class bitbuffer
local bitbuffer = {}]])
	:Break()
	:LuauBlock("main", main, typescript)
	:Break()
	:LuauBlock("editors", editors, typescript)
	:Break()
	:Push("return bitbuffer")

typescript:Push(
	"declare const bitbuffer: bitbuffer;",
	"export = bitbuffer"
)
-- stylua: ignore end

fs.writeFile("./src/init.luau", tostring(luau))
fs.writeFile("./src/index.d.ts", tostring(typescript))

require("./test.luau")
