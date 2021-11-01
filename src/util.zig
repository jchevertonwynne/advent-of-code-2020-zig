const std = @import("std");

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

        pub fn weak(self: Self) *T {
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
