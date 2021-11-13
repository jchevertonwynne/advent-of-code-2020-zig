const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var seats = try loadSeats(contents, allocator);
    defer allocator.free(seats);

    var p1: usize = 0;
    var smallest: usize = std.math.maxInt(usize);
    for (seats) |seat| {
        if (seat > p1) {
            p1 = seat;
        }
        if (seat < smallest) {
            smallest = seat;
        }
    }

    var seen = try allocator.alloc(bool, p1 - smallest + 1);
    defer allocator.free(seen);

    for (seen) |*s| s.* = false;
    for (seats) |seat| {
        seen[seat - smallest] = true;
    }

    var p2: usize = smallest;
    while (seen[p2 - smallest]) : (p2 += 1) {}

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 5, p1, p2, end - start);
}

fn loadSeats(contents: []u8, allocator: *std.mem.Allocator) ![]usize {
    var size = contents.len / 11;
    var result = try allocator.alloc(usize, size);
    errdefer allocator.free(result);

    var ind: usize = 0;
    var lines = std.mem.split(u8, contents, "\n");
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line, "")) continue;
        var num: usize = 0;
        for (line) |char, i| {
            if (char == 'B' or char == 'R') {
                var shift: usize = 1;
                shift <<= 9 - @truncate(u6, i);
                num += shift;
                
            }
        }
        result[ind] = num;
        ind += 1;
    }

    return result;
}
