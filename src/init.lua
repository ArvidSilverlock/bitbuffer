--!native
--!optimize 2
--!strict

local bitbuffer = {}

local U24_BUFFER = buffer.create(4)

local function readu24(b: buffer, offset: number)
	buffer.copy(U24_BUFFER, 0, b, offset, 3)
	return buffer.readu32(U24_BUFFER, 0)
end

local function writeu24(b: buffer, offset: number, value: number)
	buffer.writeu32(U24_BUFFER, 0, value)
	buffer.copy(b, offset, U24_BUFFER, 0, 3)
end

function bitbuffer.writeu1(b: buffer, byte: number, bit: number, value: number)
	buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 1))
end

function bitbuffer.writeu2(b: buffer, byte: number, bit: number, value: number)
	if bit >= 7 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 2))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 2))
	end
end

function bitbuffer.writeu3(b: buffer, byte: number, bit: number, value: number)
	if bit >= 6 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 3))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 3))
	end
end

function bitbuffer.writeu4(b: buffer, byte: number, bit: number, value: number)
	if bit >= 5 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 4))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 4))
	end
end

function bitbuffer.writeu5(b: buffer, byte: number, bit: number, value: number)
	if bit >= 4 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 5))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 5))
	end
end

function bitbuffer.writeu6(b: buffer, byte: number, bit: number, value: number)
	if bit >= 3 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 6))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 6))
	end
end

function bitbuffer.writeu7(b: buffer, byte: number, bit: number, value: number)
	if bit >= 2 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 7))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 7))
	end
end

function bitbuffer.writeu8(b: buffer, byte: number, bit: number, value: number)
	if bit >= 1 then
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 8))
	else
		buffer.writeu8(b, byte, bit32.replace(buffer.readu8(b, byte), value, bit, 8))
	end
end

function bitbuffer.writeu9(b: buffer, byte: number, bit: number, value: number)
	buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 9))
end

function bitbuffer.writeu10(b: buffer, byte: number, bit: number, value: number)
	if bit >= 7 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 10))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 10))
	end
end

function bitbuffer.writeu11(b: buffer, byte: number, bit: number, value: number)
	if bit >= 6 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 11))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 11))
	end
end

function bitbuffer.writeu12(b: buffer, byte: number, bit: number, value: number)
	if bit >= 5 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 12))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 12))
	end
end

function bitbuffer.writeu13(b: buffer, byte: number, bit: number, value: number)
	if bit >= 4 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 13))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 13))
	end
end

function bitbuffer.writeu14(b: buffer, byte: number, bit: number, value: number)
	if bit >= 3 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 14))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 14))
	end
end

function bitbuffer.writeu15(b: buffer, byte: number, bit: number, value: number)
	if bit >= 2 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 15))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 15))
	end
end

function bitbuffer.writeu16(b: buffer, byte: number, bit: number, value: number)
	if bit >= 1 then
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 16))
	else
		buffer.writeu16(b, byte, bit32.replace(buffer.readu16(b, byte), value, bit, 16))
	end
end

function bitbuffer.writeu17(b: buffer, byte: number, bit: number, value: number)
	writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 17))
end

function bitbuffer.writeu18(b: buffer, byte: number, bit: number, value: number)
	if bit >= 7 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 18))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 18))
	end
end

function bitbuffer.writeu19(b: buffer, byte: number, bit: number, value: number)
	if bit >= 6 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 19))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 19))
	end
end

function bitbuffer.writeu20(b: buffer, byte: number, bit: number, value: number)
	if bit >= 5 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 20))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 20))
	end
end

function bitbuffer.writeu21(b: buffer, byte: number, bit: number, value: number)
	if bit >= 4 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 21))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 21))
	end
end

function bitbuffer.writeu22(b: buffer, byte: number, bit: number, value: number)
	if bit >= 3 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 22))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 22))
	end
end

function bitbuffer.writeu23(b: buffer, byte: number, bit: number, value: number)
	if bit >= 2 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 23))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 23))
	end
end

function bitbuffer.writeu24(b: buffer, byte: number, bit: number, value: number)
	if bit >= 1 then
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 24))
	else
		writeu24(b, byte, bit32.replace(readu24(b, byte), value, bit, 24))
	end
end

function bitbuffer.writeu25(b: buffer, byte: number, bit: number, value: number)
	buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 25))
end

function bitbuffer.writeu26(b: buffer, byte: number, bit: number, value: number)
	if bit >= 7 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu1(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 26))
	end
end

function bitbuffer.writeu27(b: buffer, byte: number, bit: number, value: number)
	if bit >= 6 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu2(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 27))
	end
end

function bitbuffer.writeu28(b: buffer, byte: number, bit: number, value: number)
	if bit >= 5 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu3(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 28))
	end
end

function bitbuffer.writeu29(b: buffer, byte: number, bit: number, value: number)
	if bit >= 4 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu4(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 29))
	end
end

function bitbuffer.writeu30(b: buffer, byte: number, bit: number, value: number)
	if bit >= 3 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu5(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 30))
	end
end

function bitbuffer.writeu31(b: buffer, byte: number, bit: number, value: number)
	if bit >= 2 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu6(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 31))
	end
end

function bitbuffer.writeu32(b: buffer, byte: number, bit: number, value: number)
	if bit >= 1 then
		bitbuffer.writeu24(b, byte, bit, value)
		bitbuffer.writeu7(b, byte + 3, bit, value // 576)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 32))
	end
end

function bitbuffer.writeu33(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu8(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu34(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu9(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu35(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu10(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu36(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu11(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu37(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu12(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu38(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu13(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu39(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu14(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu40(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu15(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu41(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu16(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu42(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu17(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu43(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu18(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu44(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu19(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu45(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu20(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu46(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu21(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu47(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu22(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu48(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu23(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu49(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)

	local newBit = bit + 25
	bitbuffer.writeu24(b, byte + (newBit // 8), newBit % 8, value // 33554432)
end

function bitbuffer.writeu50(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + 3, bit, value // 33554432)
end

function bitbuffer.writeu51(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + 3, bit, value // 33554432)

	local newBit = bit + 50
	bitbuffer.writeu1(b, byte + (newBit // 8), newBit % 8, value // 1125899906842624)
end

function bitbuffer.writeu52(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + 3, bit, value // 33554432)

	local newBit = bit + 50
	bitbuffer.writeu2(b, byte + (newBit // 8), newBit % 8, value // 1125899906842624)
end

function bitbuffer.writeu53(b: buffer, byte: number, bit: number, value: number)
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + 3, bit, value // 33554432)

	local newBit = bit + 50
	bitbuffer.writeu3(b, byte + (newBit // 8), newBit % 8, value // 1125899906842624)
end

local writeFunctions = {
	bitbuffer.writeu1,
	bitbuffer.writeu2,
	bitbuffer.writeu3,
	bitbuffer.writeu4,
	bitbuffer.writeu5,
	bitbuffer.writeu6,
	bitbuffer.writeu7,
	bitbuffer.writeu8,
	bitbuffer.writeu9,
	bitbuffer.writeu10,
	bitbuffer.writeu11,
	bitbuffer.writeu12,
	bitbuffer.writeu13,
	bitbuffer.writeu14,
	bitbuffer.writeu15,
	bitbuffer.writeu16,
	bitbuffer.writeu17,
	bitbuffer.writeu18,
	bitbuffer.writeu19,
	bitbuffer.writeu20,
	bitbuffer.writeu21,
	bitbuffer.writeu22,
	bitbuffer.writeu23,
	bitbuffer.writeu24,
	bitbuffer.writeu25,
	bitbuffer.writeu26,
	bitbuffer.writeu27,
	bitbuffer.writeu28,
	bitbuffer.writeu29,
	bitbuffer.writeu30,
	bitbuffer.writeu31,
	bitbuffer.writeu32,
	bitbuffer.writeu33,
	bitbuffer.writeu34,
	bitbuffer.writeu35,
	bitbuffer.writeu36,
	bitbuffer.writeu37,
	bitbuffer.writeu38,
	bitbuffer.writeu39,
	bitbuffer.writeu40,
	bitbuffer.writeu41,
	bitbuffer.writeu42,
	bitbuffer.writeu43,
	bitbuffer.writeu44,
	bitbuffer.writeu45,
	bitbuffer.writeu46,
	bitbuffer.writeu47,
	bitbuffer.writeu48,
	bitbuffer.writeu49,
	bitbuffer.writeu50,
	bitbuffer.writeu51,
	bitbuffer.writeu52,
	bitbuffer.writeu53,
}

function bitbuffer.write(b: buffer, offset: number, width: number, value: number)
	writeFunctions[width](b, offset // 8, offset % 8, value)
end

return bitbuffer
