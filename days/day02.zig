const std = @import("std");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var answers = try solve(contents);
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

fn solve(contents: []u8) !Answers {
    var results = Answers{ .part1 = 0, .part2 = 0 };
    var lines = std.mem.tokenize(u8, contents, "\n");
    while (lines.next()) |line| {
        var e = try entry.tryFrom(line);
        if (e.valid1()) {
            results.part1 += 1;
        }
        if (e.valid2()) {
            results.part2 += 1;
        }
    }
    return results;
}

const entry = struct {
    password: []const u8,
    rule: rule,

    fn tryFrom(source: []const u8) !entry {
        var tokens = std.mem.tokenize(u8, source, " ");

        var minMax = tokens.next() orelse return errors.FailedToGetToken;
        var sep = std.mem.indexOf(u8, minMax, "-") orelse return errors.FailedToGetIndex;
        var min = try std.fmt.parseInt(usize, minMax[0..sep], 10);
        var max = try std.fmt.parseInt(usize, minMax[sep + 1 ..], 10);

        var letter = tokens.next() orelse return errors.FailedToGetToken;
        var password = tokens.next() orelse return errors.FailedToGetToken;

        return entry{ .password = password, .rule = rule{ .min = min, .max = max, .char = letter[0] } };
    }

    fn valid1(e: entry) bool {
        var count: usize = 0;
        for (e.password) |c| {
            if (c == e.rule.char) {
                count += 1;
            }
        }

        return count >= e.rule.min and count <= e.rule.max;
    }

    fn valid2(e: entry) bool {
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

const rule = struct { char: u8, min: usize, max: usize };

const errors = error{ FailedToGetToken, FailedToGetIndex };
