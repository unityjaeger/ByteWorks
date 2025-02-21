---
sidebar_position: 1
---

# Intro

ByteWorks is a library that aims to make working with buffers as comfortable as possible while still maintaining high performance. Manually managing binary formats is a tough task and is prone to errors, which is why ByteWorks includes some useful, and hard to implement formats like half precision floating point numbers, variable length quantity, bitfields, bitmasks.

## Key Features

- **Flexible**: Missing a serializer you need? You can easily implement it yourself and it will work with existing types.
- **Modular and Composable**: Compose serializers to handle even the most complex data structures with ease.
- **Bit-Level Precision**: Work with bitfields and bitmasks to pack data efficiently and manage binary flags.

## Who Is ByteWorks For?

ByteWorks is for **any Roblox developer** who needs to work with binary data. Whether you're:
- Building a **complex multiplayer game** and need to send data over the network efficiently,
- Saving **game state** or player data in a compact format,
