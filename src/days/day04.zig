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
        var record = Record.new();

        var p2Good = true;

        var lines = std.mem.split(u8, recordString, "\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            var categories = std.mem.split(u8, line, " ");
            while (categories.next()) |category| {
                var cat = category[0..3];
                var val = category[4..];
                if (std.mem.eql(u8, cat, "byr")) {
                    record.foundBirthYear = true;
                    if (p2Good and !validBirthYear(val)) {
                        p2Good = false;
                    } else {
                        record.validBirthYear = true;
                    }
                } else if (std.mem.eql(u8, cat, "iyr")) {
                    record.foundIssueYear = true;
                    if (p2Good and !validIssueYear(val)) {
                        p2Good = false;
                    } else {
                        record.validIssueYear = true;
                    }
                } else if (std.mem.eql(u8, cat, "eyr")) {
                    record.foundExpirationYear = true;
                    if (p2Good and !validExpirationYear(val)) {
                        p2Good = false;
                    } else {
                        record.validExpirationYear = true;
                    }
                } else if (std.mem.eql(u8, cat, "hgt")) {
                    record.foundHeight = true;
                    if (p2Good and !validHeight(val)) {
                        p2Good = false;
                    } else {
                        record.validHeight = true;
                    }
                } else if (std.mem.eql(u8, cat, "hcl")) {
                    record.foundHairColour = true;
                    if (p2Good and !validHairColour(val)) {
                        p2Good = false;
                    } else {
                        record.validHairColour = true;
                    }
                } else if (std.mem.eql(u8, cat, "ecl")) {
                    record.foundEyeColour = true;
                    if (p2Good and !validEyeColour(val)) {
                        p2Good = false;
                    } else {
                        record.validEyeColour = true;
                    }
                } else if (std.mem.eql(u8, cat, "pid")) {
                    record.foundPassportID = true;
                    if (p2Good and !validPassportID(val)) {
                        p2Good = false;
                    } else {
                        record.validPassportID = true;
                    }
                }
            }
        }

        if (record.valid1()) {
            p1.* += 1;
        }

        if (p2Good and record.valid2()) {
            p2.* += 1;
        }
    }
}

const Record = struct {
    const Self = @This();

    foundBirthYear: bool,
    foundIssueYear: bool,
    foundExpirationYear: bool,
    foundHeight: bool,
    foundHairColour: bool,
    foundEyeColour: bool,
    foundPassportID: bool,

    validBirthYear: bool,
    validIssueYear: bool,
    validExpirationYear: bool,
    validHeight: bool,
    validHairColour: bool,
    validEyeColour: bool,
    validPassportID: bool,

    fn new() Self {
        return Self{
            .foundBirthYear = false,
            .foundIssueYear = false,
            .foundExpirationYear = false,
            .foundHeight = false,
            .foundHairColour = false,
            .foundEyeColour = false,
            .foundPassportID = false,

            .validBirthYear = false,
            .validIssueYear = false,
            .validExpirationYear = false,
            .validHeight = false,
            .validHairColour = false,
            .validEyeColour = false,
            .validPassportID = false,
        };
    }

    fn valid1(self: Self) bool {
        return self.foundBirthYear and self.foundIssueYear and self.foundExpirationYear and self.foundHeight and self.foundHairColour and self.foundEyeColour and self.foundPassportID;
    }

    fn valid2(self: Self) bool {
        return self.validBirthYear and self.validIssueYear and self.validExpirationYear and self.validHeight and self.validHairColour and self.validEyeColour and self.validPassportID;
    }
};

fn validBirthYear(birthYearString: []const u8) bool {
    var birthYear = std.fmt.parseInt(usize, birthYearString, 10) catch return false;

    return 1920 <= birthYear and birthYear <= 2002;
}

fn validIssueYear(issueYearString: []const u8) bool {
    var issueYear = std.fmt.parseInt(usize, issueYearString, 10) catch return false;

    return 2010 <= issueYear and issueYear <= 2020;
}

fn validExpirationYear(expirationYearString: []const u8) bool {
    var expirationYear = std.fmt.parseInt(usize, expirationYearString, 10) catch return false;

    return 2020 <= expirationYear and expirationYear <= 2030;
}

fn validHeight(height: []const u8) bool {
    if (height.len < 4) {
        return false;
    }

    var unit = height[height.len - 2 ..];
    var num = height[0 .. height.len - 2];
    if (std.mem.eql(u8, unit, "cm")) {
        var cm = std.fmt.parseInt(usize, num, 10) catch return false;
        return 150 <= cm and cm <= 193;
    } else if (std.mem.eql(u8, unit, "in")) {
        var inches = std.fmt.parseInt(usize, num, 10) catch return false;
        return 59 <= inches and inches <= 76;
    } else {
        return false;
    }
}

fn validHairColour(hairColour: []const u8) bool {
    return hairColour.len == 7 and hairColour[0] == '#' and allAlphaNumeric(hairColour[1..]);
}

fn validEyeColour(eyeColour: []const u8) bool {
    const options = [_]*const [3:0]u8{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
    inline for (options) |opt| {
        if (std.mem.eql(u8, eyeColour, opt)) {
            return true;
        }
    }
    return false;
}

fn validPassportID(passportID: []const u8) bool {
    return passportID.len == 9 and allNumeric(passportID);
}

fn allNumeric(in: []const u8) bool {
    for (in) |i| {
        if (!('0' <= i and i <= '9')) {
            return false;
        }
    }

    return true;
}

fn allAlphaNumeric(in: []const u8) bool {
    for (in) |i| {
        if (!(('0' <= i and i <= '9') or ('a' <= i and i <= 'f'))) {
            return false;
        }
    }

    return true;
}
