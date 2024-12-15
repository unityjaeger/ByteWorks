local byteWorks = require(game.ReplicatedStorage.ByteWorks)

--tuple is the only "real" tuple type, boolean just uses tableIOtoTuple to get tuples
local tuple = byteWorks.tuple(byteWorks.u8, byteWorks.string(1))
local value1, value2 = 1, "a"
local buff = byteWorks.createAndSerialize(tuple, 0, value1, value2)
local result1, result2 = byteWorks.resultExcludingCursor(tuple, buff, 0)

--other types can be converted to use tuple input if applicable
local bitfield = byteWorks.tableIOToTuple(byteWorks.bitfield(byteWorks.u8, {4, 4}))
local value1, value2 = 5, 6
local buff = byteWorks.createAndSerialize(bitfield, 0, value1, value2)
local result1, result2 = byteWorks.resultExcludingCursor(bitfield, buff, 0)

--conversely, tuple types can be changed to have table input
local tuple = byteWorks.tupleIOToTable(byteWorks.tuple(byteWorks.u8, byteWorks.u16))
local value = {1, 2}
local buff = byteWorks.createAndSerialize(tuple, 0, value)
local result = byteWorks.resultExcludingCursor(tuple, buff, 0)
