const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

pub const DequeError = error{
    Empty,
};

pub fn Deque(comptime T: type) type {
    return struct {
        const Self = @This();

        elements: []T,

        head: i64,
        tail: i64,

        allocator: *std.mem.Allocator,

        pub fn init(allocator: *std.mem.Allocator) !Self {
            var elements = try allocator.alloc(T, 4);

            return Self{
                .elements = elements,
                .allocator = allocator,

                .head = 0,
                .tail = @intCast(i64, elements.len - 1),
            };
        }

        pub fn pushFront(self: *Self, elt: T) !void {
            self.elements[@intCast(usize, self.head)] = elt;
            self.head = self.inc(self.head);
            try self.maybeGrow();
        }

        pub fn popFront(self: *Self) !T {
            if (self.isEmpty()) {
                return DequeError.Empty;
            }

            self.head = self.dec(self.head);
            return self.elements[@intCast(usize, self.head)];
        }

        pub fn pushBack(self: *Self, elt: T) !void {
            self.elements[@intCast(usize, self.tail)] = elt;
            self.tail = self.dec(self.tail);
            try self.maybeGrow();
        }

        pub fn popBack(self: *Self) !T {
            if (self.isEmpty()) {
                return DequeError.Empty;
            }

            self.tail = self.inc(self.tail);
            return self.elements[@intCast(usize, self.tail)];
        }

        pub fn isEmpty(self: *Self) bool {
            return self.inc(self.tail) == self.head;
        }

        // It only makes sense to call this if we know our Deque isn't empty.
        // I.e. after a push of some kind.
        fn maybeGrow(self: *Self) !void {
            if (self.inc(self.tail) == self.head) {
                // We've just wrapped.
                var new_elements = try self.allocator.alloc(T, self.elements.len * 2);

                var idx = self.head;
                var new_idx: usize = 0;
                while (true) {
                    new_elements[new_idx] = self.elements[@intCast(usize, idx)];
                    idx = (idx + 1) & ~@intCast(i64, self.elements.len);
                    new_idx += 1;

                    if (idx == self.head) {
                        break;
                    }
                }

                var old_elements = self.elements;
                self.elements = new_elements;
                self.head = @intCast(i64, old_elements.len);
                self.tail = @intCast(i64, new_elements.len - 1);

                self.allocator.free(old_elements);
            }
        }

        fn inc(self: *Self, n: i64) i64 {
            return (n + 1) & ~@intCast(i64, self.elements.len);
        }

        fn dec(self: *Self, n: i64) i64 {
            return ((n - 1) + @intCast(i64, self.elements.len)) & ~@intCast(i64, self.elements.len);
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.elements);
        }
    };
}

test "deque basic" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var d: Deque(i64) = try Deque(i64).init(allocator);

    try d.pushFront(123);

    try expectEqual(@as(i64, 123), try d.popFront());
    try d.pushBack(456);
    try expectEqual(@as(i64, 456), try d.popBack());

    try expect(d.isEmpty());

    try d.pushFront(123);
    try expectEqual(@as(i64, 123), try d.popBack());

    try expect(d.isEmpty());

    try d.pushBack(123);
    try expectEqual(@as(i64, 123), try d.popFront());

    try expect(d.isEmpty());

    // Stack
    try d.pushFront(1);
    try d.pushFront(2);
    try d.pushFront(3);
    try d.pushFront(4);
    try d.pushFront(5);
    try expectEqual(@as(i64, 5), try d.popFront());
    try expectEqual(@as(i64, 4), try d.popFront());
    try expectEqual(@as(i64, 3), try d.popFront());
    try expectEqual(@as(i64, 2), try d.popFront());
    try expectEqual(@as(i64, 1), try d.popFront());

    try expect(d.isEmpty());

    // Queue
    try d.pushFront(1);
    try d.pushFront(2);
    try d.pushFront(3);

    try expectEqual(@as(i64, 1), try d.popBack());
    try expectEqual(@as(i64, 2), try d.popBack());
    try expectEqual(@as(i64, 3), try d.popBack());

    try expect(d.isEmpty());

    var i: i64 = 0;
    while (i < 10000) {
        try d.pushFront(i);
        i += 1;
    }

    i = 9999;
    while (i >= 0) {
        try expectEqual(i, try d.popFront());
        i -= 1;
    }

    try expect(d.isEmpty());

    try expectError(DequeError.Empty, d.popFront());

    d.deinit();
}

test "deque random" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var d: Deque(f64) = try Deque(f64).init(allocator);

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = &prng.random;

    {
        var round: usize = 0;
        while (round < 50_000) {
            round += 1;

            const len = rand.int(usize) % 1000;

            var numbers = try std.ArrayList(f64).initCapacity(allocator, len);
            {
                var i: usize = 0;
                while (i < len) {
                    try numbers.append(rand.float(f64));
                    i += 1;
                }
            }

            for (numbers.items) |elt| {
                try d.pushFront(elt);
            }
            for (numbers.items) |elt| {
                try expectEqual(elt, try d.popBack());
            }

            for (numbers.items) |elt| {
                try d.pushBack(elt);
            }
            for (numbers.items) |elt| {
                try expectEqual(elt, try d.popFront());
            }

            try expect(d.isEmpty());
        }
    }

    d.deinit();
}
