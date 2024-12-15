local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local customType = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu8(buff, offset, value[1])
		offset += 1
		buffer.writeu8(buff, offset, value[2])
		offset += 1
		return offset
	end,
	des = function(buff, offset)
		local num1, num2 = buffer.readu8(buff, offset), buffer.readu8(buff, offset + 1)
		return offset + 2, {num1, num2}
	end,
	size = function(value)
		return 2
	end,
})

local data = {5, 10}

local buff = byteWorks.createAndSerialize(customType, 0, data)
local deserialized = byteWorks.resultExcludingCursor(customType, buff, 0)
