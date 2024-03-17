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

local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32

local writei8 = buffer.writei8
local writei16 = buffer.writei16
local writei32 = buffer.writei32

local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32

local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32

local writef32 = buffer.writef32
local writef64 = buffer.writef64

local buffer_create, buffer_fromstring, buffer_copy, buffer_fill, buffer_len, buffer_readstring, buffer_writestring, buffer_tostring, buffer_readf32, buffer_readf64 =
	buffer.create, buffer.fromstring, buffer.copy, buffer.fill, buffer.len, buffer.readstring, buffer.writestring, buffer.tostring, buffer.readf32, buffer.readf64

local function readu24(b: buffer, offset: number)
	return readu8(b, offset) + readu16(b, offset + 1) * 0x100
end

local function writeu24(b: buffer, offset: number, value: number)
	writeu8(b, offset, value)
	writeu16(b, offset + 1, value // 0x100)
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
