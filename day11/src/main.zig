const std = @import("std");
const ArrayList = std.ArrayList;
const time = std.time;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    var stones = ArrayList([]const u8).init(allocator);
    defer stones.deinit();

    try parse("test-input.txt", allocator, &stones);
    const n_blinks = 25;

    var start = time.milliTimestamp();
    try blink(n_blinks, &stones, allocator);
    std.debug.print("Part 1 Total: {d}\n", .{stones.items.len});
    std.debug.print("took {d:.4}s\n", .{@as(f32, @floatFromInt(time.milliTimestamp() - start)) / 1000.0});

    // First, try memoization: not much of a speed up due to reinitializing ArrayList
    // Instead, I think I have to keep track of cycles to
    // prevent the ArrayList from growing to an unmanageable size
    // In particular, I'm sure I have to keep track of 0's
    // since 0 -> 1 -> 2024 -> 2 0 2 4
    var seen = std.StringHashMap(ArrayList([]const u8)).init(allocator);
    defer seen.deinit();
    stones = ArrayList([]const u8).init(allocator);
    try parse("test-input.txt", allocator, &stones);

    start = time.milliTimestamp();
    try blink_memoized(n_blinks, &stones, &seen, allocator);
    std.debug.print("Part 2 Total: {d}\n", .{stones.items.len});
    std.debug.print("took {d:.4}s\n", .{@as(f32, @floatFromInt(time.milliTimestamp() - start)) / 1000.0});
}
// instead 

pub fn blink_memoized(n: u8, stones: *ArrayList([]const u8), seen: *std.StringHashMap(ArrayList([]const u8)), allocator: std.mem.Allocator) !void {
    if (n == 0) return;
    const l = stones.items.len;
    // ArrayList Methods
    var offset: usize = 0;

    // std.debug.print("iter {d}: {s}\n", .{n, stones.items});
    for (0..l) |i| {
        const curr_item = stones.items[i+offset];
        // Memoization: check if value is in seen
        if (seen.get(curr_item)) |val| {
            // std.debug.print("found {s}: {s}, size: {d}\n", .{curr_item, val.items, stones.items.len});
            _ = stones.orderedRemove(i+offset);
            try stones.insertSlice(i+offset, val.items);
            // std.debug.print("\tnew size {d}\n", .{stones.items.len});
            if (val.items.len == 2) offset += 1;
            continue;
        }

        var values = ArrayList([]const u8).init(allocator);
        if (std.mem.eql(u8, curr_item, "0")) {
            stones.items[i+offset] = "1";

            // Memoization: add to seen
            try values.append("1");
        } else if (@rem(curr_item.len, 2) == 0) {
            const k = curr_item.len / 2;
            const item = stones.orderedRemove(i+offset);
            const l_item = try std.fmt.allocPrint(allocator, "{}", .{try std.fmt.parseInt(u64, item[0..k], 10)});
            const r_item = try std.fmt.allocPrint(allocator, "{}", .{try std.fmt.parseInt(u64, item[k..item.len], 10)});

            try stones.insert(i + offset, l_item);
            try stones.insert(i + offset + 1, r_item);
            offset += 1;

            // Memoization: add to seen
            try values.append(l_item);
            try values.append(r_item);
        } else {
            const new_item = try std.fmt.allocPrint(allocator, "{}", .{try std.fmt.parseInt(u64, curr_item, 10) * 2024});
            stones.items[i+offset] = new_item;

            // Memoization: add to seen
            try values.append(new_item);
        }
        try seen.put(curr_item, values);
    }
    try blink_memoized(n-1, stones, seen, allocator);
}

pub fn blink(n: u8, stones: *ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    if (n == 0) return;
    const l = stones.items.len;
    // ArrayList Methods
    var offset: usize = 0;

    for (0..l) |i| {
        if (std.mem.eql(u8, stones.items[i+offset],
                "0")) {
            stones.items[i+offset] = "1";
        } else if (@rem(stones.items[i+offset].len, 2) == 0) {
            const k = stones.items[i+offset].len / 2;
            const item = stones.orderedRemove(i+offset);
            const l_item = try std.fmt.parseInt(u64, item[0..k], 10);
            const r_item = try std.fmt.parseInt(u64, item[k..item.len], 10);
            try stones.insert(i + offset, try std.fmt.allocPrint(allocator, "{}", .{l_item}));
            try stones.insert(i + offset + 1, try std.fmt.allocPrint(allocator, "{}", .{r_item}));
            offset += 1;
        } else {
            const new_item = try std.fmt.parseInt(u64, stones.items[i+offset], 10) * 2024;
            stones.items[i+offset] = try std.fmt.allocPrint(allocator, "{}", .{new_item});
        }
    }
    try blink(n-1, stones, allocator);
}

pub fn parse(
    path: []const u8, 
    allocator: std.mem.Allocator,
    stones: *ArrayList([]const u8)
) !void {
    // Open file and read contents
    var file = try std.fs.cwd().openFile(path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    defer file.close();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        while (it.next()) |val| {
            const new_val = try allocator.alloc(u8, val.len);
            std.mem.copyForwards(u8, new_val, val);
            try stones.append(new_val);
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

