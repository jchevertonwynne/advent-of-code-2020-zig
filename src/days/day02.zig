const std = @import("std");

const mecha = @import("mecha");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;
    try solve(contents, &p1, &p2);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 2, p1, p2, end - start);
}

fn solve(contents: []u8, part1: *usize, part2: *usize) !void {
    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var entry = (try Entry.parse(&util.ZeroAllocator, line)).value;
        if (entry.valid1())
            part1.* += 1;
        if (entry.valid2())
            part2.* += 1;
    }
}

const Entry = struct {
    const Self = @This();

    rule: Rule,
    password: []const u8,

    fn valid1(self: Self) bool {
        var count: usize = 0;
        for (self.password) |c| {
            if (c == self.rule.char)
                count += 1;
        }

        return count >= self.rule.min and count <= self.rule.max;
    }

    fn valid2(self: Self) bool {
        var firstPass = self.rule.min <= self.password.len and self.password[self.rule.min - 1] == self.rule.char;
        var secondPass = self.rule.max <= self.password.len and self.password[self.rule.max - 1] == self.rule.char;

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
