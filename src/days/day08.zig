const std = @import("std");

const util = @import("../util.zig");

const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var machine = try Machine.fromString(contents, allocator);
    defer machine.instructions.deinit();

    var storage = try allocator.alloc(bool, machine.instructions.items.len * 2);
    defer allocator.free(storage);
    var seen = storage[0..machine.instructions.items.len];
    
    var p1 = part1(&machine, seen);

    var criticalInstructions = storage[machine.instructions.items.len..];
    std.mem.copy(bool, criticalInstructions, seen);

    var p2 = try part2(&machine, seen, criticalInstructions);

    var end = std.time.nanoTimestamp();

    try util.writeResponse(out, 8, p1, p2, end - start);
}

fn part1(machine: *Machine, seen: []bool) isize {
    _ = machine.run_to_loop(seen);
    defer machine.reset();
    return machine.accumulator;
}

fn part2(machine: *Machine, seen: []bool, criticalInstructions: []bool) !isize {
    for (machine.instructions.items) |*instruction, i| {
        if (criticalInstructions[i] and instruction.transform()) {
            if (machine.run_to_loop(seen) == .ReachedEnd) {
                return machine.accumulator;
            }

            _ = instruction.transform();
            machine.reset();
        }
    }

    return error.NoSwappableInstructionSolutionFound;
}

const MachineState = enum { Running, Stopped };

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

            var instruction = switch (ins[0]) {
                'a' => Instruction{ .Acc = num },
                'j' => Instruction{ .Jmp = num },
                'n' => Instruction{ .Nop = num },
                else => return error.UnparseableInstruction
            };

            try instructions.append(instruction);
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
        for (seen) |*s|
            s.* = false;

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
