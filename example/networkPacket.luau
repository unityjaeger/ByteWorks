local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local networkPacket = byteWorks.struct({
	identifier = byteWorks.u8,
	position = byteWorks.vector3(byteWorks.f32),
	rotation = byteWorks.bitfield(byteWorks.u32, {10, 12, 10}),
	state = byteWorks.literal("Dead", "Walking", "Idle", "Jumping", "Falling"),
})

local data = {
	identifier = 1,
	position = Vector3.new(0, 0, 0),
	--bitfield divides a given number type into ranges of bits, these are the max numbers for the given bit ranges
	rotation = {1023, 4095, 1023},
	state = "Idle"
}

local buff = byteWorks.createAndSerialize(networkPacket, data)
local deserialized = byteWorks.resultExcludingCursor(networkPacket, buff, 0)
