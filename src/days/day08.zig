const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var machine = try Machine.fromString(contents, allocator);
    defer machine.instructions.deinit();

    var seen = ArrayList(bool).init(allocator);
    defer seen.deinit();
    try seen.appendNTimes(false, machine.instructions.items.len);

    var p1 = part1(&machine, seen.items);
    var p2 = try part2(&machine, seen.items);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 8, p1, p2, end - start);
}

fn part1(machine: *Machine, seen: []bool) isize {
    _ = machine.run_to_loop(seen);
    defer machine.reset();
    return machine.accumulator;
}

fn part2(machine: *Machine, seen: []bool) !isize {
    var i: usize = 0;
    while (i < machine.instructions.items.len) : (i += 1) {
        if (machine.instructions.items[i].transform()) {
            if ((machine.run_to_loop(seen)) == .ReachedEnd) {
                return machine.accumulator;
            }

            _ = machine.instructions.items[i].transform();
            machine.reset();
        }
    }

    return error.NoSwappableInstructionSolutionFound;
}

const Instruction = union(enum) {
    const Self = @This();

    Acc: isize,
    Jmp: isize,
    Nop: isize,

    fn transform(self: *Self) bool {
        switch (self.*) {
            .Acc => return false,
            .Jmp => |val| {
                self.* = Self{ .Nop = val };
                return true;
            },
            .Nop => |val| {
                self.* = Self{ .Jmp = val };
                return true;
            },
        }
    }
};

const TerminationCondition = enum { Looped, ReachedEnd };

const Machine = struct {
    const Self = @This();

    index: isize,
    instructions: ArrayList(Instruction),
    accumulator: isize,

    fn fromString(source: []u8, allocator: *std.mem.Allocator) !Self {
        var instructions = ArrayList(Instruction).init(allocator);
        errdefer instructions.deinit();

        var lines = std.mem.tokenize(u8, source, "\n");
        while (lines.next()) |line| {
            var ins = line[0..3];
            var sign = line[4];
            var numS = line[5..];

            var num = try std.fmt.parseInt(isize, numS, 10);
            if (sign == '-') {
                num = try std.math.negate(num);
            }

            var instruction: ?Instruction = null;
            if (std.mem.eql(u8, ins, "acc")) {
                instruction = Instruction{ .Acc = num };
            } else if (std.mem.eql(u8, ins, "jmp")) {
                instruction = Instruction{ .Jmp = num };
            } else if (std.mem.eql(u8, ins, "nop")) {
                instruction = Instruction{ .Nop = num };
            }

            if (instruction) |parsedInstruction| {
                try instructions.append(parsedInstruction);
            } else {
                return error.UnparseableInstruction;
            }
        }

        return Machine.new(instructions);
    }

    fn new(instructions: ArrayList(Instruction)) Self {
        return .{ .index = 0, .instructions = instructions, .accumulator = 0 };
    }

    fn reset(self: *Self) void {
        self.accumulator = 0;
        self.index = 0;
    }

    fn step(self: *Self) void {
        switch (self.instructions.items[@bitCast(usize, self.index)]) {
            .Acc => |val| {
                self.accumulator += val;
                self.index += 1;
            },
            .Jmp => |val| {
                self.index += val;
            },
            .Nop => {
                self.index += 1;
            },
        }
    }

    fn run_to_loop(self: *Self, seen: []bool) TerminationCondition {
        var i: usize = 0;
        while (i < seen.len) : (i += 1) {
            seen[i] = false;
        }

        while (true) {
            self.step();
            var ind = @bitCast(usize, self.index);
            if (ind >= self.instructions.items.len) {
                return .ReachedEnd;
            }
            if (seen[ind]) {
                return .Looped;
            }
            seen[ind] = true;
        }
    }
};
