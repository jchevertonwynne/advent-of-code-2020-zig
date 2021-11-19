const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;

    solve(contents, &p1, &p2);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 6, p1, p2, end - start);
}

fn solve(contents: []u8, p1: *usize, p2: *usize) void {
    var groups = std.mem.split(u8, contents, "\n\n");
    while (groups.next()) |groupString| {
        if (groupString.len == 0) continue;

        var anyAnswered: u26 = 0;
        var allAnswered: u26 = std.math.maxInt(u26);

        var people = std.mem.split(u8, groupString, "\n");
        while (people.next()) |personString| {
            if (personString.len == 0) continue;

            var answered: u26 = 0;
            for (personString) |questionAnswer| {
                var shift: u26 = 1;
                shift <<= @truncate(u5, questionAnswer - 'a');
                answered |= shift;
            }

            anyAnswered |= answered;
            allAnswered &= answered;
        }

        p1.* += @popCount(u26, anyAnswered);
        p2.* += @popCount(u26, allAnswered);
    }
}
