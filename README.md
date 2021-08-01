A very basic VecDeque implementation written in Zig.

Not production tested.  Just here for my amusement.

Works like this:

```
var d: Deque(i64).init(allocator);
defer d.deinit();

try d.pushFront(123);
try expectEqual(123, d.popBack());

try d.pushBack(123);
try expectEqual(123, d.popFront());
```

Built on a power-of-two-sized ring buffer internally.  Pushes are
amortized constant time; pops are constant time.
