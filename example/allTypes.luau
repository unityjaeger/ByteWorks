local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local allTypes = byteWorks.struct({
	--im not doing the different types for each number type since theyre basically identical in usage
	--(but ill include the special ones)
	u8 = byteWorks.u8,
	u24 = byteWorks.u24,
	u53 = byteWorks.u53,
	i8 = byteWorks.i8,
	i24 = byteWorks.i24,
	i53 = byteWorks.i53,
	f16 = byteWorks.f16,
	vlq = byteWorks.vlq,
	svlq = byteWorks.svlq,
	boolean = byteWorks.boolean,
	cframe = byteWorks.cframe,
	vector3 = byteWorks.vector3(byteWorks.i24),
	vector3XZ = byteWorks.vector3XZ(byteWorks.f32),
	color3 = byteWorks.color3,
	map = byteWorks.map(
		byteWorks.enum("key1", "key2", "key3"), --key
		byteWorks.u8 --value
	),
	array = byteWorks.array(byteWorks.boolean, 1),
	fixedSizeArray = byteWorks.fixedSizeArray(byteWorks.boolean, 5), --will always be large enough to hold exactly 5 booleans
	bitfield = byteWorks.bitfield(byteWorks.u8, {2, 2, 2, 2}), --8 bits divided into 2, 2, 2, 2
	bitmask = byteWorks.bitmask(8), --8 bits in the mask
	optionalStruct = byteWorks.optionalStruct({ --struct containing optionals
		optionalu8 = byteWorks.optional(byteWorks.u8)
	}),
	string = byteWorks.string(5), --5 length string
})

--see tuples.luau for examples on types with tuples, which do not work properly with structs since they only return the first value (by default)
--the above is actually wanted for booleans so its mainly about the actual tuple type

local data = {
	u8 = 1,
	u24 = 2,
	u53 = 3,
	i8 = -1,
	i24 = -2,
	i53 = -3,
	f16 = 100.125,
	vlq = 12345678,
	svlq = -12345678,
	boolean = true,
	cframe = CFrame.new(5, -5, -7) * CFrame.fromOrientation(1, 2, 3),
	vector3 = Vector3.new(-100, -50, 100),
	vector3XZ = Vector3.new(100.252, 0, -100.825),
	color3 = Color3.new(1, .575, 0),
	map = {
		key1 = 1,
		key3 = 3
	},
	array = {true, false, true},
	fixedSizeArray = {true, false, true, true, false},
	bitfield = {0, 1, 2, 3},
	bitmask = {true, true, false, false, true, true, false, true}, --11001101
	optionalStruct = {
		optionalu8 = nil
	},
	string = "abcde"
}

local buff = byteWorks.createAndSerialize(allTypes, 0, data)
local deserialized = byteWorks.resultExcludingCursor(buff, 0)
