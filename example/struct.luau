local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local struct = byteWorks.struct({
	name = byteWorks.string(10),
	location = byteWorks.vector3(ByteWorks.f32),
	items = byteWorks.array(ByteWorks.struct({
		itemId = byteWorks.u16
	}), 1)
})

local data = {
	name = "0123456789",
	location = Vector3.new(1000, 2000, 3000),
	items = {
		{
			itemId = 1
		},
		{
			itemId = 2
		},
		{
			itemId = 3
		}
	}
}

local buff = byteWorks.createAndSerialize(struct, 0, data)
local deserialized = byteWorks.resultExcludingCursor(struct, buff, 0)
