const std = @import("std");
const set = @import("ziglangSet");
const ArrayList = std.ArrayList;

const Ordering = struct {
    L: set.Set(u32),
    R: set.Set(u32),

    pub fn init(allocator: std.mem.Allocator) Ordering {
        const L = set.Set(u32).init(allocator); 
        const R = set.Set(u32).init(allocator);
        return Ordering {
            .L = L,
            .R = R,
        };
    }

    pub fn check_order(self: *Ordering, L: []u32, R: []u32) bool {
        for (L) |elem| {
            if (!self.L.contains(elem)) return false;
        }

        for (R) |elem| {
            if (!self.R.contains(elem)) return false;
        }

        return true;
    }

    pub fn add_left(self: *Ordering, i: u32) !void {
        _ = try self.L.add(i);
    }

    pub fn add_right(self: *Ordering, i: u32) !void {
        _ = try self.R.add(i);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const part1_answer = try part1("input.txt", allocator);
    std.debug.print("Part 1 Total: {d}\n", .{part1_answer});

    const part2_answer = try part2("input.txt", allocator);
    std.debug.print("Part 2 Total: {d}\n", .{part2_answer - part1_answer});
}

pub fn part2(path: []const u8, allocator: std.mem.Allocator) !u32{
    // Initialize data structures
    var my_hash_map = std.AutoHashMap(u32, *Ordering).init(allocator);
    defer my_hash_map.deinit();
    var list = ArrayList(*std.ArrayList(u32)).init(allocator);
    defer list.deinit();

    try parse(path, &my_hash_map, &list, allocator);
    
    var total: u32 = 0;
    for (list.items) |problem| {
        // Trick: do not need to evaluate the strict order of the whole list; up to the middle element
        for (0..(problem.items.len/2+1)) |i| { 
            // work L -> R, switching i (the current element) with switch_idx (where switch_idx>= i) and check order
            var switch_idx = i;
            permute: while (true) {
                if (switch_idx != i) {
                    const popped = problem.orderedRemove(i);
                    try problem.append(popped);
                } 
                switch_idx += 1;
                const ordering = my_hash_map.get(problem.items[i]).?;
                const pass = ordering.check_order(problem.items[0..i], problem.items[i+1..]);
                if (!pass) continue :permute else break :permute;
            }
        }
        total += problem.items[problem.items.len / 2];
    }

    return total;
}

pub fn part1(path: []const u8, allocator: std.mem.Allocator) !u32 {
    // Initialize data structures
    var my_hash_map = std.AutoHashMap(u32, *Ordering).init(allocator);
    defer my_hash_map.deinit();
    var list = ArrayList(*std.ArrayList(u32)).init(allocator);
    defer list.deinit();

    try parse(path, &my_hash_map, &list, allocator);
    
    var total: u32 = 0;
    check_problem: for (list.items) |problem| {
        const middle_elem = problem.items[problem.items.len / 2];
        // Trick: do not need to evaluate the strict order of the whole problem, just up to the middle element
        for (0..(problem.items.len/2+1)) |i| { 
            const ordering = my_hash_map.get(problem.items[i]).?;
            const pass = ordering.check_order(problem.items[0..i], problem.items[i+1..]);
            if (!pass) continue :check_problem;
        }
        total += middle_elem;
    }

    return total;
}

pub fn parse(
    path: []const u8, 
    orderings: *std.AutoHashMap(u32, *Ordering), 
    questions: *std.ArrayList(*std.ArrayList(u32)),
    allocator: std.mem.Allocator
) !void {
    // Open file and read contents
    var file = try std.fs.cwd().openFile(path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    defer file.close();

    // First parse lines
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Reached end of orderings
        if (std.mem.eql(u8, line, "")) {
            break;
        }
        // Get the ordering pair from file and convert to u32
        var it = std.mem.splitScalar(u8, line, '|');
        const L = try std.fmt.parseInt(u32, it.next().?, 10);
        const R = try std.fmt.parseInt(u32, it.next().?, 10);

        // Add to L
        if (orderings.get(L)) |v_ordering| {
            try v_ordering.add_right(R);
        } else {
            // NOTE: THIS FUCKED ME UP. Need to clarify the distinction between heap and stack. 
            // Reference(s): 
            // - https://www.reddit.com/r/Zig/comments/1cfed4z/question_on_nesting_hashmaps/
            // - https://pedropark99.github.io/zig-book/Chapters/01-memory.html#why-you-need-an-allocator
            //
            // Explanation: 
            // 1) upon looping and defining new_ordering as, Ordering.init(allocator), I never actually
            // created a new Ordering object. As such, the HashMap stored the same pointer to the
            // Ordering object, which meant that I was modifying the same underlying Ordering object.
            // My guess was because I created a varible locally, it would be on the stack. Therefore, 
            // through some compiler optimizations, the loop simply assigned the address of new_ordering
            // to be the same through all iterations of the loop
            // 2) Quoting Pedro Parks introduction to zig, I'm pretty sure the problem was because I
            // defined new_ordering locally. As such, my pointer to Ordering (from the definition of 
            // AutoHashMap<u32, *Ordering>) would be removed from the stack. If I want this pointer to
            // be persistent, I need to allocate space in memory (the heap) for the Ordering object
            var new_ordering = try allocator.create(Ordering);
            new_ordering.* = Ordering.init(allocator);
            try new_ordering.add_right(R);
            try orderings.put(L, new_ordering);
        }

        // Add R
        if (orderings.get(R)) |v_ordering| {
            try v_ordering.add_left(L);
        } else {
            var new_ordering = try allocator.create(Ordering);
            new_ordering.* = Ordering.init(allocator);
            try new_ordering.add_left(L);
            try orderings.put(R, new_ordering);
        }

    }

    // propagate the ArrayList of ArrayLists
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var list = try allocator.create(ArrayList(u32));
        list.* = ArrayList(u32).init(allocator);
        var it = std.mem.splitScalar(u8, line, ',');

        while (it.next()) |ch| {
            // TODO: double-check that this actually append elements in the right order
            const entry = try std.fmt.parseInt(u32, ch, 10);
            try list.append(entry);
        }
        try questions.append(list);
    }
}


// Tests
test "simple test" {
    var my_hash_map = std.AutoHashMap(u32, Ordering).init(std.testing.allocator);
    // use ArenaAllocator
    defer my_hash_map.deinit(); 
    if (my_hash_map.get(1)) |v_ordering| {
        try v_ordering.add_left(2);
    } else {
        var new_ordering = Ordering.init(std.testing.allocator);
        try new_ordering.add_left(2);
        try my_hash_map.put(1, &new_ordering);
    }
    
    const val = my_hash_map.get(1).?;
    try std.testing.expectEqual(@as(u32, 2), val.L.pop());
}
