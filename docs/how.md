---
sidebar_position: 3
---

# Types

Compared to other existing Ser/Des modules (like Squash), ByteWorks does not use dynamically resized buffers. Each type has a size method that calculates the exact buffer size needed to hold the serialized data, with some types having a static size, while still being a method so everything is consistent.

This changes how you serialize multiple types sequentially slightly, instead of just being able to push them to the dynamic buffer, you have to create a buffer with the right size before performing any serialization.

The huge benefit of this approach is performance. If you use a dynamic approach not only do you need to create a new buffer each time a resize happens, you also have to copy the previous contents to the new buffer. Then, once you're done serializing all your data, you have to create another buffer with the actual needed size for the serialized data and then copy the contents to the new buffer.

## Numbers

Numbers in luau are stored as 8 byte double precision floating point numbers. If we want to represent integers, then the representable range is **−2⁵³ to 2⁵³**.

### Unsigned Integers

Unsigned integers refer to whole numbers. The available types with their respective ranges are:

| Type | Bytes | Min | Max |
| - | - | - | - |
| u8 | 1 | 0 | 255 |
| u16 | 2 | 0 | 65,535 |
| u24 | 3 | 0 | 16,777,215 |
| u32 | 4 | 0 | 4,294,967,295 |
| u53 | 7 | 0 | 9,007,199,254,740,992 |

### Signed Integers

Signed Integers refer to integers as they are commonly known in math. They have a sign bit as their first bit to dictate whether the number is a positive number or a negative number. The available types with their respective ranges are:

| Type | Bytes | Min | Max |
| - | - | - | - |
| i8 | 1 | -128 | 127 |
| i16 | 2 | -32,768 | 32,767 |
| i24 | 3 | -8,388,608 | 8,388,607 |
| i32 | 4 | -2,147,483,648 | 2,147,483,647 |
| i53 | 7 | -9,007,199,254,740,992 | 9,007,199,254,740,992 |

You are able to store up to 56 bit integers theoretically with i53, but past the specified ranges integers are not exactly representable anymore, since they round to a multiple higher than 1.

### Floating Point Numbers

Floating point numbers are commonly known as decimal numbers, the available types are:

| Type | Bytes | Min | Max |
| - | - | - | - |
| f16 | 2 | -65,504 | 65,504 |
| f32 | 4 | ca. -10^38 | ca. 10^38 |
| f64 | 8 | ca. -10^308 | ca 10^308 |

It is very important to note that floating point numbers behave differently from integers, with floating point numbers, the higher the number is, the lower the precision. Let me demonstrate this with f16:

| Min | Max | Interval |
| - | - | - |
| 128 |	256 | 0.125 |
| 256 | 512 | 0.25 |
| 512 | 1024 | 0.5 |⁠
| 1024 | 2048 | 1 |
| 2048 | 4096 | 2 |
| 4096 | 8192 | 4 |

Naturally, f32 and f64 have way better precision with low numbers like these, but this is something you have to keep in mind when using floating point numbers, especially when you're using f16.

### Variable Length Quantity

Variable length quantity numbers are useful when you don't know how many bytes a number needs, or when you encode a diverse set of numbers and you don't want to opt for the largest type needed to accomodate every possible number you will serialize. VLQs store the number in the first 7 bits and the last bit is the "continuation bit", which basically tells the algorithm if there is more to the number and if it should continue reading/writing. This means that VLQs are less efficient if you have numbers in similar ranges, as each block of 8 bits needs a continuation bit.

Here are some example ranges for different byte counts:

| Bytes | Min | Max |
| - | - | - |
| 1 | 0 | 127 |
| 2 | 0 | 16,383 |
| 3 | 0 | 2,097,151 |

### Signed Variable Length Quantity

Here are some example ranges for different byte counts:

| Bytes | Min | Max |
| - | - | - |
| 1 | -63 | 63 |
| 2 | -8,191 | 8,191 |
| 3 | -1,048,575 | 1,048,575 |

## Booleans

We only need 1 bit to determine if a boolean is true (1) or false (0), however buffers work in bytes, so we can combine 8 booleans into 1 byte to make the most of our space.

```lua
local boolean = ByteWorks.boolean
local buff = buffer.create(boolean.size())
boolean.ser(buff, 0, true, true, false, false, true, false, true, false)
--we use select because the first returned value is the offset after the deserialization, and we dont need that
print(select(2, boolean.des(buff, 0))) --> true true false false true false true false
```

## Buffers

Buffers can be written into buffers, which is just a copy operation, this is useful if you only want to serialize data when it changes instead of every time it is replicated for example.

```lua
local bufferType = ByteWorks.buffer
local sourceBuff = buffer.create(4)
buffer.writeu32(sourceBuff, 0, 123456) --write some data into the source buffer

local destBuff = buffer.create(bufferType.size(sourceBuff))
bufferType.ser(destBuff, 0, sourceBuff)

local _, deserializedBuff = bufferType.des(destBuff, 0)
print(buffer.readu32(deserializedBuff, 0)) --> 123456
```

## CFrame

Simple implementation of CFrame serialization and deserialization, it is very general purpose and I reccomend making your own serializer for CFrames that is better suited to your needs.

```lua
local cframeType = ByteWorks.cframe
local cframe = CFrame.new(10, 20, 30) * CFrame.fromOrientation(math.pi / 4, math.pi / 2, 0)

local buff = buffer.create(cframeType.size(cframe))
cframeType.ser(buff, 0, cframe)

local _, deserializedCFrame = cframeType.des(buff, 0)
print(deserializedCFrame.Position, deserializedCFrame:ToOrientation()) --> 10, 20, 30, pi/4, pi/2, 0
```

## Arrays

There are both dynamic arrays and fixed size arrays, arrays can only work with one type.

### Dynamic Arrays

```lua
local arrayType = ByteWorks.array(ByteWorks.u8)
local data = {1, 2, 3, 4, 5}

local buff = buffer.create(arrayType.size(data))
arrayType.ser(buff, 0, data)

local _, deserializedData = arrayType.des(buff, 0)
print(table.concat(deserializedData, ", ")) --> 1, 2, 3, 4, 5
```

### Fixed Size Arrays

```lua
local fixedArrayType = ByteWorks.fixedSizeArray(ByteWorks.u8, 3)
local data = {10, 20, 30}

local buff = buffer.create(fixedArrayType.size(data))
fixedArrayType.ser(buff, 0, data)

local _, deserializedData = fixedArrayType.des(buff, 0)
print(table.concat(deserializedData, ", ")) --> 10, 20, 30
```

## Maps

Maps are tables that associate keys with values. While the value type can be anything, the key type must be indexable (e.g., numbers, strings).

```lua
local mapType = ByteWorks.map(ByteWorks.string, ByteWorks.u8)
local data = {apple = 1, banana = 2, cherry = 3}

local buff = buffer.create(mapType.size(data))
mapType.ser(buff, 0, data)

local _, deserializedData = mapType.des(buff, 0)
print(deserializedData) --> {apple = 1, banana = 2, cherry = 3}
```

## Struct

Structs map a string identifier to a specific value type, since the identifiers are known ahead of time, we don't have to serialize them.

### Regular Structs

```lua
local structType = ByteWorks.struct({
    name = ByteWorks.string,
    age = ByteWorks.u8,
    isAdmin = ByteWorks.boolean,
})

local data = {name = "Alice", age = 25, isAdmin = true}

local buff = buffer.create(structType.size(data))
structType.ser(buff, 0, data)

local _, deserializedData = structType.des(buff, 0)
print(deserializedData) --> {name = "Alice", age = 25, isAdmin = true}
```

### Optional Structs

Structs also support optional fields, the cost for an optional field is only 1 byte per 8 optionals. They are a seperate type due to performance implications.

```lua
local optStructType = ByteWorks.optStruct({
	name = ByteWorks.string,
	age = ByteWorks.opt(ByteWorks.u8),
})

local data = {name = "John", age = nil}

local buff = buffer.create(optStructType.size(data))
optStructType.ser(buff, 0, data)

local _, deserializedData = optStructType.des(buff, 0)
print(deserializedData) --> {name = "John"}
```

## Literal

Literals are values that can be stored with just an u8, which is useful for things like unique identifiers.

```lua
local literalType = ByteWorks.literal("apple", "banana", "cherry")
local value = "banana"

local buff = buffer.create(literalType.size(value))
literalType.ser(buff, 0, value)

local _, deserializedValue = literalType.des(buff, 0)
print(deserializedValue) --> banana
```

## Enum

Enums store a roblox Enum either as an u8 or an u16, depending on the highest enum value present within that enum.

```lua
local enumType = ByteWorks.enum(Enum.Material)
local value = Enum.Material.Concrete

local buff = buffer.create(enumType.size(value))
enumType.ser(buff, 0, value)

local _, deserializedValue = enumType.des(buff, 0)
print(deserializedValue) --> Enum.Material.Concrete
```

## Bitfield

A bitfield allows you to pack multiple numeric values into a single integer by allocating a specific number of bits for each value. This is useful for efficiently storing small integers with bit precision. The provided type has to be either an unsigned or signed integer, other types might work if they are constant sized but this is the intended use case.

```lua
--allocated 2, 2, and 4 bits respectively, must add up to the type's size
local bitfieldType = ByteWorks.bitfield(ByteWorks.u8, {2, 2, 4})

local values = {2, 1, 8}

local buff = buffer.create(bitfieldType.size(values))
bitfieldType.ser(buff, 0, values)

local _, deserializedValues = bitfieldType.des(buff, 0)
print(table.concat(deserializedValues, ", ")) --> 2, 1, 8
```

## Bitmask

A bitmask allows you to store multiple boolean flags in a single byte (or larger integer, if enough flags are present). Each bit in the byte represents a single flag, making it highly space-efficient.

```lua
local bitmaskType = ByteWorks.bitmask(8)

--create a table of boolean flags to serialize
local flags = {true, false, true, false, true, false, true, false}

local buff = buffer.create(bitmaskType.size(flags))
bitmaskType.ser(buff, 0, flags)

local _, deserializedFlags = bitmaskType.des(buff, 0)
print(deserializedFlags) --> {true, false, true, false, true, false, true, false}
```