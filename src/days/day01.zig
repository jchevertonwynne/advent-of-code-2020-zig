const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents);

    var p1 = try part1(&numbers);
    var p2 = try part2(&numbers);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 1, p1, p2, end - start);
}

fn loadNumbers(contents: []u8) ![2020]bool {
    var result = [_]bool{false} ** 2020;

    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var num = try std.fmt.parseInt(usize, line, 10);
        if (num < 2020) {
            result[num] = true;
        }
    }

    return result;
}

fn part1(numbers: []bool) !usize {
    var seen = [_]bool{false} ** 2020;

    for (numbers) |found, number| {
        if (!found) continue;
        if (seen[2020 - number]) {
            return number * (2020 - number);
        }
        seen[number] = true;
    }

    return error.AnswerNotFound;
}

fn part2(numbers: []bool) !usize {
    var pairsSeen = [_]u22{0} ** 2020;

    for (numbers) |found, number1| {
        if (!found) continue;
        for (numbers[number1 + 1 ..]) |found2, number2| {
            if (!found2) continue;
            var sum = number1 + number2;
            var mult = number1 * number2;
            if (sum < 2020) {
                pairsSeen[sum] = @truncate(u22, mult);
            }
        }
    }

    for (numbers) |found, number| {
        if (!found) continue;
        if (pairsSeen[2020 - number] != 0) {
            return number * pairsSeen[2020 - number];
        }
    }

    return error.AnswerNotFound;
}
