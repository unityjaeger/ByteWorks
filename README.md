# ByteWorks
Module designed for serialization and deserialization of data in roblox, specifically to save bandwidth.

Note that this module is not for beginners, I have some basic error handling but if something errors or delivers unexpected results (and its not because of my implementation of something being faulty) then you have to find out what you did wrong yourself.

This module is not typed as its way too much to type retrospectively and I'm also not sure how to have some types work properly.

# Motivation
I made this module because there are some nice to have features that other Ser/Des modules don't have (at least the ones I know about), which includes
- bitfields
- bitmasks
- signed variable length quantity (as well as unsigned)
- reduced optional size for optional fields in structs (1 byte per 8 optionals)

as well as other commonly found features, including
- unsigned integers (8 bit, 16 bit, 24 bit, 32 bit, 53 bit)
- signed integers (8 bit, 16 bit, 24 bit, 32 bit, 53 bit)
- floating point numbers (16 bit, 32 bit, 64 bit)
- strings (predefined length)
- structs
- maps
- tuples
- arrays, fixed size arrays
- enums (literals)
- booleans (as a bitmask)
- roblox data types like CFrame, Vector3 (and Vector3XZ, which only works with the X and Z axis), Color3

# Basic Usage
```luau
local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local u8 = byteWorks.u8
local data = 200
-- some types need the data to be able to create an appropriately sized buffer, so always pass in the data
local buff = byteWorks.createBufferFromType(u8, data)
-- basically the same syntax as a buffer write operation, with buffer | offset | value
u8.ser(buff, 0, data)
-- first return value is the new offset to support some implemented structures
local _, deserialized = u8.des(buff, 0)

--alternatively, the code could also look like this
local u8 = byteWorks.u8
local data = 200
local buff = byteWorks.createAndSerialize(u8, data)
local deserialized = byteWorks.resultExcludingCursor(u8, buff, 0)
```
Some types need to be created by passing in parameters, for example array expects the type and a number indicating how many bytes should be allocated to store the number of entries:
```luau
local byteWorks = require(game.ReplicatedStorage.ByteWorks)

local array = byteWorks.array(byteWorks.u8, 1)
local data = {1, 2, 3, 4, 5}
local buff = byteWorks.createBufferFromType(array, data) -- this is where passing in the value is vital
array.ser(buff, 0, data)
local _, deserialized = array.des(buff, 0)
```
additional examples are in the example folder
