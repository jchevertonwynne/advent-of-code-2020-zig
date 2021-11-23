const std = @import("std");

const util = @import("../util.zig");

pub fn run(out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var p1: u25 = 0;
    var p2: u25 = 0;

    try solve(&p1, &p2, allocator);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 15, p1, p2, end - start);
}

fn solve(part1: *u25, part2: *u25, allocator: *std.mem.Allocator) !void {
    const maxTurn = 30_000_000;
    var numbers = [_]u25{ 1, 2, 16, 19, 18, 0 };

    var spoken = try allocator.alloc(u25, maxTurn);
    defer allocator.free(spoken);

    for (spoken) |*val|
        val.* = 0;

    for (numbers) |number, i|
        spoken[number] = @truncate(u25, i) + 1;

    var lastSpoken: u25 = numbers[numbers.len - 1];
    var turn: u25 = numbers.len + 1;
    while (turn < 2019) : (turn += 1) {
        var nextP = &spoken[lastSpoken];

        var next = nextP.*;

        if (next != 0)
            next = turn - next;

        nextP.* = turn;
        lastSpoken = next;
    }

    part1.* = lastSpoken;

    while (turn < maxTurn) : (turn += 1) {
        var nextP = &spoken[lastSpoken];

        var next = nextP.*;

        if (next != 0)
            next = turn - next;

        nextP.* = turn;
        lastSpoken = next;
    }

    part2.* = lastSpoken;
}
