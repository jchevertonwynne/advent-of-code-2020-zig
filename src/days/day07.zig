const std = @import("std");
const util = @import("../util.zig");
const ArrayList = std.ArrayList;
const RC = util.RC;

const Bag = struct {
    colour: []const u8,
    parents: ArrayList(*Bag),
    children: ArrayList(Contents),

    fn total_contains(b: Bag) usize {
        var res: usize = 0;

        for (b.children.items) |child| {
            res += child.count * (1 + child.bag.inner.val.total_contains());
        }

        return res;
    }
};

const Contents = struct { count: usize, bag: RC(Bag) };

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var bags = try createBags(contents, allocator);
    defer deinitBagsContents(&bags);

    var p1 = try part1(bags, allocator);
    var p2 = try part2(bags);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 7, p1, p2, end - start);
}

fn deinitBagsContents(bags: *std.StringHashMap(RC(Bag))) void {
    var it = bags.valueIterator();
    while (it.next()) |bag| {
        for (bag.inner.val.children.items) |child| {
            child.bag.destroy();
        }
        bag.inner.val.children.deinit();
        bag.inner.val.parents.deinit();
        bag.destroy();
    }
    bags.deinit();
}

fn part1(bags: std.StringHashMap(RC(Bag)), allocator: *std.mem.Allocator) !usize {
    const start = "shiny gold";

    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();
    try seen.put(start, {});

    var count: usize = 0;

    var options = ArrayList(*Bag).init(allocator);
    defer options.deinit();
    var startBag = bags.getPtr(start) orelse return error.FailedToFindBag;
    try options.appendSlice(startBag.inner.val.parents.items);

    while (options.popOrNull()) |current| {
        if (!seen.contains(current.colour)) {
            count += 1;
            try seen.put(current.colour, {});
            try options.appendSlice(current.parents.items);
        }
    }

    return count;
}

fn part2(bags: std.StringHashMap(RC(Bag))) !usize {
    const start = "shiny gold";

    var startBag = bags.getPtr(start) orelse return error.FailedToFindBag;

    return startBag.inner.val.total_contains();
}

fn createBags(source: []u8, allocator: *std.mem.Allocator) !std.StringHashMap(RC(Bag)) {
    var bags = std.StringHashMap(RC(Bag)).init(allocator);
    errdefer deinitBagsContents(&bags);

    var lines = std.mem.tokenize(u8, source, "\n");
    while (lines.next()) |line| {
        var endOfColour = std.mem.indexOf(u8, line, " bags contain ") orelse return error.ColourNotFound;
        var colour = line[0..endOfColour];
        if (!bags.contains(colour)) {
            var newBag = Bag{ .colour = colour, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator) };

            try bags.put(colour, try RC(Bag).new(newBag, allocator));
        }

        var entry = bags.get(colour) orelse return error.BagMysteriouslyDisappeared;

        var rest = line[endOfColour + 14 ..];

        if (std.mem.eql(u8, rest, "no other bags.")) {
            continue;
        }

        rest = rest[0 .. rest.len - 1];

        var children = std.mem.split(u8, rest, ", ");
        while (children.next()) |child| {
            var parts = std.mem.tokenize(u8, child, " ");

            var childCountString = parts.next() orelse return error.ChildCountNotFound;
            var childAdjective = parts.next() orelse return error.ChildAdjectiveNotFound;
            var childColour = parts.next() orelse return error.ChildColourNotFound;

            var childString = child[2 .. childAdjective.len + childColour.len + 3];
            var childCount = try std.fmt.parseInt(usize, childCountString, 10);

            if (!bags.contains(childString)) {
                var newBag = Bag{ .colour = childString, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator) };
                try bags.put(childString, try RC(Bag).new(newBag, allocator));
            }

            var childBag = bags.get(childString) orelse return error.BagMysteriouslyDisappeared;

            try entry.inner.val.children.append(Contents{ .count = childCount, .bag = childBag.copy() });
            try childBag.inner.val.parents.append(entry.weak());
        }
    }

    return bags;
}
