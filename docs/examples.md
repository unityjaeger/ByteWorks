---
sidebar_position: 2
---

# Examples

## Basic Usage

### Built-in Functions

ByteWorks provides two convenient functions, createAndSerialize and resultExcludingCursor, to simplify serialization and deserialization, at the cost of a minimal performance overhead.

```lua
--define a serializer for a vector3 with each axis using a f32
local vector3Type = ByteWorks.vector3(ByteWorks.f32)

--create buffer from the serializer type and data
local vector = Vector3.new(1, 2, 3)
local buff = ByteWorks.createAndSerialize(vector3Type, vector)

--extract the data from the buffer
local deserializedVector = ByteWorks.resultExcludingCursor(vector3Type, buff, 0)
print(deserializedVector) --> 1, 2, 3
```

### Raw Usage

For more control and performance, you can use the ser, des, and size methods directly.

```lua
local u16Type = ByteWorks.u16

--create a buffer with enough space for that type
--for u16, the size is constant so the parameter is optional, however if you use strict then you still want to pass in the value because the luau type system expects a parameter
local buff = buffer.create(u16Type.size(42))

--serialize the number
u16Type.ser(buff, 0, 42)

--deserialize, ignore the first argument that is the cursor
local _offset_, value = u16Type.des(buff, 0)
print(value) --> 42
```

## Custom Types

In ByteWorks, you can easily define custom serializers to get specific behavior you need, custom serializers will work with all built in types.

```lua
--very very simple example but you can do whatever you can come up with
local customType: ByteWorks.ByteWorksType<{number}> = table.freeze({
	ser = function(buff, offset, value)
		buffer.writeu8(buff, offset, value[1])
		offset += 1
		buffer.writeu8(buff, offset, value[2])
		offset += 1
		return offset
	end,
	des = function(buff, offset)
		local num1, num2 = buffer.readu8(buff, offset), buffer.readu8(buff, offset + 1)
		return offset + 2, {num1, num2} --offset gets returned first
	end,
	size = function(value)
		return 2
	end,
})

local data = {5, 10}

local buff = byteWorks.createAndSerialize(customType, data)
local deserialized = byteWorks.resultExcludingCursor(customType, buff, 0)
print(deserialized) --> {5, 10}
```

## Merged Buffers

```lua
local u8Type = ByteWorks.u8
local stringType = ByteWorks.string
local vector3Type = ByteWorks.vector3(ByteWorks.f32)

--create a buffer with enough space to fit all 3 values
local buff = buffer.create(
	u8Type.size(42) +
	stringType.size("Hello") +
	vector3Type.size(Vector3.new(1, 2, 3))
)

--serialize sequentially
local offset = 0
offset = u8Type.ser(buff, offset, 42)
offset = stringType.ser(buff, offset, "Hello")
offset = vector3Type.ser(buff, offset, Vector3.new(1, 2, 3))

--deserialize sequentially
offset = 0 --since this example is doing it in the same scope, we need to set offset back to 0
local value1
offset, value1 = u8Type.des(buff, offset)
local value2
offset, value2 = stringType.des(buff, offset)
local value3
offset, value3 = vector3Type.des(buff, offset)

print(value1, value2, value3) --> 42, Hello, 1, 2, 3
```
