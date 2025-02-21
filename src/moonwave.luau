--- @class ByteWorks
--- ByteWorks is a library for serializing and deserializing binary data in Roblox.
--- It provides utilities for working with buffers, integers, floating-point numbers, strings, and more.

--- @interface ByteWorksType
--- @within ByteWorks
--- A type representing a serialization/deserialization utility for a specific data type.
--- @field .ser (buff: buffer, offset: number, T...) -> number
--- @field .des (buff: buffer, offset: number) -> (number, T...)
--- @field .size (T...) -> number
--- @field .optionalFlag boolean?

--- @prop u8 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes an 8-bit unsigned integer.

--- @prop u16 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 16-bit unsigned integer.

--- @prop u24 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 24-bit unsigned integer.

--- @prop u32 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 32-bit unsigned integer.

--- @prop u53 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 53-bit unsigned integer.

--- @prop i8 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes an 8-bit signed integer.

--- @prop i16 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 16-bit signed integer.

--- @prop i24 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 24-bit signed integer.

--- @prop i32 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 32-bit signed integer.

--- @prop i53 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 53-bit signed integer.

--- @prop f16 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 16-bit floating-point number.

--- @prop f32 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 32-bit floating-point number.

--- @prop f64 ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a 64-bit floating-point number.

--- @prop vlq ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a variable-length unsigned integer.

--- @prop svlq ByteWorksType<number>
--- @within ByteWorks
--- Serializes and deserializes a variable-length signed integer.

--- @prop string ByteWorksType<string>
--- @within ByteWorks
--- Serializes and deserializes a string.

--- @function bitmask
--- @within ByteWorks
--- Creates a bitmask serializer/deserializer.
--- @param bitCount number
--- @return ByteWorksType<{boolean}>

--- @function vector3
--- @within ByteWorks
--- Creates a Vector3 serializer/deserializer.
--- @param serDesType ByteWorksType<number>
--- @return ByteWorksType<Vector3>

--- @prop color3 ByteWorksType<Color3>
--- @within ByteWorks
--- Serializes and deserializes a Color3.

--- @prop cframe ByteWorksType<CFrame>
--- @within ByteWorks
--- Serializes and deserializes a CFrame.

--- @function bitfield
--- @within ByteWorks
--- Creates a bitfield serializer/deserializer.
--- @param serDesType ByteWorksType<number>
--- @param bitCounts {number}
--- @return ByteWorksType<{number}>

--- @function fixedSizeBuffer
--- @within ByteWorks
--- Creates a fixed-size buffer serializer/deserializer.
--- @param size number
--- @return ByteWorksType<buffer>

--- @prop buffer ByteWorksType<buffer>
--- @within ByteWorks
--- Serializes and deserializes a buffer.

--- @function opt
--- @within ByteWorks
--- Wraps a serializer/deserializer to make it optional.
--- @param serDesType ByteWorksType<T>
--- @return ByteWorksType<T>

--- @function tupleIOToTable
--- @within ByteWorks
--- Converts a tuple-based serializer/deserializer to a table-based one.
--- @param serDesType ByteWorksType<...any>
--- @return ByteWorksType<any>

--- @function tableIOToTuple
--- @within ByteWorks
--- Converts a table-based serializer/deserializer to a tuple-based one.
--- @param serDesType ByteWorksType<any>
--- @return ByteWorksType<...any>

--- @function tuple
--- @within ByteWorks
--- Creates a tuple serializer/deserializer.
--- @param ... ByteWorksType<any>
--- @return ByteWorksType<...any>

--- @function literal
--- @within ByteWorks
--- Creates a serializer/deserializer for a set of literal values.
--- @param ... any
--- @return ByteWorksType<any>

--- @function enum
--- @within ByteWorks
--- Creates a serializer/deserializer for an enum.
--- @param enum Enum
--- @return ByteWorksType<any>

--- @function array
--- @within ByteWorks
--- Creates a serializer/deserializer for an array.
--- @param serDesType ByteWorksType<T>
--- @return ByteWorksType<{T}>

--- @function fixedSizeArray
--- @within ByteWorks
--- Creates a serializer/deserializer for a fixed-size array.
--- @param serDesType ByteWorksType<T>
--- @param fixedSize number
--- @return ByteWorksType<{T}>

--- @function struct
--- @within ByteWorks
--- Creates a serializer/deserializer for a struct.
--- @param fields {[string]: ByteWorksType<any>}
--- @return ByteWorksType<{[string]: any}>

--- @function optStruct
--- @within ByteWorks
--- Creates a serializer/deserializer for an optional struct.
--- @param fields {[string]: ByteWorksType<any>}
--- @return ByteWorksType<{[string]: any}>

--- @function map
--- @within ByteWorks
--- Creates a serializer/deserializer for a map.
--- @param keyType ByteWorksType<K>
--- @param valueType ByteWorksType<V>
--- @return ByteWorksType<{[K]: V}>

--- @prop boolean ByteWorksType<...boolean>
--- @within ByteWorks
--- Serializes and deserializes a boolean.

--- @function createBufferFromType
--- @within ByteWorks
--- Creates a buffer from a serializer/deserializer and values.
--- @param serDesType ByteWorksType<T>
--- @param ... T
--- @return buffer

--- @function resultExcludingCursor
--- @within ByteWorks
--- Deserializes a value, excluding the cursor.
--- @param serDesType ByteWorksType<T>
--- @param buff buffer
--- @param offset number
--- @return ...T

--- @function createAndSerialize
--- @within ByteWorks
--- Creates a buffer and serializes values into it.
--- @param serDesType ByteWorksType<T>
--- @param ... T
--- @return buffer