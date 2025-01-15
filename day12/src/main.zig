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

    // Metadata: can be calculated per region
    // area: u32, 
    // perimeter: u32,
    // sides: u32,

    pub fn new(garden: *Garden, allocator: std.mem.Allocator) ?*Region {
        return garden.next_region(allocator);
    }

    pub fn print(self: Region) void {
        for (self.map) |row| {
            for (row) |entry| {
            std.debug.print("{d} ", .{@intFromBool(entry)});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn next(self: Region) Coordinate {
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

    pub fn area(self: Region) u32 {
        var total: u32 = 0;
        for (self.map) |row| {
            for (0..row.len) |i| {
                if (row[i] == true) total +=1;
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

    // try part1("test-input.txt", allocator);
    try part2("test-input.txt", allocator);
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

    for (regions.items) |region| {
        std.debug.print("region: {c}, area {d}\n", .{region.value, region.area()});
        region.print();
    }

    // var total_price: u32 = 0;
    // total_price += region.area * region.sides;
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
        std.debug.print("region: {c}\n", .{region.value});
        region.print();
        total_price += region.area() * region.perimeter();
    }
    std.debug.print("part1 total: {d}\n", .{total_price});
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
