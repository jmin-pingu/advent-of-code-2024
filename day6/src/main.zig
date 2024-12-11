const std = @import("std");
const g = @import("grid.zig");
const s = @import("scanner.zig");

const ArrayList = std.ArrayList;
const Coordinate = g.Coordinate;
const Grid = g.Grid;
const Direction = s.Direction;
const Scanner = s.Scanner;

pub fn part2(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var layout = ArrayList([]u8).init(allocator);
    defer layout.deinit();
    var scanner = try parse(path, &layout, allocator);
    var grid = Grid.init(layout, '#', allocator);
    // iterate through positions in the grid and increment total if we find a loop
    var total: u16 = 0;
    for (0..@intCast(grid.y_bound)) |y| {
        x_loop: for (0..@intCast(grid.x_bound)) |x| {
            // attempt to add obstacle at (x, y) 
            if (!try grid.add_obstacle(@intCast(x), @intCast(y))) continue :x_loop; // skip if there exists an obstacle at the position
                                                                                    
            // trial run! if we escape without breaking, it is because we leave the grid
            trial_run: while (try scanner.move(&grid, false, allocator)) { 
                if (try scanner.is_looping(allocator)) {
                    total += 1; 
                    // std.debug.print("loop found: {}\n", .{scanner.coordinate});
                    break :trial_run;
                }
            }

            // reset for next attempt
            scanner.reset(allocator);
            try grid.reset();
        }
    }
    std.debug.print("Part 2 Total: {d}\n", .{total});
}

pub fn part1(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var layout = ArrayList([]u8).init(allocator);
    defer layout.deinit();
    var scanner = try parse(path, &layout, allocator);

    var grid = Grid.init(layout, '#', allocator);

    while (try scanner.move(&grid, true, allocator)) { }
    const total_explored = scanner.num_visited();
    std.debug.print("Part 1 Total: {d}\n", .{total_explored});
}
pub fn main() !void {
    _ = try part1("test-input.txt");
    // NOTE: The solution for part2 takes a good amount of time because in order to detect a loop, 
    // it needs to find the former value in the HashMap
    _ = try part2("test-input.txt");
}

pub fn parse(
    path: []const u8, 
    grid: *std.ArrayList([]u8),
    allocator: std.mem.Allocator
) !Scanner {
    // Open file and read contents
    var file = try std.fs.cwd().openFile(path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    defer file.close();

    // propagate the ArrayList of ArrayLists
    var y_idx: i32 = 0;
    var scanner_start = Coordinate.init(0, 0);
    var direction: Direction = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var copied_line = try allocator.alloc(u8, line.len);
        for (0..line.len) |x_idx| {
            switch (line[x_idx]) {
                '>' => {
                    scanner_start.update(@intCast(x_idx), @intCast(y_idx));
                    direction = Direction.Right;
                },
                'v' => {
                    scanner_start.update(@intCast(x_idx), @intCast(y_idx));
                    direction = Direction.Down;
                }, 
                '<' => {
                    scanner_start.update(@intCast(x_idx), @intCast(y_idx));
                    direction = Direction.Left;
                }, 
                '^' => {
                    scanner_start.update(@intCast(x_idx), @intCast(y_idx));
                    direction = Direction.Up;
                }, 
                else => {}
            }
            copied_line[x_idx] = line[x_idx];
        }
        try grid.append(copied_line);
        y_idx += 1;
    }
    // NOTE: certain struct traits are hard-coded: Scanner.movement=Direction.Right, Scanner.mark='X'
    return Scanner.init(scanner_start, direction, Direction.Right, 'X', allocator, 5);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
