---
sidebar_position: 4
---

# Advanced Examples

## Maps with Literals

In this example, the keys of the map only occupy 1 byte since we are using literals as keys. This also means the key can only be "key1", "key2", or "key3", or it will error.

```lua
local map = ByteWorks.map(
	ByteWorks.literal("key1", "key2", "key3"),
	ByteWorks.f32
)

local data = {
	key1 = 123,
	key3 = 567
}

local buff = buffer.create(map.size(data))
map.ser(buff, 0, data)

local _, deserializedData = map.des(buff, 0)
print(deserializedData) --> {key1 = 123, key3 = 567}
```