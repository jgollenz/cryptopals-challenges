const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const eql = std.mem.eql;
const code = @import("code.zig");

pub fn main() !void {}

test "challenge 1" {
    const ally = std.heap.page_allocator;

    const input: []const u8 = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output: []const u8 = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";
    var result = try code.encodeBase64(ally, try code.decodeHex(ally, input));
    assert(eql(u8, result, expected_output) == true);

    ally.free(result);
}
