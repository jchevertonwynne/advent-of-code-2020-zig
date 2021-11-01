const std = @import("std");
const util = @import("../util.zig");
const mecha = @import("mecha");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, allocator, &p1, &p2);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 2, p1, p2, end - start);
}

fn solve(contents: []u8, allocator: *std.mem.Allocator, part1: *usize, part2: *usize) !void {
    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var e = (try Entry.parse(allocator, line)).value;
        if (e.valid1()) {
            part1.* += 1;
        }
        if (e.valid2()) {
            part2.* += 1;
        }
    }
}

const Entry = struct {
    const Self = @This();

    rule: Rule,
    password: []const u8,

    fn valid1(self: Self) bool {
        var count: usize = 0;
        for (self.password) |c| {
            if (c == self.rule.char) {
                count += 1;
            }
        }

        return count >= self.rule.min and count <= self.rule.max;
    }

    fn valid2(self: Self) bool {
        var firstPass = false;
        var secondPass = false;

        if (self.rule.min < self.password.len + 1) {
            if (self.password[self.rule.min - 1] == self.rule.char) {
                firstPass = true;
            }
        }

        if (self.rule.max < self.password.len + 1) {
            if (self.password[self.rule.max - 1] == self.rule.char) {
                secondPass = true;
            }
        }

        return firstPass != secondPass;
    }

    const parse = mecha.map(Entry, mecha.toStruct(Entry), mecha.combine(.{ Rule.parse, mecha.string(": "), mecha.rest }));
};

const Rule = struct {
    min: usize,
    max: usize,
    char: u8,

    const parse = mecha.map(Rule, mecha.toStruct(Rule), mecha.combine(.{ mecha.int(usize, .{}), mecha.ascii.char('-'), mecha.int(usize, .{}), mecha.ascii.char(' '), mecha.ascii.alpha }));
};
