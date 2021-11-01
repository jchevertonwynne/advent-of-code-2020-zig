const std = @import("std");
const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var machine = try Machine.fromString(contents, allocator);
    defer machine.instructions.deinit();

    var seen = ArrayList(bool).init(allocator);
    try seen.appendNTimes(false, machine.instructions.items.len);

    var p1 = part1(&machine, seen.items);
    var p2 = try part2(&machine, seen.items);

    var end = std.time.nanoTimestamp();

    try out.print("problem eight:\n", .{});
    try out.print("\tpart 1:\n", .{});
    try out.print("\t\t{d}\n", .{p1});
    try out.print("\tpart 2:\n", .{});
    try out.print("\t\t{d}\n", .{p2});
    try out.print("\tduration:\n", .{});
    try out.print("\t\t{d}ms\n", .{@divFloor(end - start, 1_000_000)});
    try out.print("\t\t{d}us\n", .{@divFloor(end - start, 1_000)});
    try out.print("\t\t{d}ns\n", .{end - start});
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

const I = enum { Acc, Jmp, Nop };

const MachineState = enum { Running, Stopped };

const Instruction = union(I) {
    Acc: isize,
    Jmp: isize,
    Nop: isize,

    fn transform(instruction: *Instruction) bool {
        switch (instruction.*) {
            .Acc => return false,
            .Jmp => |val| {
                instruction.* = Instruction{ .Nop = val };
                return true;
            },
            .Nop => |val| {
                instruction.* = Instruction{ .Jmp = val };
                return true;
            },
        }
    }
};

const TerminationCondition = enum { Looped, ReachedEnd };

const Machine = struct {
    index: isize,
    instructions: ArrayList(Instruction),
    accumulator: isize,

    fn fromString(source: []u8, allocator: *std.mem.Allocator) !Machine {
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

    fn new(instructions: ArrayList(Instruction)) Machine {
        return .{ .index = 0, .instructions = instructions, .accumulator = 0 };
    }

    fn reset(self: *Machine) void {
        self.accumulator = 0;
        self.index = 0;
    }

    fn step(self: *Machine) void {
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

    fn run_to_loop(self: *Machine, seen: []bool) TerminationCondition {
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
