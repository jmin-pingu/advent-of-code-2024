const std = @import("std");
const ArrayList = std.ArrayList;
const Region = @import("main.zig").Region;

const Bound = @import("nav.zig").Bound;
const Coordinate = @import("nav.zig").Coordinate;
const Box = @import("nav.zig").Box;
const Movement = @import("nav.zig").Movement;

pub const Garden = struct { 
    map: ArrayList([]const u8), 
    bitmap: []bool, 
    bound: Bound, 

    const movements = std.enums.values(Movement);

    pub fn new(map: ArrayList([]const u8), allocator: std.mem.Allocator) Garden {
        const bitmap = allocator.alloc(bool, @as(usize, @intCast(map.items.len)) * @as(usize, @intCast(map.items[0].len))) catch unreachable ;
        return Garden{ .map = map, .bitmap = bitmap, .bound = Bound{.x=@intCast(map.items[0].len) , .y=@intCast(map.items.len) } };
    }

    pub fn get(self: Garden, coordinate: Coordinate) u8 {
        // NOTE: would normally need a check to prevent out of index errors
        return self.map.items[coordinate.y][coordinate.x];
    }

    pub fn next_region(self: *Garden, allocator: std.mem.Allocator) ?*Region {
        var region = allocator.create(Region) catch unreachable;
        var seen = ArrayList(Coordinate).init(allocator);
        var borders = Box.new();

        // Fill out the region
        if (self.next()) |coordinate| {
            std.debug.print("{any}\n", .{coordinate});
            region.value = self.get(coordinate);
            self.search_region(coordinate, &seen, &borders, region);
        } else {
            return null;
        }

        // Fill out bitmask
        region.map = allocator.alloc([]bool, @as(usize, 1 + borders.max.y - borders.min.y)) catch unreachable;
        for (region.map, 0..) |_, i| {
            region.map[i] = allocator.alloc(bool, @as(usize, 1 + borders.max.x - borders.min.x)) catch unreachable;
        }
        for (seen.items) |coordinate| {
            region.map[coordinate.y - borders.min.y][coordinate.x - borders.min.x] = true;
        }
        
        // Calculate bounds
        region.bound = Bound.new(borders.max.x - borders.min.x, borders.max.y - borders.min.y);
        
        return region;
    }

    fn search_region(self: *Garden, coordinate: Coordinate, seen: *ArrayList(Coordinate), borders: *Box, region: *Region) void {
        // Mark explored 
        seen.append(coordinate) catch unreachable;
        borders.update(coordinate);
        self.mark(coordinate);
        
        // Greedily search
        for (movements) |movement| {
            if (self.bound.inbound(coordinate, movement)) {
                const move = movement.get_step();
                // if the offset coordinate value != coordinate value, we have hit a boundary
                const new_x: usize = @intCast(@as(i64, coordinate.x) + move.x);
                const new_y: usize = @intCast(@as(i64, coordinate.y) + move.y);
                if (self.map.items[new_y][new_x] == self.map.items[coordinate.y][coordinate.x]) {                   
                    // search unexplored region
                    const new_coordinate = Coordinate{.x=@intCast(new_x), .y=@intCast(new_y)};
                    if (!self.bitmap[self.coordToIndex(new_coordinate)]) self.search_region(new_coordinate, seen, borders, region);
                }
            }         
        }
    }

    // Get next unmarked Coordinate
    fn next(self: Garden) ?Coordinate {
        for (self.bitmap, 0..) |val, idx| {
            if (val == false) {
                return self.indexToCoord(idx);
            }
        }
        return null;
    }

    // Helper functions
    fn coordToIndex(self: Garden, coordinate: Coordinate) usize {
        return @intCast(coordinate.x + coordinate.y * self.bound.y);
    }

    fn indexToCoord(self: Garden, index: usize) Coordinate {
        return Coordinate{
            .x = @intCast(@mod(index, self.bound.y)), 
            .y = @intCast(index / self.bound.y)
        };
    }

    fn mark(self: *Garden, coordinate: Coordinate) void {
        self.bitmap[self.coordToIndex(coordinate)] = true;
    }
};

