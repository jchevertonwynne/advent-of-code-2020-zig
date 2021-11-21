const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

const PoolAllocator = util.PoolAllocator;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var bags = try BagTree.fromString(contents, allocator);
    defer bags.deinit();

    var shinyGold = bags.bags.get("shiny gold") orelse return error.BagNotFound;

    var p1 = shinyGold.totalParents();
    var p2 = shinyGold.totalContains();

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 7, p1, p2, end - start);
}

const BagTree = struct {
    const Self = @This();

    bagSource: PoolAllocator(Bag, 128),
    bags: StringHashMap(*Bag),

    fn fromString(input: []u8, allocator: *std.mem.Allocator) !Self {
        var source = PoolAllocator(Bag, 128).init(allocator);
        errdefer source.deinit();

        var bags = StringHashMap(*Bag).init(allocator);
        errdefer bags.deinit();

        var lines = std.mem.tokenize(u8, input, "\n");
        while (lines.next()) |line| {
            var endOfColour = std.mem.indexOf(u8, line, " bags contain ") orelse return error.ColourNotFound;
            var colour = line[0..endOfColour];
            if (!bags.contains(colour)) {
                var newBag = try source.next();
                newBag.* = .{ .colour = colour, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator), .seen = false };
                try bags.put(colour, newBag);
            }

            var entry = bags.get(colour) orelse return error.BagNotFound;

            var rest = line[endOfColour + 14 ..];

            if (std.mem.eql(u8, rest, "no other bags."))
                continue;

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
                    var newBag = try source.next();
                    newBag.* = .{ .colour = childString, .parents = ArrayList(*Bag).init(allocator), .children = ArrayList(Contents).init(allocator), .seen = false };
                    try bags.put(childString, newBag);
                }

                var childBag = bags.get(childString) orelse return error.BagNotFound;

                try entry.children.append(Contents{ .count = childCount, .bag = childBag });
                try childBag.parents.append(entry);
            }
        }

        return Self{ .bags = bags, .bagSource = source };
    }

    fn deinit(self: *Self) void {
        var it = self.bags.valueIterator();
        while (it.next()) |bag|
            bag.*.deinit();
        self.bagSource.deinit();
        self.bags.deinit();
    }
};

const Bag = struct {
    const Self = @This();

    colour: []const u8,
    parents: ArrayList(*Bag),
    children: ArrayList(Contents),
    seen: bool,

    fn totalParents(self: *Self) usize {
        var result: usize = 0;

        for (self.parents.items) |parent| {
            if (!parent.seen) {
                var parentResult = parent.totalParents();
                parent.seen = true;
                result += 1 + parentResult;
            }
        }

        return result;
    }

    fn totalContains(b: Self) usize {
        var res: usize = 0;

        for (b.children.items) |child|
            res += child.count * (1 + child.bag.totalContains());

        return res;
    }

    fn deinit(self: *Self) void {
        self.parents.deinit();
        self.children.deinit();
    }
};

const Contents = struct { count: usize, bag: *Bag };
