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
	vlq = byteWorks.vlq, --variable length quantity number
	svlq = byteWorks.svlq, --signed variable length quantity number
	boolean = byteWorks.boolean,
	cframe = byteWorks.cframe,
	vector3 = byteWorks.vector3(byteWorks.i24),
	color3 = byteWorks.color3,
	map = byteWorks.map(
		byteWorks.literal("key1", "key2", "key3"), --key
		byteWorks.u8 --value
	),
	array = byteWorks.array(byteWorks.boolean, 1),
	fixedSizeArray = byteWorks.fixedSizeArray(byteWorks.boolean, 5), --will always be large enough to hold exactly 5 booleans
	bitfield = byteWorks.bitfield(byteWorks.u8, {2, 2, 2, 2}), --8 bits divided into 2, 2, 2, 2
	bitmask = byteWorks.bitmask(8), --8 bits in the mask
	optionalStruct = byteWorks.optionalStruct({ --struct containing optionals
		optionalu8 = byteWorks.optional(byteWorks.u8)
	}),
	string = byteWorks.string(5), --fixed length string
	vstring = byteWorks.vstring, --variable length string
	buffer = byteWorks.buffer(10), --fixed size buffer
	vbuffer = byteWorks.vbuffer, --variable size buffer
	literal = byteWorks.literal(1, 2, 3), --can either be 1, 2, or 3
	enum = byteWorks.enum(Enum.KeyCode), --any enum from keycode
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
	string = "abcde",
	vstring = "abcdefghijk",
	buffer = buffer.create(10),
	vbuffer = buffer.create(123),
	literal = 2,
	enum = Enum.KeyCode.E,
}

--taggedEnum exists but currently its just a worse glorified optionalStruct so i wouldnt reccomend using it

local buff = byteWorks.createAndSerialize(allTypes, data)
local deserialized = byteWorks.resultExcludingCursor(allTypes, buff, 0)
