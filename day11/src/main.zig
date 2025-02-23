const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const time = std.time;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    var stones = StringHashMap(usize).init(allocator);
    defer stones.deinit();

    stones = StringHashMap(usize).init(allocator);
    try parse("input.txt", allocator, &stones);

    var start = time.milliTimestamp();
    var post_blink_stones = try blink(25, stones, allocator);
    std.debug.print("Part 1 Total: {d}\n", .{count_stones(&post_blink_stones)});
    std.debug.print("took {d:.4}s\n", .{@as(f32, @floatFromInt(time.milliTimestamp() - start)) / 1000.0});

    start = time.milliTimestamp();
    post_blink_stones = try blink(75, stones, allocator);
    std.debug.print("Part 2 Total: {d}\n", .{count_stones(&post_blink_stones)});
    std.debug.print("took {d:.4}s\n", .{@as(f32, @floatFromInt(time.milliTimestamp() - start)) / 1000.0});
}


pub fn count_stones(stones: *StringHashMap(usize)) usize {
    var it = stones.valueIterator();
    var count: usize = 0;
    while (it.next()) |v| {
        count += v.*;
    }
    return count;
}

pub fn blink(n: u8, stones: StringHashMap(usize), allocator: std.mem.Allocator) !StringHashMap(usize) {
    if (n == 0) return stones;
    var it = stones.iterator();
    var next_stones = StringHashMap(usize).init(allocator);
    while (it.next()) |kv| {
        if (std.mem.eql(u8, kv.key_ptr.*,"0")) {
            const existing_value =  try next_stones.getOrPutValue("1", 0);
            existing_value.value_ptr.* += kv.value_ptr.*;
            continue;
        } else if (@mod(kv.key_ptr.*.len, 2) == 0) {
            const key_len = kv.key_ptr.*.len/2;
            var window = std.mem.window(u8, kv.key_ptr.*, key_len, key_len);
            while (window.next()) |new_stone| {
                const parsed_stone = try std.fmt.parseInt(usize, new_stone, 10);
                const existing_value = try next_stones.getOrPutValue(try std.fmt.allocPrint(allocator, "{d}", .{parsed_stone}), 0);
                existing_value.value_ptr.* += kv.value_ptr.*;
            }
        } else {
            const new_stone = try std.fmt.parseInt(usize, kv.key_ptr.* , 10) * 2024;
            const existing_value =  try next_stones.getOrPutValue(try std.fmt.allocPrint(allocator, "{d}", .{new_stone}), 0);
            existing_value.value_ptr.* += kv.value_ptr.*;
        }
    }

    return try blink(n-1, next_stones, allocator);
}

pub fn parse(
    path: []const u8, 
    allocator: std.mem.Allocator,
    stones: *StringHashMap(usize),
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
            const entry = try stones.getOrPutValue(new_val, 0);
            entry.value_ptr.* += 1;
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

