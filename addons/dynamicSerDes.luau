local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Shared.Modules.ByteWorks)

local dynamicTypes = {}

local dynamicVector3 = t.vector3(t.f32)
local typeIdentToType = {
	[1] = t.f32,
	[2] = t.vstring,
	[3] = t.color3,
	[4] = dynamicVector3,
	[5] = t.boolean,
	[6] = t.cframe
}

local function isArray(x)
	return #x > 0
end

local function getType(val: any)
	local rblxType = typeof(val)
	if rblxType == "number" then
		return t.f32, 1
	elseif rblxType == "string" then
		return t.vstring, 2
	elseif rblxType == "Color3" then
		return t.color3, 3
	elseif rblxType == "Vector3" then
		return dynamicVector3, 4
	elseif rblxType == "boolean" then
		return t.boolean, 5
	elseif rblxType == "CFrame" then
		return t.cframe, 6
	elseif rblxType == "table" then
		if isArray(val) then
			return dynamicTypes.dynamicArray, 7
		else
			return dynamicTypes.dynamicMap, 8
		end
	end
end

dynamicTypes.dynamicArray = {
	ser = function(buff, offset, value)
		buffer.writeu8(buff, offset, #value)
		offset += 1

		for _, v in value do
			local byteWorksType, identifier = getType(v)
			buffer.writeu8(buff, offset, identifier)
			offset = byteWorksType.ser(buff, offset + 1, v)
		end

		return offset
	end,
	des = function(buff, offset, value)
		local len = buffer.readu8(buff, offset)
		offset += 1

		local array = table.create(len)
		for i = 1, len do
			local identifier = buffer.readu8(buff, offset)
			offset, value = typeIdentToType[identifier].des(buff, offset + 1)
			table.insert(array, value)
		end

		return offset, array
	end,
	size = function(value)
		local totalLen = 1 --key value pairs
		for _, v in value do
			local byteWorksType = getType(v)
			totalLen += byteWorksType.size(v) + 1 --identifier
		end
		return totalLen
	end,
}

dynamicTypes.dynamicMap = {
	ser = function(buff, offset, value)
		local originalOffset = offset
		offset += 1
		local len = 0

		for k, v in value do
			local byteWorksType, identifier = getType(v)
			offset = t.vstring.ser(buff, offset, k)
			buffer.writeu8(buff, offset, identifier)
			offset = byteWorksType.ser(buff, offset + 1, v)
			len += 1
		end

		buffer.writeu8(buff, originalOffset, len)
		return offset
	end,
	des = function(buff, offset)
		local len = buffer.readu8(buff, offset)
		offset += 1

		local map = {}
		for i = 1, len do
			local key, value
			offset, key = t.vstring.des(buff, offset)
			local identifier = buffer.readu8(buff, offset)
			offset, value = typeIdentToType[identifier].des(buff, offset + 1)
			map[key] = value
		end

		return offset, map
	end,
	size = function(value)
		local totalLen = 1 --key value pairs
		for k, v in value do
			local byteWorksType = getType(v)
			totalLen += t.vstring.size(k)
			totalLen += byteWorksType.size(v) + 1 --identifier
		end
		return totalLen
	end,
}

typeIdentToType[7] = dynamicTypes.dynamicArray
typeIdentToType[8] = dynamicTypes.dynamicMap

local dynamic = {
	ser = function(buff, offset, value)
		local byteWorksType, identifier = getType(value)
		buffer.writeu8(buff, offset, identifier)
		offset += 1
		return byteWorksType.ser(buff, offset, value)
	end,
	des = function(buff, offset)
		local identifier = buffer.readu8(buff, offset)
		local byteWorksType = typeIdentToType[identifier]
		return byteWorksType.des(buff, offset + 1)
	end,
	size = function(value)
		local byteWorksType = getType(value)
		return byteWorksType.size(value) + 1
	end,
}

return dynamic
