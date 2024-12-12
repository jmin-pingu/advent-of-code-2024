const std = @import("std");
const ArrayList = std.ArrayList;
// import the namespace.
const set = @import("ziglangSet");
 
// NOTE: Bound is defined to have INCLUSIVE bounds, e.g. [lower, upper]
const Bound = struct {
    lower: i32,
    upper: i32,
    pub fn init(lower: i32, upper:i32) Bound {
        return Bound{
            .lower = lower,
            .upper = upper,
        };
    }

    pub fn in_bound(self: Bound, value: i32) bool {
        return value <= self.upper and value >= self.lower;
    }
};

const Grid = struct {
    layout: ArrayList([]u8),
    x_bound: Bound,
    y_bound: Bound,

    pub fn init(layout: ArrayList([]u8)) Grid {
        return Grid{
            .layout = layout,
            .x_bound = Bound.init(0, @intCast(layout.items[0].len-1)),
            .y_bound = Bound.init(0, @intCast(layout.items.len-1)),
        };
    }

    pub fn in_bound(self: Grid, coordinate: Coordinate) bool {
        return self.x_bound.in_bound(coordinate.x) and self.y_bound.in_bound(coordinate.y);
    }

    pub fn scan(self: Grid, found: *set.Set(Coordinate)) !void {
        for (0..self.layout.items.len) |y| {
            for (0..self.layout.items[0].len) |x| {
                if (self.layout.items[y][x] != '.') {
                    _ = try found.add(Coordinate.init(@intCast(x), @intCast(y), self.layout.items[y][x]));
                }
            }
        }
    }
};

const Coordinate = struct {
    x: i32, 
    y: i32, 
    mark: u8,

    pub fn init(x: i32, y: i32, mark: u8) Coordinate {
        return Coordinate{
            .x = x,
            .y = y,
            .mark = mark,
        };
    }

    pub fn eq(self: Coordinate, other: Coordinate) bool {
        return self.x == other.x and self.y == other.y and self.mark == other.mark;
    }
    
    pub fn eq_mark(self: Coordinate, other: Coordinate) bool {
        return self.mark == other.mark;
    }

    pub fn update_mark(self: *Coordinate, val: u8) void {
        self.mark = val;
    }

    pub fn add(self: Coordinate, other: Coordinate) !Coordinate {
        if (self.eq_mark(other)) return Coordinate.init(self.x + other.x, self.y + other.y, self.mark) else return Err.MarkError;
    }

    pub fn sub(self: Coordinate, other: Coordinate) !Coordinate {
        if (self.eq_mark(other)) return Coordinate.init(self.x - other.x, self.y - other.y, self.mark) else return Err.MarkError;
    }
};

const Err = error{
    MarkError
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    // try part1("test-input.txt", allocator);
    try part2("input.txt", allocator);
}

pub fn part2(path: []const u8, allocator: std.mem.Allocator) !void {
    var layout = ArrayList([]u8).init(allocator);
    defer layout.deinit();
    try parse(path, allocator, &layout);
    // Initialize struct and scanner
    const grid = Grid.init(layout);

    var antennas = set.Set(Coordinate).init(allocator);
    defer antennas.deinit();
    try grid.scan(&antennas);

    var antinodes = set.Set(Coordinate).init(allocator);
    defer antinodes.deinit();

    var iter = antennas.iterator();
    while (iter.next()) |curr| {
        var iter2 = antennas.iterator();
        while (iter2.next()) |other| {
            if (!curr.eq(other.*) and curr.eq_mark(other.*)) {
                const diff = try curr.sub(other.*);
                var antinode = try curr.add(diff);
                while (grid.in_bound(antinode)) {
                    antinode.update_mark('#');
                    _ = try antinodes.add(antinode);
                    antinode.update_mark(diff.mark);
                    antinode = try antinode.add(diff);
                }
                // Don't forget to add the antennas since they are in line
                var curr_copy = curr.*;
                var other_copy = other.*;
                other_copy.update_mark('#');
                curr_copy.update_mark('#');
                _ = try antinodes.add(other_copy);
                _ = try antinodes.add(curr_copy);
            }
        }
    }

    var it = antinodes.iterator();
    while (it.next()) |node| {
        std.debug.print("{}\n", .{node});
    }

    std.debug.print("Part 2 output: {d}\n", .{antinodes.cardinality()});
}


pub fn part1(path: []const u8, allocator: std.mem.Allocator) !void {
    var layout = ArrayList([]u8).init(allocator);
    defer layout.deinit();
    try parse(path, allocator, &layout);
    // Initialize struct and scanner
    const grid = Grid.init(layout);

    var antennas = set.Set(Coordinate).init(allocator);
    defer antennas.deinit();
    try grid.scan(&antennas);

    var antinodes = set.Set(Coordinate).init(allocator);
    defer antinodes.deinit();

    var iter = antennas.iterator();
    while (iter.next()) |curr| {
        var iter2 = antennas.iterator();
        while (iter2.next()) |other| {
            if (!curr.eq(other.*) and curr.eq_mark(other.*)) {
                var antinode = try curr.add(try curr.sub(other.*));
                if (grid.in_bound(antinode)) {
                    antinode.update_mark('#');
                    _ = try antinodes.add(antinode);
                }
            }
        }
    }
    std.debug.print("Part 1 output: {d}\n", .{antinodes.cardinality()});
}


pub fn parse(
    path: []const u8, 
    allocator: std.mem.Allocator,
    layout: *ArrayList([]u8)
) !void {
    // Open file and read contents
    var file = try std.fs.cwd().openFile(path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    defer file.close();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var new_line = try allocator.alloc(u8, line.len);
        for (line, 0..) |ch, i| {
            new_line[i] = ch;
        }
        // Need to copy the data in the parsed line BECAUSE all the 
        // array list now does is point to the last line
        try layout.append(new_line);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
