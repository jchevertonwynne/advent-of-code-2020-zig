const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents, allocator);
    defer allocator.free(numbers);

    var p1 = try part1(numbers);
    var p2 = try part2(numbers, p1);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 9, p1, p2, end - start);
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
    var toCheck = numbers[25..];
    for (toCheck) |number, ind| {
        var window = numbers[ind .. ind + 25];
        outer: for (window) |a, ind2| {
            for (window[ind2 + 1 ..]) |b| {
                if (a + b == number)
                    break :outer;
            }
        } else return number;
    }

    return error.AnswerNotFound;
}

fn part2(numbers: []usize, goal: usize) !usize {
    var i: usize = 0;
    var j: usize = 0;
    var sum: usize = 0;

    while (i < numbers.len) {
        if (sum < goal) {
            sum += numbers[j];
            j += 1;
        } else if (sum > goal) {
            sum -= numbers[i];
            i += 1;
        } else {
            var smallest = std.mem.min(usize, numbers[i..j]);
            var largest = std.mem.max(usize, numbers[i..j]);
            return smallest + largest;
        }
    }

    return error.AnswerNotFound;
}
