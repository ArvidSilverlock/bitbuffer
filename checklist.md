## Luau Primitives
|value|read|write|
|-----|----|-----|
| UInt8 | ❌ | ✅ |
| UInt16 | ❌ | ✅ |
| UInt32 | ❌ | ✅ |
| Int8 | ❌ | ✅ |
| Int16 | ❌ | ✅ |
| Int32 | ❌ | ✅ |
| Float16 | ❌ | ✅ |
| Float32 | ❌ | ✅ |
| Float64 | ❌ | ✅ |
| Boolean | ❌ | ❌ |

## Luau Strings
|value|read|write|description|
|-----|----|-----|-----------|
| String | ❌ | ❌ |string with its length encoded at the start|
| ChunkString | ❌ | ❌ |string split into chunks, similar to gif block values|
| NullTerminatedString | ❌ | ❌ |string of infinite length until a byte with a value of 0|

## Roblox Types
|value|read|write|
|-----|----|-----|
| CFrame | ❌ | ❌ |
| Vector3 | ❌ | ❌ |
| Vector2 | ❌ | ❌ |
| BrickColor | ❌ | ❌ |
| Color3 | ❌ | ❌ |
| UDim2 | ❌ | ❌ |
| UDim | ❌ | ❌ |
| Enum | ❌ | ❌ |
| NumberRange | ❌ | ❌ |
| NumberSequence | ❌ | ❌ |
| ColorSequence | ❌ | ❌ |