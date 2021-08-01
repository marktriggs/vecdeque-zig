const std = @import("std");
const deque = @import("./vecdeque.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var d = try deque.Deque(i64).init(allocator);
    defer d.deinit();

    try d.pushFront(123);
    std.debug.print("Popped: {}\n", .{ d.popBack() });

    try d.pushBack(123);
    std.debug.print("Popped: {}\n", .{ d.popBack() });
}
