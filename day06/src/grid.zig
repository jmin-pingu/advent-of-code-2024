const std = @import("std");
const ArrayList = std.ArrayList;
const GridError = error{
    OutOfBoundsErr
};

pub const Coordinate = struct {
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


pub const Grid = struct {
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
