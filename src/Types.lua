export type Read = (b: buffer, offset: number, width: number) -> number
export type Write = (b: buffer, offset: number, value: number, width: number) -> ()

export type ToBase = (b: buffer, separator: string?, prefix: (string | boolean)?, useBigEndian: boolean?) -> string
export type FromBase = (str: string) -> buffer

export type BufferRead<T> = (b: buffer, offset: number) -> T
export type BitBufferRead<T> = (self: Reader) -> T

export type BufferWrite<T> = (b: buffer, offset: number, value: T) -> ()
export type BitBufferWrite<T> = (self: Writer, value: T) -> ()

type ReadNumber = (self: Reader) -> number
type ReadVariableWidthNumber = (self: Reader, width: number) -> number

type WriteNumber = (self: Writer, value: number) -> ()
type WriteVariableWidthNumber = (self: Writer, value: number, width: number) -> ()

export type Editor = {
	_buffer: buffer,
	_offset: number,
	_byte: number,
	_isByteAligned: boolean?,

	SetOffset: (self: Editor, offset: number, updateByteOffset: boolean?) -> (),
	Skip: (self: Editor, amount: number, updateByteOffset: boolean?) -> (),
	Align: (self: Editor) -> (),

	UpdateByteOffset: (self: Editor) -> (),
}

export type Reader = {
	UInt: ReadVariableWidthNumber,
	UInt8: ReadNumber,
	UInt16: ReadNumber,
	UInt24: ReadNumber,
	UInt32: ReadNumber,

	Int: ReadVariableWidthNumber,
	Int8: ReadNumber,
	Int16: ReadNumber,
	Int24: ReadNumber,
	Int32: ReadNumber,

	Float16: ReadNumber,
	Float32: ReadNumber,
	Float64: ReadNumber,

	String: (self: Reader, lengthWidth: number?) -> string,
	NullTerminatedString: (self: Reader) -> string,

	Boolean: (self: Reader) -> boolean,

	CFrame: (self: Reader) -> CFrame,

	Vector3: (self: Reader) -> Vector3,
	Vector3int16: (self: Reader) -> Vector3int16,

	Vector2: (self: Reader) -> Vector2,
	Vector2int16: (self: Reader) -> Vector2int16,

	Color3: (self: Reader) -> Color3,
	BrickColor: (self: Reader) -> BrickColor,

	ColorSequence: (self: Reader) -> ColorSequence,
	NumberSequence: (self: Reader) -> NumberSequence,

	Enum: (self: Reader, enumType: Enum?) -> EnumItem,

	Variadic: <T>(self: Reader, readCallback: (self: Reader) -> T, count: number) -> ...T,
} & Editor

export type Writer = {
	UInt: WriteVariableWidthNumber,
	UInt8: WriteNumber,
	UInt16: WriteNumber,
	UInt24: WriteNumber,
	UInt32: WriteNumber,

	Int: WriteVariableWidthNumber,
	Int8: WriteNumber,
	Int16: WriteNumber,
	Int24: WriteNumber,
	Int32: WriteNumber,

	Float16: WriteNumber,
	Float32: WriteNumber,
	Float64: WriteNumber,

	String: (self: Writer, value: string, lengthWidth: number?) -> (),
	NullTerminatedString: (self: Writer, value: string) -> (),

	Boolean: (self: Writer, value: boolean) -> (),

	CFrame: (self: Writer, value: CFrame) -> (),

	Vector3: (self: Writer, value: Vector3) -> (),
	Vector3int16: (self: Writer, value: Vector3int16) -> (),

	Vector2: (self: Writer, value: Vector2) -> (),
	Vector2int16: (self: Writer, value: Vector2int16) -> (),

	Color3: (self: Writer, value: Color3) -> (),
	BrickColor: (self: Writer, value: BrickColor) -> (),

	ColorSequence: (self: Writer, value: ColorSequence) -> (),
	NumberSequence: (self: Writer, value: NumberSequence) -> (),

	Enum: (self: Writer, value: EnumItem, enumType: Enum?) -> (),

	Variadic: <T>(self: Writer, readCallback: (self: Reader) -> T, ...T) -> (),
} & Editor

return {}
