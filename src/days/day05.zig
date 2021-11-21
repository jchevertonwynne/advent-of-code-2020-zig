const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    var smallest: usize = std.math.maxInt(usize);

    var lines = std.mem.split(u8, contents, "\n");
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line, "")) continue;
        var seat: usize = 0;
        for (line) |char, i| {
            if (char == 'B' or char == 'R') {
                var shift: usize = 1;
                shift <<= 9 - @truncate(u6, i);
                seat += shift;
            }
        }
        p1 = std.math.max(p1, seat);
        smallest = std.math.min(smallest, seat);
        p2 ^= seat;
    }

    while (smallest <= p1) : (smallest += 1)
        p2 ^= smallest;

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 5, p1, p2, end - start);
}
