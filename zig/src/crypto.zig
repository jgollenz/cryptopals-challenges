const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

// https://en.wikipedia.org/wiki/Letter_frequency
const letter_freq_english = [_]f32{ 8.2, 1.5, 2.8, 4.3, 13, 2.2, 2, 6.1, 7, 0.15, 0.77, 4, 2.4, 6.7, 7.5, 1.9, 0.095, 6, 6.3, 9.1, 2.8, 0.98, 2.4, 0.15, 2, 0.074 };
const first_letter_freq_english = [_]f32{ 11.7, 4.4, 5.2, 3.2, 2.8, 4, 1.6, 4.2, 7.3, 0.51, 0.86, 2.4, 3.8, 2.3, 7.6, 4.3, 0.22, 2.8, 6.7, 16, 1.2, 0.82, 5.5, 0.045, 0.76, 0.045 };

pub fn xor(ally: Allocator, in: []const u8, key: []const u8) ![]const u8 {
    if (in.len == 0 or key.len == 0 or in.len != key.len) return error.InvalidParam;

    const out = try ally.alloc(u8, in.len);

    for (in) |char, i| {
        out[i] = char ^ key[i];
    }

    return out;
}

pub fn single_byte_xor(ally: Allocator, in: []const u8, key: u8) ![]const u8 {
    const out = try ally.alloc(u8, in.len);
    for (in) |char, i| {
        out[i] = char ^ key;
    }

    return out;
}

fn letter_freq_analysis(in: []const u8) f32 {
    // populate frequency map
    var frequency_map = [_]f32{0} ** 26;
    var first_letter_freq_map = [_]f32{0} ** 26;
    var in_word: bool = false;
    for (in) |char| {
        if (std.ascii.isWhitespace(char)) {
            in_word = false;
        } else if (std.ascii.isAlphabetic(char)) {
            if (!in_word) {
                first_letter_freq_map[std.ascii.toLower(char) - 97] += 1.0;
                in_word = true;
            }
            frequency_map[std.ascii.toLower(char) - 97] += 1.0;
        } else {
            in_word = true;
        }
    }

    for (frequency_map) |freq, j| {
        frequency_map[j] = freq / @intToFloat(f32, in.len);
    }

    for (first_letter_freq_map) |freq, j| {
        first_letter_freq_map[j] = freq / @intToFloat(f32, in.len);
    }

    // compute fitting quotient
    var delta_sum: f32 = 0.0;
    for (frequency_map) |freq, j| {
        delta_sum += std.math.fabs(letter_freq_english[j] - freq * 100);
    }

    var first_letter_delta_sum: f32 = 0.0;
    for (first_letter_freq_map) |freq, j| {
        first_letter_delta_sum += std.math.fabs(first_letter_freq_english[j] - freq * 100);
    }

    return delta_sum / @intToFloat(f32, 26) + first_letter_delta_sum / @intToFloat(f32, 26);
}

pub fn brute_force_single_byte_xor(ally: Allocator, in: []const u8) !u8 {
    var highest_score: f32 = 100.0;
    var key: u8 = 0;

    var i: u8 = 0;
    while (i < 255) : (i += 1) {
        var score: f32 = 0.0;
        const plaintext = try single_byte_xor(ally, in, i);

        score = letter_freq_analysis(plaintext);

        ally.free(plaintext);

        if (score < highest_score) {
            key = i;
            highest_score = score;
        }
    }

    return key;
}

// TODO: add tests
