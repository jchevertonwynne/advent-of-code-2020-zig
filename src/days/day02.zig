const std = @import("std");
const mecha = @import("mecha");

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var answers = try solve(contents, allocator);
    var p1 = answers.part1;
    var p2 = answers.part2;

    var end = std.time.nanoTimestamp();

    try out.print("problem two:\n", .{});
    try out.print("\tpart 1:\n", .{});
    try out.print("\t\t{d}\n", .{p1});
    try out.print("\tpart 2:\n", .{});
    try out.print("\t\t{d}\n", .{p2});
    try out.print("\tduration:\n", .{});
    try out.print("\t\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try out.print("\t\t{d}us\n", .{@divFloor(end - start, 1_000)});
    try out.print("\t\t{d}ns\n", .{end - start});
}

const Answers = struct { part1: usize, part2: usize };

fn solve(contents: []u8, allocator: *std.mem.Allocator) !Answers {
    var results = Answers{ .part1 = 0, .part2 = 0 };
    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var e = (try entry(allocator, line)).value;
        if (e.valid1()) {
            results.part1 += 1;
        }
        if (e.valid2()) {
            results.part2 += 1;
        }
    }
    return results;
}

const Entry = struct {
    rule: Rule,
    password: []const u8,

    fn valid1(e: Entry) bool {
        var count: usize = 0;
        for (e.password) |c| {
            if (c == e.rule.char) {
                count += 1;
            }
        }

        return count >= e.rule.min and count <= e.rule.max;
    }

    fn valid2(e: Entry) bool {
        var firstPass = false;
        var secondPass = false;

        if (e.rule.min < e.password.len + 1) {
            if (e.password[e.rule.min - 1] == e.rule.char) {
                firstPass = true;
            }
        }

        if (e.rule.max < e.password.len + 1) {
            if (e.password[e.rule.max - 1] == e.rule.char) {
                secondPass = true;
            }
        }

        return firstPass != secondPass;
    }
};

const Rule = struct { min: usize, max: usize, char: u8 };

const rule = mecha.map(Rule, mecha.toStruct(Rule), mecha.combine(.{ mecha.int(usize, .{}), mecha.ascii.char('-'), mecha.int(usize, .{}), mecha.ascii.char(' '), mecha.ascii.alpha }));

const entry = mecha.map(Entry, mecha.toStruct(Entry), mecha.combine(.{ rule, mecha.string(": "), mecha.rest }));
