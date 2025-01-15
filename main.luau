--!native
--!strict

local ByteWorks = {}
--writef16 and readf16 taken from Blink by Axen ngl

export type ByteWorksType<T...> = {
	ser: (buff: buffer, offset: number, T...) -> number,
	des: (buff: buffer, offset: number) -> (number, T...),
	size: (T...) -> number,
	optionalFlag: boolean?
}

local function writei24(buff: buffer, offset: number, value: number): ()
	if value < 0 then
		value = value + 16777216
	end
	buffer.writeu16(buff, offset, value / 256)
	buffer.writeu8(buff, offset + 2, value % 256)
end

local function readi24(buff: buffer, offset: number): number
	local value: number = 256 * buffer.readu16(buff, offset) + buffer.readu8(buff, offset + 2)
	if value >= 8388608 then
		return value - 16777216
	end
	return value
end

local function writeu24(buff: buffer, offset: number, value: number): ()
	buffer.writeu16(buff, offset, value / 256)
	buffer.writeu8(buff, offset + 2, value)
end

local function readu24(buff: buffer, offset: number): number
	return 256 * buffer.readu16(buff, offset) + buffer.readu8(buff, offset + 2)
end

local function writeu53(buff: buffer, offset: number, value: number): ()
	buffer.writeu32(buff, offset, value / 16777216)
	writeu24(buff, offset + 4, value)
end

local function readu53(buff: buffer, offset: number): number
	return 16777216 * buffer.readu32(buff, offset) + readu24(buff, offset + 4)
end

local function writei53(buff: buffer, offset: number, value: number): ()
	if value < 0 then
		value = value + 9007199254740992
	end
	buffer.writeu32(buff, offset, value / 16777216)
	writeu24(buff, offset + 4, value % 16777216)
end

local function readi53(buff: buffer, offset: number): number
	local value: number = 16777216 * buffer.readu32(buff, offset) + readu24(buff, offset + 4)
	if value >= 4503599627370496 then
		value = value - 9007199254740992
	end
	return value
end

local function writef16(buff: buffer, offset: number, value: number): ()
	if value > 65504 then
		buffer.writeu16(buff, offset, 0b0_11111_0000000000)
	elseif value < -65504 then
		buffer.writeu16(buff, offset, 0b1_11111_0000000000)
	elseif value ~= value then
		error("value cannot be NaN")
	elseif value == 0 then
		buffer.writeu16(buff, offset, 0)
	else
		local float: number = value
		local absolute: number = math.abs(float)
		local interval: number = math.ldexp(1, math.floor(math.log(absolute, 2)) - 10)
		local roundedValue: number = (absolute // interval) * interval
		local fraction: number, exponent: number = math.frexp(roundedValue)

		exponent += 14
		local mantissa: number = math.round(if exponent <= 0
			then fraction * 0x400 / math.ldexp(1, math.abs(exponent))
			else fraction * 0x800) % 0x400
		local result: number = mantissa
			+ math.max(exponent, 0) * 0x400
			+ if float < 0 then 0x8000 else 0
		buffer.writeu16(buff, offset, result)
	end
end

local function readf16(buff: buffer, offset: number): number
	local encoded: number = buffer.readu16(buff, offset)
	local mantissaExponent: number = encoded % 0x8000

	local value: number
	if mantissaExponent == 0b0_11111_0000000000 then
		if encoded // 0x8000 == 1 then
			value = -math.huge
		else
			value = math.huge
		end
	elseif mantissaExponent == 0b1_11111_0000000000 or mantissaExponent == 0b0_00000_0000000000 then
		value = 0
	else
		local mantissa: number = mantissaExponent % 0x400
		local exponent: number = mantissaExponent // 0x400
		local fraction: number

		if exponent == 0 then
			fraction = mantissa / 0x400
		else
			fraction = mantissa / 0x800 + 0.5
		end

		local result: number = math.ldexp(fraction, exponent - 14)
		return if encoded // 0x8000 == 1 then -result else result
	end

	return value
end

--unsigned integers
ByteWorks.u8 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu8(buff, offset, value)
		return offset + 1
	end,
	des = function(buff, offset: number)
		return offset + 1, buffer.readu8(buff, offset)
	end,
	size = function(value)
		return 1
	end,
}) :: ByteWorksType<number>
ByteWorks.u16 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset: number)
		return offset + 2, buffer.readu16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
}) :: ByteWorksType<number>
ByteWorks.u24 = table.freeze({
	ser = function(buff, offset, value)
		writeu24(buff, offset, value)
		return offset + 3
	end,
	des = function(buff, offset: number)
		return offset + 3, readu24(buff, offset)
	end,
	size = function(value)
		return 3
	end,
}) :: ByteWorksType<number>
ByteWorks.u32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset: number)
		return offset + 4, buffer.readu32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
}) :: ByteWorksType<number>

ByteWorks.u53 = table.freeze({
	ser = function(buff, offset, value)
		writeu53(buff, offset, value)
		return offset + 7
	end,
	des = function(buff, offset: number)
		return offset + 7, readu53(buff, offset)
	end,
	size = function(value)
		return 7
	end,
}) :: ByteWorksType<number>

--signed integers
ByteWorks.i8 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei8(buff, offset, value)
		return offset + 1
	end,
	des = function(buff, offset: number)
		return offset + 1, buffer.readi8(buff, offset)
	end,
	size = function(value)
		return 1
	end,
}) :: ByteWorksType<number>
ByteWorks.i16 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset: number)
		return offset + 2, buffer.readi16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
}) :: ByteWorksType<number>
ByteWorks.i24 = table.freeze({
	ser = function(buff, offset, value)
		writei24(buff, offset, value)
		return offset + 3
	end,
	des = function(buff, offset: number)
		return offset + 3, readi24(buff, offset)
	end,
	size = function(value)
		return 3
	end,
}) :: ByteWorksType<number>
ByteWorks.i32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writei32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset: number)
		return offset + 4, buffer.readi32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
}) :: ByteWorksType<number>
ByteWorks.i53 = table.freeze({
	ser = function(buff, offset, value)
		writei53(buff, offset, value)
		return offset + 7
	end,
	des = function(buff, offset: number)
		return offset + 7, readi53(buff, offset)
	end,
	size = function(value)
		return 7
	end,
}) :: ByteWorksType<number>

--floating point numbers
ByteWorks.f16 = table.freeze({
	ser = function(buff, offset, value)
		writef16(buff, offset, value)
		return offset + 2
	end,
	des = function(buff, offset: number)
		return offset + 2, readf16(buff, offset)
	end,
	size = function(value)
		return 2
	end,
}) :: ByteWorksType<number>
ByteWorks.f32 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef32(buff, offset, value)
		return offset + 4
	end,
	des = function(buff, offset: number)
		return offset + 4, buffer.readf32(buff, offset)
	end,
	size = function(value)
		return 4
	end,
}) :: ByteWorksType<number>
ByteWorks.f64 = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef64(buff, offset, value)
		return offset + 8
	end,
	des = function(buff, offset: number)
		return offset + 8, buffer.readf64(buff, offset)
	end,
	size = function(value)
		return 8
	end,
}) :: ByteWorksType<number>

--variable length unsigned integers
ByteWorks.vlq = table.freeze({
	ser = function(buff, offset, value)
		repeat
			local byte: number = bit32.band(value, 0x7F) 
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
		local result: number = 0
		local shift: number = 0
		local byte: number

		repeat
			byte = buffer.readu8(buff, offset)
			offset += 1
			result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), shift))
			shift += 7
		until bit32.band(byte, 0x80) == 0

		return offset, result
	end,
	size = function(value)
		local bytes: number = 0

		repeat
			value = bit32.rshift(value, 7)
			bytes += 1
		until value == 0

		return bytes
	end,
}) :: ByteWorksType<number>

--variable length signed integers
ByteWorks.svlq = table.freeze({
	ser = function(buff, offset, value)
		local zigzagValue: number = bit32.bxor(bit32.lshift(value, 1), bit32.arshift(value, 31))

		repeat
			local byte: number = bit32.band(zigzagValue, 0x7F)
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
		local result: number = 0
		local shift: number = 0
		local byte: number

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
}) :: ByteWorksType<number>

function ByteWorks.string(count: number): ByteWorksType<string>
	return table.freeze({
		ser = function(buff, offset, value)
			buffer.writestring(buff, offset, value, count)
			return offset + count
		end,
		des = function(buff, offset: number)
			return offset + count, buffer.readstring(buff, offset, count)
		end,
		size = function(value)
			return count
		end,
	})
end

ByteWorks.vstring = table.freeze({
	ser = function(buff, offset, value)
		local len = value:len()
		offset = ByteWorks.vlq.ser(buff, offset, len)
		buffer.writestring(buff, offset, value)
		return offset
	end,
	des = function(buff, offset)
		local len
		offset, len = ByteWorks.vlq.des(buff, offset)
		return offset + len, buffer.readstring(buff, offset, len)
	end,
	size = function(value)
		local len = value:len()
		return ByteWorks.vlq.size(len) + len
	end,
}) :: ByteWorksType<string>

function ByteWorks.bitmask(bitCount: number): ByteWorksType<{boolean}>
	local byteCount: number = math.ceil(bitCount / 8)
	return table.freeze({
		ser = function(buff, offset: number, value)
			for i: number = 0, byteCount - 1 do
				local num: number = 0
				for j: number, bool: boolean in value do
					num += bit32.lshift(bool and 1 or 0, j - 1)
				end
				buffer.writeu8(buff, offset + i, num)
			end
			return offset + byteCount
		end,
		des = function(buff, offset: number)
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

function ByteWorks.vector3(serDesType: ByteWorksType<number>): ByteWorksType<Vector3>
	local size: number = serDesType.size(0)
	local totalSize: number = size * 3

	return table.freeze({
		ser = function(buff, offset, value: Vector3)
			serDesType.ser(buff, offset, value.X)
			offset += size
			serDesType.ser(buff, offset, value.Y)
			offset += size
			serDesType.ser(buff, offset, value.Z)
			offset += size
			return offset
		end,
		des = function(buff, offset: number)
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

function ByteWorks.vector3XZ(serDesType: ByteWorksType<number>): ByteWorksType<Vector3>
	local size: number = serDesType.size(0)
	local totalSize: number = size * 2

	return table.freeze({
		ser = function(buff, offset, value: Vector3)
			serDesType.ser(buff, offset, value.X)
			offset += size
			serDesType.ser(buff, offset, value.Z)
			offset += size
			return offset
		end,
		des = function(buff, offset: number)
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
	ser = function(buff, offset, value: Color3)
		writef16(buff, offset, value.R)
		offset += 2
		writef16(buff, offset, value.G)
		offset += 2
		writef16(buff, offset, value.B)
		offset += 2
		return offset
	end,
	des = function(buff, offset: number)
		return offset + 6, Color3.new(
			readf16(buff, offset),
			readf16(buff, offset + 2),
			readf16(buff, offset + 4)
		)
	end,
	size = function(value)
		return 6 --3 f16s
	end,
}) :: ByteWorksType<Color3>

ByteWorks.cframe = table.freeze({
	ser = function(buff, offset, value)
		buffer.writef32(buff, offset, value.X)
		offset += 4
		buffer.writef32(buff, offset, value.Y)
		offset += 4
		buffer.writef32(buff, offset, value.Z)
		offset += 4

		local rotX: number, rotY: number, rotZ: number = value:ToOrientation()
		writef16(buff, offset, rotX)
		offset += 2
		writef16(buff, offset, rotY)
		offset += 2
		writef16(buff, offset, rotZ)
		offset += 2

		return offset
	end,

	des = function(buff, offset)
		local posX: number = buffer.readf32(buff, offset)
		offset += 4
		local posY: number = buffer.readf32(buff, offset)
		offset += 4
		local posZ: number = buffer.readf32(buff, offset)
		offset += 4

		local rotX: number = readf16(buff, offset)
		offset += 2
		local rotY: number = readf16(buff, offset)
		offset += 2
		local rotZ: number = readf16(buff, offset)
		offset += 2

		return offset, CFrame.new(posX, posY, posZ) * CFrame.fromOrientation(rotX, rotY, rotZ)
	end,

	size = function(value)
		return 18
	end,
}) :: ByteWorksType<CFrame>

function ByteWorks.bitfield(serDesType: ByteWorksType<number>, bitCounts: {number}): ByteWorksType<{number}>
	local size: number = serDesType.size(0)
	local sizeInBits: number = size * 8
	local masks: {number} = {}

	for i: number, bitCount: number in bitCounts do
		masks[i] = bit32.lshift(1, bitCount) - 1
	end

	return table.freeze({
		ser = function(buff, offset, value)
			local packedValue: number = 0
			local curentBitPosition: number = sizeInBits

			for i: number, bitCount: number in bitCounts do
				curentBitPosition -= bitCount
				packedValue = bit32.bor(packedValue, bit32.lshift(value[i], curentBitPosition))
			end

			serDesType.ser(buff, offset, packedValue)
			return offset + size
		end,
		des = function(buff, offset)
			local _, packedValue: number = serDesType.des(buff, offset)
			local currentBitPosition: number = sizeInBits
			local values: {number} = {}

			for i: number, bitCount: number in bitCounts do
				currentBitPosition -= bitCount
				local value: number = bit32.rshift(packedValue, currentBitPosition)
				values[i] = bit32.band(value, masks[i])
			end

			return offset + size, values
		end,
		size = function(value)
			return size
		end,
	})
end

function ByteWorks.buffer(size: number): ByteWorksType<buffer>
	return table.freeze({
		ser = function(buff, offset, value)
			buffer.copy(buff, offset, value, 0, size)
			return offset + size
		end,
		des = function(buff, offset: number)
			local newBuffer = buffer.create(size)
			buffer.copy(newBuffer, 0, buff, offset, size)
			return offset + size, newBuffer
		end,
		size = function(value)
			return size
		end,
	})
end

--if it works it works
function ByteWorks.optional<T>(serDesType: ByteWorksType<T>)
	local clone: ByteWorksType<T> = table.clone(serDesType)
	clone.optionalFlag = true
	return clone
end

--quick and dirty wrapper method to convert tuple I/O to table I/O
--if you want optimal performance you should copy and modify the methods using tuples to natively use table I/O
--boolean is a tuple so its easy to only use a single boolean without having it be a table filled with 7 other booleans defaulting to false (for stuff like {thing = true})
function ByteWorks.tupleIOToTable(serDesType: ByteWorksType<...any>): ByteWorksType<any>
	return table.freeze({
		ser = function(buff, offset, value)
			return serDesType.ser(buff, offset, table.unpack(value))
		end,
		des = function(buff, offset)
			local result: {any} & {n: number | nil} = table.pack(serDesType.des(buff, offset))
			local cursor: number = table.remove(result, 1) :: number
			result.n = nil --get outta here!!!
			return cursor, result
		end,
		size = serDesType.size
	})
end

--why not
function ByteWorks.tableIOToTuple(serDesType: ByteWorksType<any>): ByteWorksType<...any>
	return table.freeze({
		ser = function(buff, offset, ...)
			return serDesType.ser(buff, offset, {...})
		end,
		des = function(buff, offset)
			local cursor: number, result: any = serDesType.des(buff, offset)
			return cursor, table.unpack(result)
		end,
		size = serDesType.size
	})
end

function ByteWorks.tuple(...: ByteWorksType<any>): ByteWorksType<any>
	local types: {ByteWorksType<any>} = {...}
	return table.freeze({
		ser = function(buff, offset, ...)
			local cursor: number = offset
			for i: number, value: any in {...} do
				cursor = types[i].ser(buff, cursor, value)
			end
			return cursor
		end,
		des = function(buff, offset)
			local cursor: number = offset
			local result: {any} = {}
			for i: number, serDesType: ByteWorksType<any> in types do
				cursor, result[i] = serDesType.des(buff, cursor)
			end
			return cursor, table.unpack(result)
		end,
		size = function(...)
			local totalSize: number = 0
			for i, value in {...} do
				totalSize += types[i].size(value)
			end
			return totalSize
		end,
	})
end

function ByteWorks.literal<T>(...: T): ByteWorksType<T>
	local enums: {T} = {...}
	if #enums > 255 then --dont shout at me for not making use of index 0
		error("cannot have more than 255 literals")
	end

	return table.freeze({
		ser = function(buff, offset, value)
			buffer.writeu8(buff, offset, table.find(enums, value) :: number)
			return offset + 1
		end,
		des = function(buff, offset: number)
			return offset + 1, enums[buffer.readu8(buff, offset)]
		end,
		size = function()
			return 1
		end,
	})
end

function ByteWorks.taggedEnum(enums: {[any]: ByteWorksType<any>}): ByteWorksType<any>
	local enumsAsInts = {}
	local n = 1
	for enum in enums do
		enumsAsInts[n] = enum
		n += 1
	end

	return table.freeze({
		ser = function(buff, offset: number, value)
			local startOffset = offset
			offset += 1

			local totalCount = 0
			for key, realValue in value do
				local position = table.find(enumsAsInts, key) :: number
				buffer.writeu8(buff, offset, position)
				offset = enums[key].ser(buff, offset + 1, realValue)
				totalCount += 1
			end

			buffer.writeu8(buff, startOffset, totalCount)
			return offset
		end,
		des = function(buff, offset)
			local totalCount = buffer.readu8(buff, offset)
			offset += 1

			local results = {}
			for i = 1, totalCount do
				local key = enumsAsInts[buffer.readu8(buff, offset)]
				offset += 1

				local value
				offset, value = enums[key].des(buff, offset)
				results[key] = value
			end

			return offset, results
		end,
		size = function(value)
			local totalSize = 1
			for key, realValue in value do
				totalSize += enums[key].size(realValue) + 1
			end
			return totalSize
		end,
	})
end

function ByteWorks.enum(enum): ByteWorksType<any>
	local highestValue = 0
	for _, enumItem in enum:GetEnumItems() do
		if enumItem.Value > highestValue then
			highestValue = enumItem.Value
		end
	end

	local numberType: ByteWorksType<number> = highestValue > 255 and ByteWorks.u16 or ByteWorks.u8
	local size = numberType.size(0)
	
	return table.freeze({
		ser = function(buff, offset, value: EnumItem)
			return numberType.ser(buff, offset, value.Value)
		end,
		des = function(buff, offset)
			local value: number
			offset, value = numberType.des(buff, offset)
			local enumItem: EnumItem? = enum:FromValue(value)
			return offset, enumItem
		end,
		size = function(value)
			return size
		end,
	})
end

function ByteWorks.array<T>(serDesType: ByteWorksType<T>): ByteWorksType<{T}>
	return table.freeze({
		ser = function(buff, offset, value: {T})
			offset = ByteWorks.vlq.ser(buff, offset, #value)
			local cursor: number = offset

			for _, element: T in value do
				cursor = serDesType.ser(buff, cursor, element)
			end

			return cursor
		end,
		des = function(buff, offset)
			local count: number
			offset, count = ByteWorks.vlq.des(buff, offset)
			local cursor: number = offset
			local elements: {T} = {}

			for i: number = 1, count do
				cursor, elements[i] = serDesType.des(buff, cursor)
			end

			return cursor, elements
		end,
		size = function(value)
			return serDesType.size(value[1]) * #value + ByteWorks.vlq.size(#value)
		end,
	})
end

--no size indicator overhead!!
function ByteWorks.fixedSizeArray<T>(serDesType: ByteWorksType<T>, fixedSize: number): ByteWorksType<{T}>
	return table.freeze({
		ser = function(buff, offset, value)
			local cursor: number = offset

			for _, element: T in value do
				cursor = serDesType.ser(buff, cursor, element)
			end

			return offset + fixedSize
		end,
		des = function(buff, offset)
			local cursor = offset
			local value = {}

			for i = 1, fixedSize do
				cursor, value[i] = serDesType.des(buff, cursor)
			end

			return offset + fixedSize, value
		end,
		size = function(value)
			return serDesType.size(value[1]) * fixedSize
		end,
	})
end

function ByteWorks.mixedBufferArray(assignedSizes: {[number]: ByteWorksType<any>}): ByteWorksType<any>
	local sizes: {number} = {}
	local sizeMap: {number} = {}

	local n: number = 1
	for size: number in assignedSizes do
		sizes[n] = size
		sizeMap[size] = n
		n += 1
	end

	local bits: number = math.ceil(math.log(n, 2))
	local entriesPerByte: number = math.floor(8 / bits)
	if n > 8 or n == 0 then
		error("Number of types must be between 1 and 8")
	end

	local masks: {number} = {}
	for j = 0, entriesPerByte - 1 do
		masks[j] = bit32.lshift(2^bits - 1, j * bits)
	end

	local entriesPerByte: number = math.floor(8 / bits)
	return table.freeze({
		ser = function(buff, offset, value)
			offset += ByteWorks.vlq.ser(buff, offset, #value)
			local totalBitFields: number = math.ceil(#value / entriesPerByte)
			for i = 1, totalBitFields do
				local bitFieldOffset = offset
				offset += 1

				local bitFlag = 0
				for j = 0, entriesPerByte - 1 do
					local index = (i - 1) * entriesPerByte + j + 1
					local currentValue = value[index]
					if not currentValue then
						break
					end

					local size = buffer.len(currentValue)
					local sizeIndex = sizeMap[size] - 1
					bitFlag = bit32.bor(bitFlag, bit32.lshift(sizeIndex, j * bits))
					buffer.copy(buff, offset, currentValue, 0)
					offset += size
				end

				buffer.writeu8(buff, bitFieldOffset, bitFlag)
			end

			return offset
		end,

		des = function(buff, offset)
			local entries: number
			offset, entries = ByteWorks.vlq.des(buff, offset)

			local values = {}
			local addedEntries = 0

			local totalBitFields = math.ceil(entries / entriesPerByte)
			for i = 1, totalBitFields do
				local bitFieldOffset = offset
				offset += 1
				local bitFlag = buffer.readu8(buff, bitFieldOffset)

				for j = 0, entriesPerByte - 1 do
					local sizeIndex = bit32.rshift(bit32.band(bitFlag, masks[j]), j * bits) + 1
					local size = sizes[sizeIndex]
					local _, result = assignedSizes[size].des(buff, offset)
					table.insert(values, result)
					addedEntries += 1
					offset += size

					if addedEntries == entries then
						break
					end
				end
			end

			return offset, values
		end,

		size = function(value: {buffer})
			local totalBitFields = math.ceil(#value / entriesPerByte)
			local totalSize = totalBitFields

			for _, buff in value do
				totalSize += buffer.len(buff)
			end

			return totalSize + ByteWorks.vlq.size(totalBitFields)
		end,
	})
end

function ByteWorks.struct(fields: {[string]: ByteWorksType<any>}): ByteWorksType<{[string]: any}>
	local order: {string} = {}
	for field: string in fields do
		table.insert(order, field)
	end

	return table.freeze({
		ser = function(buff, offset, value)
			local cursor: number = offset

			for _, field: string in order do
				local serDesType: ByteWorksType<any> = fields[field]
				cursor = serDesType.ser(buff, cursor, value[field])
			end

			return cursor
		end,
		des = function(buff, offset)
			local cursor: number = offset
			local elements: {[string]: any} = {}

			for _, field: string in order do
				local serDesType: ByteWorksType<any> = fields[field]
				cursor, elements[field] = serDesType.des(buff, cursor)
			end

			return cursor, elements
		end,
		size = function(value)
			local totalSize: number = 0

			for _, field in order do
				local serDesType: ByteWorksType<any> = fields[field]
				totalSize += serDesType.size(value[field])
			end

			return totalSize
		end,
	})
end

function ByteWorks.optionalStruct(fields: {[string]: ByteWorksType<any>}): ByteWorksType<{[string]: any}>
	local order: {string} = {}
	local optionalFields: {string} = {}
	local optionalCount: number = 0

	for fieldName: string, field: ByteWorksType<any> in fields do
		table.insert(order, fieldName)
		if field.optionalFlag then
			table.insert(optionalFields, fieldName)
			optionalCount += 1
		end
	end

	if optionalCount == 0 then
		warn("using optional struct with no optionals is slower than just using a struct")
	end

	local optionalBytes: number = math.ceil(optionalCount / 8)
	return table.freeze({
		ser = function(buff, offset: number, value)
			local bitmap: number = 0
			local cursor: number = offset + optionalBytes

			for i: number, fieldName: string in optionalFields do
				if value[fieldName] ~= nil then
					bitmap = bit32.bor(bitmap, bit32.lshift(1, i - 1))
				end
			end

			for i: number = 1, optionalBytes do
				buffer.writeu8(buff, offset + i - 1, bit32.band(bit32.rshift(bitmap, (i - 1) * 8), 0xFF))
			end

			for _, fieldName: string in order do
				local serDesType: ByteWorksType<any> = fields[fieldName]
				if not serDesType.optionalFlag or value[fieldName] ~= nil then
					cursor = serDesType.ser(buff, cursor, value[fieldName])
				end
			end

			return cursor
		end,

		des = function(buff, offset: number)
			local cursor: number = offset + optionalBytes
			local elements: {[string]: any} = {}

			local bitmap: number = 0
			for i: number = optionalBytes, 1, -1 do
				bitmap = bit32.bor(bit32.lshift(bitmap, 8), buffer.readu8(buff, offset + i - 1))
			end

			local optionalIndex: number = 0
			for _, fieldName: string in order do
				local serDesType: ByteWorksType<any> = fields[fieldName]
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
			local totalSize: number = optionalBytes

			for _, fieldName: string in order do
				local serDesType: ByteWorksType<any> = fields[fieldName]
				if not serDesType.optionalFlag or value[fieldName] ~= nil then
					totalSize += serDesType.size(value[fieldName])
				end
			end

			return totalSize
		end,
	})
end

function ByteWorks.map<K, V>(keyType: ByteWorksType<K>, valueType: ByteWorksType<V>): ByteWorksType<{[K]: V}>
	return table.freeze({
		ser = function(buff, offset: number, value)
			local cursor: number = offset + 1
			local elementCount: number = 0
			for k: K, v: V in value do
				cursor = keyType.ser(buff, cursor, k)
				cursor = valueType.ser(buff, cursor, v)
				elementCount += 1
			end

			buffer.writeu8(buff, offset, elementCount)
			return cursor
		end,
		des = function(buff, offset)
			local elementCount: number = buffer.readu8(buff, offset)
			local cursor: number = offset + 1

			local map: {[K]: V} = {}
			for i: number = 1, elementCount do
				local key: K, value: V
				cursor, key = keyType.des(buff, cursor)
				cursor, value = valueType.des(buff, cursor)
				map[key] = value
			end

			return cursor, map
		end,
		size = function(value)
			local totalSize: number = 0
			for k: K, v: V in value do
				totalSize += keyType.size(k) + valueType.size(v)
			end
			return totalSize + 1
		end,
	})
end

--quick benchmarks show that the difference between this and a seperate implementation is insignificant
ByteWorks.boolean = ByteWorks.tableIOToTuple(ByteWorks.bitmask(8)) :: ByteWorksType<...boolean>

--if u want multiple buffers together u can just do
--buffer.create(type1.size(value1) + type2.size(value2))
function ByteWorks.createBufferFromType<T>(serDesType: ByteWorksType<T>, value: T): buffer
	return buffer.create(serDesType.size(value))
end

--just do local _, result = ByteWorks[...].des(...) lol (unless using tuple types)
function ByteWorks.resultExcludingCursor<T>(serDesType: ByteWorksType<T>, buff: buffer, offset: number): ...T
	return select(2, serDesType.des(buff, offset))
end

function ByteWorks.createAndSerialize<T>(serDesType: ByteWorksType<T>, offset: number, ...: T): buffer
	local buff: buffer = buffer.create(serDesType.size(...))
	serDesType.ser(buff, offset, ...)
	return buff
end

return ByteWorks
