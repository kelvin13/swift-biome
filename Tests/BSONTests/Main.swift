import Testing
import Base16
import _BSON

@main 
enum Main
{
    static 
    func main() throws
    {
        var tests:UnitTests = .init()
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/multi-type.json
        // cannot use this test, because it encodes a deprecated binary subtype, which is
        // (intentionally) impossible to construct with swift-bson.

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/maxkey.json
        tests.group("max")
        {
            $0.test(name: "max",
                canonical: "080000007F610000",
                expected: ["a": .max])
        }
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/minkey.json
        tests.group("min")
        {
            $0.test(name: "min",
                canonical: "08000000FF610000",
                expected: ["a": .min])
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/null.json
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/undefined.json
        tests.group("null")
        {
            $0.test(name: "null",
                canonical: "080000000A610000",
                expected: ["a": .null])
            
            $0.test(name: "undefined",
                degenerate: "0800000006610000",
                canonical: "080000000A610000",
                expected: ["a": .null])
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/boolean.json
        tests.group("bool")
        {
            $0.test(name: "true",
                canonical: "090000000862000100",
                expected: ["b": true])
            $0.test(name: "false",
                canonical: "090000000862000000",
                expected: ["b": false])
            
            $0.test(name: "invalid-subtype",
                invalid: "090000000862000200",
                failure: BSON.BooleanSubtypeError.invalid(2))
            
            $0.test(name: "invalid-subtype-negative",
                invalid: "09000000086200FF00",
                failure: BSON.BooleanSubtypeError.invalid(255))
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/int32.json
        tests.group("int32")
        {
            $0.test(name: "min",
                canonical: "0C0000001069000000008000",
                expected: ["i": .int32(-2147483648)])
            
            $0.test(name: "max",
                canonical: "0C000000106900FFFFFF7F00",
                expected: ["i": .int32(2147483647)])
            
            $0.test(name: "-1",
                canonical: "0C000000106900FFFFFFFF00",
                expected: ["i": .int32(-1)])
            
            $0.test(name: "0",
                canonical: "0C0000001069000000000000",
                expected: ["i": .int32(0)])
            
            $0.test(name: "+1",
                canonical: "0C0000001069000100000000",
                expected: ["i": .int32(1)])

            $0.test(name: "truncated",
                invalid: "090000001061000500",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/int32.json
        tests.group("int64")
        {
            $0.test(name: "min",
                canonical: "10000000126100000000000000008000",
                expected: ["a": .int64(-9223372036854775808)])
            
            $0.test(name: "max",
                canonical: "10000000126100FFFFFFFFFFFFFF7F00",
                expected: ["a": .int64(9223372036854775807)])
            
            $0.test(name: "-1",
                canonical: "10000000126100FFFFFFFFFFFFFFFF00",
                expected: ["a": .int64(-1)])
            
            $0.test(name: "0",
                canonical: "10000000126100000000000000000000",
                expected: ["a": .int64(0)])
            
            $0.test(name: "+1",
                canonical: "10000000126100010000000000000000",
                expected: ["a": .int64(1)])

            $0.test(name: "truncated",
                invalid: "0C0000001261001234567800",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/timestamp.json
        tests.group("uint64")
        {
            $0.test(name: "(123456789, 42)",
                canonical: "100000001161002A00000015CD5B0700",
                expected: ["a": .uint64(123456789 << 32 | 42)])
            
            $0.test(name: "ones",
                canonical: "10000000116100FFFFFFFFFFFFFFFF00",
                expected: ["a": .uint64(.max)])
            
            $0.test(name: "(4000000000, 4000000000)",
                canonical: "1000000011610000286BEE00286BEE00",
                expected: ["a": .uint64(4000000000 << 32 | 4000000000)])
            
            $0.test(name: "truncated",
                invalid: "0f0000001161002A00000015CD5B00",
                failure: BSON.EndOfInputError.unexpected)
            
            // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/top.json
            $0.group("top")
            {
                $0.test(name: "dollar-prefixed-key",
                    canonical: "0F00000010246B6579002A00000000",
                    expected: ["$key": .int32(42)])
                
                $0.test(name: "dollar-key",
                    canonical: "0E00000002240002000000610000",
                    expected: ["$": "a"])
                
                $0.test(name: "dotted-key",
                    canonical: "1000000002612E620002000000630000",
                    expected: ["a.b": "c"])
                
                $0.test(name: "dot-key",
                    canonical: "0E000000022E0002000000610000",
                    expected: [".": "a"])
                
                $0.test(name: "empty-truncated-header",
                    degenerate: "0100000000",
                    canonical: "0500000000",
                    expected: [:])
                
                $0.test(name: "empty",
                    canonical: "0500000000",
                    expected: [:])
                
                $0.test(name: "invalid-end-of-object-0x01",
                    invalid: "0500000001",
                    failure: BSON.EndOfInputError.unexpected)
                
                $0.test(name: "invalid-end-of-object-0xff",
                    invalid: "05000000FF",
                    failure: BSON.EndOfInputError.unexpected)
                
                $0.test(name: "invalid-end-of-object-0x70",
                    invalid: "0500000070",
                    failure: BSON.EndOfInputError.unexpected)
                
                $0.test(name: "zeroes",
                    invalid: "00000000000000000000",
                    failure: BSON.EndOfInputError.expected(encountered: 5))
                
                $0.test(name: "invalid-length-over",
                    invalid: "1200000002666F6F0004000000626172",
                    failure: BSON.EndOfInputError.unexpected)
                
                $0.test(name: "invalid-length-under",
                    invalid: "1200000002666F6F00040000006261720000DEADBEEF",
                    failure: BSON.EndOfInputError.expected(encountered: 4))
                
                // note: type code 0x00 is interpreted as end-of-object
                $0.test(name: "invalid-type-0x00",
                    invalid: "07000000000000",
                    failure: BSON.EndOfInputError.expected(encountered: 2))
                
                $0.test(name: "invalid-type-0x80",
                    invalid: "07000000800000",
                    failure: BSON.TypeError.init(code: 0x80))
                
                $0.test(name: "truncated",
                    invalid: "1200000002666F",
                    failure: BSON.EndOfInputError.unexpected)
                
                $0.test(name: "invalid-key",
                    invalid: "0D000000107800000100000000",
                    failure: BSON.EndOfInputError.expected(encountered: 1))
                
            }
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/decimal128-1.json
        tests.group("decimal128")
        {
            $0.test(name: "positive-quiet-nan",
                canonical: "180000001364000000000000000000000000000000007C00",
                expected: ["d": .decimal128(.init(
                    high: 0x7C00_0000_0000_0000, 
                    low:  0x0000_0000_0000_0000))])
            
            $0.test(name: "negative-quiet-nan",
                canonical: "18000000136400000000000000000000000000000000FC00",
                expected: ["d": .decimal128(.init(
                    high: 0xFC00_0000_0000_0000, 
                    low:  0x0000_0000_0000_0000))])
            
            $0.test(name: "positive-signaling-nan",
                canonical: "180000001364000000000000000000000000000000007E00",
                expected: ["d": .decimal128(.init(
                    high: 0x7E00_0000_0000_0000, 
                    low:  0x0000_0000_0000_0000))])
            
            $0.test(name: "negative-signaling-nan",
                canonical: "18000000136400000000000000000000000000000000FE00",
                expected: ["d": .decimal128(.init(
                    high: 0xFE00_0000_0000_0000, 
                    low:  0x0000_0000_0000_0000))])
            
            // this only serves to verify we are handling byte-order correctly;
            // there is very little point in elaborating decimal128 tests further
            $0.test(name: "largest",
                canonical: "18000000136400F2AF967ED05C82DE3297FF6FDE3C403000",
                expected: ["d": .decimal128(.init(
                    high: 0x3040_3CDE_6FFF_9732, 
                    low:  0xDE82_5CD0_7E96_AFF2))])
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/datetime.json
        tests.group("millisecond")
        {
            $0.test(name: "epoch",
                canonical: "10000000096100000000000000000000",
                expected: ["a": .millisecond(0)])
            
            $0.test(name: "positive",
                canonical: "10000000096100C5D8D6CC3B01000000",
                expected: ["a": .millisecond(1356351330501)])
            
            $0.test(name: "negative",
                canonical: "10000000096100C33CE7B9BDFFFFFF00",
                expected: ["a": .millisecond(-284643869501)])
            
            $0.test(name: "positive-2",
                canonical: "1000000009610000DC1FD277E6000000",
                expected: ["a": .millisecond(253402300800000)])
            
            $0.test(name: "positive-3",
                canonical: "10000000096100D1D6D6CC3B01000000",
                expected: ["a": .millisecond(1356351330001)])
            
            $0.test(name: "truncated",
                invalid: "0C0000000961001234567800",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/double.json
        tests.group("double")
        {
            $0.test(name: "+1.0",
                canonical: "10000000016400000000000000F03F00",
                expected: ["d": .double(1.0)])
            
            $0.test(name: "-1.0",
                canonical: "10000000016400000000000000F0BF00",
                expected: ["d": .double(-1.0)])
            
            $0.test(name: "+1.0001220703125",
                canonical: "10000000016400000000008000F03F00",
                expected: ["d": .double(1.0001220703125)])
            
            $0.test(name: "-1.0001220703125",
                canonical: "10000000016400000000008000F0BF00",
                expected: ["d": .double(-1.0001220703125)])
            
            $0.test(name: "1.2345678921232E+18",
                canonical: "100000000164002a1bf5f41022b14300",
                expected: ["d": .double(1.2345678921232e18)])
            
            $0.test(name: "-1.2345678921232E+18",
                canonical: "100000000164002a1bf5f41022b1c300",
                expected: ["d": .double(-1.2345678921232e18)])
            
            // remaining corpus test cases are pointless because swift cannot distinguish
            // between -0.0 and +0.0

            // note: frameshift
            $0.test(name: "truncated",
                invalid: "0B0000000164000000F03F00",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/oid.json
        tests.group("id")
        {
            $0.test(name: "zeroes",
                canonical: "1400000007610000000000000000000000000000",
                expected: ["a": .id(.init(timestamp: 0x0000_0000, 
                    (0x00, 0x00, 0x00, 0x00, 0x00), (0x00, 0x00, 0x00)))])
            
            $0.test(name: "ones",
                canonical: "14000000076100FFFFFFFFFFFFFFFFFFFFFFFF00",
                expected: ["a": .id(.init(timestamp: 0xffff_ffff, 
                    (0xff, 0xff, 0xff, 0xff, 0xff), (0xff, 0xff, 0xff)))])
            
            $0.test(name: "random",
                canonical: "1400000007610056E1FC72E0C917E9C471416100",
                expected: ["a": .id(.init(timestamp: 0x56e1_fc72, 
                    (0xe0, 0xc9, 0x17, 0xe9, 0xc4), (0x71, 0x41, 0x61)))])
            
            $0.test(name: "truncated",
                invalid: "1200000007610056E1FC72E0C917E9C471",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/dbpointer.json
        tests.group("pointer")
        {
            $0.test(name: "ascii",
                canonical: "1A0000000C610002000000620056E1FC72E0C917E9C471416100",
                expected: ["a": .pointer("b", .init(
                    timestamp: 0x56e1fc72, (0xe0, 0xc9, 0x17, 0xe9, 0xc4), (0x71, 0x41, 0x61)))])
            
            $0.test(name: "unicode",
                canonical: "1B0000000C610003000000C3A90056E1FC72E0C917E9C471416100",
                expected: ["a": .pointer("é", .init(
                    timestamp: 0x56e1fc72, (0xe0, 0xc9, 0x17, 0xe9, 0xc4), (0x71, 0x41, 0x61)))])
            
            $0.test(name: "invalid-length-negative",
                invalid: "1A0000000C6100FFFFFFFF620056E1FC72E0C917E9C471416100",
                failure: BSON.HeaderError<BSON.UTF8<ArraySlice<UInt8>>>.init(length: -1))
            
            $0.test(name: "invalid-length-zero",
                invalid: "1A0000000C610000000000620056E1FC72E0C917E9C471416100",
                failure: BSON.EndOfUTF8Error.unexpected)
            
            $0.test(name: "truncated",
                invalid: "160000000C61000300000061620056E1FC72E0C91700",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "truncated-identifier",
                invalid: "1A0000000C61000300000061620056E1FC72E0C917E9C4716100",
                failure: BSON.EndOfInputError.unexpected)
        }
        
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/binary.json
        tests.group("binary")
        {
            $0.test(name: "generic-empty",
                canonical: "0D000000057800000000000000",
                expected: ["x": .binary(.init(subtype: .generic, bytes: []))])
            
            $0.test(name: "generic",
                canonical: "0F0000000578000200000000FFFF00",
                expected: ["x": .binary(.init(subtype: .generic,
                    bytes: Base16.decode(utf8: "ffff".utf8)!))])
            
            $0.test(name: "function",
                canonical: "0F0000000578000200000001FFFF00",
                expected: ["x": .binary(.init(subtype: .function,
                    bytes: Base16.decode(utf8: "ffff".utf8)!))])
            
            $0.test(name: "uuid",
                canonical: "1D000000057800100000000473FFD26444B34C6990E8E7D1DFC035D400", 
                expected: ["x": .binary(.init(subtype: .uuid,
                    bytes: Base16.decode(utf8: "73ffd26444b34c6990e8e7d1dfc035d4".utf8)!))])
            
            $0.test(name: "md5",
                canonical: "1D000000057800100000000573FFD26444B34C6990E8E7D1DFC035D400", 
                expected: ["x": .binary(.init(subtype: .md5,
                    bytes: Base16.decode(utf8: "73ffd26444b34c6990e8e7d1dfc035d4".utf8)!))])
            
            $0.test(name: "compressed",
                canonical: "1D000000057800100000000773FFD26444B34C6990E8E7D1DFC035D400", 
                expected: ["x": .binary(.init(subtype: .compressed,
                    bytes: Base16.decode(utf8: "73ffd26444b34c6990e8e7d1dfc035d4".utf8)!))])
            
            $0.test(name: "custom",
                canonical: "0F0000000578000200000080FFFF00",
                expected: ["x": .binary(.init(subtype: .custom(code: 0x80),
                    bytes: Base16.decode(utf8: "ffff".utf8)!))])
            
            $0.test(name: "invalid-length-over",
                invalid: "1D000000057800FF0000000573FFD26444B34C6990E8E7D1DFC035D400",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-negative",
                invalid: "0D000000057800FFFFFFFF0000",
                failure: BSON.BinarySubtypeError.missing)
            // TODO: tests for legacy binary subtype 0x02

        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/document.json
        tests.group("document")
        {
            $0.test(name: "empty",
                canonical: "0D000000037800050000000000",
                expected: ["x": [:]])
            
            $0.test(name: "empty-key",
                canonical: "150000000378000D00000002000200000062000000",
                expected: ["x": ["": "b"]])
            
            $0.test(name: "single-character-key",
                canonical: "160000000378000E0000000261000200000062000000",
                expected: ["x": ["a": "b"]])
            
            $0.test(name: "dollar-prefixed-key",
                canonical: "170000000378000F000000022461000200000062000000",
                expected: ["x": ["$a": "b"]])
            
            $0.test(name: "dollar-key",
                canonical: "160000000378000E0000000224000200000061000000",
                expected: ["x": ["$": "a"]])
            
            $0.test(name: "dotted-key",
                canonical: "180000000378001000000002612E62000200000063000000",
                expected: ["x": ["a.b": "c"]])
            
            $0.test(name: "dot-key",
                canonical: "160000000378000E000000022E000200000061000000",
                expected: ["x": [".": "a"]])
            
            $0.test(name: "invalid-length-over",
                invalid: "1800000003666F6F000F0000001062617200FFFFFF7F0000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-under",
                invalid: "1500000003666F6F000A0000000862617200010000",
                failure: BSON.EndOfInputError.expected(encountered: 1))
            
            $0.test(name: "invalid-value",
                invalid: "1C00000003666F6F001200000002626172000500000062617A000000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-key",
                invalid: "150000000378000D00000010610000010000000000",
                failure: BSON.EndOfInputError.expected(encountered: 1))
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/array.json
        tests.group("tuple")
        {
            $0.test(name: "empty",
                canonical: "0D000000046100050000000000", 
                expected: ["a": []])
            $0.test(name: "single-element",
                canonical: "140000000461000C0000001030000A0000000000", 
                expected: ["a": [.int32(10)]])
            
            $0.test(name: "single-element-empty-key",
                degenerate: "130000000461000B00000010000A0000000000", 
                canonical: "140000000461000C0000001030000A0000000000", 
                expected: ["a": [.int32(10)]])
            
            $0.test(name: "single-element-invalid-key",
                degenerate: "150000000461000D000000106162000A0000000000", 
                canonical: "140000000461000C0000001030000A0000000000", 
                expected: ["a": [.int32(10)]])
            
            $0.test(name: "multiple-element-duplicate-keys",
                degenerate: "1b000000046100130000001030000a000000103000140000000000", 
                canonical: "1b000000046100130000001030000a000000103100140000000000", 
                expected: ["a": [.int32(10), .int32(20)]])
            
            $0.test(name: "invalid-length-over",
                invalid: "140000000461000D0000001030000A0000000000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-under",
                invalid: "140000000461000B0000001030000A0000000000",
                failure: BSON.EndOfInputError.expected(encountered: 1))
            
            $0.test(name: "invalid-element",
                invalid: "1A00000004666F6F00100000000230000500000062617A000000",
                failure: BSON.EndOfInputError.unexpected)
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/regex.json
        tests.group("regex")
        {
            $0.test(name: "empty",
                canonical: "0A0000000B6100000000",
                expected: ["a": .regex(.init(pattern: "", options: []))])
            
            $0.test(name: "empty-options",
                canonical: "0D0000000B6100616263000000",
                expected: ["a": .regex(.init(pattern: "abc", options: []))])
            
            $0.test(name: "I-HAVE-OPTIONS",
                canonical: "0F0000000B610061626300696D0000",
                expected: ["a": .regex(.init(pattern: "abc", options: [.i, .m]))])
            
            $0.test(name: "slash",
                canonical: "110000000B610061622F636400696D0000",
                expected: ["a": .regex(.init(pattern: "ab/cd", options: [.i, .m]))])
            
            $0.test(name: "non-alphabetized",
                degenerate: "100000000B6100616263006D69780000",
                canonical: "100000000B610061626300696D780000",
                expected: ["a": .regex(.init(pattern: "abc", options: [.i, .m, .x]))])
            
            $0.test(name: "escaped",
                canonical: "100000000B610061625C226162000000",
                expected: ["a": .regex(.init(pattern: #"ab\"ab"#, options: []))])
            
            // note: frameshift
            $0.test(name: "invalid-pattern",
                invalid: "0F0000000B610061006300696D0000",
                failure: BSON.Regex.OptionError.invalid("c"))
            // note: frameshift
            $0.test(name: "invalid-options",
                invalid: "100000000B61006162630069006D0000",
                failure: BSON.TypeError.init(code: 109))
        }
        
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/string.json
        tests.group("string")
        {
            $0.test(name: "empty",
                canonical: "0D000000026100010000000000",
                expected: ["a": ""])
            
            $0.test(name: "single-character",
                canonical: "0E00000002610002000000620000",
                expected: ["a": "b"])
            
            $0.test(name: "multiple-character",
                canonical: "190000000261000D0000006162616261626162616261620000",
                expected: ["a": "abababababab"])
            
            $0.test(name: "utf-8-double-code-unit",
                canonical: "190000000261000D000000C3A9C3A9C3A9C3A9C3A9C3A90000",
                expected: ["a": "\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}"])
            
            $0.test(name: "utf-8-triple-code-unit",
                canonical: "190000000261000D000000E29886E29886E29886E298860000",
                expected: ["a": "\u{2606}\u{2606}\u{2606}\u{2606}"])
            
            $0.test(name: "utf-8-null-bytes",
                canonical: "190000000261000D0000006162006261620062616261620000",
                expected: ["a": "ab\u{00}bab\u{00}babab"])
            
            $0.test(name: "escaped",
                canonical:
                    """
                    3200000002610026000000\
                    61625C220102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F6162\
                    0000
                    """,
                expected: 
                [
                    "a":
                    """
                    ab\\\"\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\
                    \t\n\u{0b}\u{0c}\r\u{0e}\u{0f}\u{10}\
                    \u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}\u{18}\u{19}\
                    \u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}ab
                    """
                ])
                        
            $0.test(name: "missing-trailing-null-byte",
                invalid: "0C0000000261000000000000",
                failure: BSON.EndOfUTF8Error.unexpected)
            
            $0.test(name: "invalid-length-negative",
                invalid: "0C000000026100FFFFFFFF00",
                failure: BSON.HeaderError<BSON.UTF8<ArraySlice<UInt8>>>.init(length: -1))
            
            $0.test(name: "invalid-length-over",
                invalid: "10000000026100050000006200620000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-over-document",
                invalid: "120000000200FFFFFF00666F6F6261720000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-under",
                invalid: "0E00000002610001000000000000",
                failure: BSON.EndOfInputError.expected(encountered: 1))
            
            $0.test(name: "invalid-utf-8",
                canonical: "0E00000002610002000000E90000",
                expected: ["a": .string(.init([0xe9]))])
        }
        
        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/symbol.json
        tests.group("symbol")
        {
            $0.test(name: "empty",
                degenerate: "0D0000000E6100010000000000",
                canonical: "0D000000026100010000000000",
                expected: ["a": ""])
            
            $0.test(name: "single-character",
                degenerate: "0E0000000E610002000000620000",
                canonical: "0E00000002610002000000620000",
                expected: ["a": "b"])
            
            $0.test(name: "multiple-character",
                degenerate: "190000000E61000D0000006162616261626162616261620000",
                canonical: "190000000261000D0000006162616261626162616261620000",
                expected: ["a": "abababababab"])
            
            $0.test(name: "utf-8-double-code-unit",
                degenerate: "190000000E61000D000000C3A9C3A9C3A9C3A9C3A9C3A90000",
                canonical: "190000000261000D000000C3A9C3A9C3A9C3A9C3A9C3A90000",
                expected: ["a": "\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}"])
            
            $0.test(name: "utf-8-triple-code-unit",
                degenerate: "190000000E61000D000000E29886E29886E29886E298860000",
                canonical: "190000000261000D000000E29886E29886E29886E298860000",
                expected: ["a": "\u{2606}\u{2606}\u{2606}\u{2606}"])
            
            $0.test(name: "utf-8-null-bytes",
                degenerate: "190000000E61000D0000006162006261620062616261620000",
                canonical: "190000000261000D0000006162006261620062616261620000",
                expected: ["a": "ab\u{00}bab\u{00}babab"])
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/code.json
        tests.group("javascript")
        {
            $0.test(name: "empty",
                canonical: "0D0000000D6100010000000000",
                expected: ["a": .javascript("")])
            
            $0.test(name: "single-character",
                canonical: "0E0000000D610002000000620000",
                expected: ["a": .javascript("b")])
            
            $0.test(name: "multiple-character",
                canonical: "190000000D61000D0000006162616261626162616261620000",
                expected: ["a": .javascript("abababababab")])
            
            $0.test(name: "utf-8-double-code-unit",
                canonical: "190000000D61000D000000C3A9C3A9C3A9C3A9C3A9C3A90000",
                expected: ["a": .javascript("\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}\u{e9}")])
            
            $0.test(name: "utf-8-triple-code-unit",
                canonical: "190000000D61000D000000E29886E29886E29886E298860000",
                expected: ["a": .javascript("\u{2606}\u{2606}\u{2606}\u{2606}")])
            
            $0.test(name: "utf-8-null-bytes",
                canonical: "190000000D61000D0000006162006261620062616261620000",
                expected: ["a": .javascript("ab\u{00}bab\u{00}babab")])
            
            $0.test(name: "missing-trailing-null-byte",
                invalid: "0C0000000D61000000000000",
                failure: BSON.EndOfUTF8Error.unexpected)
            
            $0.test(name: "invalid-length-negative",
                invalid: "0C0000000D6100FFFFFFFF00",
                failure: BSON.HeaderError<BSON.UTF8<ArraySlice<UInt8>>>.init(length: -1))
            
            $0.test(name: "invalid-length-over",
                invalid: "100000000D6100050000006200620000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-over-document",
                invalid: "120000000D00FFFFFF00666F6F6261720000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-under",
                invalid: "0E0000000D610001000000000000",
                failure: BSON.EndOfInputError.expected(encountered: 1))
        }

        // https://github.com/mongodb/specifications/blob/master/source/bson-corpus/tests/code_w_scope.json
        tests.group("javascript-scope")
        {
            $0.test(name: "empty",
                canonical: "160000000F61000E0000000100000000050000000000",
                expected: ["a": .javascriptScope([:], "")])
            
            $0.test(name: "empty-scope",
                canonical: "1A0000000F610012000000050000006162636400050000000000",
                expected: ["a": .javascriptScope([:], "abcd")])
            
            $0.test(name: "empty-code",
                canonical: "1D0000000F61001500000001000000000C000000107800010000000000",
                expected: ["a": .javascriptScope(["x": .int32(1)], "")])
            
            $0.test(name: "non-empty",
                canonical: "210000000F6100190000000500000061626364000C000000107800010000000000",
                expected: ["a": .javascriptScope(["x": .int32(1)], "abcd")])
            
            $0.test(name: "unicode",
                canonical: "1A0000000F61001200000005000000C3A9006400050000000000",
                expected: ["a": .javascriptScope([:], "\u{e9}\u{00}d")])
            
            // note: we do not validate the redundant field length,
            // so those tests are not included

            // note: the length is actually too short, but because we use the component-wise
            // length headers instead of the field length, this manifests itself as a
            // frameshift error.
            $0.test(name: "invalid-length-frameshift-clips-scope",
                invalid: "280000000F6100200000000400000061626364001300000010780001000000107900010000000000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-length-over",
                invalid: "280000000F6100200000000600000061626364001300000010780001000000107900010000000000",
                failure: BSON.EndOfInputError.unexpected)
            // note: frameshift
            $0.test(name: "invalid-length-frameshift",
                invalid: "280000000F610020000000FF00000061626364001300000010780001000000107900010000000000",
                failure: BSON.EndOfInputError.unexpected)
            
            $0.test(name: "invalid-scope",
                invalid: "1C0000000F001500000001000000000C000000020000000000000000",
                failure: BSON.EndOfUTF8Error.unexpected)
        }
        try tests.summarize()
    }
}
extension UnitTests
{
    mutating
    func test<Failure>(name:String, invalid:String, failure:Failure)
        where Failure:Error & Equatable
    {
        let invalid:[UInt8] = Base16.decode(utf8: invalid.utf8)!
        let document:BSON.Document<ArraySlice<UInt8>> = .init(
            slicing: invalid.dropFirst(4))
        self.do(expecting: failure, name: name)
        {
            _ in _ = try document.canonicalized()
        }
    }
    mutating
    func test(name:String, degenerate:String? = nil, canonical:String, 
        expected:BSON.Document<[UInt8]>)
    {
        let canonical:[UInt8] = Base16.decode(utf8: canonical.utf8)!
        let size:Int32 = canonical.prefix(4).withUnsafeBytes
        {
            .init(littleEndian: $0.load(as: Int32.self))
        }

        let document:BSON.Document<ArraySlice<UInt8>> = .init(
            slicing: canonical.dropFirst(4))

        self.assert(canonical.count ==? .init(size), name: "\(name).document-encoded-header")
        self.assert(document.header ==? size, name: "\(name).document-computed-header")

        self.assert(expected ~~ document, name: "\(name).canonical-equivalence")
        self.assert(expected == document, name: "\(name).binary-equivalence")

        if  let degenerate:String
        {
            let degenerate:[UInt8] = Base16.decode(utf8: degenerate.utf8)!
            let document:BSON.Document<ArraySlice<UInt8>> = .init(
                slicing: degenerate.dropFirst(4))
            self.do(name: "\(name).canonicalization")
            {
                let canonicalized:BSON.Document<ArraySlice<UInt8>> = 
                    try document.canonicalized()
                
                $0.assert(expected ~~ document,
                    name: "\(name).canonicalized-canonical-equivalence")
                $0.assert(expected == canonicalized,
                    name: "\(name).canonicalized-binary-equivalence")
            }
        }
    }
}