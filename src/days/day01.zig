const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents, allocator);
    defer allocator.free(numbers);

    var p1 = try part1(numbers);
    var p2 = try part2(numbers);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 1, p1, p2, end - start);
}

fn loadNumbers(contents: []u8, allocator: *std.mem.Allocator) ![]usize {
    var numbers = ArrayList(usize).init(allocator);
    errdefer numbers.deinit();

    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line|
        try numbers.append(try std.fmt.parseInt(usize, line, 10));

    return numbers.toOwnedSlice();
}

fn part1(numbers: []usize) !usize {
    var seen = [_]bool{false} ** 2020;

    for (numbers) |number| {
        if (number <= 2020) {
            if (seen[2020 - number])
                return number * (2020 - number);
            seen[number] = true;
        }
    }

    return error.AnswerNotFound;
}

fn part2(numbers: []usize) !usize {
    var pairsSeen = [_]u22{0} ** 2020;

    for (numbers) |number1, ind| {
        for (numbers[ind + 1 ..]) |number2| {
            var sum = number1 + number2;
            var mult = number1 * number2;
            if (sum < 2020)
                pairsSeen[sum] = @truncate(u22, mult);
        }
    }

    for (numbers) |number| {
        if (pairsSeen[2020 - number] != 0)
            return number * pairsSeen[2020 - number];
    }

    return error.AnswerNotFound;
}
