const std = @import("std");
const ArrayList = std.ArrayList;

const Direction = enum{
    Up, 
    Down,
    Left, 
    Right,
};

const GridError = error{
    OutOfBoundsErr
};

const Grid = struct {
    x_bound: i32,
    y_bound: i32,
    layout: ArrayList([]u8),
    obstacle: u8,
    modified_coordinates: ArrayList(Coordinate), 
    default_values: u8 = '.',
    
    pub fn init(layout: ArrayList([]u8), obstacle: u8, allocator: std.mem.Allocator) Grid {
        return Grid{
            .x_bound=@intCast(layout.items[0].len),
            .y_bound=@intCast(layout.items.len),
            .layout=layout,
            .obstacle=obstacle,
            .modified_coordinates = ArrayList(Coordinate).init(allocator)
        };  
    }

    pub fn in_bound(self: Grid, x: i32, y: i32) bool {
        return x < self.x_bound and y < self.y_bound and x >= 0 and y >= 0;
    }

    // Invariant: the input (x, y) must be inbound
    pub fn not_obstacle(self: Grid, x: i32, y: i32) GridError!bool {
        if (!self.in_bound(x, y))  {
            return GridError.OutOfBoundsErr;
        }
        return self.layout.items[@intCast(y)][@intCast(x)] != self.obstacle;
    }

    pub fn add_obstacle(self: *Grid, x: i32, y: i32) !bool {
        if (self.in_bound(x, y) and try self.not_obstacle(x, y)) {
            try self.modified_coordinates.append(Coordinate.init(x, y));
            self.layout.items[@intCast(y)][@intCast(x)] = self.obstacle;
            return true;
        } else {
            return false;
        }
    }

    pub fn reset(self: *Grid) !void {
        while (self.modified_coordinates.popOrNull()) |coord| {
            self.layout.items[@intCast(coord.y)][@intCast(coord.x)] = self.default_values;
        }
    }

    pub fn mark(self: *Grid, x: i32, y: i32, marker: u8) !bool {
        // Check in bound, not obstacle, and also not already marked
        if (self.in_bound(x, y) and try self.not_obstacle(x, y) and self.layout.items[@intCast(y)][@intCast(x)] != marker) {
            self.layout.items[@intCast(y)][@intCast(x)] = marker;
            return true;
        } else {
            return false;
        }
    }

    pub fn print(grid: Grid) void {
        for (grid.layout.items) |line| {
            std.debug.print("{c}\n", .{line});
        }
    }
};


const Scanner = struct {
    direction: Direction,
    coordinate: Coordinate, 
    start_direction: Direction,
    start_coordinate: Coordinate, 
    visited: i32 = 0,
    movement: Direction, 
    mark: u8,
    history: std.StringHashMap(Direction),
    step_count: u16 = 0,
    step_size: u16,

    pub fn init(
        coordinate: Coordinate, 
        direction: Direction, 
        movement: Direction, 
        mark: u8, 
        allocator: std.mem.Allocator, 
        step_size: u16
    ) Scanner {
        return Scanner {
            .coordinate = coordinate, 
            .direction = direction,
            .start_coordinate = coordinate, 
            .start_direction = direction,
            .movement = movement,
            .mark = mark,
            .step_size = step_size,
            .history = std.StringHashMap(Direction).init(allocator), // need to make sure that this does not lead to a memory leak
        };
    }

    pub fn reset(self: *Scanner, allocator: std.mem.Allocator) void {
        self.coordinate = self.start_coordinate;
        self.direction = self.start_direction;
        self.step_count = 0;
        self.history.deinit();
        self.history = std.StringHashMap(Direction).init(allocator);
    }

    pub fn is_looping(self: *Scanner, allocator: std.mem.Allocator) !bool {
        const key = try std.fmt.allocPrint(
            allocator,
            "{d}_{d}",
            .{ self.coordinate.x , self.coordinate.y },
        );

        if (self.history.get(key)) |direc| {
            if (direc == self.direction) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    pub fn update_direction(self: *Scanner) void {
        switch (self.movement) {
        .Right => {
            switch (self.direction) {
            .Up => {self.direction = Direction.Right;},
            .Down => {self.direction = Direction.Left;},
            .Left => {self.direction = Direction.Up;},
            .Right => {self.direction = Direction.Down;},
            }
        },
        .Left => {
            switch (self.direction) {
            .Up => {self.direction = Direction.Left;},
            .Down => {self.direction = Direction.Right;},
            .Left => {self.direction = Direction.Down;},
            .Right => {self.direction = Direction.Up;},
            }
        },
        else => {}
        }
    }

    pub fn move(self: *Scanner, grid: *Grid, mark_grid: bool, allocator: std.mem.Allocator) !bool {
        // First, mark the current position. 
        if (mark_grid and try grid.mark(self.coordinate.x, self.coordinate.y, self.mark)) self.visited += 1;

        var next_x: i32 = 0;
        var next_y: i32 = 0;
        switch (self.direction) {
            .Up => {
                next_x = self.coordinate.x;
                next_y = self.coordinate.y - 1;
            },
            .Down => {
                next_x = self.coordinate.x;
                next_y = self.coordinate.y + 1;
            }, 
            .Left => {
                next_x = self.coordinate.x - 1;
                next_y = self.coordinate.y;
            }, 
            .Right => {
                next_x = self.coordinate.x + 1;
                next_y = self.coordinate.y;
            }, 
        }
        if (!grid.in_bound(next_x, next_y)) return false;
        if (!try grid.not_obstacle(next_x, next_y)) {
            self.update_direction();
            return true;
        }
        
        // record history
        if (@rem(self.step_count, self.step_size) == 0) {
            const key = try std.fmt.allocPrint(
                allocator,
                "{d}_{d}",
                .{ self.coordinate.x, self.coordinate.y },
            );
            // save the coordinate 
            try self.history.put(key, self.direction);
            self.step_count = 0;
        }

        // Take a step only when you update coordinate
        self.step_count += 1;
        self.coordinate.update(next_x, next_y);
        return true;
    }
    
    pub fn num_visited (self: Scanner) i32 {
        return self.visited;
    }
};

const Coordinate = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Coordinate {
        return Coordinate {
            .x = x,
            .y = y
        };
    }

    pub fn update(self: *Coordinate, x: i32, y: i32) void {
        self.*.x = x;
        self.*.y = y;
    }
};

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
    _ = try part1("input.txt");
    // NOTE: The solution for part2 takes a good amount of time because in order to detect a loop, 
    // it needs to find the former value in the HashMap
    _ = try part2("input.txt");
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
