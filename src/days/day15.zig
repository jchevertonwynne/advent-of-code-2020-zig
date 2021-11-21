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
    const cutoff = 5_000_000;
    var numbers = [_]u25{ 1, 2, 16, 19, 18, 0 };

    var spoken = try allocator.alloc(u25, cutoff);
    defer allocator.free(spoken);

    const context = struct {
        pub fn hash(_: @This(), key: u25) u64 {
            return key;
        }

        pub fn eql(_: @This(), a: u25, b: u25) bool {
            return a == b;
        }
    };

    var spokenLarge = std.HashMap(u25, u25, context, 80).init(allocator);
    try spokenLarge.ensureCapacity(1_200_000);
    defer spokenLarge.deinit();

    for (spoken) |*val|
        val.* = 0;

    for (numbers) |number, i|
        spoken[number] = @truncate(u25, i) + 1;

    var lastSpoken: u25 = numbers[numbers.len - 1];
    var turn: u25 = numbers.len + 1;
    while (turn < maxTurn) : (turn += 1) {
        var nextP = if (lastSpoken > cutoff) block: {
            var found = try spokenLarge.getOrPut(lastSpoken);
            if (!found.found_existing)
                found.value_ptr.* = 0;
            break :block found.value_ptr;
        } else &spoken[lastSpoken];

        var next = nextP.*;
        
        if (next != 0)
            next = turn - next;

        nextP.* = turn;
        lastSpoken = next;

        if (turn == 2019)
            part1.* = lastSpoken;
    }

    try std.io.getStdOut().writer().print("{}\n", .{spokenLarge.count()});

    part2.* = lastSpoken;
}
