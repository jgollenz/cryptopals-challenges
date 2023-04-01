const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const eql = std.mem.eql;
const fmt = std.fmt;
const math = std.math;

const hextet = 0b111111;
const octet = 0b11111111;

// TODO: looks like fmt.hexToBytes & fmt.bytesToHex takes care of this. They come with Zig 0.11.0
//
// HEX
//

// TODO: add tests
// converts a hex-encoded string into a plain string
pub fn decodeHex(ally: Allocator, in: []const u8) ![]const u8 {
    assert((in.len % 2) == 0);

    const out = try ally.alloc(u8, in.len / 2);

    var head: usize = 0;
    while (head < in.len) : (head += 2) {
        out[head / 2] = try fmt.parseInt(u8, in[head .. head + 2], 16);
    }

    return out;
}

// converts a plain string to a hex-encoded string
pub fn encodeHex(ally: Allocator, in: []const u8) ![]const u8 {
    const out = try ally.alloc(u8, in.len * 2);

    const hex_charset = "0123456789abcdef";

    for (in) |char, i| {
        out[i * 2] = hex_charset[char >> 4];
        out[i * 2 + 1] = hex_charset[char & 0b1111];
    }

    return out;
}

//
// BASE_64
//

const base64_encoding_table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// TODO: format
const base64_decoding_map = std.ComptimeStringMap(u8, .{ .{ "A", 0 }, .{ "B", 1 }, .{ "C", 2 }, .{ "D", 3 }, .{ "E", 4 }, .{ "F", 5 }, .{ "G", 6 }, .{ "H", 7 }, .{ "I", 8 }, .{ "J", 9 }, .{ "K", 10 }, .{ "L", 11 }, .{ "M", 12 }, .{ "N", 13 }, .{ "O", 14 }, .{ "P", 15 }, .{ "Q", 16 }, .{ "R", 17 }, .{ "S", 18 }, .{ "T", 19 }, .{ "U", 20 }, .{ "V", 21 }, .{ "W", 22 }, .{ "X", 23 }, .{ "Y", 24 }, .{ "Z", 25 }, .{ "a", 26 }, .{ "b", 27 }, .{ "c", 28 }, .{ "d", 29 }, .{ "e", 30 }, .{ "f", 31 }, .{ "g", 32 }, .{ "h", 33 }, .{ "i", 34 }, .{ "j", 35 }, .{ "k", 36 }, .{ "l", 37 }, .{ "m", 38 }, .{ "n", 39 }, .{ "o", 40 }, .{ "p", 41 }, .{ "q", 42 }, .{ "r", 43 }, .{ "s", 44 }, .{ "t", 45 }, .{ "u", 46 }, .{ "v", 47 }, .{ "w", 48 }, .{ "x", 49 }, .{ "y", 50 }, .{ "z", 51 }, .{ "0", 52 }, .{ "1", 53 }, .{ "2", 54 }, .{ "3", 55 }, .{ "4", 56 }, .{ "5", 57 }, .{ "6", 58 }, .{ "7", 59 }, .{ "8", 60 }, .{ "9", 61 }, .{ "+", 62 }, .{ "/", 63 } });

pub fn decodeBase64(ally: Allocator, in: []const u8) ![]u8 {
    if (in.len == 0) return "";

    assert((in.len % 4) == 0);

    var out_size: usize = try math.divCeil(usize, in.len, 4) * 3;

    if (in[in.len - 1] == '=') out_size = out_size - 1;
    if (in[in.len - 2] == '=') out_size = out_size - 1;
    const quadruplets = try math.divFloor(usize, out_size, 3);
    const out = try ally.alloc(u8, out_size);

    var in_head: usize = 0;
    var out_head: usize = 0;
    while (in_head < quadruplets * 4) : ({
        in_head += 4;
        out_head += 3;
    }) {
        const one: u32 = @intCast(u32, base64_decoding_map.get(in[in_head .. in_head + 1]).?) << 18;
        const two: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 1 .. in_head + 2]).?) << 12;
        const three: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 2 .. in_head + 3]).?) << 6;
        const four: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 3 .. in_head + 4]).?);

        const combined = one | two | three | four;

        out[out_head] = @intCast(u8, combined >> 16);
        out[out_head + 1] = @intCast(u8, (combined >> 8) & octet);
        out[out_head + 2] = @intCast(u8, combined & octet);
    }

    const remainder = out_size - quadruplets * 3;

    if (remainder == 2) {
        const one: u32 = @intCast(u32, base64_decoding_map.get(in[in_head .. in_head + 1]).?) << 18;
        const two: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 1 .. in_head + 2]).?) << 12;
        const three: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 2 .. in_head + 3]).?) << 6;

        const combined = one | two | three;

        out[out_head] = @intCast(u8, combined >> 16);
        out[out_head + 1] = @intCast(u8, (combined >> 8) & octet);
    } else if (remainder == 1) {
        const one: u32 = @intCast(u32, base64_decoding_map.get(in[in_head .. in_head + 1]).?) << 18;
        const two: u32 = @intCast(u32, base64_decoding_map.get(in[in_head + 1 .. in_head + 2]).?) << 12;

        const combined = one | two;

        out[out_head] = @intCast(u8, combined >> 16);
    }

    return out;
}

// converts a plain string to a base64-encoded string
pub fn encodeBase64(ally: Allocator, in: []const u8) ![]u8 {
    if (in.len == 0) return "";

    const out_size: usize = try math.divCeil(usize, in.len, 3) * 4;
    const triplets = try math.divFloor(usize, in.len, 3);
    const out = try ally.alloc(u8, out_size);

    var in_head: usize = 0;
    var out_head: usize = 0;
    while (in_head < triplets * 3) : ({
        in_head += 3;
        out_head += 4;
    }) {
        const one: u32 = @intCast(u32, in[in_head]) << 16;
        const two: u32 = @intCast(u32, in[in_head + 1]) << 8;
        const three: u32 = @intCast(u32, in[in_head + 2]);

        const combined = one | two | three;

        out[out_head] = base64_encoding_table[combined >> 18];
        out[out_head + 1] = base64_encoding_table[(combined >> 12) & hextet];
        out[out_head + 2] = base64_encoding_table[(combined >> 6) & hextet];
        out[out_head + 3] = base64_encoding_table[combined & hextet];
    }

    const remainder = in.len - triplets * 3;

    if (remainder == 2) {
        const one: u32 = @intCast(u32, in[in_head]) << 16;
        const two: u32 = @intCast(u32, in[in_head + 1]) << 8;

        const combined = one | two;

        out[out_head] = base64_encoding_table[combined >> 18];
        out[out_head + 1] = base64_encoding_table[(combined >> 12) & hextet];
        out[out_head + 2] = base64_encoding_table[(combined >> 6) & hextet];
        out[out_head + 3] = '=';
    } else if (remainder == 1) {
        const one: u32 = @intCast(u32, in[in_head]) << 16;

        out[out_head] = base64_encoding_table[one >> 18];
        out[out_head + 1] = base64_encoding_table[(one >> 12) & hextet];
        out[out_head + 2] = '=';
        out[out_head + 3] = '=';
    }

    return out;
}

test "base64: padded strings" {
    // TODO: use debugging allocator
    const ally = std.heap.page_allocator;

    // TODO: decode the encoding output and cmp to original
    assert(eql(u8, try encodeBase64(ally, ""), ""));
    assert(eql(u8, try encodeBase64(ally, "f"), "Zg=="));
    assert(eql(u8, try encodeBase64(ally, "fo"), "Zm8="));
    assert(eql(u8, try encodeBase64(ally, "foo"), "Zm9v"));
    assert(eql(u8, try encodeBase64(ally, "foob"), "Zm9vYg=="));
    assert(eql(u8, try encodeBase64(ally, "fooba"), "Zm9vYmE="));
    assert(eql(u8, try encodeBase64(ally, "foobar"), "Zm9vYmFy"));

    assert(eql(u8, try decodeBase64(ally, ""), ""));
    assert(eql(u8, try decodeBase64(ally, "Zg=="), "f"));
    assert(eql(u8, try decodeBase64(ally, "Zm8="), "fo"));
    assert(eql(u8, try decodeBase64(ally, "Zm9v"), "foo"));
    assert(eql(u8, try decodeBase64(ally, "Zm9vYg=="), "foob"));
    assert(eql(u8, try decodeBase64(ally, "Zm9vYmE="), "fooba"));
    assert(eql(u8, try decodeBase64(ally, "Zm9vYmFy"), "foobar"));
}

test "hex" {
    const ally = std.heap.page_allocator;

    assert(eql(u8, try encodeHex(ally, ""), ""));
    assert(eql(u8, try encodeHex(ally, "f"), "66"));
    assert(eql(u8, try encodeHex(ally, "fo"), "666f"));
    assert(eql(u8, try encodeHex(ally, "foo"), "666f6f"));
    assert(eql(u8, try encodeHex(ally, "foob"), "666f6f62"));
    assert(eql(u8, try encodeHex(ally, "fooba"), "666f6f6261"));
    assert(eql(u8, try encodeHex(ally, "foobar"), "666f6f626172"));

    assert(eql(u8, try decodeHex(ally, ""), ""));
    assert(eql(u8, try decodeHex(ally, "66"), "f"));
    assert(eql(u8, try decodeHex(ally, "666f"), "fo"));
    assert(eql(u8, try decodeHex(ally, "666f6f"), "foo"));
    assert(eql(u8, try decodeHex(ally, "666f6f62"), "foob"));
    assert(eql(u8, try decodeHex(ally, "666f6f6261"), "fooba"));
    assert(eql(u8, try decodeHex(ally, "666f6f626172"), "foobar"));
}
