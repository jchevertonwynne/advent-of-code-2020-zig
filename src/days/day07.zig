const std = @import("std");
const util = @import("util.zig");
const RC = util.RC;

const Bag = struct {
    colour: []const u8,
    parents: std.ArrayList(*Bag),
    contains: std.ArrayList(Contents),

    fn total_contains(b: Bag) usize {
        var res: usize = 0;

        for (b.contains.items) |contained| {
            res += contained.count * (1 + contained.bag.val.total_contains());
        }

        return res;
    }
};

const Contents = struct { count: usize, bag: RC(Bag) };

pub fn run(comptime T: type, contents: []u8, out: *T, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var bags = try createBags(contents, allocator);
    defer bags.deinit();
    defer deinitBagsContents(bags);

    var p1 = part1(bags, allocator);
    var p2 = part2(bags);

    var end = std.time.nanoTimestamp();

    try out.print("problem seven:\n", .{});
    try out.print("\tpart 1:\t\t{d}\n", .{p1});
    try out.print("\tpart 2:\t\t{d}\n", .{p2});
    try out.print("\tduration:\t{d}ns\n", .{end - start});
}

fn deinitBagsContents(bags: std.StringHashMap(RC(Bag))) void {
    var it = bags.valueIterator();
    while (it.next()) |bag| {
        for (bag.val.contains.items) |child| {
            child.bag.destroy();
        }
        bag.val.contains.deinit();
        bag.val.parents.deinit();
        bag.destroy();
    }
}

fn part1(bags: std.StringHashMap(RC(Bag)), allocator: *std.mem.Allocator) !usize {
    const start = "shiny gold";

    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();
    try seen.put(start, {});

    var count: usize = 0;

    var options = std.ArrayList(*Bag).init(allocator);
    defer options.deinit();
    var startBag = bags.getPtr(start) orelse unreachable;
    try options.appendSlice(startBag.val.parents.items);

    while (options.popOrNull()) |current| {
        if (!seen.contains(current.colour)) {
            count += 1;
            try seen.put(current.colour, {});
            try options.appendSlice(current.parents.items);
        }
    }

    return count;
}

fn part2(bags: std.StringHashMap(RC(Bag))) usize {
    const start = "shiny gold";

    var startBag = bags.getPtr(start) orelse unreachable;

    return startBag.val.total_contains();
}

const bagCreationError = error{ ColourNotFound, ChildCountNotFound, ChildAdjectiveNotFound, ChildColourNotFound };

fn createBags(source: []u8, allocator: *std.mem.Allocator) !std.StringHashMap(RC(Bag)) {
    var bags = std.StringHashMap(RC(Bag)).init(allocator);

    var lines = std.mem.tokenize(u8, source, "\n");
    while (lines.next()) |line| {
        var endOfColour = std.mem.indexOf(u8, line, " bags contain ") orelse return bagCreationError.ColourNotFound;
        var colour = line[0..endOfColour];
        if (!bags.contains(colour)) {
            var newBag = Bag{ .colour = colour, .parents = std.ArrayList(*Bag).init(allocator), .contains = std.ArrayList(Contents).init(allocator) };

            try bags.put(colour, try RC(Bag).new(newBag, allocator));
        }

        var entry = bags.get(colour) orelse unreachable;

        var rest = line[endOfColour + 14 ..];

        if (std.mem.eql(u8, rest, "no other bags.")) {
            continue;
        }

        rest = rest[0 .. rest.len - 1];

        var children = std.mem.split(u8, rest, ", ");
        while (children.next()) |child| {
            var parts = std.mem.tokenize(u8, child, " ");

            var childCountString = parts.next() orelse return bagCreationError.ChildCountNotFound;
            var childAdjective = parts.next() orelse return bagCreationError.ChildAdjectiveNotFound;
            var childColour = parts.next() orelse return bagCreationError.ChildColourNotFound;

            var childString = child[2 .. childAdjective.len + childColour.len + 3];
            var childCount = try std.fmt.parseInt(usize, childCountString, 10);

            if (!bags.contains(childString)) {
                var newBag = Bag{ .colour = childString, .parents = std.ArrayList(*Bag).init(allocator), .contains = std.ArrayList(Contents).init(allocator) };
                try bags.put(childString, try RC(Bag).new(newBag, allocator));
            }

            var childBag = bags.get(childString) orelse unreachable;

            try entry.val.contains.append(Contents{ .count = childCount, .bag = childBag.copy() });
            try childBag.val.parents.append(entry.val);
        }
    }

    return bags;
}
