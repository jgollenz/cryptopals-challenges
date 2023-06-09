const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const eql = std.mem.eql;
const code = @import("code.zig");
const crypto = @import("crypto.zig");

pub fn main() !void {}

test "challenge 1" {
    const ally = std.heap.page_allocator;

    const input: []const u8 = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected: []const u8 = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    const result = try code.encodeBase64(ally, try code.decodeHex(ally, input));
    assert(eql(u8, result, expected) == true);

    ally.free(result);
}

test "challenge 2" {
    const ally = std.heap.page_allocator;

    const input: []const u8 = "1c0111001f010100061a024b53535009181c";
    const key: []const u8 = "686974207468652062756c6c277320657965";
    const expected: []const u8 = "746865206b696420646f6e277420706c6179";

    const result = try crypto.xor(ally, try code.decodeHex(ally, input), try code.decodeHex(ally, key));
    assert(eql(u8, try code.encodeHex(ally, result), expected) == true);

    ally.free(result);
}

test "challenge 3" {
    const ally = std.heap.page_allocator;

    const ciphertext: []const u8 = try code.decodeHex(ally, "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736");

    const expected = "Cooking MC's like a pound of bacon";
    const key = try crypto.brute_force_single_byte_xor(ally, ciphertext);
    const plaintext = try crypto.single_byte_xor(ally, ciphertext, key);
    assert(eql(u8, plaintext, expected) == true);
}
