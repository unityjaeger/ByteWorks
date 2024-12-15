local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local type1 = byteWorks.cframe
local type2 = byteWorks.boolean
local type3 = byteWorks.u8

local data1 = CFrame.new(1, 2, 3) * CFrame.Angles(-2, 0, 2)
local data2 = true
local data3 = 255

local buff = buffer.create(type1.size(data1) + type2.size(data2) + type3.size(data3))

local cursor
cursor = type1.ser(buff, 0, data1)
cursor = type2.ser(buff, cursor, data2)
--you dont have to do cursor = x for the last serialization since that is only for the next operation
type3.ser(buff, cursor, data3)

local deserialized1
local deserialized2
local deserialized3

cursor, deserialized1 = type1.des(buff, 0)
cursor, deserialized2 = type2.des(buff, cursor)
--you have to do cursor, result = x for deserialization since the first return value is the cursor
cursor, deserialized3 = type3.des(buff, cursor)
