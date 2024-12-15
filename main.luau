local ByteWorks = {}
--writef16 and readf16 taken from Blink by Axen ngl

local function writei24(buff, offset, value)
	if value < 0 then
		value = value + 16777216
	end
	buffer.writeu16(buff, offset, value / 256)
	buffer.writeu8(buff, offset + 2, value % 256)
end

local function readi24(buff, offset)
	local value = 256 * buffer.readu16(buff, offset) + buffer.readu8(buff, offset + 2)
	if value >= 8388608 then
		value = value - 16777216
	end
	return value
end

local function writeu24(buff, offset, value)
	buffer.writeu16(buff, offset, value / 256)
	buffer.writeu8(buff, offset + 2, value)
end

local function readu24(buff, offset)
	return 256 * buffer.readu16(buff, offset) + buffer.readu8(buff, offset + 2)
end

local function writeu53(buff, offset, value)
	buffer.writeu32(buff, offset, value / 16777216)
	writeu24(buff, offset + 4, value)
end

local function readu53(buff, offset)
	return 16777216 * buffer.readu32(buff, offset) + readu24(buff, offset + 4)
end

local function writei53(buff, offset, value)
	if value < 0 then
		value = value + 9007199254740992
	end
	buffer.writeu32(buff, offset, value / 16777216)
	writeu24(buff, offset + 4, value % 16777216)
end

local function readi53(buff, offset)
	local value = 16777216 * buffer.readu32(buff, offset) + readu24(buff, offset + 4)
	if value >= 4503599627370496 then
		value = value - 9007199254740992
	end
	return value
end

local function writef16(buff, offset, value)
	if value > 65504 then
		buffer.writeu16(buff, offset, 0b0_11111_0000000000)
	elseif value < -65504 then
		buffer.writeu16(buff, offset, 0b1_11111_0000000000)
	elseif value ~= value then
		error("value cannot be NaN")
	elseif value == 0 then
		buffer.writeu16(buff, offset, 0)
	else
		local float = value
		local absolute = math.abs(float)
		local interval = math.ldexp(1, math.floor(math.log(absolute, 2)) - 10)
		local roundedValue = (absolute // interval) * interval
		local fraction, exponent = math.frexp(roundedValue)

		exponent += 14
		local mantissa = math.round(if exponent <= 0
			then fraction * 0x400 / math.ldexp(1, math.abs(exponent))
			else fraction * 0x800) % 0x400
		local result = mantissa
			+ math.max(exponent, 0) * 0x400
			+ if float < 0 then 0x8000 else 0
		buffer.writeu16(buff, offset, result)
	end
end

local function readf16(buff, offset)
	local encoded = buffer.readu16(buff, offset)
	local mantissaExponent = encoded % 0x8000

	local value
	if mantissaExponent == 0b0_11111_0000000000 then
		if encoded // 0x8000 == 1 then
			value = -math.huge
		else
			value = math.huge
		end
	elseif mantissaExponent == 0b1_11111_0000000000 or mantissaExponent == 0b0_00000_0000000000 then
		value = 0
	else
		local mantissa = mantissaExponent % 0x400
		local exponent = mantissaExponent // 0x400
		local fraction

		if exponent == 0 then
			fraction = mantissa / 0x400
		else
			fraction = mantissa / 0x800 + 0.5
		end

		local result = math.ldexp(fraction, exponent - 14)
		return if encoded // 0x8000 == 1 then -result else result
	end
end

--unsigned integers
ByteWorks.u8 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu8(buff, offset, value)
		return offset + 1
	end,
	des = function(buff, offset)
		return offset + 1, buffer.readu8(buff, offset)
	end,
	size = function(value)
		return 1
	end,
})
ByteWorks.u16 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset)
		return offset + 2, buffer.readu16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
})
ByteWorks.u24 = table.freeze({
	ser = function(buff, offset, value)
		writeu24(buff, offset, value)
		return offset + 3
	end,
	des = function(buff, offset)
		return offset + 3, readu24(buff, offset)
	end,
	size = function(value)
		return 3
	end,
})
ByteWorks.u32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset)
		return offset + 4, buffer.readu32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
})
ByteWorks.u53 = table.freeze({
	ser = function(buff, offset, value)
		writeu53(buff, offset, value)
		return offset + 7
	end,
	des = function(buff, offset)
		return offset + 7, readu53(buff, offset)
	end,
	size = function(value)
		return 7
	end,
})

--signed integers
ByteWorks.i8 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei8(buff, offset, value)
		return offset + 1
	end,
	des = function(buff, offset)
		return offset + 1, buffer.readi8(buff, offset)
	end,
	size = function(value)
		return 1
	end,
})
ByteWorks.i16 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset)
		return offset + 2, buffer.readi16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
})
ByteWorks.i24 = table.freeze({
	ser = function(buff, offset, value)
		writei24(buff, offset, value)
		return offset + 3
	end,
	des = function(buff, offset)
		return offset + 3, readi24(buff, offset)
	end,
	size = function(value)
		return 3
	end,
})
ByteWorks.i32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset)
		return offset + 4, buffer.readi32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
})
ByteWorks.i53 = table.freeze({
	ser = function(buff, offset, value)
		writei53(buff, offset, value)
		return offset + 7
	end,
	des = function(buff, offset)
		return offset + 7, readi53(buff, offset)
	end,
	size = function(value)
		return 7
	end,
})

--floating point numbers
ByteWorks.f16 = table.freeze({
	ser = function(buff, offset, value)
		writef16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset)
		return offset + 2, readf16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
})
ByteWorks.f32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset)
		return offset + 4, buffer.readf32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
})
ByteWorks.f64 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef64(buff, offset, value)
		return offset + 8
	end,
	des = function(buff, offset)
		return offset + 8, buffer.readf64(buff, offset)
	end,
	size = function(value)
		return 8
	end,
})

--variable length unsigned integers
ByteWorks.vlq = table.freeze({
	ser = function(buff, offset, value)
		repeat
			local byte = bit32.band(value, 0x7F) 
			value = bit32.rshift(value, 7)
			if value > 0 then
				byte = bit32.bor(byte, 0x80)
			end
			buffer.writeu8(buff, offset, byte)
			offset += 1
		until value == 0
		
		return offset
	end,
	des = function(buff, offset)
		local result = 0
		local shift = 0
		local byte
		
		repeat
			byte = buffer.readu8(buff, offset)
			offset += 1
			result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), shift))
			shift += 7
		until bit32.band(byte, 0x80) == 0
		
		return offset, result
	end,
	size = function(value)
		local bytes = 0
		
		repeat
			value = bit32.rshift(value, 7)
			bytes += 1
		until value == 0
		
		return bytes
	end,
})

--variable length signed integers
ByteWorks.svlq = table.freeze({
	ser = function(buff, offset, value)
		local zigzagValue = bit32.bxor(bit32.lshift(value, 1), bit32.arshift(value, 31))
		
		repeat
			local byte = bit32.band(zigzagValue, 0x7F)
			zigzagValue = bit32.rshift(zigzagValue, 7)
			if zigzagValue > 0 then
				byte = bit32.bor(byte, 0x80)
			end
			buffer.writeu8(buff, offset, byte)
			offset += 1
		until zigzagValue == 0
		
		return offset
	end,
	des = function(buff, offset)
		local result = 0
		local shift = 0
		local byte
		
		repeat
			byte = buffer.readu8(buff, offset)
			offset += 1
			result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), shift))
			shift += 7
		until bit32.band(byte, 0x80) == 0
		
		return offset, bit32.arshift(result, 1) * -(bit32.band(result, 1))
	end,
	size = function(value)
		local zigzagValue = bit32.bxor(bit32.lshift(value, 1), bit32.arshift(value, 31))
		local bytes = 0
		
		repeat
			zigzagValue = bit32.rshift(zigzagValue, 7)
			bytes += 1
		until zigzagValue == 0
		
		return bytes
	end,
})

function ByteWorks.string(count)
	return table.freeze({
		ser = function(buff, offset, value)
			buffer.writestring(buff, offset, value, count)
			return offset + count
		end,
		des = function(buff, offset)
			return offset + count, buffer.readstring(buff, offset, count)
		end,
		size = function(value)
			return count
		end,
	})
end

function ByteWorks.bitmask(bitCount)
	local byteCount = math.ceil(bitCount / 8)
	return table.freeze({
		ser = function(buff, offset, value)
			for i = 0, byteCount - 1 do
				local num = 0
				for j, bool in value do
					num += bit32.lshift(bool and 1 or 0, j - 1)
				end
				buffer.writeu8(buff, offset + i, num)
			end
			return offset + byteCount
		end,
		des = function(buff, offset)
			local fields = {}
			for i = 0, byteCount - 1 do
				for j = 0, 7 do
					local num = buffer.readu8(buff, offset + i)
					table.insert(fields, bit32.band(bit32.rshift(num, j), 1) == 1)
				end
			end
			return offset + byteCount, fields
		end,
		size = function(value)
			return byteCount
		end,
	})
end

function ByteWorks.vector3(serDesType)
	local size = serDesType.size()
	local totalSize = size * 3
	
	return table.freeze({
		ser = function(buff, offset, value)
			serDesType.ser(buff, offset, value.X)
			offset += size
			serDesType.ser(buff, offset, value.Y)
			offset += size
			serDesType.ser(buff, offset, value.Z)
			offset += size
			return offset
		end,
		des = function(buff, offset)
			return offset + totalSize, Vector3.new(
				select(2, serDesType.des(buff, offset)),
				select(2, serDesType.des(buff, offset + size)),
				select(2, serDesType.des(buff, offset + size * 2))
			)
		end,
		size = function(value)
			return totalSize
		end,
	})
end

function ByteWorks.vector3XZ(serDesType)
	local size = serDesType.size()
	local totalSize = size * 2
	
	return table.freeze({
		ser = function(buff, offset, value)
			serDesType.ser(buff, offset, value.X)
			offset += size
			serDesType.ser(buff, offset, value.Z)
			offset += size
			return offset
		end,
		des = function(buff, offset)
			return offset + totalSize, Vector3.new(
				select(2, serDesType.des(buff, offset)),
				0,
				select(2, serDesType.des(buff, offset + size))
			)
		end,
		size = function(value)
			return totalSize
		end,
	})
end

ByteWorks.color3 = table.freeze({
	ser = function(buff, offset, value)
		writef16(buff, offset, value.X)
		offset += 2
		writef16(buff, offset, value.X)
		offset += 2
		writef16(buff, offset, value.X)
		offset += 2
		return offset
	end,
	des = function(buff, offset)
		return offset + 6, Color3.new(
			readf16(buff, offset),
			readf16(buff, offset + 2),
			readf16(buff, offset + 4)
		)
	end,
	size = function(value)
		return 6 --3 f16s
	end,
})

ByteWorks.cframe = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef32(buff, offset, value.X)
		offset += 4
		buffer.writef32(buff, offset, value.Y)
		offset += 4
		buffer.writef32(buff, offset, value.Z)
		offset += 4
		
		local rotX, rotY, rotZ = value:ToOrientation()
		writef16(buff, offset, rotX)
		offset += 2
		writef16(buff, offset, rotY)
		offset += 2
		writef16(buff, offset, rotZ)
		offset += 2
		return offset
	end,
	des = function(buff, offset, value)
		return offset + 18, CFrame.new(
			buffer.readf32(buff, offset),
			buffer.readf32(buff, offset + 4),
			buffer.readf32(buff, offset + 8)
		) * CFrame.fromOrientation(
			readf16(buff, offset + 12),
			readf16(buff, offset + 14),
			readf16(buff, offset + 16)
		)
	end,
	size = function(value)
		return 18
	end,
})

function ByteWorks.bitfield(serDesType, bitCounts)
	local sizeInBits = serDesType.size() * 8

	return table.freeze({
		ser = function(buff, offset, values)
			local bit32bor = 0
			local cursor = offset + sizeInBits

			for i, bitCount in bitCounts do
				cursor -= bitCount
				bit32bor = bit32.bor(bit32bor, bit32.lshift(values[i], cursor))
			end
			
			serDesType.ser(buff, offset, bit32bor)
			return offset + serDesType.size()
		end,
		des = function(buff, offset)
			local _, packed = serDesType.des(buff, offset)
			local cursor = offset + sizeInBits
			local values = {}

			for i, bitCount in bitCounts do
				cursor -= bitCount
				values[i] = bit32.rshift(bit32.band(packed, bit32.lshift(bit32.lshift(1, bitCount) - 1, cursor)), cursor)
			end
			
			return offset + serDesType.size(), values
		end,
		size = function(value)
			return serDesType.size()
		end,
	})
end

--if it works it works
function ByteWorks.optional(serDesType)
	local clone = table.clone(serDesType)
	clone.optionalFlag = true
	return clone
end

--quick and dirty wrapper method to convert tuple I/O to table I/O
--if you want optimal performance you should copy and modify the methods using tuples to natively use table I/O
--boolean is a tuple so its easy to only use a single boolean without having it be a table filled with 7 other booleans defaulting to false (for stuff like {thing = true})
function ByteWorks.tupleIOToTable(serDesType)
	return table.freeze({
		ser = function(buff, offset, value)
			return serDesType.ser(buff, offset, table.unpack(value))
		end,
		des = function(buff, offset)
			local result = table.pack(serDesType.des(buff, offset))
			local cursor = table.remove(result, 1)
			result.n = nil --get outta here!!!
			return cursor, result
		end,
		size = serDesType.size
	})
end

--why not
function ByteWorks.tableIOToTuple(serDesType)
	return table.freeze({
		ser = function(buff, offset, ...)
			return serDesType.ser(buff, offset, {...})
		end,
		des = function(buff, offset)
			local cursor, result = serDesType.des(buff, offset)
			return cursor, table.unpack(result)
		end,
		size = serDesType.size
	})
end

function ByteWorks.tuple(...)
	local types = {...}
	return table.freeze({
		ser = function(buff, offset, ...)
			local cursor = offset + 0
			for i, value in {...} do
				cursor = types[i].ser(buff, cursor, value)
			end
			return cursor
		end,
		des = function(buff, offset)
			local cursor = offset + 0
			local result = {}
			for i, serDesType in types do
				cursor, result[i] = serDesType.des(buff, cursor)
			end
			return cursor, table.unpack(result)
		end,
		size = function()
			local totalSize = 0
			for _, serDesType in types do
				totalSize += serDesType.size()
			end
			return totalSize
		end,
	})
end

function ByteWorks.enum(...)
	local enums = {...}
	if #enums > 255 then --dont shout at me for not making use of index 0
		error("cannot have more than 255 enums")
	end
	
	return table.freeze({
		ser = function(buff, offset, value)
			buffer.writeu8(buff, offset, table.find(enums, value))
			return offset + 1
		end,
		des = function(buff, offset)
			return offset + 1, enums[buffer.readu8(buff, offset)]
		end,
		size = function()
			return 1
		end,
		
	})
end

function ByteWorks.array(serDesType, sizeIndicator)
	local sizeIndicatorType = 
		sizeIndicator == 1 and ByteWorks.u8 or
		sizeIndicator == 2 and ByteWorks.u16 or
		sizeIndicator == 3 and ByteWorks.u24 or
		sizeIndicator == 4 and ByteWorks.u32
	
	if not sizeIndicator then
		error("size indicator was not specified or was not 1, 2, 3 or 4 (bytes)")
	end
	
	return table.freeze({
		ser = function(buff, offset, elements)
			sizeIndicatorType.ser(buff, offset, #elements)
			local cursor = offset + sizeIndicator

			for _, element in elements do
				cursor = serDesType.ser(buff, cursor, element)
			end
			
			return cursor
		end,
		des = function(buff, offset)
			local _, count = sizeIndicatorType.des(buff, offset)
			local cursor = offset + sizeIndicator
			local elements = {}
			
			for i = 1, count do
				cursor, elements[i] = serDesType.des(buff, cursor)
			end

			return cursor, elements
		end,
		size = function(value)
			return serDesType.size(value[1]) * #value + sizeIndicator
		end,
	})
end

--no size indicator overhead!!
function ByteWorks.fixedSizeArray(serDesType, fixedSize)
	return table.freeze({
		ser = function(buff, offset, elements)
			local cursor = offset

			for _, element in elements do
				cursor = serDesType.ser(buff, cursor, element)
			end

			return offset + fixedSize
		end,
		des = function(buff, offset)
			local cursor = offset
			local elements = {}

			for i = 1, fixedSize do
				cursor, elements[i] = serDesType.des(buff, cursor)
			end

			return offset + fixedSize, elements
		end,
		size = function(value)
			return serDesType.size(value[1]) * fixedSize
		end,
	})
end

function ByteWorks.struct(fields)
	local order = {}
	for field in fields do
		table.insert(order, field)
	end
	
	return table.freeze({
		ser = function(buff, offset, value)
			local cursor = offset

			for _, field in order do
				local serDesType = fields[field]
				cursor = serDesType.ser(buff, cursor, value[field])
			end

			return cursor
		end,
		des = function(buff, offset)
			local cursor = offset
			local elements = {}

			for _, field in order do
				local serDesType = fields[field]
				cursor, elements[field] = serDesType.des(buff, cursor)
			end

			return cursor, elements
		end,
		size = function(value)
			local totalSize = 0
			
			for _, field in order do
				local serDesType = fields[field]
				totalSize += serDesType.size(value[field])
			end

			return totalSize
		end,
	})
end

function ByteWorks.optionalStruct(fields)
	local order = {}
	local optionalFields = {}
	local optionalCount = 0

	for fieldName, field in fields do
		table.insert(order, fieldName)
		if field.optionalFlag then
			table.insert(optionalFields, fieldName)
			optionalCount += 1
		end
	end
	
	if optionalCount == 0 then
		warn("using optional struct with no optionals is slower than just using a struct")
	end

	local optionalBytes = math.ceil(optionalCount / 8)
	return table.freeze({
		ser = function(buff, offset, value)
			local bitmap = 0
			local cursor = offset + optionalBytes

			for i, fieldName in optionalFields do
				if value[fieldName] ~= nil then
					bitmap = bit32.bor(bitmap, bit32.lshift(1, i - 1))
				end
			end

			for i = 1, optionalBytes do
				buffer.writeu8(buff, offset + i - 1, bit32.band(bit32.rshift(bitmap, (i - 1) * 8), 0xFF))
			end

			for _, fieldName in order do
				local serDesType = fields[fieldName]
				if not serDesType.optionalFlag or value[fieldName] ~= nil then
					cursor = serDesType.ser(buff, cursor, value[fieldName])
				end
			end

			return cursor
		end,

		des = function(buff, offset)
			local cursor = offset + optionalBytes
			local elements = {}

			local bitmap = 0
			for i = optionalBytes, 1, -1 do
				bitmap = bit32.bor(bit32.lshift(bitmap, 8), buffer.readu8(buff, offset + i - 1))
			end

			local optionalIndex = 0
			for _, fieldName in order do
				local serDesType = fields[fieldName]
				if serDesType.optionalFlag then
					optionalIndex += 1
					if bit32.band(bitmap, bit32.lshift(1, optionalIndex - 1)) ~= 0 then
						cursor, elements[fieldName] = serDesType.des(buff, cursor)
					end
				else
					cursor, elements[fieldName] = serDesType.des(buff, cursor)
				end
			end

			return cursor, elements
		end,

		size = function(value)
			local totalSize = optionalBytes

			for _, fieldName in order do
				local serDesType = fields[fieldName]
				if not serDesType.optionalFlag or value[fieldName] ~= nil then
					totalSize += serDesType.size(value[fieldName])
				end
			end

			return totalSize
		end,
	})
end

function ByteWorks.map(keyType, valueType)
	return table.freeze({
		ser = function(buff, offset, value)
			local cursor = offset + 1
			local elementCount = 0
			for k, v in value do
				cursor = keyType.ser(buff, cursor, k)
				cursor = valueType.ser(buff, cursor, v)
				elementCount += 1
			end
			
			buffer.writeu8(buff, offset, elementCount)
			return cursor
		end,
		des = function(buff, offset)
			local elementCount = buffer.readu8(buff, offset)
			local cursor = offset + 1
			
			local map = {}
			for i = 1, elementCount do
				local key, value
				cursor, key = keyType.des(buff, cursor)
				cursor, value = valueType.des(buff, cursor)
				map[key] = value
			end
			
			return cursor, map
		end,
		size = function(value)
			local totalSize = 0
			for k, v in value do
				totalSize += keyType.size(k) + valueType.size(k)
			end
			return totalSize + 1
		end,
	})
end

--quick benchmarks show that the difference between this and a seperate implementation is insignificant
ByteWorks.boolean = ByteWorks.tableIOToTuple(ByteWorks.bitmask(8))

--if u want multiple buffers together u can just do
--buffer.create(type1.size(value1) + type2.size(value2))
function ByteWorks.createBufferFromType(serDesType, value)
	return buffer.create(serDesType.size(value))
end

--just do local _, result = ByteWorks[...].des(...) lol
function ByteWorks.resultExcludingCursor(serDesType, buff, offset)
	return select(2, serDesType.des(buff, offset))
end

function ByteWorks.createAndSerialize(serDesType, offset, value)
	local buff = buffer.create(serDesType.size(value))
	serDesType.ser(buff, offset, value)
	return buff
end

return ByteWorks
