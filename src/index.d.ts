type _writer<T> = (b: buffer, byte: number, bit: number, value: T) => void;
type _iWriter = _writer<number>
type _reader<T> = (b: buffer, byte: number, bit: number) => T;
type _iReader = _reader<number>
declare interface bitbuffer {
	/**
	 * Writes a 1 bit unsigned integer [0, 1]
	 */
	writeu1: _iWriter,
	/**
	 * Writes a 2 bit unsigned integer [0, 3]
	 */
	writeu2: _iWriter,
	/**
	 * Writes a 3 bit unsigned integer [0, 7]
	 */
	writeu3: _iWriter,
	/**
	 * Writes a 4 bit unsigned integer [0, 15]
	 */
	writeu4: _iWriter,
	/**
	 * Writes a 5 bit unsigned integer [0, 31]
	 */
	writeu5: _iWriter,
	/**
	 * Writes a 6 bit unsigned integer [0, 63]
	 */
	writeu6: _iWriter,
	/**
	 * Writes a 7 bit unsigned integer [0, 127]
	 */
	writeu7: _iWriter,
	/**
	 * Writes a 8 bit unsigned integer [0, 255]
	 */
	writeu8: _iWriter,
	/**
	 * Writes a 9 bit unsigned integer [0, 511]
	 */
	writeu9: _iWriter,
	/**
	 * Writes a 10 bit unsigned integer [0, 1023]
	 */
	writeu10: _iWriter,
	/**
	 * Writes a 11 bit unsigned integer [0, 2047]
	 */
	writeu11: _iWriter,
	/**
	 * Writes a 12 bit unsigned integer [0, 4095]
	 */
	writeu12: _iWriter,
	/**
	 * Writes a 13 bit unsigned integer [0, 8191]
	 */
	writeu13: _iWriter,
	/**
	 * Writes a 14 bit unsigned integer [0, 16383]
	 */
	writeu14: _iWriter,
	/**
	 * Writes a 15 bit unsigned integer [0, 32767]
	 */
	writeu15: _iWriter,
	/**
	 * Writes a 16 bit unsigned integer [0, 65535]
	 */
	writeu16: _iWriter,
	/**
	 * Writes a 17 bit unsigned integer [0, 131071]
	 */
	writeu17: _iWriter,
	/**
	 * Writes a 18 bit unsigned integer [0, 262143]
	 */
	writeu18: _iWriter,
	/**
	 * Writes a 19 bit unsigned integer [0, 524287]
	 */
	writeu19: _iWriter,
	/**
	 * Writes a 20 bit unsigned integer [0, 1048575]
	 */
	writeu20: _iWriter,
	/**
	 * Writes a 21 bit unsigned integer [0, 2097151]
	 */
	writeu21: _iWriter,
	/**
	 * Writes a 22 bit unsigned integer [0, 4194303]
	 */
	writeu22: _iWriter,
	/**
	 * Writes a 23 bit unsigned integer [0, 8388607]
	 */
	writeu23: _iWriter,
	/**
	 * Writes a 24 bit unsigned integer [0, 16777215]
	 */
	writeu24: _iWriter,
	/**
	 * Writes a 25 bit unsigned integer [0, 33554431]
	 */
	writeu25: _iWriter,
	/**
	 * Writes a 26 bit unsigned integer [0, 67108863]
	 */
	writeu26: _iWriter,
	/**
	 * Writes a 27 bit unsigned integer [0, 134217727]
	 */
	writeu27: _iWriter,
	/**
	 * Writes a 28 bit unsigned integer [0, 268435455]
	 */
	writeu28: _iWriter,
	/**
	 * Writes a 29 bit unsigned integer [0, 536870911]
	 */
	writeu29: _iWriter,
	/**
	 * Writes a 30 bit unsigned integer [0, 1073741823]
	 */
	writeu30: _iWriter,
	/**
	 * Writes a 31 bit unsigned integer [0, 2147483647]
	 */
	writeu31: _iWriter,
	/**
	 * Writes a 32 bit unsigned integer [0, 4294967295]
	 */
	writeu32: _iWriter,
	/**
	 * Writes a 33 bit unsigned integer [0, 8589934591]
	 */
	writeu33: _iWriter,
	/**
	 * Writes a 34 bit unsigned integer [0, 17179869183]
	 */
	writeu34: _iWriter,
	/**
	 * Writes a 35 bit unsigned integer [0, 34359738367]
	 */
	writeu35: _iWriter,
	/**
	 * Writes a 36 bit unsigned integer [0, 68719476735]
	 */
	writeu36: _iWriter,
	/**
	 * Writes a 37 bit unsigned integer [0, 137438953471]
	 */
	writeu37: _iWriter,
	/**
	 * Writes a 38 bit unsigned integer [0, 274877906943]
	 */
	writeu38: _iWriter,
	/**
	 * Writes a 39 bit unsigned integer [0, 549755813887]
	 */
	writeu39: _iWriter,
	/**
	 * Writes a 40 bit unsigned integer [0, 1099511627775]
	 */
	writeu40: _iWriter,
	/**
	 * Writes a 41 bit unsigned integer [0, 2199023255551]
	 */
	writeu41: _iWriter,
	/**
	 * Writes a 42 bit unsigned integer [0, 4398046511103]
	 */
	writeu42: _iWriter,
	/**
	 * Writes a 43 bit unsigned integer [0, 8796093022207]
	 */
	writeu43: _iWriter,
	/**
	 * Writes a 44 bit unsigned integer [0, 17592186044415]
	 */
	writeu44: _iWriter,
	/**
	 * Writes a 45 bit unsigned integer [0, 35184372088831]
	 */
	writeu45: _iWriter,
	/**
	 * Writes a 46 bit unsigned integer [0, 70368744177663]
	 */
	writeu46: _iWriter,
	/**
	 * Writes a 47 bit unsigned integer [0, 140737488355327]
	 */
	writeu47: _iWriter,
	/**
	 * Writes a 48 bit unsigned integer [0, 281474976710655]
	 */
	writeu48: _iWriter,
	/**
	 * Writes a 49 bit unsigned integer [0, 562949953421311]
	 */
	writeu49: _iWriter,
	/**
	 * Writes a 50 bit unsigned integer [0, 1125899906842623]
	 */
	writeu50: _iWriter,
	/**
	 * Writes a 51 bit unsigned integer [0, 2251799813685247]
	 */
	writeu51: _iWriter,
	/**
	 * Writes a 52 bit unsigned integer [0, 4503599627370495]
	 */
	writeu52: _iWriter,
	/**
	 * Writes a 53 bit unsigned integer [0, 9007199254740991]
	 */
	writeu53: _iWriter,
	// Readers
	/**
	 * Reads a 1 bit unsigned integer [0, 1]
	 */
	readu1: _iReader,
	/**
	 * Reads a 2 bit unsigned integer [0, 3]
	 */
	readu2: _iReader,
	/**
	 * Reads a 3 bit unsigned integer [0, 7]
	 */
	readu3: _iReader,
	/**
	 * Reads a 4 bit unsigned integer [0, 15]
	 */
	readu4: _iReader,
	/**
	 * Reads a 5 bit unsigned integer [0, 31]
	 */
	readu5: _iReader,
	/**
	 * Reads a 6 bit unsigned integer [0, 63]
	 */
	readu6: _iReader,
	/**
	 * Reads a 7 bit unsigned integer [0, 127]
	 */
	readu7: _iReader,
	/**
	 * Reads a 8 bit unsigned integer [0, 255]
	 */
	readu8: _iReader,
	/**
	 * Reads a 9 bit unsigned integer [0, 511]
	 */
	readu9: _iReader,
	/**
	 * Reads a 10 bit unsigned integer [0, 1023]
	 */
	readu10: _iReader,
	/**
	 * Reads a 11 bit unsigned integer [0, 2047]
	 */
	readu11: _iReader,
	/**
	 * Reads a 12 bit unsigned integer [0, 4095]
	 */
	readu12: _iReader,
	/**
	 * Reads a 13 bit unsigned integer [0, 8191]
	 */
	readu13: _iReader,
	/**
	 * Reads a 14 bit unsigned integer [0, 16383]
	 */
	readu14: _iReader,
	/**
	 * Reads a 15 bit unsigned integer [0, 32767]
	 */
	readu15: _iReader,
	/**
	 * Reads a 16 bit unsigned integer [0, 65535]
	 */
	readu16: _iReader,
	/**
	 * Reads a 17 bit unsigned integer [0, 131071]
	 */
	readu17: _iReader,
	/**
	 * Reads a 18 bit unsigned integer [0, 262143]
	 */
	readu18: _iReader,
	/**
	 * Reads a 19 bit unsigned integer [0, 524287]
	 */
	readu19: _iReader,
	/**
	 * Reads a 20 bit unsigned integer [0, 1048575]
	 */
	readu20: _iReader,
	/**
	 * Reads a 21 bit unsigned integer [0, 2097151]
	 */
	readu21: _iReader,
	/**
	 * Reads a 22 bit unsigned integer [0, 4194303]
	 */
	readu22: _iReader,
	/**
	 * Reads a 23 bit unsigned integer [0, 8388607]
	 */
	readu23: _iReader,
	/**
	 * Reads a 24 bit unsigned integer [0, 16777215]
	 */
	readu24: _iReader,
	/**
	 * Reads a 25 bit unsigned integer [0, 33554431]
	 */
	readu25: _iReader,
	/**
	 * Reads a 26 bit unsigned integer [0, 67108863]
	 */
	readu26: _iReader,
	/**
	 * Reads a 27 bit unsigned integer [0, 134217727]
	 */
	readu27: _iReader,
	/**
	 * Reads a 28 bit unsigned integer [0, 268435455]
	 */
	readu28: _iReader,
	/**
	 * Reads a 29 bit unsigned integer [0, 536870911]
	 */
	readu29: _iReader,
	/**
	 * Reads a 30 bit unsigned integer [0, 1073741823]
	 */
	readu30: _iReader,
	/**
	 * Reads a 31 bit unsigned integer [0, 2147483647]
	 */
	readu31: _iReader,
	/**
	 * Reads a 32 bit unsigned integer [0, 4294967295]
	 */
	readu32: _iReader,
	/**
	 * Reads a 33 bit unsigned integer [0, 8589934591]
	 */
	readu33: _iReader,
	/**
	 * Reads a 34 bit unsigned integer [0, 17179869183]
	 */
	readu34: _iReader,
	/**
	 * Reads a 35 bit unsigned integer [0, 34359738367]
	 */
	readu35: _iReader,
	/**
	 * Reads a 36 bit unsigned integer [0, 68719476735]
	 */
	readu36: _iReader,
	/**
	 * Reads a 37 bit unsigned integer [0, 137438953471]
	 */
	readu37: _iReader,
	/**
	 * Reads a 38 bit unsigned integer [0, 274877906943]
	 */
	readu38: _iReader,
	/**
	 * Reads a 39 bit unsigned integer [0, 549755813887]
	 */
	readu39: _iReader,
	/**
	 * Reads a 40 bit unsigned integer [0, 1099511627775]
	 */
	readu40: _iReader,
	/**
	 * Reads a 41 bit unsigned integer [0, 2199023255551]
	 */
	readu41: _iReader,
	/**
	 * Reads a 42 bit unsigned integer [0, 4398046511103]
	 */
	readu42: _iReader,
	/**
	 * Reads a 43 bit unsigned integer [0, 8796093022207]
	 */
	readu43: _iReader,
	/**
	 * Reads a 44 bit unsigned integer [0, 17592186044415]
	 */
	readu44: _iReader,
	/**
	 * Reads a 45 bit unsigned integer [0, 35184372088831]
	 */
	readu45: _iReader,
	/**
	 * Reads a 46 bit unsigned integer [0, 70368744177663]
	 */
	readu46: _iReader,
	/**
	 * Reads a 47 bit unsigned integer [0, 140737488355327]
	 */
	readu47: _iReader,
	/**
	 * Reads a 48 bit unsigned integer [0, 281474976710655]
	 */
	readu48: _iReader,
	/**
	 * Reads a 49 bit unsigned integer [0, 562949953421311]
	 */
	readu49: _iReader,
	/**
	 * Reads a 50 bit unsigned integer [0, 1125899906842623]
	 */
	readu50: _iReader,
	/**
	 * Reads a 51 bit unsigned integer [0, 2251799813685247]
	 */
	readu51: _iReader,
	/**
	 * Reads a 52 bit unsigned integer [0, 4503599627370495]
	 */
	readu52: _iReader,
	/**
	 * Reads a 53 bit unsigned integer [0, 9007199254740991]
	 */
	readu53: _iReader,

	readu: _iReader[],
	writeu: _iWriter[],
	// Signed Writers
	/**
	 * Writes a 2 bit signed integer [-2, 1]
	 */
	writei2: _iWriter,
	/**
	 * Writes a 3 bit signed integer [-4, 3]
	 */
	writei3: _iWriter,
	/**
	 * Writes a 4 bit signed integer [-8, 7]
	 */
	writei4: _iWriter,
	/**
	 * Writes a 5 bit signed integer [-16, 15]
	 */
	writei5: _iWriter,
	/**
	 * Writes a 6 bit signed integer [-32, 31]
	 */
	writei6: _iWriter,
	/**
	 * Writes a 7 bit signed integer [-64, 63]
	 */
	writei7: _iWriter,
	/**
	 * Writes a 8 bit signed integer [-128, 127]
	 */
	writei8: _iWriter,
	/**
	 * Writes a 9 bit signed integer [-256, 255]
	 */
	writei9: _iWriter,
	/**
	 * Writes a 10 bit signed integer [-512, 511]
	 */
	writei10: _iWriter,
	/**
	 * Writes a 11 bit signed integer [-1024, 1023]
	 */
	writei11: _iWriter,
	/**
	 * Writes a 12 bit signed integer [-2048, 2047]
	 */
	writei12: _iWriter,
	/**
	 * Writes a 13 bit signed integer [-4096, 4095]
	 */
	writei13: _iWriter,
	/**
	 * Writes a 14 bit signed integer [-8192, 8191]
	 */
	writei14: _iWriter,
	/**
	 * Writes a 15 bit signed integer [-16384, 16383]
	 */
	writei15: _iWriter,
	/**
	 * Writes a 16 bit signed integer [-32768, 32767]
	 */
	writei16: _iWriter,
	/**
	 * Writes a 17 bit signed integer [-65536, 65535]
	 */
	writei17: _iWriter,
	/**
	 * Writes a 18 bit signed integer [-131072, 131071]
	 */
	writei18: _iWriter,
	/**
	 * Writes a 19 bit signed integer [-262144, 262143]
	 */
	writei19: _iWriter,
	/**
	 * Writes a 20 bit signed integer [-524288, 524287]
	 */
	writei20: _iWriter,
	/**
	 * Writes a 21 bit signed integer [-1048576, 1048575]
	 */
	writei21: _iWriter,
	/**
	 * Writes a 22 bit signed integer [-2097152, 2097151]
	 */
	writei22: _iWriter,
	/**
	 * Writes a 23 bit signed integer [-4194304, 4194303]
	 */
	writei23: _iWriter,
	/**
	 * Writes a 24 bit signed integer [-8388608, 8388607]
	 */
	writei24: _iWriter,
	/**
	 * Writes a 25 bit signed integer [-16777216, 16777215]
	 */
	writei25: _iWriter,
	/**
	 * Writes a 26 bit signed integer [-33554432, 33554431]
	 */
	writei26: _iWriter,
	/**
	 * Writes a 27 bit signed integer [-67108864, 67108863]
	 */
	writei27: _iWriter,
	/**
	 * Writes a 28 bit signed integer [-134217728, 134217727]
	 */
	writei28: _iWriter,
	/**
	 * Writes a 29 bit signed integer [-268435456, 268435455]
	 */
	writei29: _iWriter,
	/**
	 * Writes a 30 bit signed integer [-536870912, 536870911]
	 */
	writei30: _iWriter,
	/**
	 * Writes a 31 bit signed integer [-1073741824, 1073741823]
	 */
	writei31: _iWriter,
	/**
	 * Writes a 32 bit signed integer [-2147483648, 2147483647]
	 */
	writei32: _iWriter,
	/**
	 * Writes a 33 bit signed integer [-4294967296, 4294967295]
	 */
	writei33: _iWriter,
	/**
	 * Writes a 34 bit signed integer [-8589934592, 8589934591]
	 */
	writei34: _iWriter,
	/**
	 * Writes a 35 bit signed integer [-17179869184, 17179869183]
	 */
	writei35: _iWriter,
	/**
	 * Writes a 36 bit signed integer [-34359738368, 34359738367]
	 */
	writei36: _iWriter,
	/**
	 * Writes a 37 bit signed integer [-68719476736, 68719476735]
	 */
	writei37: _iWriter,
	/**
	 * Writes a 38 bit signed integer [-137438953472, 137438953471]
	 */
	writei38: _iWriter,
	/**
	 * Writes a 39 bit signed integer [-274877906944, 274877906943]
	 */
	writei39: _iWriter,
	/**
	 * Writes a 40 bit signed integer [-549755813888, 549755813887]
	 */
	writei40: _iWriter,
	/**
	 * Writes a 41 bit signed integer [-1099511627776, 1099511627775]
	 */
	writei41: _iWriter,
	/**
	 * Writes a 42 bit signed integer [-2199023255552, 2199023255551]
	 */
	writei42: _iWriter,
	/**
	 * Writes a 43 bit signed integer [-4398046511104, 4398046511103]
	 */
	writei43: _iWriter,
	/**
	 * Writes a 44 bit signed integer [-8796093022208, 8796093022207]
	 */
	writei44: _iWriter,
	/**
	 * Writes a 45 bit signed integer [-17592186044416, 17592186044415]
	 */
	writei45: _iWriter,
	/**
	 * Writes a 46 bit signed integer [-35184372088832, 35184372088831]
	 */
	writei46: _iWriter,
	/**
	 * Writes a 47 bit signed integer [-70368744177664, 70368744177663]
	 */
	writei47: _iWriter,
	/**
	 * Writes a 48 bit signed integer [-140737488355328, 140737488355327]
	 */
	writei48: _iWriter,
	/**
	 * Writes a 49 bit signed integer [-281474976710656, 281474976710655]
	 */
	writei49: _iWriter,
	/**
	 * Writes a 50 bit signed integer [-562949953421312, 562949953421311]
	 */
	writei50: _iWriter,
	/**
	 * Writes a 51 bit signed integer [-1125899906842624, 1125899906842623]
	 */
	writei51: _iWriter,
	/**
	 * Writes a 52 bit signed integer [-2251799813685248, 2251799813685247]
	 */
	writei52: _iWriter,
	// Signed Readers
	/**
	 * Reads a 2 bit signed integer [-2, 1]
	 */
	readi2: _iReader,
	/**
	 * Reads a 3 bit signed integer [-4, 3]
	 */
	readi3: _iReader,
	/**
	 * Reads a 4 bit signed integer [-8, 7]
	 */
	readi4: _iReader,
	/**
	 * Reads a 5 bit signed integer [-16, 15]
	 */
	readi5: _iReader,
	/**
	 * Reads a 6 bit signed integer [-32, 31]
	 */
	readi6: _iReader,
	/**
	 * Reads a 7 bit signed integer [-64, 63]
	 */
	readi7: _iReader,
	/**
	 * Reads a 8 bit signed integer [-128, 127]
	 */
	readi8: _iReader,
	/**
	 * Reads a 9 bit signed integer [-256, 255]
	 */
	readi9: _iReader,
	/**
	 * Reads a 10 bit signed integer [-512, 511]
	 */
	readi10: _iReader,
	/**
	 * Reads a 11 bit signed integer [-1024, 1023]
	 */
	readi11: _iReader,
	/**
	 * Reads a 12 bit signed integer [-2048, 2047]
	 */
	readi12: _iReader,
	/**
	 * Reads a 13 bit signed integer [-4096, 4095]
	 */
	readi13: _iReader,
	/**
	 * Reads a 14 bit signed integer [-8192, 8191]
	 */
	readi14: _iReader,
	/**
	 * Reads a 15 bit signed integer [-16384, 16383]
	 */
	readi15: _iReader,
	/**
	 * Reads a 16 bit signed integer [-32768, 32767]
	 */
	readi16: _iReader,
	/**
	 * Reads a 17 bit signed integer [-65536, 65535]
	 */
	readi17: _iReader,
	/**
	 * Reads a 18 bit signed integer [-131072, 131071]
	 */
	readi18: _iReader,
	/**
	 * Reads a 19 bit signed integer [-262144, 262143]
	 */
	readi19: _iReader,
	/**
	 * Reads a 20 bit signed integer [-524288, 524287]
	 */
	readi20: _iReader,
	/**
	 * Reads a 21 bit signed integer [-1048576, 1048575]
	 */
	readi21: _iReader,
	/**
	 * Reads a 22 bit signed integer [-2097152, 2097151]
	 */
	readi22: _iReader,
	/**
	 * Reads a 23 bit signed integer [-4194304, 4194303]
	 */
	readi23: _iReader,
	/**
	 * Reads a 24 bit signed integer [-8388608, 8388607]
	 */
	readi24: _iReader,
	/**
	 * Reads a 25 bit signed integer [-16777216, 16777215]
	 */
	readi25: _iReader,
	/**
	 * Reads a 26 bit signed integer [-33554432, 33554431]
	 */
	readi26: _iReader,
	/**
	 * Reads a 27 bit signed integer [-67108864, 67108863]
	 */
	readi27: _iReader,
	/**
	 * Reads a 28 bit signed integer [-134217728, 134217727]
	 */
	readi28: _iReader,
	/**
	 * Reads a 29 bit signed integer [-268435456, 268435455]
	 */
	readi29: _iReader,
	/**
	 * Reads a 30 bit signed integer [-536870912, 536870911]
	 */
	readi30: _iReader,
	/**
	 * Reads a 31 bit signed integer [-1073741824, 1073741823]
	 */
	readi31: _iReader,
	/**
	 * Reads a 32 bit signed integer [-2147483648, 2147483647]
	 */
	readi32: _iReader,
	/**
	 * Reads a 33 bit signed integer [-4294967296, 4294967295]
	 */
	readi33: _iReader,
	/**
	 * Reads a 34 bit signed integer [-8589934592, 8589934591]
	 */
	readi34: _iReader,
	/**
	 * Reads a 35 bit signed integer [-17179869184, 17179869183]
	 */
	readi35: _iReader,
	/**
	 * Reads a 36 bit signed integer [-34359738368, 34359738367]
	 */
	readi36: _iReader,
	/**
	 * Reads a 37 bit signed integer [-68719476736, 68719476735]
	 */
	readi37: _iReader,
	/**
	 * Reads a 38 bit signed integer [-137438953472, 137438953471]
	 */
	readi38: _iReader,
	/**
	 * Reads a 39 bit signed integer [-274877906944, 274877906943]
	 */
	readi39: _iReader,
	/**
	 * Reads a 40 bit signed integer [-549755813888, 549755813887]
	 */
	readi40: _iReader,
	/**
	 * Reads a 41 bit signed integer [-1099511627776, 1099511627775]
	 */
	readi41: _iReader,
	/**
	 * Reads a 42 bit signed integer [-2199023255552, 2199023255551]
	 */
	readi42: _iReader,
	/**
	 * Reads a 43 bit signed integer [-4398046511104, 4398046511103]
	 */
	readi43: _iReader,
	/**
	 * Reads a 44 bit signed integer [-8796093022208, 8796093022207]
	 */
	readi44: _iReader,
	/**
	 * Reads a 45 bit signed integer [-17592186044416, 17592186044415]
	 */
	readi45: _iReader,
	/**
	 * Reads a 46 bit signed integer [-35184372088832, 35184372088831]
	 */
	readi46: _iReader,
	/**
	 * Reads a 47 bit signed integer [-70368744177664, 70368744177663]
	 */
	readi47: _iReader,
	/**
	 * Reads a 48 bit signed integer [-140737488355328, 140737488355327]
	 */
	readi48: _iReader,
	/**
	 * Reads a 49 bit signed integer [-281474976710656, 281474976710655]
	 */
	readi49: _iReader,
	/**
	 * Reads a 50 bit signed integer [-562949953421312, 562949953421311]
	 */
	readi50: _iReader,
	/**
	 * Reads a 51 bit signed integer [-1125899906842624, 1125899906842623]
	 */
	readi51: _iReader,
	/**
	 * Reads a 52 bit signed integer [-2251799813685248, 2251799813685247]
	 */
	readi52: _iReader,
	readi: _iReader[],
	writei: _iWriter[],
	// Float writers
	/**
	 * Writes a Half-precision IEEE 754 number
	 */
	writef16: _iWriter,
	/**
	 * Writes a Single-precision IEEE 754 number
	 */
	writef32: _iWriter,
	/**
	 * Writes a Double-precision IEEE 754 number
	 */
	writef64: _iWriter,
	// Float readers
	/**
	 * Reads a Half-precision IEEE 754 number
	 */
	readf16: _iReader,
	/**
	 * Reads a Single-precision IEEE 754 number
	 */
	readf32: _iReader,
	/**
	 * Reads a Double-precision IEEE 754 number
	 */
	readf64: _iReader
	// Strings
	/**
	 * Used to write data from a string into the buffer at a specified offset.
	 *
	 * If an optional `count` is specified, only `count` bytes are taken from the string.
	 *
	 * Count cannot be larger than the string length.
	 */
	writestring: _writer<string>,
	/**
	 * Used to read a string of length `count` from the buffer at specified offset.
	 */
	readstring: _reader<string>

	// Other
	/**
	 * Sets the `count` bits in the buffer starting at the specified `offset` to the `value`.
	 *
	 * If `count` is `undefined` or is omitted, all bytes from the specified offset until the end of the buffer are set.
	 */
	fill: (b: buffer, byte: number, bit: number, value: number, count?: number) => void
	/**
	 * Copy `count` bytes from `source` starting at offset `sourceOffset` into the `target` at `targetOffset`.
	 *
	 * Unlike `buffer.copy`, it is not possible for `source` and `target` to be the same and then copy an overlapping region. This may be added in future.
	 *
	 * If `sourceOffset` is `undefined` or is omitted, it defaults to 0.
	 *
	 * If `count` is `undefined` or is omitted, the whole `source` data starting from `sourceOffset` is copied.
	 */
	copy: (
		target: buffer,
		targetByte: number,
		targetBit: number,
		source: buffer,
		sourceByte?: number,
		sourceBit?: number,
		count?: number
	) => void;
	/**
	 *	Returns the buffer data as a binary string, mainly useful for debugging.
	 *
	 *	@param b buffer
	 *	@param separator the separator characters to use between bytes
	 *
	 *	@return the binary string
	 */
	tobinary: (b: buffer, separator?: string) => string,
	/**
	 * Creates a buffer initialized to the contents of the 'binary' string.
	 * @param str the binary string
	 * @param separator the separator characters to use between bytes
	 * @returns decoded buffer
	 */
	frombinary: (str: string, separator?: string) => buffer,
	/**
	 * Returns the buffer data as a hexadecimal string, mainly useful for debugging.
	 * @param b the source buffer
	 * @param separator the separator characters to use between bytes
	 * @returns a hexadecimal string
	 */
	tohexadecimal: (b: buffer, separator?: string) => string,
	/**
	 * Creates a buffer initialized to the contents of the hexadecimal string.
	 * @param str a hexadecimal string
	 * @param separator the separator characters to use between bytes
	 * @returns 
	 */
	fromhexadecimal: (str: string, separator?: string) => buffer,
	/**
	 * Returns the buffer data as a base64 encoded string.
	 * @param b the source buffer
	 * @returns a base64 encoded string
	 */
	tobase64: (b: buffer) => string
	/**
	 * Creates a buffer initialized to the contents of the base64 encoded string.
	 * @param str a base64 encoded string
	 * @returns the decoded buffer
	 */
	frombase64: (str: string) => buffer
	
	writer: (b: buffer) => Writer;
	reader: (b: buffer) => Reader
}
declare interface Writer {
	IncrementOffset: (amount: number) => void;
	Align: () => void;
	UInt1: (value: number) => void;
	UInt2: (value: number) => void;
	UInt3: (value: number) => void;
	UInt4: (value: number) => void;
	UInt5: (value: number) => void;
	UInt6: (value: number) => void;
	UInt7: (value: number) => void;
	UInt8: (value: number) => void;
	UInt9: (value: number) => void;
	UInt10: (value: number) => void;
	UInt11: (value: number) => void;
	UInt12: (value: number) => void;
	UInt13: (value: number) => void;
	UInt14: (value: number) => void;
	UInt15: (value: number) => void;
	UInt16: (value: number) => void;
	UInt17: (value: number) => void;
	UInt18: (value: number) => void;
	UInt19: (value: number) => void;
	UInt20: (value: number) => void;
	UInt21: (value: number) => void;
	UInt22: (value: number) => void;
	UInt23: (value: number) => void;
	UInt24: (value: number) => void;
	UInt25: (value: number) => void;
	UInt26: (value: number) => void;
	UInt27: (value: number) => void;
	UInt28: (value: number) => void;
	UInt29: (value: number) => void;
	UInt30: (value: number) => void;
	UInt31: (value: number) => void;
	UInt32: (value: number) => void;
	UInt33: (value: number) => void;
	UInt34: (value: number) => void;
	UInt35: (value: number) => void;
	UInt36: (value: number) => void;
	UInt37: (value: number) => void;
	UInt38: (value: number) => void;
	UInt39: (value: number) => void;
	UInt40: (value: number) => void;
	UInt41: (value: number) => void;
	UInt42: (value: number) => void;
	UInt43: (value: number) => void;
	UInt44: (value: number) => void;
	UInt45: (value: number) => void;
	UInt46: (value: number) => void;
	UInt47: (value: number) => void;
	UInt48: (value: number) => void;
	UInt49: (value: number) => void;
	UInt50: (value: number) => void;
	UInt51: (value: number) => void;
	UInt52: (value: number) => void;
	UInt53: (value: number) => void;

	Int2: (value: number) => void;
	Int3: (value: number) => void;
	Int4: (value: number) => void;
	Int5: (value: number) => void;
	Int6: (value: number) => void;
	Int7: (value: number) => void;
	Int8: (value: number) => void;
	Int9: (value: number) => void;
	Int10: (value: number) => void;
	Int11: (value: number) => void;
	Int12: (value: number) => void;
	Int13: (value: number) => void;
	Int14: (value: number) => void;
	Int15: (value: number) => void;
	Int16: (value: number) => void;
	Int17: (value: number) => void;
	Int18: (value: number) => void;
	Int19: (value: number) => void;
	Int20: (value: number) => void;
	Int21: (value: number) => void;
	Int22: (value: number) => void;
	Int23: (value: number) => void;
	Int24: (value: number) => void;
	Int25: (value: number) => void;
	Int26: (value: number) => void;
	Int27: (value: number) => void;
	Int28: (value: number) => void;
	Int29: (value: number) => void;
	Int30: (value: number) => void;
	Int31: (value: number) => void;
	Int32: (value: number) => void;
	Int33: (value: number) => void;
	Int34: (value: number) => void;
	Int35: (value: number) => void;
	Int36: (value: number) => void;
	Int37: (value: number) => void;
	Int38: (value: number) => void;
	Int39: (value: number) => void;
	Int40: (value: number) => void;
	Int41: (value: number) => void;
	Int42: (value: number) => void;
	Int43: (value: number) => void;
	Int44: (value: number) => void;
	Int45: (value: number) => void;
	Int46: (value: number) => void;
	Int47: (value: number) => void;
	Int48: (value: number) => void;
	Int49: (value: number) => void;
	Int50: (value: number) => void;
	Int51: (value: number) => void;
	Int52: (value: number) => void;
	Int53: (value: number) => void;

	Float32: (value: number) => void;
	Float64: (value: number) => void;
	NumberSequence: (value: NumberSequence) => void;
	ColorSequence: (value: ColorSequence) => void;
	CFrame: (value: CFrame) => void;
	Boolean: (value: boolean) => void;
	LosslessCFrame: (value: CFrame) => void;
	NumberRange: (value: NumberRange) => void;
	Vector3int16: (value: Vector3int16) => void;
	Vector2int16: (value: Vector2int16) => void;
	UDim2: (value: UDim2) => void;
	NumberSequenceKeypoint: (value: NumberSequenceKeypoint) => void;
	BrickColor: (value: BrickColor) => void;
	Vector2: (value: Vector2) => void;
	UDim: (value: UDim) => void;
	Color3: (value: Color3) => void;
	ColorSequenceKeypoint: (value: ColorSequenceKeypoint) => void;
	Vector3: (value: Vector3) => void;
}
declare interface Reader {
	IncrementOffset: (amount: number) => void
	Align: () => void
	UInt1: () => number
	UInt2: () => number
	UInt3: () => number
	UInt4: () => number
	UInt5: () => number
	UInt6: () => number
	UInt7: () => number
	UInt8: () => number
	UInt9: () => number
	UInt10: () => number
	UInt11: () => number
	UInt12: () => number
	UInt13: () => number
	UInt14: () => number
	UInt15: () => number
	UInt16: () => number
	UInt17: () => number
	UInt18: () => number
	UInt19: () => number
	UInt20: () => number
	UInt21: () => number
	UInt22: () => number
	UInt23: () => number
	UInt24: () => number
	UInt25: () => number
	UInt26: () => number
	UInt27: () => number
	UInt28: () => number
	UInt29: () => number
	UInt30: () => number
	UInt31: () => number
	UInt32: () => number
	UInt33: () => number
	UInt34: () => number
	UInt35: () => number
	UInt36: () => number
	UInt37: () => number
	UInt38: () => number
	UInt39: () => number
	UInt40: () => number
	UInt41: () => number
	UInt42: () => number
	UInt43: () => number
	UInt44: () => number
	UInt45: () => number
	UInt46: () => number
	UInt47: () => number
	UInt48: () => number
	UInt49: () => number
	UInt50: () => number
	UInt51: () => number
	UInt52: () => number
	UInt53: () => number

	Int2: () => number
	Int3: () => number
	Int4: () => number
	Int5: () => number
	Int6: () => number
	Int7: () => number
	Int8: () => number
	Int9: () => number
	Int10: () => number
	Int12: () => number
	Int13: () => number
	Int14: () => number
	Int15: () => number
	Int16: () => number
	Int17: () => number
	Int18: () => number
	Int19: () => number
	Int20: () => number
	Int22: () => number
	Int23: () => number
	Int24: () => number
	Int25: () => number
	Int26: () => number
	Int27: () => number
	Int28: () => number
	Int29: () => number
	Int30: () => number
	Int32: () => number
	Int33: () => number
	Int34: () => number
	Int35: () => number
	Int36: () => number
	Int37: () => number
	Int38: () => number
	Int39: () => number
	Int40: () => number
	Int42: () => number
	Int43: () => number
	Int44: () => number
	Int45: () => number
	Int46: () => number
	Int47: () => number
	Int48: () => number
	Int49: () => number
	Int50: () => number
	Int51: () => number
	Int52: () => number

	Float32: () => number
	Float64: () => number

	NumberSequence: () => NumberSequence
	ColorSequence: () => ColorSequence
	CFrame: () => CFrame
	Boolean: () => boolean
	LosslessCFrame: () => CFrame
	NumberRange: () => NumberRange
	Vector3int16: () => Vector3int16
	Vector2int16: () => Vector2int16
	UDim2: () => UDim2
	NumberSequenceKeypoint: () => NumberSequenceKeypoint
	BrickColor: () => BrickColor
	Vector2: () => Vector2
	UDim: () => UDim
	Color3: () => Color3
	ColorSequenceKeypoint: () => ColorSequenceKeypoint
	Vector3: () => Vector3
}
declare const bitbuffer: bitbuffer;
export = bitbuffer