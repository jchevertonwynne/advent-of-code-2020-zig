const std = @import("std");

pub fn ArrayVec(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        inner: [size]T,
        len: usize,

        pub fn new() Self {
            return .{ .inner = undefined, .len = 0 };
        }

        pub fn insert(self: *Self, val: T) void {
            if (self.len == size) {
                @panic("too big sad face");
            } 
            self.inner[self.len] = val;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }
            self.len -= 1;
            return self.inner[self.len];
        }

        pub fn items(self: Self) []const T {
            return self.inner[0..self.len];
        } 
    };
}

pub fn HashSet(comptime T: type) type {
    const mapType = if (T == []const u8) std.StringHashMap(void) else std.AutoHashMap(T, void);

    return struct {
        const Self = @This();

        map: mapType,

        pub fn init(allocator: *std.mem.Allocator) Self {
            return .{ .map = mapType.init(allocator) };
        }

        pub fn count(self: Self) u32 {
            return self.map.count();
        }

        pub fn insertCheck(self: *Self, val: T) !bool {
            var contained = self.contains(val);
            if (contained) {
                return false;
            }
            try self.insert(val);
            return true;
        }

        pub fn insert(self: *Self, val: T) !void {
            return self.map.put(val, {});
        }

        pub fn contains(self: Self, val: T) bool {
            return self.map.contains(val);
        }

        pub fn clear(self: *Self) void {
            self.map.clearRetainingCapacity();
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }
    };
}

pub fn RC(comptime T: type) type {
    const internal = struct { val: T, count: usize };

    return struct {
        const Self = @This();

        inner: *internal,
        alloc: *std.mem.Allocator,

        pub fn new(val: T, allocator: *std.mem.Allocator) !Self {
            var inner = try allocator.create(internal);
            inner.count = 1;
            inner.val = val;
            return Self{ .inner = inner, .alloc = allocator };
        }

        pub fn ptr(self: Self) *T {
            return &self.inner.val;
        }

        pub fn copy(self: Self) Self {
            self.inner.count += 1;
            return self;
        }

        pub fn destroy(self: Self) void {
            self.inner.count -= 1;
            if (self.inner.count == 0) {
                self.alloc.destroy(self.inner);
            }
        }
    };
}

pub const Contents = struct {
    allocator: *std.mem.Allocator,
    day01: []u8,
    day02: []u8,
    day07: []u8,
    day08: []u8,

    pub fn load(allocator: *std.mem.Allocator) !Contents {
        var dir = std.fs.cwd();
        var day01String = try dir.readFileAlloc(allocator, "files/01.txt", std.math.maxInt(usize));
        errdefer allocator.free(day01String);
        var day02String = try dir.readFileAlloc(allocator, "files/02.txt", std.math.maxInt(usize));
        errdefer allocator.free(day02String);
        var day07String = try dir.readFileAlloc(allocator, "files/07.txt", std.math.maxInt(usize));
        errdefer allocator.free(day07String);
        var day08String = try dir.readFileAlloc(allocator, "files/08.txt", std.math.maxInt(usize));
        errdefer allocator.free(day08String);

        return Contents{
            .allocator = allocator,
            .day01 = day01String,
            .day02 = day02String,
            .day07 = day07String,
            .day08 = day08String,
        };
    }

    pub fn discard(c: Contents) void {
        c.allocator.free(c.day01);
        c.allocator.free(c.day02);
        c.allocator.free(c.day07);
        c.allocator.free(c.day08);
    }
};

pub fn writeResponse(out: anytype, day: usize, part1: anytype, part2: anytype, time: i128) !void {
    try out.print("problem {}:\n", .{day});
    try out.print("\tpart 1:\t{}\n", .{part1});
    try out.print("\tpart 2:\t{}\n", .{part2});
    try out.print("duration:\n", .{});
    try out.print("\t{d}ms\n", .{@divFloor(time, 1_000_000)});
    try out.print("\t{d}us\n", .{@divFloor(time, 1_000)});
    try out.print("\t{d}ns\n\n", .{time});
}
