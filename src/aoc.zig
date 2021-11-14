const std = @import("std");

const day01 = @import("./days/day01.zig");
const day02 = @import("./days/day02.zig");
const day03 = @import("./days/day03.zig");
const day04 = @import("./days/day04.zig");
const day05 = @import("./days/day05.zig");
const day06 = @import("./days/day06.zig");
const day07 = @import("./days/day07.zig");
const day08 = @import("./days/day08.zig");
const day09 = @import("./days/day09.zig");
const utils = @import("util.zig");

const Contents = utils.Contents;

pub fn main() !void {
    var buf: [1 << 22]u8 = undefined;
    var bufAllocator = std.heap.FixedBufferAllocator.init(&buf);
    var allocator = &bufAllocator.allocator;
    // var genAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(!genAllocator.deinit());
    // var allocator = &genAllocator.allocator;

    var contents = try Contents.load(allocator);
    defer contents.discard();

    var out = try std.ArrayList(u8).initCapacity(allocator, 8192);
    defer out.deinit();
    var writer = out.writer();

    var start = std.time.nanoTimestamp();

    try day01.run(contents.day01, &writer, allocator);
    try day02.run(contents.day02, &writer);
    try day03.run(contents.day03, &writer);
    try day04.run(contents.day04, &writer);
    try day05.run(contents.day05, &writer);
    try day06.run(contents.day06, &writer);
    try day07.run(contents.day07, &writer, allocator);
    try day08.run(contents.day08, &writer, allocator);
    try day09.run(contents.day09, &writer, allocator);

    var end = std.time.nanoTimestamp();

    try writer.print("aoc ran in:\n", .{});
    try writer.print("\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try writer.print("\t{d}us\n", .{@divFloor(end - start, 1_000)});

    const stdout = std.io.getStdOut();
    defer stdout.close();
    _ = try stdout.write(out.items);
}
