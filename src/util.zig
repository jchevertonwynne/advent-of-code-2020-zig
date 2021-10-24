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
