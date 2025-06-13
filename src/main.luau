--!native
--!strict
--optimize 2

local ByteWorks = {}

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
	if value ~= value then
		buffer.writeu16(buff, offset, 0x7E01)
		return
	elseif value == 0 then
		buffer.writeu16(buff, offset, 0x0000)
		return
	end

	local sign = 0
	if value < 0 then
		sign = 0x8000
		value = -value
	end

	if value > 65504 then
		buffer.writeu16(buff, offset, bit32.bor(sign, 0x7C00))
		return
	end

	local fraction, exponent = math.frexp(value)
	if exponent < -13 then
		fraction = fraction * math.ldexp(1, exponent + 13)
		exponent = 0
	else
		exponent = exponent + 14
		fraction = (fraction * 2 - 1)
	end

	buffer.writeu16(buff, offset, bit32.bor(
		sign,
		bit32.lshift(exponent, 10),
		fraction * 1024
		))
end

local function readf16(buff: buffer, offset: number): number
	local value = buffer.readu16(buff, offset)

	local banded = bit32.band(value, 0x7C00)
	if value == 0 then
		return (bit32.band(value, 0x8000) ~= 0) and -0 or 0
	elseif value == 0x7C00 then
		return math.huge
	elseif value == 0xFC00 then
		return -math.huge
	elseif (banded == 0x7C00) and (bit32.band(value, 0x03FF) ~= 0) then
		return 0/0
	end

	local sign = bit32.band(value, 0x8000) == 0 and 1 or -1
	local exponent = bit32.rshift(banded, 10)
	local fraction = bit32.band(value, 0x03FF) / 1024

	if exponent == 0 then
		return sign * math.ldexp(fraction, -14)
	else
		return sign * math.ldexp(1 + fraction, exponent - 15)
	end
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

		local decoded = bit32.arshift(result, 1)
		if bit32.band(result, 1) ~= 0 then 
			decoded = -decoded - 1
		end
		return offset, decoded
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

ByteWorks.string = table.freeze({
	ser = function(buff, offset, value)
		local len = string.len(value)
		offset = ByteWorks.vlq.ser(buff, offset, len)
		buffer.writestring(buff, offset, value)
		return offset + len
	end,
	des = function(buff, offset)
		local len
		offset, len = ByteWorks.vlq.des(buff, offset)
		return offset + len, buffer.readstring(buff, offset, len)
	end,
	size = function(value)
		local len = string.len(value)
		return ByteWorks.vlq.size(len) + len
	end,
}) :: ByteWorksType<string>

function ByteWorks.bitmask(bitCount: number): ByteWorksType<{boolean}>
	local byteCount = math.ceil(bitCount / 8)
	return table.freeze({
		ser = function(buff, offset: number, value)
			for i = 0, byteCount - 1 do
				local num = 0
				for j, bool in value do
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
	local totalSize = serDesType.size(0) * 3

	local innerSer = serDesType.ser
	local innerDes = serDesType.des

	return table.freeze({
		ser = function(buff, offset, value: Vector3)
			offset = innerSer(buff, offset, value.X)
			offset = innerSer(buff, offset, value.Y)
			offset = innerSer(buff, offset, value.Z)
			return offset
		end,
		des = function(buff, offset: number)
			local x, y, z
			offset, x = innerDes(buff, offset)
			offset, y = innerDes(buff, offset)
			offset, z = innerDes(buff, offset)
			return offset, Vector3.new(x, y, z)
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
		return offset + 2
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

		local rotX, rotY, rotZ = value:ToOrientation()
		writef16(buff, offset, rotX)
		offset += 2
		writef16(buff, offset, rotY)
		offset += 2
		writef16(buff, offset, rotZ)
		offset += 2

		return offset
	end,

	des = function(buff, offset)
		local posX = buffer.readf32(buff, offset)
		offset += 4
		local posY = buffer.readf32(buff, offset)
		offset += 4
		local posZ = buffer.readf32(buff, offset)
		offset += 4

		local rotX = readf16(buff, offset)
		offset += 2
		local rotY = readf16(buff, offset)
		offset += 2
		local rotZ = readf16(buff, offset)
		offset += 2

		return offset, CFrame.new(posX, posY, posZ) * CFrame.fromOrientation(rotX, rotY, rotZ)
	end,

	size = function(value)
		return 18
	end,
}) :: ByteWorksType<CFrame>

function ByteWorks.bitfield(serDesType: ByteWorksType<number>, bitCounts: {number}): ByteWorksType<{number}>
	local size = serDesType.size(0)
	local innerSer = serDesType.ser
	local innerDes = serDesType.des
	local sizeInBits = size * 8
	local totalEntries = #bitCounts
	local masks: {number} = {}

	for i, bitCount in bitCounts do
		masks[i] = bit32.lshift(1, bitCount) - 1
	end

	return table.freeze({
		ser = function(buff, offset, value)
			local packedValue = 0
			local curentBitPosition = sizeInBits

			for i, bitCount in bitCounts do
				curentBitPosition -= bitCount
				packedValue = bit32.bor(packedValue, bit32.lshift(value[i], curentBitPosition))
			end

			return innerSer(buff, offset, packedValue)
		end,
		des = function(buff, offset)
			local packedValue
			offset, packedValue = innerDes(buff, offset)
			local currentBitPosition = sizeInBits
			local values: {number} = table.create(totalEntries)

			for i, bitCount in bitCounts do
				currentBitPosition -= bitCount
				local value = bit32.rshift(packedValue, currentBitPosition)
				values[i] = bit32.band(value, masks[i])
			end

			return offset, values
		end,
		size = function(value)
			return size
		end,
	})
end

function ByteWorks.fixedSizeBuffer(size: number): ByteWorksType<buffer>
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

ByteWorks.buffer = table.freeze({
	ser = function(buff, offset, value)
		local size = buffer.len(value)
		offset = ByteWorks.vlq.ser(buff, offset, size)
		buffer.copy(buff, offset, value, 0, size)
		return offset + size
	end,
	des = function(buff, offset: number)
		local len
		offset, len = ByteWorks.vlq.des(buff, offset)
		local newBuffer = buffer.create(len)
		buffer.copy(newBuffer, 0, buff, offset, len)
		return offset + len, newBuffer
	end,
	size = function(value)
		local len = buffer.len(value)
		return len + ByteWorks.vlq.size(len)
	end,
}) :: ByteWorksType<buffer>

--if it works it works
function ByteWorks.opt<T>(serDesType: ByteWorksType<T>)
	local clone: ByteWorksType<T> = table.clone(serDesType)
	clone.optionalFlag = true
	return clone
end

--quick and dirty wrapper method to convert tuple I/O to table I/O
--if you want optimal performance you should copy and modify the methods using tuples to natively use table I/O
--boolean is a tuple so its easy to only use a single boolean without having it be a table filled with 7 other booleans defaulting to false (for stuff like {thing = true})
function ByteWorks.tupleIOToTable(serDesType: ByteWorksType<...any>): ByteWorksType<any>
	local innerSer = serDesType.ser
	local innerDes = serDesType.des
	return table.freeze({
		ser = function(buff, offset, value)
			return innerSer(buff, offset, table.unpack(value))
		end,
		des = function(buff, offset)
			local result: {any} & {n: number | nil} = table.pack(innerDes(buff, offset))
			local cursor = table.remove(result, 1) :: number
			result.n = nil --get outta here!!!
			return cursor, result
		end,
		size = serDesType.size
	})
end

--why not
function ByteWorks.tableIOToTuple(serDesType: ByteWorksType<any>): ByteWorksType<...any>
	local innerSer = serDesType.ser
	local innerDes = serDesType.des
	return table.freeze({
		ser = function(buff, offset, ...)
			return innerSer(buff, offset, {...})
		end,
		des = function(buff, offset)
			local cursor, result = innerDes(buff, offset)
			return cursor, table.unpack(result)
		end,
		size = serDesType.size
	})
end

function ByteWorks.tuple(...: ByteWorksType<any>): ByteWorksType<...any>
	local types: {ByteWorksType<any>} = {...}
	return table.freeze({
		ser = function(buff, offset, ...)
			for i, value in {...} do
				offset = types[i].ser(buff, offset, value)
			end
			return offset
		end,
		des = function(buff, offset)
			local result: {any} = {}
			for i, serDesType in types do
				offset, result[i] = serDesType.des(buff, offset)
			end
			return offset, table.unpack(result)
		end,
		size = function(...)
			local totalSize = 0
			for i, value in {...} do
				totalSize += types[i].size(value)
			end
			return totalSize
		end,
	})
end

function ByteWorks.literal(...: any): ByteWorksType<any>
	local literals = {...}
	if #literals > 255 then
		error("only up to 256 literals are supported")
	end

	return table.freeze({
		ser = function(buff, offset, value)
			buffer.writeu8(buff, offset, table.find(literals, value) :: number - 1)
			return offset + 1
		end,
		des = function(buff, offset: number)
			return offset + 1, literals[buffer.readu8(buff, offset) + 1]
		end,
		size = function()
			return 1
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
	local numberTypeSer = numberType.ser
	local numberTypeDes = numberType.des

	return table.freeze({
		ser = function(buff, offset, value: EnumItem)
			return numberTypeSer(buff, offset, value.Value)
		end,
		des = function(buff, offset)
			local value: number
			offset, value = numberTypeDes(buff, offset)
			local enumItem: EnumItem? = enum:FromValue(value)
			return offset, enumItem
		end,
		size = function(value)
			return size
		end,
	})
end

function ByteWorks.array<T>(serDesType: ByteWorksType<T>): ByteWorksType<{T}>
	local vlqSer = ByteWorks.vlq.ser
	local vlqDes = ByteWorks.vlq.des
	local vlqSize = ByteWorks.vlq.size
	local innerSer = serDesType.ser
	local innerDes = serDesType.des
	local innerSize = serDesType.size

	return table.freeze({
		ser = function(buff, offset, value: {T})
			offset = vlqSer(buff, offset, #value)

			for _, element: T in value do
				offset = innerSer(buff, offset, element)
			end

			return offset
		end,
		des = function(buff, offset)
			local count
			offset, count = vlqDes(buff, offset)
			local elements = table.create(count)

			for i = 1, count do
				offset, elements[i] = innerDes(buff, offset)
			end

			return offset, elements
		end,
		size = function(value)
			local totalSize = vlqSize(#value)
			for _, v in value do
				totalSize += innerSize(v :: T)
			end
			return totalSize
		end,
	})
end

--no size indicator overhead!!
function ByteWorks.fixedSizeArray<T>(serDesType: ByteWorksType<T>, fixedSize: number): ByteWorksType<{T}>
	local innerSer = serDesType.ser
	local innerDes = serDesType.des
	local innerSize = serDesType.size

	return table.freeze({
		ser = function(buff, offset, value)
			for _, element in value do
				offset = innerSer(buff, offset, element)
			end

			return offset
		end,
		des = function(buff, offset)
			local value = table.create(fixedSize)

			for i = 1, fixedSize do
				offset, value[i] = innerDes(buff, offset)
			end

			return offset, value
		end,
		size = function(value)
			local totalSize = 0
			for _, v in value do
				totalSize += innerSize(v)
			end
			return totalSize
		end,
	})
end

function ByteWorks.struct(fields: {[string]: ByteWorksType<any>}): ByteWorksType<{[string]: any}>
	local order = {}
	for field in fields do
		table.insert(order, field)
	end

	return table.freeze({
		ser = function(buff, offset, value)
			for _, field in order do
				local serDesType = fields[field]
				offset = serDesType.ser(buff, offset, value[field])
			end

			return offset
		end,
		des = function(buff, offset)
			local elements = {}

			for _, field in order do
				local serDesType = fields[field]
				offset, elements[field] = serDesType.des(buff, offset)
			end

			return offset, elements
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

function ByteWorks.optStruct(fields: {[string]: ByteWorksType<any>}): ByteWorksType<{[string]: any}>
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
		ser = function(buff, offset: number, value)
			local bitmap = 0

			for i, fieldName in optionalFields do
				if value[fieldName] ~= nil then
					bitmap = bit32.bor(bitmap, bit32.lshift(1, i - 1))
				end
			end

			for i = 1, optionalBytes do
				buffer.writeu8(buff, offset + i - 1, bit32.band(bit32.rshift(bitmap, (i - 1) * 8), 0xFF))
				offset += 1
			end

			for _, fieldName in order do
				local serDesType = fields[fieldName]
				if not serDesType.optionalFlag or value[fieldName] ~= nil then
					offset = serDesType.ser(buff, offset, value[fieldName])
				end
			end

			return offset
		end,

		des = function(buff, offset: number)
			local elements = {}

			local bitmap = 0
			for i = optionalBytes, 1, -1 do
				bitmap = bit32.bor(bit32.lshift(bitmap, 8), buffer.readu8(buff, offset + i - 1))
				offset += 1
			end

			local optionalIndex = 0
			for _, fieldName in order do
				local serDesType = fields[fieldName]
				if serDesType.optionalFlag then
					optionalIndex += 1
					if bit32.band(bitmap, bit32.lshift(1, optionalIndex - 1)) ~= 0 then
						offset, elements[fieldName] = serDesType.des(buff, offset)
					end
				else
					offset, elements[fieldName] = serDesType.des(buff, offset)
				end
			end

			return offset, elements
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

function ByteWorks.map<K, V>(keyType: ByteWorksType<K>, valueType: ByteWorksType<V>): ByteWorksType<{[K]: V}>
	local keySer = keyType.ser
	local keyDes = keyType.des
	local keySize = keyType.size
	local valueSer = valueType.ser
	local valueDes = valueType.des
	local valueSize = valueType.size

	return table.freeze({
		ser = function(buff, offset: number, value: {[K]: V})
			local writeAt = offset
			offset += 1

			local elementCount = 0
			for k, v in value do
				offset = keySer(buff, offset, k)
				offset = valueSer(buff, offset, v)
				elementCount += 1
			end

			buffer.writeu8(buff, writeAt, elementCount)
			return offset
		end,
		des = function(buff, offset)
			local elementCount = buffer.readu8(buff, offset)
			offset += 1

			local map: {[K]: V} = {}
			for i = 1, elementCount do
				local key, value
				offset, key = keyDes(buff, offset)
				offset, value = valueDes(buff, offset)
				map[key] = value
			end

			return offset, map
		end,
		size = function(value)
			local totalSize = 0
			for k, v in value do
				totalSize += keySize(k) + valueSize(v)
			end
			return totalSize + 1
		end,
	})
end

--quick benchmarks show that the difference between this and a seperate implementation is insignificant
ByteWorks.boolean = ByteWorks.tableIOToTuple(ByteWorks.bitmask(8)) :: ByteWorksType<...boolean>

--if u want multiple buffers together u can just do
--buffer.create(type1.size(value1) + type2.size(value2))
function ByteWorks.createBufferFromType<T>(serDesType: ByteWorksType<T>, ...: T): buffer
	return buffer.create(serDesType.size(...))
end

--just do local _, result = ByteWorks[...].des(...) lol (unless using tuple types)
function ByteWorks.resultExcludingCursor<T>(serDesType: ByteWorksType<T>, buff: buffer, offset: number): ...T
	return select(2, serDesType.des(buff, offset))
end

function ByteWorks.createAndSerialize<T>(serDesType: ByteWorksType<T>, ...: T): buffer
	local buff: buffer = buffer.create(serDesType.size(...))
	serDesType.ser(buff, 0, ...)
	return buff
end

return ByteWorks
