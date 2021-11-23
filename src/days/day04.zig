const std = @import("std");

const util = @import("../util.zig");

pub fn run(contents: []u8, out: anytype) !void {
    var start = std.time.nanoTimestamp();

    var p1: usize = 0;
    var p2: usize = 0;

    solve(contents, &p1, &p2);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 4, p1, p2, end - start);
}

fn solve(contents: []u8, p1: *usize, p2: *usize) void {
    var records = std.mem.split(u8, contents, "\n\n");
    while (records.next()) |recordString| {
        var record = Record.fromString(recordString);

        if (record.valid1())
            p1.* += 1;

        if (record.valid2())
            p2.* += 1;
    }
}

const Record = struct {
    const Self = @This();

    birthYear: ?[]const u8,
    issueYear: ?[]const u8,
    expirationYear: ?[]const u8,
    height: ?[]const u8,
    hairColour: ?[]const u8,
    eyeColour: ?[]const u8,
    passportID: ?[]const u8,

    fn new() Self {
        return Self{
            .birthYear = null,
            .issueYear = null,
            .expirationYear = null,
            .height = null,
            .hairColour = null,
            .eyeColour = null,
            .passportID = null,
        };
    }

    fn fromString(source: []const u8) Self {
        var record = Record.new();
        var lines = std.mem.split(u8, source, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) 
                continue;

            var mappings = [_]struct{field: [:0]const u8, ptr: *?[]const u8} {
                .{.field = "byr", .ptr = &record.birthYear},
                .{.field = "iyr", .ptr = &record.issueYear},
                .{.field = "eyr", .ptr = &record.expirationYear},
                .{.field = "hgt", .ptr = &record.height},
                .{.field = "hcl", .ptr = &record.hairColour},
                .{.field = "ecl", .ptr = &record.eyeColour},
                .{.field = "pid", .ptr = &record.passportID},
            };

            var categories = std.mem.split(u8, line, " ");
            while (categories.next()) |category| {
                var cat = category[0..3];
                var val = category[4..];

                for (mappings) |m| {
                    if (std.mem.eql(u8, m.field, cat)) {
                        m.ptr.* = val;
                        break;
                    }
                }
            }
        }
        return record;
    }

    fn valid1(self: Self) bool {
        _ = self.birthYear orelse return false;
        _ = self.issueYear orelse return false;
        _ = self.expirationYear orelse return false;
        _ = self.height orelse return false;
        _ = self.hairColour orelse return false;
        _ = self.eyeColour orelse return false;
        _ = self.passportID orelse return false;
        return true;
    }

    fn valid2(self: Self) bool {
        return self.validBirthYear() and self.validIssueYear() and self.validExpirationYear() and self.validHeight() and self.validHairColour() and self.validEyeColour() and self.validPassport();
    }

    fn validBirthYear(self: Self) bool {
        var birthYear = std.fmt.parseInt(usize, self.birthYear orelse return false, 10) catch return false;

        return 1920 <= birthYear and birthYear <= 2002;
    }

    fn validIssueYear(self: Self) bool {
        var issueYear = std.fmt.parseInt(usize, self.issueYear orelse return false, 10) catch return false;

        return 2010 <= issueYear and issueYear <= 2020;
    }

    fn validExpirationYear(self: Self) bool {
        var expirationYear = std.fmt.parseInt(usize, self.expirationYear orelse return false, 10) catch return false;

        return 2020 <= expirationYear and expirationYear <= 2030;
    }

    fn validHeight(self: Self) bool {
        var heightString = self.height orelse return false;
        if (heightString.len < 4)
            return false;

        var unit = heightString[heightString.len - 2 ..];
        var num = heightString[0 .. heightString.len - 2];
        if (std.mem.eql(u8, unit, "cm")) {
            var cm = std.fmt.parseInt(usize, num, 10) catch return false;
            return 150 <= cm and cm <= 193;
        } else if (std.mem.eql(u8, unit, "in")) {
            var inches = std.fmt.parseInt(usize, num, 10) catch return false;
            return 59 <= inches and inches <= 76;
        } else return false;
    }

    fn validHairColour(self: Self) bool {
        var hairColour = self.hairColour orelse return false;

        return hairColour.len == 7 and hairColour[0] == '#' and allAlphaNumeric(hairColour[1..]);
    }

    fn validEyeColour(self: Self) bool {
        var eyeColour = self.eyeColour orelse return false;
        const options = [_]*const [3:0]u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
        inline for (options) |opt| {
            if (std.mem.eql(u8, eyeColour, opt))
                return true;
        }
        return false;
    }

    fn validPassport(self: Self) bool {
        var passportID = self.passportID orelse return false;

        return passportID.len == 9 and allNumeric(passportID);
    }
};

fn allNumeric(in: []const u8) bool {
    for (in) |i| {
        if (!('0' <= i and i <= '9'))
            return false;
    }

    return true;
}

fn allAlphaNumeric(in: []const u8) bool {
    for (in) |i| {
        if (!(('0' <= i and i <= '9') or ('a' <= i and i <= 'f')))
            return false;
    }

    return true;
}
