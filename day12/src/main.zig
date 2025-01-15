const std = @import("std");
const Garden = @import("garden.zig").Garden;
const Bound = @import("nav.zig").Bound;
const Coordinate = @import("nav.zig").Coordinate;
const Box = @import("nav.zig").Box;
const Movement = @import("nav.zig").Movement;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

pub const Region = struct { 
    map: [][]bool,
    value: u8, 
    bound: Bound,

    const Mask = struct {
        depth: u8,
        mask: []bool,
    
        pub fn new(region: Region, allocator: std.mem.Allocator) Mask {
            return Mask {
                .depth = 0,
                .mask = allocator.alloc(bool, region.map[0].len) catch unreachable
            };
        }
    
        pub fn next(self: *Mask, region: Region) bool {
            if (self.depth == 0) {
                std.mem.copyForwards(bool, self.mask, region.map[@intCast(self.depth)]); 
            } else if (self.depth == region.bound.y + 1) {
                return false;
            } else {
                for (region.map[@as(usize, @intCast(self.depth - 1))], region.map[@as(usize, @intCast(self.depth - 1)) + 1], 0..) |l, r, idx| {
                    if (l == false and r == true) {
                        self.mask[idx] = true;
                    } else {
                        self.mask[idx] = false;
                    }
                }
            }
            self.depth += 1;
            return true;
        }
    
        pub fn countSegments(self: Mask) u32 {
            var total: u32 = 0;
            var former = false;
            for (self.mask) |value| {
                if (value and !former) total += 1;
                former = value;
            }
            return total;
        }

        pub fn count(self: Mask) u32 {
            var total: u32 = 0;
            for (self.mask) |value| {
                if (value) total += 1;
            }
            return total;
        }

        pub fn print(self: Mask) void {
            for (self.mask) |val| {
                std.debug.print("{d} ", .{@intFromBool(val)});
            }
            std.debug.print("\n", .{});
        }
    };

    pub fn new(garden: *Garden, allocator: std.mem.Allocator) ?*Region {
        return garden.next_region(allocator);
    }

    pub fn print(self: Region) void {
        for (self.map) |row| {
            for (row) |val| {
            std.debug.print("{d} ", .{@intFromBool(val)});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn rotate(self: *Region, allocator: std.mem.Allocator) !void {
        const tmp: [][]bool = try allocator.alloc([]bool, self.map[0].len);
        for (tmp) |*row| {
            row.* = try allocator.alloc(bool, self.map.len);
        }
        for (0..self.map.len) |j| {
            for (0..self.map[0].len) |i| {
                tmp[i][self.map.len - 1 - j] = self.map[j][i];
            }
        }
        const tmp_x = self.bound.x;
        self.bound.x = self.bound.y;
        self.bound.y = tmp_x;

        self.map = tmp;
    }

    pub fn area(self: Region) u32 {
        var total: u32 = 0;
        for (self.map) |row| {
            for (0..row.len) |i| {
                if (row[i] == true) total +=1;
            }
        }
        return total;
    }
 
    pub fn sides(self: *Region, allocator: std.mem.Allocator) u32 {
        var total: u32 = 0;
        for (0..4) |_| {
            self.rotate(allocator) catch unreachable;
            var mask = Mask.new(self.*, allocator);
            while (mask.next(self.*)) {
                total += mask.countSegments();
            }
        }
        return total;
    }

    pub fn perimeter(self: *Region, allocator: std.mem.Allocator) u32 {
        var total: u32 = 0;
        for (0..4) |_| {
            self.rotate(allocator) catch unreachable;
            var mask = Mask.new(self.*, allocator);
            while (mask.next(self.*)) {
                total += mask.count();
            }
        }
        return total;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    try part1("input.txt", allocator);
    try part2("input.txt", allocator);
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !void {
    var map = ArrayList([]const u8).init(allocator);
    defer map.deinit();

    try parse(input, allocator, &map);

    var garden = Garden.new(map, allocator);
    var regions = ArrayList(*Region).init(allocator);

    while (Region.new(&garden, allocator)) |region| {
        try regions.append(region);
    }

    var total_price: u32 = 0;
    for (regions.items) |region| {
        total_price += region.sides(allocator) * region.area();
    }
    std.debug.print("part 2 total {d}\n", .{total_price});
}


pub fn part1(input: []const u8, allocator: std.mem.Allocator) !void {
    var map = ArrayList([]const u8).init(allocator);
    defer map.deinit();

    try parse(input, allocator, &map);

    var garden = Garden.new(map, allocator);
    var regions = ArrayList(*Region).init(allocator);

    while (Region.new(&garden, allocator)) |region| {
        try regions.append(region);
    }

    var total_price: u32 = 0;
    for (regions.items) |region| {
        total_price += region.perimeter(allocator) * region.area();
    }
    std.debug.print("part 1 total {d}\n", .{total_price});
}

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
