const std = @import("std");

pub const Bound = struct {
    x: u32, 
    y: u32,
    
    pub fn new(x: u32, y: u32) Bound {
        return Bound{ .x = x, .y = y };
    }

    pub fn inbound(self: Bound, coordinate: Coordinate, movement: Movement) bool {
        switch (movement) {
            .Up => {
                if (self.y <= coordinate.y + 1) return false;
            },
            .Down => {
                if (coordinate.y == 0) return false;
            },
            .Left => {
                if (coordinate.x == 0) return false;
            },
            .Right => {
                if (self.x <= coordinate.x + 1) return false;
            },
        }
        return true;
    }
};

pub const Movement = enum {
    Up,
    Down, 
    Left, 
    Right,

    pub fn get_step(movement: Movement) struct {x: i8, y: i8} {
        switch (movement) {
            .Up => {
                return .{ .x=0 , .y=1 };
            },
            .Down => {
                return .{ .x=0 , .y=-1 };
            },
            .Left => {
                return .{ .x=-1, .y=0 };
            },
            .Right => {
                return .{ .x=1 , .y=0 };
            },
        }
    }
};


pub const Box = struct {
    min: Coordinate, 
    max: Coordinate, 

    pub fn new() Box {
        // NOTE: could impose additional checks to ensure that min/max are valid boxes
        // e.g. min.x <= max.x and min.y <= max.y
        return Box {
            .min = Coordinate.new(1000, 1000), 
            .max = Coordinate.new(0, 0), 
        };
    }
    
    pub fn update(self: *Box, coordinate: Coordinate) void {
        if (coordinate.x > self.max.x) self.max.x = coordinate.x;
        if (coordinate.y > self.max.y) self.max.y = coordinate.y;
        if (coordinate.x < self.min.x) self.min.x = coordinate.x;
        if (coordinate.y < self.min.y) self.min.y = coordinate.y;
    }
};

pub const Coordinate = struct {
    x: u32, 
    y: u32,

    pub fn new(x: u32, y: u32) Coordinate {
        return Coordinate{.x = x, .y = y};
    }
};

