const std = @import("std");
const ArrayList = std.ArrayList;

pub fn run(contents: []u8, out: anytype, allocator: *std.mem.Allocator) !void {
    var start = std.time.nanoTimestamp();

    var machine = try Machine.fromString(contents, allocator);
    defer machine.instructions.deinit();

    var p1 = try part1(&machine, allocator);
    var p2 = try part2(&machine, allocator);

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

fn part1(machine: *Machine, allocator: *std.mem.Allocator) !isize {
    var seen = ArrayList(bool).init(allocator);
    defer seen.deinit();
    _ = try machine.run_to_loop(&seen);
    defer machine.reset();
    return machine.accumulator;
}

const Uncompleteable = error{Uncompleteable};

fn part2(machine: *Machine, allocator: *std.mem.Allocator) !isize {
    var seen = ArrayList(bool).init(allocator);
    defer seen.deinit();
    var i: usize = 0;
    while (i < machine.instructions.items.len) : (i += 1) {
        if (transform(&machine.instructions.items[i])) {
            if ((try machine.run_to_loop(&seen)) == .ReachedEnd) {
                return machine.accumulator;
            }

            _ = transform(&machine.instructions.items[i]);
            machine.reset();
        }
    }

    return Uncompleteable.Uncompleteable;
}

const I = enum { Acc, Jmp, Nop };

const MachineState = enum { Running, Stopped };

const Instruction = union(I) { Acc: isize, Jmp: isize, Nop: isize };

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

            if (std.mem.eql(u8, ins, "acc")) {
                try instructions.append(Instruction{ .Acc = num });
            } else if (std.mem.eql(u8, ins, "jmp")) {
                try instructions.append(Instruction{ .Jmp = num });
            } else if (std.mem.eql(u8, ins, "nop")) {
                try instructions.append(Instruction{ .Nop = num });
            }
        }

        return Machine.new(instructions);
    }

    fn new(instructions: std.ArrayList(Instruction)) Machine {
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

    fn run_to_loop(self: *Machine, seen: *ArrayList(bool)) !TerminationCondition {
        seen.clearRetainingCapacity();
        try seen.appendNTimes(false, self.instructions.items.len);

        while (true) {
            self.step();
            var ind = @bitCast(usize, self.index);
            if (ind >= seen.items.len) {
                return .ReachedEnd;
            }
            if (seen.items[ind]) {
                return .Looped;
            }
            seen.items[ind] = true;
        }
    }
};
