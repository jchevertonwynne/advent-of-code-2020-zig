const std = @import("std");
const util = @import("../util.zig");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const RC = util.RC;
const HashSet = util.HashSet;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var bags = try BagTree.fromString(contents, allocator);
    defer bags.deinit();

    var p1 = try part1(bags, allocator);
    var p2 = try part2(bags);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 7, p1, p2, end - start);
}

fn part1(bags: BagTree, allocator: *std.mem.Allocator) !usize {
    return try bags.parents("shiny gold", allocator);
}

fn part2(bags: BagTree) !usize {
    return try bags.contains("shiny gold");
}

const BagTree = struct {
    const Self = @This();

    bags: StringHashMap(RC(Bag)),

    fn fromString(source: []u8, allocator: *std.mem.Allocator) !Self {
        var bags = StringHashMap(RC(Bag)).init(allocator);
        errdefer bags.deinit();

        var lines = std.mem.tokenize(u8, source, "\n");
        while (lines.next()) |line| {
            var endOfColour = std.mem.indexOf(u8, line, " bags contain ") orelse return error.ColourNotFound;
            var colour = line[0..endOfColour];
            if (!bags.contains(colour)) {
                var newBag = try RC(Bag).new(Bag{ .colour = colour, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator) }, allocator);
                errdefer newBag.destroy();                
                try bags.put(colour, newBag);
            }

            var entry = (bags.get(colour) orelse return error.BagNotFound).ptr();

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
                    var newBag = try RC(Bag).new(Bag{ .colour = childString, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator) }, allocator);
                    errdefer newBag.destroy();
                    try bags.put(childString, newBag);
                }

                var childBag = bags.get(childString) orelse return error.BagNotFound;

                try entry.children.append(Contents{ .count = childCount, .bag = childBag.copy() });
                try childBag.ptr().parents.append(entry);
            }
        }

        return Self{ .bags = bags };
    }

    fn deinit(self: *Self) void {
        var it = self.bags.valueIterator();
        while (it.next()) |bag| {
            bag.ptr().deinit();
            bag.destroy();
        }
        self.bags.deinit();
    }

    fn parents(self: Self, start: []const u8, allocator: *std.mem.Allocator) !usize {
        var seen = HashSet([]const u8).init(allocator);
        defer seen.deinit();

        var sourceBag = self.bags.getPtr(start) orelse return error.BagNotFound;

        return try sourceBag.ptr().parentsHelper(self.bags, &seen);
    }

    fn contains(self: Self, source: []const u8) !usize {
        var startBag = self.bags.getPtr(source) orelse return error.FailedToFindBag;

        return startBag.ptr().totalContains();
    }
};

const Bag = struct {
    const Self = @This();

    colour: []const u8,
    parents: ArrayList(*Bag),
    children: ArrayList(Contents),

    fn parentsHelper(self: *Self, bags: StringHashMap(RC(Bag)), seen: *HashSet([]const u8)) anyerror!usize {
        var result: usize = 0;

        for (self.parents.items) |parent| {
            if (try seen.insertCheck(parent.colour)) {
                var parentResult = try parent.parentsHelper(bags, seen);
                result += 1 + parentResult;
            }
        }

        return result;
    }

    fn totalContains(b: Self) usize {
        var res: usize = 0;

        for (b.children.items) |child| {
            res += child.count * (1 + child.bag.ptr().totalContains());
        }

        return res;
    }

    fn deinit(self: *Self) void {
        for (self.children.items) |child| {
            child.bag.destroy();
        }
        self.parents.deinit();
        self.children.deinit();
    }
};

const Contents = struct { count: usize, bag: RC(Bag) };
