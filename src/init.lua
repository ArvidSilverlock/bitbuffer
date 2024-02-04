--!native
--!optimize 2
--!strict

-- stylua: ignore start
---@diagnostic disable: undefined-type

local bitbuffer = {}

do -- uint
	local readu8 = buffer.readu8
	local readu16 = buffer.readu16
	local readu32 = buffer.readu32

	local writeu8 = buffer.writeu8
	local writeu16 = buffer.writeu16
	local writeu32 = buffer.writeu32

	local function readu24(b: buffer, offset: number)
		return readu8(b, offset) + readu16(b, offset + 1) * 256
	end

	local function writeu24(b: buffer, offset: number, value: number)
		writeu8(b, offset, value)
		writeu16(b, offset + 1, value // 256)
	end

	local bit32_replace = bit32.replace
	local bit32_extract = bit32.extract

	do -- write
		function bitbuffer.writeu1(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 1))
		end

		function bitbuffer.writeu2(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 6 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 2))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 2))
			end
		end

		function bitbuffer.writeu3(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 5 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 3))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 3))
			end
		end

		function bitbuffer.writeu4(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 4 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 4))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 4))
			end
		end

		function bitbuffer.writeu5(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 3 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 5))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 5))
			end
		end

		function bitbuffer.writeu6(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 2 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 6))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 6))
			end
		end

		function bitbuffer.writeu7(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 1 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 7))
			else
				writeu8(b, byte, bit32_replace(readu8(b, byte), value, bit, 7))
			end
		end

		function bitbuffer.writeu8(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 8))
			else
				writeu8(b, byte, value)
			end
		end

		function bitbuffer.writeu9(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 9))
		end

		function bitbuffer.writeu10(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 6 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 10))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 10))
			end
		end

		function bitbuffer.writeu11(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 5 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 11))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 11))
			end
		end

		function bitbuffer.writeu12(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 4 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 12))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 12))
			end
		end

		function bitbuffer.writeu13(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 3 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 13))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 13))
			end
		end

		function bitbuffer.writeu14(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 2 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 14))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 14))
			end
		end

		function bitbuffer.writeu15(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 1 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 15))
			else
				writeu16(b, byte, bit32_replace(readu16(b, byte), value, bit, 15))
			end
		end

		function bitbuffer.writeu16(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 16))
			else
				writeu16(b, byte, value)
			end
		end

		function bitbuffer.writeu17(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 17))
		end

		function bitbuffer.writeu18(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 6 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 18))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 18))
			end
		end

		function bitbuffer.writeu19(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 5 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 19))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 19))
			end
		end

		function bitbuffer.writeu20(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 4 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 20))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 20))
			end
		end

		function bitbuffer.writeu21(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 3 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 21))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 21))
			end
		end

		function bitbuffer.writeu22(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 2 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 22))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 22))
			end
		end

		function bitbuffer.writeu23(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 1 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 23))
			else
				writeu24(b, byte, bit32_replace(readu24(b, byte), value, bit, 23))
			end
		end

		function bitbuffer.writeu24(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
			else
				writeu24(b, byte, value)
			end
		end

		function bitbuffer.writeu25(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 25))
		end

		function bitbuffer.writeu26(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 6 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 2))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 2))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 26))
			end
		end

		function bitbuffer.writeu27(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 5 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 3))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 3))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 27))
			end
		end

		function bitbuffer.writeu28(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 4 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 4))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 4))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 28))
			end
		end

		function bitbuffer.writeu29(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 3 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 5))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 5))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 29))
			end
		end

		function bitbuffer.writeu30(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 2 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 6))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 6))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 30))
			end
		end

		function bitbuffer.writeu31(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 1 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 7))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000, bit, 7))
				end
			else
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, 0, 31))
			end
		end

		function bitbuffer.writeu32(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 8))
			else
				writeu32(b, byte, value)
			end
		end

		function bitbuffer.writeu33(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 9))
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 1))
			end
		end

		function bitbuffer.writeu34(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 6 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 10))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 10))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 2))
			end
		end

		function bitbuffer.writeu35(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 5 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 11))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 11))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 3))
			end
		end

		function bitbuffer.writeu36(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 4 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 12))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 12))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 4))
			end
		end

		function bitbuffer.writeu37(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 3 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 13))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 13))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 5))
			end
		end

		function bitbuffer.writeu38(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 2 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 14))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 14))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 6))
			end
		end

		function bitbuffer.writeu39(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 1 then
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 15))
				else
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000, bit, 15))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x100000000, 0, 7))
			end
		end

		function bitbuffer.writeu40(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 16))
			else
				writeu32(b, byte, value)
				writeu8(b, byte + 4, value // 0x100000000)
			end
		end

		function bitbuffer.writeu41(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 17))
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 9))
			end
		end

		function bitbuffer.writeu42(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 6 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 18))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 18))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 10))
			end
		end

		function bitbuffer.writeu43(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 5 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 19))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 19))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 11))
			end
		end

		function bitbuffer.writeu44(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 4 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 20))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 20))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 12))
			end
		end

		function bitbuffer.writeu45(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 3 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 21))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 21))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 13))
			end
		end

		function bitbuffer.writeu46(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 2 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 22))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 22))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 14))
			end
		end

		function bitbuffer.writeu47(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				if bit > 1 then
					writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 23))
				else
					writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x1000000, bit, 23))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x100000000, 0, 15))
			end
		end

		function bitbuffer.writeu48(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
			else
				writeu32(b, byte, value)
				writeu16(b, byte + 4, value // 0x100000000)
			end
		end

		function bitbuffer.writeu49(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
				byte += 3
				writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000000000, bit, 1))
			else
				writeu32(b, byte, value)
				byte += 4
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x100000000, 0, 17))
			end
		end

		function bitbuffer.writeu50(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
				byte += 3
				if bit > 6 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000000000, bit, 2))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000000000, bit, 2))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x100000000, 0, 18))
			end
		end

		function bitbuffer.writeu51(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
				byte += 3
				if bit > 5 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000000000, bit, 3))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000000000, bit, 3))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x100000000, 0, 19))
			end
		end

		function bitbuffer.writeu52(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
				byte += 3
				if bit > 4 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000000000, bit, 4))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000000000, bit, 4))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x100000000, 0, 20))
			end
		end

		function bitbuffer.writeu53(b: buffer, offset: number, value: number)
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))
				byte += 3
				writeu32(b, byte, bit32_replace(readu32(b, byte), value // 0x1000000, bit, 24))
				byte += 3
				if bit > 3 then
					writeu16(b, byte, bit32_replace(readu16(b, byte), value // 0x1000000000000, bit, 5))
				else
					writeu8(b, byte, bit32_replace(readu8(b, byte), value // 0x1000000000000, bit, 5))
				end
			else
				writeu32(b, byte, value)
				byte += 4
				writeu24(b, byte, bit32_replace(readu24(b, byte), value // 0x100000000, 0, 21))
			end
		end
	end

	do -- read
		function bitbuffer.readu1(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return bit32_extract(readu8(b, byte), bit, 1)
		end

		function bitbuffer.readu2(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 6
				then bit32_extract(readu16(b, byte), bit, 2)
				else bit32_extract(readu8(b, byte), bit, 2)
		end

		function bitbuffer.readu3(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 5
				then bit32_extract(readu16(b, byte), bit, 3)
				else bit32_extract(readu8(b, byte), bit, 3)
		end

		function bitbuffer.readu4(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 4
				then bit32_extract(readu16(b, byte), bit, 4)
				else bit32_extract(readu8(b, byte), bit, 4)
		end

		function bitbuffer.readu5(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 3
				then bit32_extract(readu16(b, byte), bit, 5)
				else bit32_extract(readu8(b, byte), bit, 5)
		end

		function bitbuffer.readu6(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 2
				then bit32_extract(readu16(b, byte), bit, 6)
				else bit32_extract(readu8(b, byte), bit, 6)
		end

		function bitbuffer.readu7(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 1
				then bit32_extract(readu16(b, byte), bit, 7)
				else bit32_extract(readu8(b, byte), bit, 7)
		end

		function bitbuffer.readu8(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 0
				then bit32_extract(readu16(b, byte), bit, 8)
				else readu8(b, byte)
		end

		function bitbuffer.readu9(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return bit32_extract(readu16(b, byte), bit, 9)
		end

		function bitbuffer.readu10(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 6
				then bit32_extract(readu24(b, byte), bit, 10)
				else bit32_extract(readu16(b, byte), bit, 10)
		end

		function bitbuffer.readu11(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 5
				then bit32_extract(readu24(b, byte), bit, 11)
				else bit32_extract(readu16(b, byte), bit, 11)
		end

		function bitbuffer.readu12(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 4
				then bit32_extract(readu24(b, byte), bit, 12)
				else bit32_extract(readu16(b, byte), bit, 12)
		end

		function bitbuffer.readu13(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 3
				then bit32_extract(readu24(b, byte), bit, 13)
				else bit32_extract(readu16(b, byte), bit, 13)
		end

		function bitbuffer.readu14(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 2
				then bit32_extract(readu24(b, byte), bit, 14)
				else bit32_extract(readu16(b, byte), bit, 14)
		end

		function bitbuffer.readu15(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 1
				then bit32_extract(readu24(b, byte), bit, 15)
				else bit32_extract(readu16(b, byte), bit, 15)
		end

		function bitbuffer.readu16(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 0
				then bit32_extract(readu24(b, byte), bit, 16)
				else readu16(b, byte)
		end

		function bitbuffer.readu17(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return bit32_extract(readu24(b, byte), bit, 17)
		end

		function bitbuffer.readu18(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 6
				then bit32_extract(readu32(b, byte), bit, 18)
				else bit32_extract(readu24(b, byte), bit, 18)
		end

		function bitbuffer.readu19(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 5
				then bit32_extract(readu32(b, byte), bit, 19)
				else bit32_extract(readu24(b, byte), bit, 19)
		end

		function bitbuffer.readu20(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 4
				then bit32_extract(readu32(b, byte), bit, 20)
				else bit32_extract(readu24(b, byte), bit, 20)
		end

		function bitbuffer.readu21(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 3
				then bit32_extract(readu32(b, byte), bit, 21)
				else bit32_extract(readu24(b, byte), bit, 21)
		end

		function bitbuffer.readu22(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 2
				then bit32_extract(readu32(b, byte), bit, 22)
				else bit32_extract(readu24(b, byte), bit, 22)
		end

		function bitbuffer.readu23(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 1
				then bit32_extract(readu32(b, byte), bit, 23)
				else bit32_extract(readu24(b, byte), bit, 23)
		end

		function bitbuffer.readu24(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return if bit > 0
				then bit32_extract(readu32(b, byte), bit, 24)
				else readu24(b, byte)
		end

		function bitbuffer.readu25(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			return bit32_extract(readu32(b, byte), bit, 25)
		end

		function bitbuffer.readu26(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 6
							then bit32_extract(readu16(b, byte + 3), bit, 2)
							else bit32_extract(readu8(b, byte + 3), bit, 2)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x4000000
			end
		end

		function bitbuffer.readu27(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 5
							then bit32_extract(readu16(b, byte + 3), bit, 3)
							else bit32_extract(readu8(b, byte + 3), bit, 3)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x8000000
			end
		end

		function bitbuffer.readu28(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 4
							then bit32_extract(readu16(b, byte + 3), bit, 4)
							else bit32_extract(readu8(b, byte + 3), bit, 4)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x10000000
			end
		end

		function bitbuffer.readu29(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 3
							then bit32_extract(readu16(b, byte + 3), bit, 5)
							else bit32_extract(readu8(b, byte + 3), bit, 5)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x20000000
			end
		end

		function bitbuffer.readu30(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 2
							then bit32_extract(readu16(b, byte + 3), bit, 6)
							else bit32_extract(readu8(b, byte + 3), bit, 6)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x40000000
			end
		end

		function bitbuffer.readu31(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 1
							then bit32_extract(readu16(b, byte + 3), bit, 7)
							else bit32_extract(readu8(b, byte + 3), bit, 7)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x80000000
			end
		end

		function bitbuffer.readu32(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu16(b, byte + 3), bit, 8) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
			end
		end

		function bitbuffer.readu33(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu16(b, byte + 3), bit, 9) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x2 * 0x100000000
			end
		end

		function bitbuffer.readu34(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 6
							then bit32_extract(readu24(b, byte + 3), bit, 10)
							else bit32_extract(readu16(b, byte + 3), bit, 10)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x4 * 0x100000000
			end
		end

		function bitbuffer.readu35(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 5
							then bit32_extract(readu24(b, byte + 3), bit, 11)
							else bit32_extract(readu16(b, byte + 3), bit, 11)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x8 * 0x100000000
			end
		end

		function bitbuffer.readu36(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 4
							then bit32_extract(readu24(b, byte + 3), bit, 12)
							else bit32_extract(readu16(b, byte + 3), bit, 12)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x10 * 0x100000000
			end
		end

		function bitbuffer.readu37(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 3
							then bit32_extract(readu24(b, byte + 3), bit, 13)
							else bit32_extract(readu16(b, byte + 3), bit, 13)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x20 * 0x100000000
			end
		end

		function bitbuffer.readu38(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 2
							then bit32_extract(readu24(b, byte + 3), bit, 14)
							else bit32_extract(readu16(b, byte + 3), bit, 14)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x40 * 0x100000000
			end
		end

		function bitbuffer.readu39(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 1
							then bit32_extract(readu24(b, byte + 3), bit, 15)
							else bit32_extract(readu16(b, byte + 3), bit, 15)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) % 0x80 * 0x100000000
			end
		end

		function bitbuffer.readu40(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu24(b, byte + 3), bit, 16) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu8(b, byte + 4) * 0x100000000
			end
		end

		function bitbuffer.readu41(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu24(b, byte + 3), bit, 17) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x200 * 0x100000000
			end
		end

		function bitbuffer.readu42(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 6
							then bit32_extract(readu32(b, byte + 3), bit, 18)
							else bit32_extract(readu24(b, byte + 3), bit, 18)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x400 * 0x100000000
			end
		end

		function bitbuffer.readu43(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 5
							then bit32_extract(readu32(b, byte + 3), bit, 19)
							else bit32_extract(readu24(b, byte + 3), bit, 19)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x800 * 0x100000000
			end
		end

		function bitbuffer.readu44(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 4
							then bit32_extract(readu32(b, byte + 3), bit, 20)
							else bit32_extract(readu24(b, byte + 3), bit, 20)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x1000 * 0x100000000
			end
		end

		function bitbuffer.readu45(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 3
							then bit32_extract(readu32(b, byte + 3), bit, 21)
							else bit32_extract(readu24(b, byte + 3), bit, 21)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x2000 * 0x100000000
			end
		end

		function bitbuffer.readu46(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 2
							then bit32_extract(readu32(b, byte + 3), bit, 22)
							else bit32_extract(readu24(b, byte + 3), bit, 22)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x4000 * 0x100000000
			end
		end

		function bitbuffer.readu47(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ (
						if bit > 1
							then bit32_extract(readu32(b, byte + 3), bit, 23)
							else bit32_extract(readu24(b, byte + 3), bit, 23)
					) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) % 0x8000 * 0x100000000
			end
		end

		function bitbuffer.readu48(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu16(b, byte + 4) * 0x100000000
			end
		end

		function bitbuffer.readu49(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
					+ bit32_extract(readu8(b, byte + 6), bit, 1) * 0x1000000000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu24(b, byte + 4) % 0x20000 * 0x100000000
			end
		end

		function bitbuffer.readu50(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
					+ (
						if bit > 6
							then bit32_extract(readu16(b, byte + 6), bit, 2)
							else bit32_extract(readu8(b, byte + 6), bit, 2)
					) * 0x1000000000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu24(b, byte + 4) % 0x40000 * 0x100000000
			end
		end

		function bitbuffer.readu51(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
					+ (
						if bit > 5
							then bit32_extract(readu16(b, byte + 6), bit, 3)
							else bit32_extract(readu8(b, byte + 6), bit, 3)
					) * 0x1000000000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu24(b, byte + 4) % 0x80000 * 0x100000000
			end
		end

		function bitbuffer.readu52(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
					+ (
						if bit > 4
							then bit32_extract(readu16(b, byte + 6), bit, 4)
							else bit32_extract(readu8(b, byte + 6), bit, 4)
					) * 0x1000000000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu24(b, byte + 4) % 0x100000 * 0x100000000
			end
		end

		function bitbuffer.readu53(b: buffer, offset: number): number
			local byte, bit = offset // 8, offset % 8
			if bit > 0 then
				return bit32_extract(readu32(b, byte), bit, 24)
					+ bit32_extract(readu32(b, byte + 3), bit, 24) * 0x1000000
					+ (
						if bit > 3
							then bit32_extract(readu16(b, byte + 6), bit, 5)
							else bit32_extract(readu8(b, byte + 6), bit, 5)
					) * 0x1000000000000
			else
				return readu32(b, byte) % 0x100000000
					+ readu24(b, byte + 4) % 0x200000 * 0x100000000
			end
		end
	end

	local unsignedRead, unsignedWrite =
		{ bitbuffer.readu1, bitbuffer.readu2, bitbuffer.readu3, bitbuffer.readu4, bitbuffer.readu5, bitbuffer.readu6, bitbuffer.readu7, bitbuffer.readu8, bitbuffer.readu9, bitbuffer.readu10, bitbuffer.readu11, bitbuffer.readu12, bitbuffer.readu13, bitbuffer.readu14, bitbuffer.readu15, bitbuffer.readu16, bitbuffer.readu17, bitbuffer.readu18, bitbuffer.readu19, bitbuffer.readu20, bitbuffer.readu21, bitbuffer.readu22, bitbuffer.readu23, bitbuffer.readu24, bitbuffer.readu25, bitbuffer.readu26, bitbuffer.readu27, bitbuffer.readu28, bitbuffer.readu29, bitbuffer.readu30, bitbuffer.readu31, bitbuffer.readu32, bitbuffer.readu33, bitbuffer.readu34, bitbuffer.readu35, bitbuffer.readu36, bitbuffer.readu37, bitbuffer.readu38, bitbuffer.readu39, bitbuffer.readu40, bitbuffer.readu41, bitbuffer.readu42, bitbuffer.readu43, bitbuffer.readu44, bitbuffer.readu45, bitbuffer.readu46, bitbuffer.readu47, bitbuffer.readu48, bitbuffer.readu49, bitbuffer.readu50, bitbuffer.readu51, bitbuffer.readu52, bitbuffer.readu53 },
		{ bitbuffer.writeu1, bitbuffer.writeu2, bitbuffer.writeu3, bitbuffer.writeu4, bitbuffer.writeu5, bitbuffer.writeu6, bitbuffer.writeu7, bitbuffer.writeu8, bitbuffer.writeu9, bitbuffer.writeu10, bitbuffer.writeu11, bitbuffer.writeu12, bitbuffer.writeu13, bitbuffer.writeu14, bitbuffer.writeu15, bitbuffer.writeu16, bitbuffer.writeu17, bitbuffer.writeu18, bitbuffer.writeu19, bitbuffer.writeu20, bitbuffer.writeu21, bitbuffer.writeu22, bitbuffer.writeu23, bitbuffer.writeu24, bitbuffer.writeu25, bitbuffer.writeu26, bitbuffer.writeu27, bitbuffer.writeu28, bitbuffer.writeu29, bitbuffer.writeu30, bitbuffer.writeu31, bitbuffer.writeu32, bitbuffer.writeu33, bitbuffer.writeu34, bitbuffer.writeu35, bitbuffer.writeu36, bitbuffer.writeu37, bitbuffer.writeu38, bitbuffer.writeu39, bitbuffer.writeu40, bitbuffer.writeu41, bitbuffer.writeu42, bitbuffer.writeu43, bitbuffer.writeu44, bitbuffer.writeu45, bitbuffer.writeu46, bitbuffer.writeu47, bitbuffer.writeu48, bitbuffer.writeu49, bitbuffer.writeu50, bitbuffer.writeu51, bitbuffer.writeu52, bitbuffer.writeu53 }

	function bitbuffer.readu(b: buffer, offset: number, width: number): number
		return unsignedRead[width](b, offset)
	end

	function bitbuffer.writeu(b: buffer, offset: number, value: number, width: number)
		unsignedWrite[width](b, offset, value)
	end
end

do -- int
	local readi8 = buffer.readi8
	local readi16 = buffer.readi16
	local readi32 = buffer.readi32

	local writei8 = buffer.writei8
	local writei16 = buffer.writei16
	local writei32 = buffer.writei32

	do -- write
		function bitbuffer.writei2(b: buffer, offset: number, value: number)
			bitbuffer.writeu2(b, offset, (value + 4) % 4)
		end

		function bitbuffer.writei3(b: buffer, offset: number, value: number)
			bitbuffer.writeu3(b, offset, (value + 8) % 8)
		end

		function bitbuffer.writei4(b: buffer, offset: number, value: number)
			bitbuffer.writeu4(b, offset, (value + 16) % 16)
		end

		function bitbuffer.writei5(b: buffer, offset: number, value: number)
			bitbuffer.writeu5(b, offset, (value + 32) % 32)
		end

		function bitbuffer.writei6(b: buffer, offset: number, value: number)
			bitbuffer.writeu6(b, offset, (value + 64) % 64)
		end

		function bitbuffer.writei7(b: buffer, offset: number, value: number)
			bitbuffer.writeu7(b, offset, (value + 128) % 128)
		end

		function bitbuffer.writei8(b: buffer, offset: number, value: number)
			if offset % 8 > 0 then
				bitbuffer.writeu8(b, offset, (value + 256) % 256)
			else
				writei8(b, offset // 8, value)
			end
		end

		function bitbuffer.writei9(b: buffer, offset: number, value: number)
			bitbuffer.writeu9(b, offset, (value + 512) % 512)
		end

		function bitbuffer.writei10(b: buffer, offset: number, value: number)
			bitbuffer.writeu10(b, offset, (value + 1024) % 1024)
		end

		function bitbuffer.writei11(b: buffer, offset: number, value: number)
			bitbuffer.writeu11(b, offset, (value + 2048) % 2048)
		end

		function bitbuffer.writei12(b: buffer, offset: number, value: number)
			bitbuffer.writeu12(b, offset, (value + 4096) % 4096)
		end

		function bitbuffer.writei13(b: buffer, offset: number, value: number)
			bitbuffer.writeu13(b, offset, (value + 8192) % 8192)
		end

		function bitbuffer.writei14(b: buffer, offset: number, value: number)
			bitbuffer.writeu14(b, offset, (value + 16384) % 16384)
		end

		function bitbuffer.writei15(b: buffer, offset: number, value: number)
			bitbuffer.writeu15(b, offset, (value + 32768) % 32768)
		end

		function bitbuffer.writei16(b: buffer, offset: number, value: number)
			if offset % 8 > 0 then
				bitbuffer.writeu16(b, offset, (value + 65536) % 65536)
			else
				writei16(b, offset // 8, value)
			end
		end

		function bitbuffer.writei17(b: buffer, offset: number, value: number)
			bitbuffer.writeu17(b, offset, (value + 131072) % 131072)
		end

		function bitbuffer.writei18(b: buffer, offset: number, value: number)
			bitbuffer.writeu18(b, offset, (value + 262144) % 262144)
		end

		function bitbuffer.writei19(b: buffer, offset: number, value: number)
			bitbuffer.writeu19(b, offset, (value + 524288) % 524288)
		end

		function bitbuffer.writei20(b: buffer, offset: number, value: number)
			bitbuffer.writeu20(b, offset, (value + 1048576) % 1048576)
		end

		function bitbuffer.writei21(b: buffer, offset: number, value: number)
			bitbuffer.writeu21(b, offset, (value + 2097152) % 2097152)
		end

		function bitbuffer.writei22(b: buffer, offset: number, value: number)
			bitbuffer.writeu22(b, offset, (value + 4194304) % 4194304)
		end

		function bitbuffer.writei23(b: buffer, offset: number, value: number)
			bitbuffer.writeu23(b, offset, (value + 8388608) % 8388608)
		end

		function bitbuffer.writei24(b: buffer, offset: number, value: number)
			bitbuffer.writeu24(b, offset, (value + 16777216) % 16777216)
		end

		function bitbuffer.writei25(b: buffer, offset: number, value: number)
			bitbuffer.writeu25(b, offset, (value + 33554432) % 33554432)
		end

		function bitbuffer.writei26(b: buffer, offset: number, value: number)
			bitbuffer.writeu26(b, offset, (value + 67108864) % 67108864)
		end

		function bitbuffer.writei27(b: buffer, offset: number, value: number)
			bitbuffer.writeu27(b, offset, (value + 134217728) % 134217728)
		end

		function bitbuffer.writei28(b: buffer, offset: number, value: number)
			bitbuffer.writeu28(b, offset, (value + 268435456) % 268435456)
		end

		function bitbuffer.writei29(b: buffer, offset: number, value: number)
			bitbuffer.writeu29(b, offset, (value + 536870912) % 536870912)
		end

		function bitbuffer.writei30(b: buffer, offset: number, value: number)
			bitbuffer.writeu30(b, offset, (value + 1073741824) % 1073741824)
		end

		function bitbuffer.writei31(b: buffer, offset: number, value: number)
			bitbuffer.writeu31(b, offset, (value + 2147483648) % 2147483648)
		end

		function bitbuffer.writei32(b: buffer, offset: number, value: number)
			if offset % 8 > 0 then
				bitbuffer.writeu32(b, offset, (value + 4294967296) % 4294967296)
			else
				writei32(b, offset // 8, value)
			end
		end

		function bitbuffer.writei33(b: buffer, offset: number, value: number)
			bitbuffer.writeu33(b, offset, (value + 8589934592) % 8589934592)
		end

		function bitbuffer.writei34(b: buffer, offset: number, value: number)
			bitbuffer.writeu34(b, offset, (value + 17179869184) % 17179869184)
		end

		function bitbuffer.writei35(b: buffer, offset: number, value: number)
			bitbuffer.writeu35(b, offset, (value + 34359738368) % 34359738368)
		end

		function bitbuffer.writei36(b: buffer, offset: number, value: number)
			bitbuffer.writeu36(b, offset, (value + 68719476736) % 68719476736)
		end

		function bitbuffer.writei37(b: buffer, offset: number, value: number)
			bitbuffer.writeu37(b, offset, (value + 137438953472) % 137438953472)
		end

		function bitbuffer.writei38(b: buffer, offset: number, value: number)
			bitbuffer.writeu38(b, offset, (value + 274877906944) % 274877906944)
		end

		function bitbuffer.writei39(b: buffer, offset: number, value: number)
			bitbuffer.writeu39(b, offset, (value + 549755813888) % 549755813888)
		end

		function bitbuffer.writei40(b: buffer, offset: number, value: number)
			bitbuffer.writeu40(b, offset, (value + 1099511627776) % 1099511627776)
		end

		function bitbuffer.writei41(b: buffer, offset: number, value: number)
			bitbuffer.writeu41(b, offset, (value + 2199023255552) % 2199023255552)
		end

		function bitbuffer.writei42(b: buffer, offset: number, value: number)
			bitbuffer.writeu42(b, offset, (value + 4398046511104) % 4398046511104)
		end

		function bitbuffer.writei43(b: buffer, offset: number, value: number)
			bitbuffer.writeu43(b, offset, (value + 8796093022208) % 8796093022208)
		end

		function bitbuffer.writei44(b: buffer, offset: number, value: number)
			bitbuffer.writeu44(b, offset, (value + 17592186044416) % 17592186044416)
		end

		function bitbuffer.writei45(b: buffer, offset: number, value: number)
			bitbuffer.writeu45(b, offset, (value + 35184372088832) % 35184372088832)
		end

		function bitbuffer.writei46(b: buffer, offset: number, value: number)
			bitbuffer.writeu46(b, offset, (value + 70368744177664) % 70368744177664)
		end

		function bitbuffer.writei47(b: buffer, offset: number, value: number)
			bitbuffer.writeu47(b, offset, (value + 140737488355328) % 140737488355328)
		end

		function bitbuffer.writei48(b: buffer, offset: number, value: number)
			bitbuffer.writeu48(b, offset, (value + 281474976710656) % 281474976710656)
		end

		function bitbuffer.writei49(b: buffer, offset: number, value: number)
			bitbuffer.writeu49(b, offset, (value + 562949953421312) % 562949953421312)
		end

		function bitbuffer.writei50(b: buffer, offset: number, value: number)
			bitbuffer.writeu50(b, offset, (value + 1125899906842624) % 1125899906842624)
		end

		function bitbuffer.writei51(b: buffer, offset: number, value: number)
			bitbuffer.writeu51(b, offset, (value + 2251799813685248) % 2251799813685248)
		end

		function bitbuffer.writei52(b: buffer, offset: number, value: number)
			bitbuffer.writeu52(b, offset, (value + 4503599627370496) % 4503599627370496)
		end
	end

	do -- read
		function bitbuffer.readi2(b: buffer, offset: number): number
			return ( bitbuffer.readu2(b, offset) + 2 ) % 4 - 2
		end

		function bitbuffer.readi3(b: buffer, offset: number): number
			return ( bitbuffer.readu3(b, offset) + 4 ) % 8 - 4
		end

		function bitbuffer.readi4(b: buffer, offset: number): number
			return ( bitbuffer.readu4(b, offset) + 8 ) % 16 - 8
		end

		function bitbuffer.readi5(b: buffer, offset: number): number
			return ( bitbuffer.readu5(b, offset) + 16 ) % 32 - 16
		end

		function bitbuffer.readi6(b: buffer, offset: number): number
			return ( bitbuffer.readu6(b, offset) + 32 ) % 64 - 32
		end

		function bitbuffer.readi7(b: buffer, offset: number): number
			return ( bitbuffer.readu7(b, offset) + 64 ) % 128 - 64
		end

		function bitbuffer.readi8(b: buffer, offset: number): number
			return if offset % 8 > 0
				then ( bitbuffer.readu8(b, offset) + 128 ) % 256 - 128
				else readi8(b, offset // 8)
		end

		function bitbuffer.readi9(b: buffer, offset: number): number
			return ( bitbuffer.readu9(b, offset) + 256 ) % 512 - 256
		end

		function bitbuffer.readi10(b: buffer, offset: number): number
			return ( bitbuffer.readu10(b, offset) + 512 ) % 1024 - 512
		end

		function bitbuffer.readi11(b: buffer, offset: number): number
			return ( bitbuffer.readu11(b, offset) + 1024 ) % 2048 - 1024
		end

		function bitbuffer.readi12(b: buffer, offset: number): number
			return ( bitbuffer.readu12(b, offset) + 2048 ) % 4096 - 2048
		end

		function bitbuffer.readi13(b: buffer, offset: number): number
			return ( bitbuffer.readu13(b, offset) + 4096 ) % 8192 - 4096
		end

		function bitbuffer.readi14(b: buffer, offset: number): number
			return ( bitbuffer.readu14(b, offset) + 8192 ) % 16384 - 8192
		end

		function bitbuffer.readi15(b: buffer, offset: number): number
			return ( bitbuffer.readu15(b, offset) + 16384 ) % 32768 - 16384
		end

		function bitbuffer.readi16(b: buffer, offset: number): number
			return if offset % 8 > 0
				then ( bitbuffer.readu16(b, offset) + 32768 ) % 65536 - 32768
				else readi16(b, offset // 8)
		end

		function bitbuffer.readi17(b: buffer, offset: number): number
			return ( bitbuffer.readu17(b, offset) + 65536 ) % 131072 - 65536
		end

		function bitbuffer.readi18(b: buffer, offset: number): number
			return ( bitbuffer.readu18(b, offset) + 131072 ) % 262144 - 131072
		end

		function bitbuffer.readi19(b: buffer, offset: number): number
			return ( bitbuffer.readu19(b, offset) + 262144 ) % 524288 - 262144
		end

		function bitbuffer.readi20(b: buffer, offset: number): number
			return ( bitbuffer.readu20(b, offset) + 524288 ) % 1048576 - 524288
		end

		function bitbuffer.readi21(b: buffer, offset: number): number
			return ( bitbuffer.readu21(b, offset) + 1048576 ) % 2097152 - 1048576
		end

		function bitbuffer.readi22(b: buffer, offset: number): number
			return ( bitbuffer.readu22(b, offset) + 2097152 ) % 4194304 - 2097152
		end

		function bitbuffer.readi23(b: buffer, offset: number): number
			return ( bitbuffer.readu23(b, offset) + 4194304 ) % 8388608 - 4194304
		end

		function bitbuffer.readi24(b: buffer, offset: number): number
			return ( bitbuffer.readu24(b, offset) + 8388608 ) % 16777216 - 8388608
		end

		function bitbuffer.readi25(b: buffer, offset: number): number
			return ( bitbuffer.readu25(b, offset) + 16777216 ) % 33554432 - 16777216
		end

		function bitbuffer.readi26(b: buffer, offset: number): number
			return ( bitbuffer.readu26(b, offset) + 33554432 ) % 67108864 - 33554432
		end

		function bitbuffer.readi27(b: buffer, offset: number): number
			return ( bitbuffer.readu27(b, offset) + 67108864 ) % 134217728 - 67108864
		end

		function bitbuffer.readi28(b: buffer, offset: number): number
			return ( bitbuffer.readu28(b, offset) + 134217728 ) % 268435456 - 134217728
		end

		function bitbuffer.readi29(b: buffer, offset: number): number
			return ( bitbuffer.readu29(b, offset) + 268435456 ) % 536870912 - 268435456
		end

		function bitbuffer.readi30(b: buffer, offset: number): number
			return ( bitbuffer.readu30(b, offset) + 536870912 ) % 1073741824 - 536870912
		end

		function bitbuffer.readi31(b: buffer, offset: number): number
			return ( bitbuffer.readu31(b, offset) + 1073741824 ) % 2147483648 - 1073741824
		end

		function bitbuffer.readi32(b: buffer, offset: number): number
			return if offset % 8 > 0
				then ( bitbuffer.readu32(b, offset) + 2147483648 ) % 4294967296 - 2147483648
				else readi32(b, offset // 8)
		end

		function bitbuffer.readi33(b: buffer, offset: number): number
			return ( bitbuffer.readu33(b, offset) + 4294967296 ) % 8589934592 - 4294967296
		end

		function bitbuffer.readi34(b: buffer, offset: number): number
			return ( bitbuffer.readu34(b, offset) + 8589934592 ) % 17179869184 - 8589934592
		end

		function bitbuffer.readi35(b: buffer, offset: number): number
			return ( bitbuffer.readu35(b, offset) + 17179869184 ) % 34359738368 - 17179869184
		end

		function bitbuffer.readi36(b: buffer, offset: number): number
			return ( bitbuffer.readu36(b, offset) + 34359738368 ) % 68719476736 - 34359738368
		end

		function bitbuffer.readi37(b: buffer, offset: number): number
			return ( bitbuffer.readu37(b, offset) + 68719476736 ) % 137438953472 - 68719476736
		end

		function bitbuffer.readi38(b: buffer, offset: number): number
			return ( bitbuffer.readu38(b, offset) + 137438953472 ) % 274877906944 - 137438953472
		end

		function bitbuffer.readi39(b: buffer, offset: number): number
			return ( bitbuffer.readu39(b, offset) + 274877906944 ) % 549755813888 - 274877906944
		end

		function bitbuffer.readi40(b: buffer, offset: number): number
			return ( bitbuffer.readu40(b, offset) + 549755813888 ) % 1099511627776 - 549755813888
		end

		function bitbuffer.readi41(b: buffer, offset: number): number
			return ( bitbuffer.readu41(b, offset) + 1099511627776 ) % 2199023255552 - 1099511627776
		end

		function bitbuffer.readi42(b: buffer, offset: number): number
			return ( bitbuffer.readu42(b, offset) + 2199023255552 ) % 4398046511104 - 2199023255552
		end

		function bitbuffer.readi43(b: buffer, offset: number): number
			return ( bitbuffer.readu43(b, offset) + 4398046511104 ) % 8796093022208 - 4398046511104
		end

		function bitbuffer.readi44(b: buffer, offset: number): number
			return ( bitbuffer.readu44(b, offset) + 8796093022208 ) % 17592186044416 - 8796093022208
		end

		function bitbuffer.readi45(b: buffer, offset: number): number
			return ( bitbuffer.readu45(b, offset) + 17592186044416 ) % 35184372088832 - 17592186044416
		end

		function bitbuffer.readi46(b: buffer, offset: number): number
			return ( bitbuffer.readu46(b, offset) + 35184372088832 ) % 70368744177664 - 35184372088832
		end

		function bitbuffer.readi47(b: buffer, offset: number): number
			return ( bitbuffer.readu47(b, offset) + 70368744177664 ) % 140737488355328 - 70368744177664
		end

		function bitbuffer.readi48(b: buffer, offset: number): number
			return ( bitbuffer.readu48(b, offset) + 140737488355328 ) % 281474976710656 - 140737488355328
		end

		function bitbuffer.readi49(b: buffer, offset: number): number
			return ( bitbuffer.readu49(b, offset) + 281474976710656 ) % 562949953421312 - 281474976710656
		end

		function bitbuffer.readi50(b: buffer, offset: number): number
			return ( bitbuffer.readu50(b, offset) + 562949953421312 ) % 1125899906842624 - 562949953421312
		end

		function bitbuffer.readi51(b: buffer, offset: number): number
			return ( bitbuffer.readu51(b, offset) + 1125899906842624 ) % 2251799813685248 - 1125899906842624
		end

		function bitbuffer.readi52(b: buffer, offset: number): number
			return ( bitbuffer.readu52(b, offset) + 2251799813685248 ) % 4503599627370496 - 2251799813685248
		end
	end

	local signedRead, signedWrite =
		{ nil :: any, bitbuffer.readi2, bitbuffer.readi3, bitbuffer.readi4, bitbuffer.readi5, bitbuffer.readi6, bitbuffer.readi7, bitbuffer.readi8, bitbuffer.readi9, bitbuffer.readi10, bitbuffer.readi11, bitbuffer.readi12, bitbuffer.readi13, bitbuffer.readi14, bitbuffer.readi15, bitbuffer.readi16, bitbuffer.readi17, bitbuffer.readi18, bitbuffer.readi19, bitbuffer.readi20, bitbuffer.readi21, bitbuffer.readi22, bitbuffer.readi23, bitbuffer.readi24, bitbuffer.readi25, bitbuffer.readi26, bitbuffer.readi27, bitbuffer.readi28, bitbuffer.readi29, bitbuffer.readi30, bitbuffer.readi31, bitbuffer.readi32, bitbuffer.readi33, bitbuffer.readi34, bitbuffer.readi35, bitbuffer.readi36, bitbuffer.readi37, bitbuffer.readi38, bitbuffer.readi39, bitbuffer.readi40, bitbuffer.readi41, bitbuffer.readi42, bitbuffer.readi43, bitbuffer.readi44, bitbuffer.readi45, bitbuffer.readi46, bitbuffer.readi47, bitbuffer.readi48, bitbuffer.readi49, bitbuffer.readi50, bitbuffer.readi51, bitbuffer.readi52 },
		{ nil :: any, bitbuffer.writei2, bitbuffer.writei3, bitbuffer.writei4, bitbuffer.writei5, bitbuffer.writei6, bitbuffer.writei7, bitbuffer.writei8, bitbuffer.writei9, bitbuffer.writei10, bitbuffer.writei11, bitbuffer.writei12, bitbuffer.writei13, bitbuffer.writei14, bitbuffer.writei15, bitbuffer.writei16, bitbuffer.writei17, bitbuffer.writei18, bitbuffer.writei19, bitbuffer.writei20, bitbuffer.writei21, bitbuffer.writei22, bitbuffer.writei23, bitbuffer.writei24, bitbuffer.writei25, bitbuffer.writei26, bitbuffer.writei27, bitbuffer.writei28, bitbuffer.writei29, bitbuffer.writei30, bitbuffer.writei31, bitbuffer.writei32, bitbuffer.writei33, bitbuffer.writei34, bitbuffer.writei35, bitbuffer.writei36, bitbuffer.writei37, bitbuffer.writei38, bitbuffer.writei39, bitbuffer.writei40, bitbuffer.writei41, bitbuffer.writei42, bitbuffer.writei43, bitbuffer.writei44, bitbuffer.writei45, bitbuffer.writei46, bitbuffer.writei47, bitbuffer.writei48, bitbuffer.writei49, bitbuffer.writei50, bitbuffer.writei51, bitbuffer.writei52 }

	function bitbuffer.readi(b: buffer, offset: number, width: number): number
		return signedRead[width](b, offset)
	end

	function bitbuffer.writei(b: buffer, offset: number, value: number, width: number)
		signedWrite[width](b, offset, value)
	end
end

do -- float
	do -- write
		function bitbuffer.writef32(b: buffer, offset: number, value: number)
			if offset % 8 == 0 then
				buffer.writef32(b, offset // 8, value)
				return
			end

			local mantissa, exponent, sign = 0, 0, 0
			if math.abs(value) > 3.4028234663852886e+38 then
				exponent, sign = 0b11111111, if value < 0 then 1 else 0
			elseif value ~= value then
				mantissa, exponent, sign = 1, 0b11111111, 1
			elseif value ~= 0 then
				mantissa, exponent = math.frexp(value)
				exponent += 126

				mantissa = math.round(if exponent <= 0
					then math.abs(mantissa) * 0x800000 / math.ldexp(1, math.abs(exponent))
					else math.abs(mantissa) * 0x1000000)
				exponent = math.max(exponent, 0)
				sign = if value < 0 then 1 else 0
			end

			bitbuffer.writeu23(b, offset, mantissa)
			bitbuffer.writeu8(b, offset + 23, exponent)
			bitbuffer.writeu1(b, offset + 31, sign)
		end

		function bitbuffer.writef64(b: buffer, offset: number, value: number)
			if offset % 8 == 0 then
				buffer.writef64(b, offset // 8, value)
				return
			end

			local mantissa, exponent, sign = 0, 0, 0
			if math.abs(value) > 1.7976931348623157e+308 then
				exponent, sign = 0b11111111111, if value < 0 then 1 else 0
			elseif value ~= value then
				mantissa, exponent, sign = 1, 0b11111111111, 1
			elseif value ~= 0 then
				mantissa, exponent = math.frexp(value)
				exponent += 1022

				mantissa = math.round(if exponent <= 0
					then math.abs(mantissa) * 0x10000000000000 / math.ldexp(1, math.abs(exponent))
					else math.abs(mantissa) * 0x20000000000000)
				exponent = math.max(exponent, 0)
				sign = if value < 0 then 1 else 0
			end

			bitbuffer.writeu52(b, offset, mantissa)
			bitbuffer.writeu11(b, offset + 52, exponent)
			bitbuffer.writeu1(b, offset + 63, sign)
		end
	end

	do -- read
		function bitbuffer.readf32(b: buffer, offset: number): number
			if offset % 8 == 0 then
				return buffer.readf32(b, offset // 8)
			end

			local mantissa = bitbuffer.readu23(b, offset)
			local exponent = bitbuffer.readu8(b, offset + 23)
			local sign = bitbuffer.readu1(b, offset + 31) == 1

			if mantissa == 0 and exponent == 0b11111111 then
				return if sign then -math.huge else math.huge
			elseif mantissa == 1 and exponent == 0b11111111 then
				return 0 / 0
			elseif mantissa == 0 and exponent == 0 then
				return 0
			else
				mantissa = if exponent == 0
					then mantissa / 0x800000
					else mantissa / 0x1000000 + 0.5

				local value = math.ldexp(mantissa, exponent - 126)
				return if sign then -value else value
			end
		end

		function bitbuffer.readf64(b: buffer, offset: number): number
			if offset % 8 == 0 then
				return buffer.readf64(b, offset // 8)
			end

			local mantissa = bitbuffer.readu52(b, offset)
			local exponent = bitbuffer.readu11(b, offset + 52)
			local sign = bitbuffer.readu1(b, offset + 63) == 1

			if mantissa == 0 and exponent == 0b11111111111 then
				return if sign then -math.huge else math.huge
			elseif mantissa == 1 and exponent == 0b11111111111 then
				return 0 / 0
			elseif mantissa == 0 and exponent == 0 then
				return 0
			else
				mantissa = if exponent == 0
					then mantissa / 0x10000000000000
					else mantissa / 0x20000000000000 + 0.5

				local value = math.ldexp(mantissa, exponent - 1022)
				return if sign then -value else value
			end
		end
	end
end

do -- string
	function bitbuffer.readstring(b: buffer, offset: number, count: number?): string
		if offset % 8 == 0 then
			return buffer.readtring(b, offset // 8)
		else
			local output = table.create((count + 5) // 6)

			local chunkMax = count // 6 * 6

			for stringIndex = 1, chunkMax, 6 do
				local chunk = bitbuffer.readu48(b, offset + (stringIndex - 1) * 8)
				table.insert(output, string.pack("I6", chunk))
			end

			local overflowStart = offset + (chunkMax - 1) * 8
			for stringIndex = 1, count - chunkMax do
				local chunk = bitbuffer.readu8(b, overflowStart + stringIndex * 8)
				table.insert(output, string.char(chunk))
			end

			return table.concat(output)
		end
	end

	function bitbuffer.writestring(b: buffer, offset: number, value: string, count: number?)
		if offset % 8 == 0 then
			buffer.writestring(b, offset // 8, value, count)
		else
			local stringLength = count or #value
			local chunkMax = stringLength // 6 * 6

			for stringIndex = 1, chunkMax, 6 do
				local chunk = string.unpack("I6", value, stringIndex)
				bitbuffer.writeu48(b, offset + (stringIndex - 1) * 8, chunk)
			end

			local overflowStart = offset + (chunkMax - 1) * 8
			for stringIndex = 1, stringLength - chunkMax do
				local byte = value:byte(chunkMax + stringIndex)
				bitbuffer.writeu8(b, overflowStart + stringIndex * 8, byte)
			end
		end
	end
end

do -- other
	function bitbuffer.fill(b: buffer, offset: number, value: number, count: number?)
		if offset % 8 == 0 and count % 8 == 0 then
			buffer.fill(b, offset // 8, value, count)
		else
			error("unimplemented")
		end
	end

	function bitbuffer.copy(target: buffer, targetOffset: number, source: buffer, sourceOffset: number?, count: number?)
		if targetOffset % 8 == 0 and sourceOffset % 8 == 0 and count % 8 == 0 then
			buffer.copy(target, targetOffset, source, sourceOffset, count)
		else
			error("unimplemented")
		end
	end
end

do -- baseconversion
	local NUMBER_TO_BASE64 = buffer.fromstring("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
	local BASE64_TO_NUMBER = {}

	local CHARACTER_TO_BINARY = {}
	local BINARY_TO_NUMBER = {}

	local CHARACTER_TO_HEXADECIMAL = {}
	local HEXADECIMAL_TO_NUMBER = {}

	for index = 0, 255 do
		local binary = table.create(8)
		for field = 0, 7 do
			binary[8 - field] = bit32.extract(index, field, 1)
		end

		local binaryString = table.concat(binary)
		local hexadecimalString = string.format("%02x", index)

		local char = string.char(index)

		CHARACTER_TO_BINARY[char] = binaryString
		BINARY_TO_NUMBER[binaryString] = index

		CHARACTER_TO_HEXADECIMAL[char] = hexadecimalString
		HEXADECIMAL_TO_NUMBER[hexadecimalString] = index
	end

	for index = 0, 63 do
		BASE64_TO_NUMBER[buffer.readu8(NUMBER_TO_BASE64, index)] = index
	end

	local function baseLookupGenerator(default)
		local cache = { [""] = default }

		return function(separator: string)
			if cache[separator] then
				return cache[separator]
			end

			local lookupTable = {}
			for index = 0, 255 do
				local char = string.char(index)
				lookupTable[char] = default[char] .. separator
			end

			cache[separator] = lookupTable
			return lookupTable
		end
	end

	local getBinaryLookup = baseLookupGenerator(CHARACTER_TO_BINARY)
	local getHexadecimalLookup = baseLookupGenerator(CHARACTER_TO_HEXADECIMAL)

	-- Pre-create default separator lookups
	getBinaryLookup("_")
	getHexadecimalLookup("_")

	function bitbuffer.tobinary(b: buffer, separator: string?): string
		local separatorLength = if separator then #separator else 1
		local lookupTable = getBinaryLookup(separator or "_")

		local str = buffer.tostring(b):gsub(".", lookupTable)
		return str:sub(1, -1 - separatorLength)
	end

	function bitbuffer.frombinary(str: string, separator: string?)
		local separatorLength = if separator then #separator else 0

		local codeLength = 8 + separatorLength
		local b = buffer.create((#str + separatorLength) / codeLength)

		local offset = 0
		for index = 1, #str, codeLength do
			local code = str:sub(index, index + 7)
			buffer.writeu8(b, offset, BINARY_TO_NUMBER[code])
			offset += 1
		end

		return b
	end

	function bitbuffer.tohexadecimal(b: buffer, separator: string?): string
		local separatorLength = if separator then #separator else 1
		local lookupTable = getHexadecimalLookup(separator or "_")

		local str = buffer.tostring(b):gsub(".", lookupTable)
		return str:sub(1, -1 - separatorLength)
	end

	function bitbuffer.fromhexadecimal(str: string, separator: string?)
		local separatorLength = if separator then #separator else 0

		local codeLength = 2 + separatorLength
		local b = buffer.create((#str + separatorLength) / codeLength)

		local offset = 0
		for index = 1, #str, codeLength do
			local code = str:sub(index, index + 1)
			buffer.writeu8(b, offset, HEXADECIMAL_TO_NUMBER[code])
			offset += 1
		end

		return b
	end

	local function flipu16(value: number): number
		return (value // 256) -- FF00 -> 00FF
			+ (value % 256 * 256) -- 00FF -> FF00
	end

	function bitbuffer.tobase64(b: buffer): string
		local bufferLength = buffer.len(b)
		local bitCount = buffer.len(b) * 8

		local paddingLength = 2 - (bufferLength - 1) % (2 + 1)
		local characterCount = math.ceil(bitCount / 6)

		local endOffset = (characterCount - 1) * 6
		local overhang = bitCount - endOffset

		local output = buffer.create(characterCount + paddingLength)
		local outputIndex = 0

		for offset = 0, endOffset - overhang, 6 do
			local byte, bit = offset // 8, offset % 8
			local byteWidth = (bit + 13) // 8
			bit = (byteWidth * 8 - 6) - bit

			local focus = if byteWidth == 1 then buffer.readu8(b, byte) else flipu16(buffer.readu16(b, byte))
			local code = bit32.extract(focus, bit, 6)

			buffer.writeu8(output, outputIndex, buffer.readu8(NUMBER_TO_BASE64, code))
			outputIndex += 1
		end

		if overhang > 0 then
			local byte, bit = endOffset // 8, (8 - overhang) - endOffset % 8

			local focus = buffer.readu8(b, byte)
			local code = bit32.lshift(bit32.extract(focus, bit, overhang), 6 - overhang)

			buffer.writeu8(output, outputIndex, buffer.readu8(NUMBER_TO_BASE64, code))
		end

		buffer.fill(output, characterCount, 61, paddingLength) -- '='
		return buffer.tostring(output)
	end

	function bitbuffer.frombase64(str: string)
		local paddingStart, paddingEnd = string.find(str, "=*$")
		local padding = paddingEnd - paddingStart + 1

		local codeCount = #str - padding
		local bitCount = (codeCount * 6) - (padding * 2)

		local output = buffer.create(bitCount // 8)
		local outputOffset = 0

		for inputIndex = 1, codeCount do
			local byte, bit = outputOffset // 8, outputOffset % 8
			local byteWidth = (bit + 13) // 8
			bit = (byteWidth * 8 - 6) - bit

			local code = BASE64_TO_NUMBER[str:byte(inputIndex)]
			if byteWidth == 2 then
				buffer.writeu16(output, byte, flipu16(bit32.replace(flipu16(buffer.readu16(output, byte)), code, bit, 6)))
			else
				buffer.writeu8(output, byte, bit32.replace(buffer.readu8(output, byte), code, bit, 6))
			end

			outputOffset += 6
		end

		return output
	end
end

return bitbuffer