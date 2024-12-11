const std = @import("std");
const ArrayList = std.ArrayList;

const g = @import("grid.zig");
const Coordinate = g.Coordinate;
const Grid = g.Grid;

pub const Direction = enum{
    Up, 
    Down,
    Left, 
    Right,
};

pub const Scanner = struct {
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

