const std = @import("std");
const ArrayList = std.ArrayList;
 
const Op = enum {
    Add,
    Multiply,
    Concat, 
};

// can't we do like a tree like evaluation
//
//                                                         |- prev_input * input_3 
//         |--- prev_input + input_2 (if < answer) branch; |
//         |                                               |- prev_input + input_3 
//         |
// input_1 | 
//         |                                               |- prev_input * input_3 
//         |--- prev_input * input_2 (if < answer) branch; |
//                                                         X- prev_input + input_3 
//

fn part1_scanner(input: []u64, answer: u64, total: u64, op: Op) u64 {
    var new_total: u64 = 0;
    switch (op) {
        .Add => {
            new_total = total + input[0];
        },
        .Multiply => {
            new_total = total * input[0];
        },
        else => {}
    }
    // We have no more things to send
    if (input.len == 1) {
        if (new_total == answer) return 1 else return 0;
    } 

    // We still have things to send
    if (new_total > answer) {
        return 0;
    } else {
        return part1_scanner(input[1..], answer, new_total, Op.Multiply) + part1_scanner(input[1..], answer, new_total, Op.Add);
    }
}

fn part2_scanner(input: []u64, answer: u64, total: u64, op: Op, allocator: std.mem.Allocator) !u64 {
    var new_total: u64 = 0;
    switch (op) {
        .Add => {
            new_total = total + input[0];
        },
        .Multiply => {
            new_total = total * input[0];
        },
        .Concat => {
            const concatted = try std.fmt.allocPrint(
                allocator,
                "{d}{d}",
                .{ total, input[0] },
            );
            new_total = try std.fmt.parseInt(u64, concatted, 10);
        }
    }
    // We have no more things to send
    if (input.len == 1) {
        if (new_total == answer) return 1 else return 0;
    } 

    // We still have things to send
    if (new_total > answer) {
        return 0;
    } else {
        return try part2_scanner(input[1..], answer, new_total, Op.Concat, allocator) + try part2_scanner(input[1..], answer, new_total, Op.Multiply, allocator) + try part2_scanner(input[1..], answer, new_total, Op.Add, allocator);
        
    }
}


pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var answers_list = ArrayList(u64).init(allocator);
    defer answers_list.deinit();

    var options_list = ArrayList(ArrayList(u64)).init(allocator);
    defer options_list.deinit();

    try parse("input.txt", &answers_list, &options_list, allocator);

    // I used a recursive solution. Note that this is not the most performant
    var total: u64 = 0;
    for (answers_list.items, options_list.items) |answer, options| {
        const total_correct = part1_scanner(options.items, answer, 1, Op.Multiply);
        if (total_correct > 0) total += answer;
        
    }
    std.debug.print("Part 1 total: {d}\n", .{total});

    total = 0;
    for (answers_list.items, options_list.items) |answer, options| {
        const total_correct = try part2_scanner(options.items, answer, 1, Op.Multiply, allocator);
        if (total_correct > 0) total += answer;
        
    }
    std.debug.print("Part 2 total: {d}\n", .{total});
}

pub fn parse(
    path: []const u8, 
    answers_list: *ArrayList(u64),
    options_list: *ArrayList(ArrayList(u64)),
    allocator: std.mem.Allocator,
) !void {
    // Open file and read contents
    var file = try std.fs.cwd().openFile(path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    defer file.close();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var colon_split = std.mem.tokenizeAny(u8, line, ":");
        const answer = colon_split.next().?;
        try answers_list.append(try std.fmt.parseInt(u64, answer, 10));

        var options = std.mem.tokenizeAny(u8, colon_split.next().?, " ");
        var parsed_options = ArrayList(u64).init(allocator);
        while (options.next()) |entry| {
            const parsed = try std.fmt.parseInt(u64, entry, 10);
            try parsed_options.append(parsed);
        }
        try options_list.append(parsed_options);
    }
}


test "test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
