const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

// TODO: task is to define a data structure where we can find area + perimeter
// NOTE: the challenge is enclosed regions
// NOTE: we can scan AND THEN count or scan AND count
// Use a filter like below
//       X
//      XXX
//       X
// NOTE: need a greedy algorithm to find disjoint regions
// Maybe we can mark the map and use a greedy algorithm.
// Right as we finish marking a region via the greedy algorithm, we start from the next
// unmarked position
// The algorithm ends when every position is marked

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var region_map = AutoHashMap(u8, Region).init(
        allocator 
    );

    var map = ArrayList([]const u8).init(allocator);
    defer map.deinit();
    try parse("test-input.txt", allocator, &map);
    const garden = Garden.new(map);
    for (0..garden.bound.x) |x| {
        for (0..garden.bound.y) |y| {
            const total = garden.cross_peek(Coordinate{.x=@intCast(x), .y=@intCast(y)});
            const value = garden.get(Coordinate{.x=@intCast(x), .y=@intCast(y)});
            const gop = try region_map.getOrPut(value);
            if (gop.found_existing) {
            	gop.value_ptr.*.update(1, total);
            } else {
                gop.value_ptr.* = Region.new(1, total);
            }
        }
    }
    // var total_price: u32 = 0;
    var it = region_map.iterator();
    while (it.next()) |kv| {
        std.debug.print("{c}: area {d}, perimeter {d}\n", .{kv.key_ptr.*, kv.value_ptr.area, kv.value_ptr.perimeter});
    }
}

const Region = struct { 
    area: u32, 
    perimeter: u32,
    
    pub fn new(area: u32, perimeter: u32) Region {
        return Region{ .area = area, .perimeter= perimeter };
    }
    pub fn update(self: *Region, area: u32, perimeter: u32) void {
        self.area += area;
        self.perimeter += perimeter;
    }
};

const Movement = enum {
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

const Coordinate = struct {
    x: u32, 
    y: u32,
};

const Bound = struct {
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

const Garden = struct { 
    map: ArrayList([]const u8), 
    bound: Bound, 
    const movements = std.enums.values(Movement);
    pub fn new(map: ArrayList([]const u8)) Garden {
        return Garden{ .map = map, .bound = Bound{.x=@intCast(map.items[0].len) , .y=@intCast(map.items.len) } };
    }

    pub fn get(self: Garden, coordinate: Coordinate) u8 {
        // NOTE: would normally need a check to prevent out of index errors
        return self.map.items[coordinate.y][coordinate.x];
    }
    pub fn cross_peek(self: Garden, coordinate: Coordinate) u8 {
        var total: u8 = 0;
        for (movements) |movement| {
            if (self.bound.inbound(coordinate, movement)) {
                const move = movement.get_step();
                // if the offset coordinate value != coordinate value, we have hit a boundary
                if (self.map.items[@intCast(@as(i64, coordinate.y) + move.y)][@intCast(@as(i64, coordinate.x) + move.x)] != self.map.items[coordinate.y][coordinate.x]) total += 1;
            } else {
                total += 1;
            }
        }
        return total;
    }
};

pub fn parse(
    path: []const u8, 
    allocator: std.mem.Allocator,
    map: *ArrayList([]const u8)
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
            try map.append(new_val);
        }
    }
}


test "test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
