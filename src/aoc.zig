const day01 = @import("./days/day01.zig");
const day02 = @import("./days/day02.zig");
const day07 = @import("./days/day07.zig");
const day08 = @import("./days/day08.zig");
const std = @import("std");
const utils = @import("util.zig");
const Contents = utils.Contents;

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = &arenaAllocator.allocator;

    var contents = try Contents.load(allocator);
    defer contents.discard();

    var out = try std.ArrayList(u8).initCapacity(allocator, 8192);
    defer out.deinit();
    var writer = out.writer();

    var start = std.time.nanoTimestamp();

    try day01.run(contents.day01, &writer, allocator);
    try day02.run(contents.day02, &writer, allocator);
    try day07.run(contents.day07, &writer, allocator);
    try day08.run(contents.day08, &writer, allocator);

    var end = std.time.nanoTimestamp();

    try writer.print("overall that took: {d}ns or {d}ms\n", .{ end - start, @divFloor(end - start, 1_000_000) });
    try writer.print("\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(end - start, 1_000)});
    try writer.print("\t{d}ns\n", .{end - start});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    _ = try stdout.write(out.items);
}
