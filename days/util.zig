const std = @import("std");

pub fn RC(comptime T: type) type {
    return struct {
        const Self = @This();

        val: *T,
        count: *usize,
        alloc: *std.mem.Allocator,

        pub fn new(val: T, allocator: *std.mem.Allocator) !Self {
            var counter = try allocator.create(usize);
            var valP = try allocator.create(T);
            counter.* = 1;
            valP.* = val;
            return Self{ .val = valP, .count = counter, .alloc = allocator };
        }

        pub fn copy(self: Self) Self {
            self.count.* += 1;
            return self;
        }

        pub fn destroy(self: Self) void {
            self.count.* -= 1;
            if (self.count.* == 0) {
                self.alloc.destroy(self.count);
                self.alloc.destroy(self.val);
            }
        }
    };
}
