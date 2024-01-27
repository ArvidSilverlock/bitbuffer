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
		buffer.writeu8(b, byte, value)
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
		buffer.writeu16(b, byte, value)
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
		writeu24(b, byte, value)
	end
end

function bitbuffer.writeu25(b: buffer, byte: number, bit: number, value: number)
	buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 25))
end

function bitbuffer.writeu26(b: buffer, byte: number, bit: number, value: number)
	if bit >= 7 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu1(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 26))
	end
end

function bitbuffer.writeu27(b: buffer, byte: number, bit: number, value: number)
	if bit >= 6 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu2(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 27))
	end
end

function bitbuffer.writeu28(b: buffer, byte: number, bit: number, value: number)
	if bit >= 5 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu3(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 28))
	end
end

function bitbuffer.writeu29(b: buffer, byte: number, bit: number, value: number)
	if bit >= 4 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu4(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 29))
	end
end

function bitbuffer.writeu30(b: buffer, byte: number, bit: number, value: number)
	if bit >= 3 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu5(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 30))
	end
end

function bitbuffer.writeu31(b: buffer, byte: number, bit: number, value: number)
	if bit >= 2 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu6(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 31))
	end
end

function bitbuffer.writeu32(b: buffer, byte: number, bit: number, value: number)
	if bit >= 1 then
		local _a = bit + 25
		bitbuffer.writeu25(b, byte, bit, value)
		bitbuffer.writeu7(b, byte + _a // 8, _a % 8, value // 0x2000000)
	else
		buffer.writeu32(b, byte, value)
	end
end

function bitbuffer.writeu33(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu8(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu34(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu9(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu35(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu10(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu36(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu11(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu37(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu12(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu38(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu13(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu39(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu14(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu40(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu15(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu41(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu16(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu42(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu17(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu43(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu18(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu44(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu19(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu45(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu20(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu46(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu21(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu47(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu22(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu48(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu23(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu49(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu24(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu50(b: buffer, byte: number, bit: number, value: number)
	local _a = bit + 25
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + _a // 8, _a % 8, value // 0x2000000)
end

function bitbuffer.writeu51(b: buffer, byte: number, bit: number, value: number)
	local _a, _b = bit + 25, bit + 50
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + _a // 8, _a % 8, value // 0x2000000)
	bitbuffer.writeu1(b, byte + _b // 8, _b % 8, value // 0x4000000000000)
end

function bitbuffer.writeu52(b: buffer, byte: number, bit: number, value: number)
	local _a, _b = bit + 25, bit + 50
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + _a // 8, _a % 8, value // 0x2000000)
	bitbuffer.writeu2(b, byte + _b // 8, _b % 8, value // 0x4000000000000)
end

function bitbuffer.writeu53(b: buffer, byte: number, bit: number, value: number)
	local _a, _b = bit + 25, bit + 50
	bitbuffer.writeu25(b, byte, bit, value)
	bitbuffer.writeu25(b, byte + _a // 8, _a % 8, value // 0x2000000)
	bitbuffer.writeu3(b, byte + _b // 8, _b % 8, value // 0x4000000000000)
end

function bitbuffer.readu1(b: buffer, byte: number, bit: number): number
	return bit32.extract(buffer.readu8(b, byte), bit, 1)
end

function bitbuffer.readu2(b: buffer, byte: number, bit: number): number
	return if bit >= 7
		then bit32.extract(buffer.readu16(b, byte), bit, 2)
		else bit32.extract(buffer.readu8(b, byte), bit, 2)
end

function bitbuffer.readu3(b: buffer, byte: number, bit: number): number
	return if bit >= 6
		then bit32.extract(buffer.readu16(b, byte), bit, 3)
		else bit32.extract(buffer.readu8(b, byte), bit, 3)
end

function bitbuffer.readu4(b: buffer, byte: number, bit: number): number
	return if bit >= 5
		then bit32.extract(buffer.readu16(b, byte), bit, 4)
		else bit32.extract(buffer.readu8(b, byte), bit, 4)
end

function bitbuffer.readu5(b: buffer, byte: number, bit: number): number
	return if bit >= 4
		then bit32.extract(buffer.readu16(b, byte), bit, 5)
		else bit32.extract(buffer.readu8(b, byte), bit, 5)
end

function bitbuffer.readu6(b: buffer, byte: number, bit: number): number
	return if bit >= 3
		then bit32.extract(buffer.readu16(b, byte), bit, 6)
		else bit32.extract(buffer.readu8(b, byte), bit, 6)
end

function bitbuffer.readu7(b: buffer, byte: number, bit: number): number
	return if bit >= 2
		then bit32.extract(buffer.readu16(b, byte), bit, 7)
		else bit32.extract(buffer.readu8(b, byte), bit, 7)
end

function bitbuffer.readu8(b: buffer, byte: number, bit: number): number
	return if bit >= 1
		then bit32.extract(buffer.readu16(b, byte), bit, 8)
		else bit32.extract(buffer.readu8(b, byte), bit, 8)
end

function bitbuffer.readu9(b: buffer, byte: number, bit: number): number
	return bit32.extract(buffer.readu16(b, byte), bit, 9)
end

function bitbuffer.readu10(b: buffer, byte: number, bit: number): number
	return if bit >= 7
		then bit32.extract(readu24(b, byte), bit, 10)
		else bit32.extract(buffer.readu16(b, byte), bit, 10)
end

function bitbuffer.readu11(b: buffer, byte: number, bit: number): number
	return if bit >= 6
		then bit32.extract(readu24(b, byte), bit, 11)
		else bit32.extract(buffer.readu16(b, byte), bit, 11)
end

function bitbuffer.readu12(b: buffer, byte: number, bit: number): number
	return if bit >= 5
		then bit32.extract(readu24(b, byte), bit, 12)
		else bit32.extract(buffer.readu16(b, byte), bit, 12)
end

function bitbuffer.readu13(b: buffer, byte: number, bit: number): number
	return if bit >= 4
		then bit32.extract(readu24(b, byte), bit, 13)
		else bit32.extract(buffer.readu16(b, byte), bit, 13)
end

function bitbuffer.readu14(b: buffer, byte: number, bit: number): number
	return if bit >= 3
		then bit32.extract(readu24(b, byte), bit, 14)
		else bit32.extract(buffer.readu16(b, byte), bit, 14)
end

function bitbuffer.readu15(b: buffer, byte: number, bit: number): number
	return if bit >= 2
		then bit32.extract(readu24(b, byte), bit, 15)
		else bit32.extract(buffer.readu16(b, byte), bit, 15)
end

function bitbuffer.readu16(b: buffer, byte: number, bit: number): number
	return if bit >= 1
		then bit32.extract(readu24(b, byte), bit, 16)
		else bit32.extract(buffer.readu16(b, byte), bit, 16)
end

function bitbuffer.readu17(b: buffer, byte: number, bit: number): number
	return bit32.extract(readu24(b, byte), bit, 17)
end

function bitbuffer.readu18(b: buffer, byte: number, bit: number): number
	return if bit >= 7
		then bit32.extract(buffer.readu32(b, byte), bit, 18)
		else bit32.extract(readu24(b, byte), bit, 18)
end

function bitbuffer.readu19(b: buffer, byte: number, bit: number): number
	return if bit >= 6
		then bit32.extract(buffer.readu32(b, byte), bit, 19)
		else bit32.extract(readu24(b, byte), bit, 19)
end

function bitbuffer.readu20(b: buffer, byte: number, bit: number): number
	return if bit >= 5
		then bit32.extract(buffer.readu32(b, byte), bit, 20)
		else bit32.extract(readu24(b, byte), bit, 20)
end

function bitbuffer.readu21(b: buffer, byte: number, bit: number): number
	return if bit >= 4
		then bit32.extract(buffer.readu32(b, byte), bit, 21)
		else bit32.extract(readu24(b, byte), bit, 21)
end

function bitbuffer.readu22(b: buffer, byte: number, bit: number): number
	return if bit >= 3
		then bit32.extract(buffer.readu32(b, byte), bit, 22)
		else bit32.extract(readu24(b, byte), bit, 22)
end

function bitbuffer.readu23(b: buffer, byte: number, bit: number): number
	return if bit >= 2
		then bit32.extract(buffer.readu32(b, byte), bit, 23)
		else bit32.extract(readu24(b, byte), bit, 23)
end

function bitbuffer.readu24(b: buffer, byte: number, bit: number): number
	return if bit >= 1
		then bit32.extract(buffer.readu32(b, byte), bit, 24)
		else bit32.extract(readu24(b, byte), bit, 24)
end

function bitbuffer.readu25(b: buffer, byte: number, bit: number): number
	return bit32.extract(buffer.readu32(b, byte), bit, 25)
end

function bitbuffer.readu26(b: buffer, byte: number, bit: number): number
	if bit >= 7 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu1(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 26)
	end
end

function bitbuffer.readu27(b: buffer, byte: number, bit: number): number
	if bit >= 6 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu2(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 27)
	end
end

function bitbuffer.readu28(b: buffer, byte: number, bit: number): number
	if bit >= 5 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu3(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 28)
	end
end

function bitbuffer.readu29(b: buffer, byte: number, bit: number): number
	if bit >= 4 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu4(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 29)
	end
end

function bitbuffer.readu30(b: buffer, byte: number, bit: number): number
	if bit >= 3 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu5(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 30)
	end
end

function bitbuffer.readu31(b: buffer, byte: number, bit: number): number
	if bit >= 2 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu6(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return bit32.extract(buffer.readu32(b, byte), bit, 31)
	end
end

function bitbuffer.readu32(b: buffer, byte: number, bit: number): number
	if bit >= 1 then
		local _a = bit + 25
		return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu7(b, byte + _a // 8, _a % 8) * 0x2000000
	else
		return buffer.readu32(b, byte)
	end
end

function bitbuffer.readu33(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu8(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu34(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu9(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu35(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu10(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu36(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu11(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu37(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu12(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu38(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu13(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu39(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu14(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu40(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu15(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu41(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu16(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu42(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu17(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu43(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu18(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu44(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu19(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu45(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu20(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu46(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu21(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu47(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu22(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu48(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu23(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu49(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu24(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu50(b: buffer, byte: number, bit: number): number
	local _a = bit + 25
	return bitbuffer.readu25(b, byte, bit) + bitbuffer.readu25(b, byte + _a // 8, _a % 8) * 0x2000000
end

function bitbuffer.readu51(b: buffer, byte: number, bit: number): number
	local _a, _b = bit + 25, bit + 50
	return bitbuffer.readu25(b, byte, bit)
		+ bitbuffer.readu25(b, byte + _a // 8, _a % 8) * 0x2000000
		+ bitbuffer.readu1(b, byte + _b // 8, _b % 8) * 0x4000000000000
end

function bitbuffer.readu52(b: buffer, byte: number, bit: number): number
	local _a, _b = bit + 25, bit + 50
	return bitbuffer.readu25(b, byte, bit)
		+ bitbuffer.readu25(b, byte + _a // 8, _a % 8) * 0x2000000
		+ bitbuffer.readu2(b, byte + _b // 8, _b % 8) * 0x4000000000000
end

function bitbuffer.readu53(b: buffer, byte: number, bit: number): number
	local _a, _b = bit + 25, bit + 50
	return bitbuffer.readu25(b, byte, bit)
		+ bitbuffer.readu25(b, byte + _a // 8, _a % 8) * 0x2000000
		+ bitbuffer.readu3(b, byte + _b // 8, _b % 8) * 0x4000000000000
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
local readFunctions = {
	bitbuffer.readu1,
	bitbuffer.readu2,
	bitbuffer.readu3,
	bitbuffer.readu4,
	bitbuffer.readu5,
	bitbuffer.readu6,
	bitbuffer.readu7,
	bitbuffer.readu8,
	bitbuffer.readu9,
	bitbuffer.readu10,
	bitbuffer.readu11,
	bitbuffer.readu12,
	bitbuffer.readu13,
	bitbuffer.readu14,
	bitbuffer.readu15,
	bitbuffer.readu16,
	bitbuffer.readu17,
	bitbuffer.readu18,
	bitbuffer.readu19,
	bitbuffer.readu20,
	bitbuffer.readu21,
	bitbuffer.readu22,
	bitbuffer.readu23,
	bitbuffer.readu24,
	bitbuffer.readu25,
	bitbuffer.readu26,
	bitbuffer.readu27,
	bitbuffer.readu28,
	bitbuffer.readu29,
	bitbuffer.readu30,
	bitbuffer.readu31,
	bitbuffer.readu32,
	bitbuffer.readu33,
	bitbuffer.readu34,
	bitbuffer.readu35,
	bitbuffer.readu36,
	bitbuffer.readu37,
	bitbuffer.readu38,
	bitbuffer.readu39,
	bitbuffer.readu40,
	bitbuffer.readu41,
	bitbuffer.readu42,
	bitbuffer.readu43,
	bitbuffer.readu44,
	bitbuffer.readu45,
	bitbuffer.readu46,
	bitbuffer.readu47,
	bitbuffer.readu48,
	bitbuffer.readu49,
	bitbuffer.readu50,
	bitbuffer.readu51,
	bitbuffer.readu52,
	bitbuffer.readu53,
}

function bitbuffer.write(b: buffer, offset: number, width: number, value: number)
	writeFunctions[width](b, offset // 8, offset % 8, value)
end

function bitbuffer.read(b: buffer, offset: number, width: number): number
	return readFunctions[width](b, offset // 8, offset % 8)
end

return bitbuffer
