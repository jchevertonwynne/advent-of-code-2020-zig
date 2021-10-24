const std = @import("std");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var numbers = try loadNumbers(contents, allocator);
    defer numbers.deinit();

    var p1 = part1(numbers.items);
    var p2 = part2(numbers.items);

    var end = std.time.nanoTimestamp();

    try out.print("problem one:\n", .{});
    try out.print("\tpart 1:\n", .{});
    try out.print("\t\t{d}\n", .{p1});
    try out.print("\tpart 2:\n", .{});
    try out.print("\t\t{d}\n", .{p2});
    try out.print("\tduration:\n", .{});
    try out.print("\t\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try out.print("\t\t{d}us\n", .{@divFloor(end - start, 1_000)});
    try out.print("\t\t{d}ns\n", .{end - start});
}

fn loadNumbers(contents: []u8, allocator: *std.mem.Allocator) !std.ArrayList(usize) {
    var numbers = std.ArrayList(usize).init(allocator);
    errdefer numbers.deinit();

    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        try numbers.append(try std.fmt.parseInt(usize, line, 10));
    }

    return numbers;
}

fn part1(numbers: []usize) usize {
    var seen: u2020 = 0;

    for (numbers) |number| {
        if (number <= 2020) {
            var paired: u2020 = 1;
            paired <<= @truncate(u11, 2020 - number);
            if ((seen & paired) != 0) {
                return number * (2020 - number);
            }
            var num: u2020 = 1;
            num <<= @truncate(u11, number);
            seen |= num;
        }
    }

    unreachable;
}

fn part2(numbers: []usize) usize {
    var pairsSeen: [2020]u22 = [_]u22{0} ** 2020;

    for (numbers) |number1, ind| {
        for (numbers[ind + 1 ..]) |number2| {
            var sum = number1 + number2;
            var mult = number1 * number2;
            if (sum < 2020) {
                var seen = @truncate(u22, mult);
                pairsSeen[sum] = seen;
            }
        }
    }

    for (numbers) |number| {
        if (pairsSeen[2020 - number] != 0) {
            return number * pairsSeen[2020 - number];
        }
    }

    unreachable;
}
