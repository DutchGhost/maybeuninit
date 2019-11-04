/// A wrapper type to construct uninitialized instances of `T`.
pub inline fn MaybeUninit(comptime T: type) type {
    return extern union {
        value: T,
        uninit: void,

        const Self = @This();

        /// Creates a new initialized `MaybeUninit(T)` initialized with the given value.
        inline fn init(value: T) Self {
            return Self{ .value = value };
        }

        /// Creates a new `MaybeUninit(T)` in an uninitialized state.
        inline fn uninit() Self {
            return Self{ .uninit = {} };
        }

        /// Creates a new `MaybeUnint(T)` in an uninitialized state, with the memory being filled with `0` bytes.
        /// It depends on `T` whether that already makes for proper initialization.
        inline fn zeroed() Self {
            var u = Self.uninit();

            var bytes = @ptrCast([*]u8, u.as_mut_ptr());
            @memset(bytes, 0, @sizeOf(T));

            return u;
        }

        /// Gets a pointer to the contained value.
        inline fn as_ptr(self: *const Self) *const T {
            return &self.value;
        }

        /// Gets a mutable pointer to the contained value
        inline fn as_mut_ptr(self: *Self) *T {
            return &self.value;
        }

        /// Extracts the value from the `MaybeUninit(T)` container.
        inline fn assume_init(self: Self) T {
            return self.value;
        }

        /// Reads the value from the `MabeUninit(T)` container.
        /// Whenever possible, prefer to use [`MaybeUninit::assume_init`] instead, which prevents duplicating the content of the `MaybeUninit(T)`.
        inline fn read(self: *const Self) T {
            return self.as_ptr().*;
        }

        /// Sets the value of the `MaybeUninit(T)`.
        inline fn write(self: *Self, value: T) void {
            self.value = value;
        }

        /// Gets a pointer to the first element of the slice.
        inline fn first_ptr(this: []const Self) *const T {
            return @ptrCast(*const T, this.ptr);
        }

        /// Gets a mutable pointer to the first element of the slice.
        inline fn first_ptr_mut(this: []Self) *T {
            return @ptrCast(*T, this.ptr);
        }
    };
}

const testing = if (@import("builtin").is_test) struct {
    fn expectEqual(x: var, y: var) void {
        @import("std").debug.assert(x == y);
    }
} else void;

test "test usage" {
    var maybe = MaybeUninit(u64).zeroed();

    testing.expectEqual(maybe.read(), 0);

    maybe.write(10);
    testing.expectEqual(maybe.read(), 10);
}

test "first_ptr" {
    var maybe = [2]MaybeUninit(i64){ MaybeUninit(i64).init(10), MaybeUninit(i64).uninit() };

    var ptr = MaybeUninit(i64).first_ptr(&maybe);

    testing.expectEqual(ptr.*, 10);
}

test "assert size" {
    testing.expectEqual(@sizeOf(MaybeUninit(u64)), @sizeOf(u64));
    testing.expectEqual(@sizeOf(MaybeUninit(?*u64)), @sizeOf(*u64));
    testing.expectEqual(@sizeOf(?MaybeUninit(*u64)), usize(16));
}

test "assert align" {
    testing.expectEqual(@alignOf(MaybeUninit(u64)), @alignOf(u64));
    testing.expectEqual(@alignOf(MaybeUninit(?*u64)), @alignOf(*u64));
    testing.expectEqual(@alignOf(?MaybeUninit(*u32)), usize(8));
}

test "comptime init" {
    comptime {
        var maybe = MaybeUninit(i32).init(42);
        var ptr = maybe.as_mut_ptr();
        testing.expectEqual(ptr.*, 42);
    }
}

test "first_ptr_mut" {
    var maybe = [1] MaybeUninit(u64) {MaybeUninit(u64).uninit()};
    var ptr = MaybeUninit(u64).first_ptr_mut(&maybe);
    ptr.* = 10;
    testing.expectEqual(ptr.*, 10);
}