const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var width = (std.mem.indexOf(u8, contents, "\n") orelse return error.NoNewLine) + 1;

    var p1: usize = undefined;
    var p2: usize = undefined;

    solve(contents, width, &p1, &p2);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 3, p1, p2, end - start);
}

fn solve(contents: []u8, width: usize, p1: *usize, p2: *usize) void {
    const opts = [_][2]usize{
        [2]usize{ 1, 1 },
        [2]usize{ 5, 1 },
        [2]usize{ 7, 1 },
        [2]usize{ 1, 2 },
        [2]usize{ 3, 1 },
    };

    var res: usize = 1;
    inline for (opts) |opt| {
        var slopeResult = runSlope(contents, width, opt[0], opt[1]);
        res *= slopeResult;
        p1.* = slopeResult;
    }
    p2.* = res;
}

fn runSlope(contents: []u8, width: usize, right: usize, down: usize) usize {
    var row: usize = 0;
    var col: usize = 0;

    var trees: usize = 0;

    while (row * width < contents.len) {
        if (contents[row * width + col] == '#')
            trees += 1;
        row += down;
        col += right;
        col %= width - 1;
    }

    return trees;
}
