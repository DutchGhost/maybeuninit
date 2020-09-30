/// A wrapper type to construct uninitialized instances of `T`.
pub inline fn MaybeUninit(comptime T: type) type {
    if (T == noreturn) {
        @compileError("Can't construct MaybeUninit(noreturn)." ++
            "It blows up your computer. See https://github.com/ziglang/zig/issues/3603");
    }

    return extern union {
        value: T,
        uninit: void,

        /// A hack to get around a compiler bug.
        /// see https://github.com/ziglang/zig/issues/3994
        const UNINIT = Self{ .uninit = {} };
        const Self = @This();

        /// Creates a new initialized `MaybeUninit(T)` initialized with the given value.
        pub inline fn init(value: T) Self {
            return .{ .value = value };
        }

        /// Creates a new `MaybeUninit(T)` in an uninitialized state.
        pub inline fn uninit() Self {
            return Self.UNINIT;
        }

        /// Creates a new `MaybeUninit(T)` in an uninitialized state,
        /// with the memory being filled with `byte`.
        /// It depends on `T` whether that already makes for proper
        /// initialization.
        pub fn withByte(byte: u8) Self {
            var u = Self.uninit();

            if (comptime @sizeOf(T) > 0) {
                var bytes = @ptrCast([*]u8, u.asMutPtr());
                @memset(bytes, byte, @sizeOf(T));
            }

            return u;
        }

        /// Creates a new `MaybeUnint(T)` in an uninitialized state,
        /// with the memory being filled with `0` bytes.
        /// It depends on `T` whether that already makes for proper
        /// initialization.
        pub inline fn zeroed() Self {
            return Self.withByte(0);
        }

        /// Gets a pointer to the contained value.
        pub inline fn asPtr(self: *const Self) *const T {
            return &self.value;
        }

        /// Gets a mutable pointer to the contained value
        pub inline fn asMutPtr(self: *Self) *T {
            return &self.value;
        }

        /// Extracts the value from the `MaybeUninit(T)` container.
        pub inline fn assumeInit(self: Self) T {
            return self.value;
        }

        /// Reads the value from the `MabeUninit(T)` container.
        /// Whenever possible, prefer to use [`MaybeUninit::assumeInit`] instead,
        /// which prevents duplicating the content of the `MaybeUninit(T)`.
        pub inline fn read(self: *const Self) T {
            return self.asPtr().*;
        }

        /// Sets the value of the `MaybeUninit(T)`.
        pub inline fn write(self: *Self, value: T) void {
            self.value = value;
        }

        /// Gets a pointer to the first element of the slice.
        pub inline fn firstPtr(this: []const Self) *const T {
            return @ptrCast(*const T, this.ptr);
        }

        /// Gets a mutable pointer to the first element of the slice.
        pub inline fn firstPtrMut(this: []Self) *T {
            return @ptrCast(*T, this.ptr);
        }
    };
}

const testing = if (@import("builtin").is_test)
    struct {
        fn expectEqual(x: anytype, y: anytype) void {
            @import("std").debug.assert(x == y);
        }
    }
else
    void;

test "with byte" {
    var maybe = MaybeUninit(u64).withByte(0xaa);

    var n = maybe.assumeInit();

    testing.expectEqual(n, 0xaaaaaaaaaaaaaaaa);
}

test "zero init" {
    var maybe = MaybeUninit(u8).zeroed();
    var maybe_void = MaybeUninit(void).zeroed();
    maybe_void.write({});
    var void_initted = maybe_void.assumeInit();
    testing.expectEqual(void_initted, {});
}

test "arbitrary test" {
    var maybe = MaybeUninit(u64).zeroed();

    testing.expectEqual(maybe.read(), 0);

    maybe.write(10);
    testing.expectEqual(maybe.read(), 10);
}

test "first ptr" {
    var maybe = [2]MaybeUninit(i64){ MaybeUninit(i64).init(10), MaybeUninit(i64).uninit() };

    var ptr = MaybeUninit(i64).firstPtr(&maybe);

    testing.expectEqual(ptr.*, 10);
}

test "assert size" {
    testing.expectEqual(@sizeOf(MaybeUninit(u64)), @sizeOf(u64));
    testing.expectEqual(@sizeOf(MaybeUninit(?*u64)), @sizeOf(*u64));
    testing.expectEqual(@sizeOf(?MaybeUninit(*u64)), @sizeOf(u8) * 16);
}

test "assert align" {
    testing.expectEqual(@alignOf(MaybeUninit(u64)), @alignOf(u64));
    testing.expectEqual(@alignOf(MaybeUninit(?*u64)), @alignOf(*u64));
    testing.expectEqual(@alignOf(?MaybeUninit(*u32)), @sizeOf(u8) * 8);
}

test "comptime init" {
    comptime {
        var maybe = MaybeUninit(i32).init(42);
        var ptr = maybe.asMutPtr();
        testing.expectEqual(ptr.*, 42);
    }
}

test "first ptr mut" {
    var maybe = [1]MaybeUninit(u64){MaybeUninit(u64).uninit()};
    var ptr = MaybeUninit(u64).firstPtrMut(&maybe);
    ptr.* = 10;
    testing.expectEqual(ptr.*, 10);
}
