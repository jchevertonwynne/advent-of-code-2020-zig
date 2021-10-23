const day01 = @import("./days/day01.zig");
const day02 = @import("./days/day02.zig");
const day07 = @import("./days/day07.zig");
const day08 = @import("./days/day08.zig");
const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arenaAllocator.deinit();
    var alloc = &arenaAllocator.allocator;

    var contents = try Contents.load(alloc);
    defer contents.discard();

    var out = try std.ArrayList(u8).initCapacity(alloc, 8192);
    var writer = out.writer();

    var start = std.time.nanoTimestamp();

    try day01.run(contents.day01, &writer, alloc);
    try day02.run(contents.day02, &writer);
    try day07.run(contents.day07, &writer, alloc);
    try day08.run(contents.day08, &writer, alloc);

    var end = std.time.nanoTimestamp();

    try writer.print("overall that took: {d}ns or {d}ms\n", .{ end - start, @divFloor(end - start, 1_000_000) });
    try writer.print("\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(end - start, 1_000)});
    try writer.print("\t{d}ns\n", .{end - start});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    try stdout.writer().writeAll(out.items);
}

const Contents = struct {
    allocator: *std.mem.Allocator,
    day01: []u8,
    day02: []u8,
    day07: []u8,
    day08: []u8,

    fn load(allocator: *std.mem.Allocator) !Contents {
        var dir = std.fs.cwd();
        return Contents{
            .allocator = allocator,
            .day01 = try dir.readFileAlloc(allocator, "files/01.txt", std.math.maxInt(usize)),
            .day02 = try dir.readFileAlloc(allocator, "files/02.txt", std.math.maxInt(usize)),
            .day07 = try dir.readFileAlloc(allocator, "files/07.txt", std.math.maxInt(usize)),
            .day08 = try dir.readFileAlloc(allocator, "files/08.txt", std.math.maxInt(usize)),
        };
    }

    fn discard(c: Contents) void {
        c.allocator.free(c.day01);
        c.allocator.free(c.day02);
        c.allocator.free(c.day07);
        c.allocator.free(c.day08);
    }
};
