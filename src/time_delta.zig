const std = @import("std");
const root = @import("root");

// use core::time::Duration;

// use std::error::Error;

// use crate::{expect, try_opt};

// #[cfg(any(feature = "rkyv", feature = "rkyv-16", feature = "rkyv-32", feature = "rkyv-64"))]
// use rkyv::{Archive, Deserialize, Serialize};

/// The number of nanoseconds in a microsecond.
const NANOS_PER_MICRO: i32 = 1000;
/// The number of nanoseconds in a millisecond.
const NANOS_PER_MILLI: i32 = 1_000_000;
/// The number of nanoseconds in seconds.
const NANOS_PER_SEC: i32 = 1_000_000_000;
/// The number of microseconds per second.
const MICROS_PER_SEC: i64 = 1_000_000;
/// The number of milliseconds per second.
const MILLIS_PER_SEC: i64 = 1000;
/// The number of seconds in a minute.
const SECS_PER_MINUTE: i64 = 60;
/// The number of seconds in an hour.
const SECS_PER_HOUR: i64 = 3600;
/// The number of (non-leap) seconds in days.
const SECS_PER_DAY: i64 = 86_400;
/// The number of (non-leap) seconds in a week.
const SECS_PER_WEEK: i64 = 604_800;

// creating custion max i64_max const
const i64_max = std.math.maxInt(i64);

fn div_mod_floor_64(comptime T: type, this: T, other: T) struct { T, T } {
    const div_euclid = std.math.divFloor(T, this, other) catch unreachable;
    // const m = std.math.mul(T, div_euclid, other) catch unreachable;
    const rem_euclid = @mod(this, other);
    return .{ div_euclid, rem_euclid };
}

pub const TimeDeltaError = error{OutOfRangeError};

// Time duration with nanosecond precision.
//
// This also allows for negative durations; see individual methods for details.
//
// A `TimeDelta` is represented internally as a complement of seconds and
// nanoseconds. The range is restricted to that of `i64` milliseconds, with the
// minimum value notably being set to `-i64_max` rather than allowing the full
// range of `std.math.minInt(i64)`. This is to allow easy flipping of sign, so that for
pub const TimeDelta = struct {
    secs: i64,
    nanos: i32, // Always 0 <= nanos < NANOS_PER_SEC
    const Self = @This();

    pub fn new(secs: i64, nanos: i32) TimeDelta {
        if (secs < MIN.secs or secs > MAX.secs or nanos >= 1_000_000_000 or
            (secs == MAX.secs and nanos > MAX.nanos) or
            (secs == MIN.secs and nanos < MIN.nanos))
        {
            @panic("new TimeDelta should be in between MAX and MIN of TimeDelta");
        }
        return TimeDelta{
            .secs = secs,
            .nanos = nanos,
        };
    }

    pub fn equal(self: Self, rhs: Self) bool {
        if (self.nanos == rhs.nanos and self.secs == rhs.secs) {
            return true;
        }
        return false;
    }

    pub fn seconds(_seconds: i64) TimeDelta {
        return TimeDelta.new(_seconds, 0);
    }


    pub fn weeks(_weeks: i64) TimeDelta {
        return TimeDelta.new(_weeks * SECS_PER_WEEK, 0);
    }


    pub fn days(_days: i64) TimeDelta {
        return TimeDelta.new(_days * SECS_PER_DAY, 0);
    }


    pub fn hours(_hours: i64) TimeDelta {
       return TimeDelta.new(_hours * SECS_PER_HOUR, 0);
    }


    pub fn minutes(_minutes: i64) TimeDelta {
        return TimeDelta.new(_minutes * SECS_PER_MINUTE, 0);
    }


    pub fn milliseconds(_milliseconds: i64) TimeDelta {
        const secs, const millis = div_mod_floor_64(i64, _milliseconds, MILLIS_PER_SEC);
        return TimeDelta{ .secs = secs, .nanos = std.math.mul(i32, @intCast(millis), NANOS_PER_MILLI) catch @panic("try_millisecods unable to get mul") };
    
    }


    pub fn microseconds(_microseconds: i64) TimeDelta {
        const secs, const micros = div_mod_floor_64(@TypeOf(_microseconds), _microseconds, @intCast(MICROS_PER_SEC));
        const _nanos = std.math.mul(i32, @intCast(micros), NANOS_PER_MICRO) catch unreachable;
        return TimeDelta{ .secs = secs, .nanos = _nanos };
    }

    // Makes a new `TimeDelta` with the given number of nanoseconds.
    //
    // The number of nanoseconds acceptable by this constructor is less than
    // the total number that can actually be stored in a `TimeDelta`, so it is
    // not possible to specify a value that would be out of bounds. This
    // function is therefore infallible.
    pub fn nanoseconds(_nanos: i64) TimeDelta {
        const secs, const nanos = div_mod_floor_64(@TypeOf(_nanos), _nanos, NANOS_PER_SEC);
        return TimeDelta{
            .secs = secs, // i32 -> i64
            .nanos = @intCast(nanos), 
        };
    }

    /// Returns the total number of whole weeks in the `TimeDelta`.
    pub fn num_weeks(self: Self) i64 {
        return self.num_days() / 7;
    }

    /// Returns the total number of whole days in the `TimeDelta`.
    pub fn num_days(self: Self) i64 {
        return @divTrunc(self.num_seconds(), SECS_PER_DAY);
    }

    /// Returns the total number of whole hours in the `TimeDelta`.
    pub fn num_hours(self: Self) i64 {
        return @divTrunc(self.num_seconds(), SECS_PER_HOUR);
    }

    /// Returns the total number of whole minutes in the `TimeDelta`.
    pub fn num_minutes(self: Self) i64 {
        return @divTrunc(self.num_seconds(), SECS_PER_MINUTE);
    }

    /// Returns the total number of whole seconds in the `TimeDelta`.
    pub fn num_seconds(self: Self) i64 {
        // If secs is negative, nanos should be subtracted from the duration.
        if (self.secs < 0 and self.nanos > 0) {
            return self.secs + 1;
        }

        return self.secs;
    }

    /// Returns the fractional number of seconds in the `TimeDelta`.
    pub fn as_seconds_f64(self: Self) f64 {
        const _secs = std.math.cast(f64, self.secs).?;
        const _nanos = std.math.cast(f64, self.nanos).?;
        const _nano_per_sec = std.math.cast(f64, NANOS_PER_SEC).?;

        const value = _secs + @divTrunc(_nanos, _nano_per_sec);

        return value;
    }

    /// Returns the total number of whole milliseconds in the `TimeDelta`.
    pub fn num_milliseconds(self: Self) i64 {
        // A proper TimeDelta will not overflow, because MIN and MAX are defined such
        // that the range is within the bounds of an i64, from -i64_max through to
        // +i64_max inclusive. Notably, std.math.minInt(i64) is excluded from this range.
        const secs_part = self.num_seconds() * MILLIS_PER_SEC;
        const nanos_part = @divTrunc(self.subsec_nanos(), NANOS_PER_MILLI);
        return secs_part + nanos_part;
    }

    /// Returns the number of milliseconds in the fractional part of the duration.
    ///
    /// This is the number of milliseconds such that
    /// `subsec_millis() + num_seconds() * 1_000` is the truncated number of
    /// milliseconds in the duration.
    pub fn subsec_millis(self: Self) i32 {
        return @intCast(@divTrunc(self.subsec_nanos(), NANOS_PER_MILLI));
    }

    /// Returns the total number of whole microseconds in the `TimeDelta`,
    /// or `None` on overflow (exceeding 2^63 microseconds in either direction).
    pub fn num_microseconds(self: Self) i128 {
        const secs_part = std.math.mul(i128, self.num_seconds(), MICROS_PER_SEC) catch @panic("secs is too big");
        const nanos_part = @divTrunc(self.subsec_nanos(), NANOS_PER_MICRO);
        return  std.math.add(i128, secs_part, nanos_part) catch @panic("secs + nano is overflowed");
    }

    /// Returns the number of microseconds in the fractional part of the duration.
    ///
    /// This is the number of microseconds such that
    /// `subsec_micros() + num_seconds() * 1_000_000` is the truncated number of
    /// microseconds in the duration.
    pub fn subsec_micros(self: Self) i32 {
        return @intCast(@divTrunc(self.subsec_nanos(), NANOS_PER_MICRO));
    }

    // TODO: this function fails in test for overflow edge case fix it
    /// Returns the total number of whole nanoseconds in the `TimeDelta`,
    /// or `None` on overflow (exceeding 2^63 nanoseconds in either direction).
    pub fn num_nanoseconds(self: Self) i128 {
        const secs_part = std.math.mul(i128, self.num_seconds(), @intCast(NANOS_PER_SEC)) catch @panic("num_seconds * NANO_PER_SEC has overflowed");
        const nanos_part = self.subsec_nanos();
        return std.math.add(i128, secs_part, nanos_part) catch @panic("secs_part + nanos_part was overflowed");
    }

    /// Returns the number of nanoseconds in the fractional part of the duration.
    ///
    /// This is the number of nanoseconds such that
    /// `subsec_nanos() + num_seconds() * 1_000_000_000` is the total number of
    /// nanoseconds in the `TimeDelta`.
    pub fn subsec_nanos(self: Self) i32 {
        if (self.secs < 0 and self.nanos > 0) {
            return @as(i32, @intCast(self.nanos)) - @as(i32, @intCast(NANOS_PER_SEC));
        }
        return @intCast(self.nanos);
    }

    /// Add two `TimeDelta`s, returning `None` if overflow occurred.
    pub fn checked_add(self: Self, rhs: TimeDelta) ?TimeDelta {
        // No overflow checks here because we stay comfortably within the range of an `i64`.
        // Range checks happen in `TimeDelta.new`.
        var secs = self.secs + rhs.secs;
        var nanos = self.nanos + rhs.nanos;
        if (nanos >= NANOS_PER_SEC) {
            nanos -= NANOS_PER_SEC;
            secs += 1;
        }
        return TimeDelta.new(secs, nanos);
    }

    /// Subtract two `TimeDelta`s, returning `None` if overflow occurred.
    pub fn checked_sub(self: Self, rhs: TimeDelta) ?TimeDelta {
        // No overflow checks here because we stay comfortably within the range of an `i64`.
        // Range checks happen in `TimeDelta.new`.
        var secs = self.secs - rhs.secs;
        var nanos = self.nanos - rhs.nanos;
        if (nanos < 0) {
            nanos += NANOS_PER_SEC;
            secs -= 1;
        }
        return TimeDelta.new(secs, nanos);
    }

    /// Multiply a `TimeDelta` with a i32, returning `None` if overflow occurred.
    pub fn checked_mul(self: Self, rhs: i32) ?TimeDelta {
        // Multiply nanoseconds as i64, because it cannot overflow that way.
        const total_nanos = self.nanos * rhs;
        const extra_secs, const nanos = div_mod_floor_64(total_nanos, NANOS_PER_SEC);
        // Multiply seconds as i128 to prevent overflow
        const secs: i128 = self.secs * rhs + extra_secs;
        if (secs <= std.math.minInt(i64) or secs >= std.math.maxInt(i64)) {
            return null;
        }

        return TimeDelta{ .secs = secs, .nanos = nanos };
    }

    /// Divide a `TimeDelta` with a i32, returning `None` if dividing by 0.
    pub fn checked_div(self: Self, rhs: i32) ?TimeDelta {
        if (rhs == 0) {
            return null;
        }
        const secs = self.secs / rhs;
        const carry = self.secs % rhs;
        const extra_nanos = carry * NANOS_PER_SEC / rhs;
        const nanos = self.nanos / rhs + extra_nanos;

        const _secs, const _nanos = switch (nanos) {
            std.math.minInt(i32)...-1 => struct { (secs - 1), (nanos + NANOS_PER_SEC) },
            NANOS_PER_SEC...std.math.maxInt(i32) => struct { (secs + 1), (nanos - NANOS_PER_SEC) },
            else => struct { secs, nanos },
        };

        return TimeDelta{ .secs = _secs, .nanos = _nanos };
    }

    /// Returns the `TimeDelta` as an absolute (non-negative) value.
    pub fn abs(self: Self) TimeDelta {
        if (self.secs < 0 and self.nanos != 0) {
            return TimeDelta{
                .secs = @abs(self.secs + 1),
                .nanos = NANOS_PER_SEC - self.nanos,
            };
        }
        return TimeDelta{ .secs = @abs(self.secs), .nanos = self.nanos };
    }

    /// A `TimeDelta` where the stored seconds and nanoseconds are equal to zero.
    pub fn zero() TimeDelta {
        return TimeDelta{ .secs = 0, .nanos = 0 };
    }

    /// Returns `true` if the `TimeDelta` equals `TimeDelta.zero()`.
    pub fn is_zero(self: Self) bool {
        return (self.secs == 0 and self.nanos == 0);
    }

    pub fn add(self: Self, rhs: TimeDelta) Self {
        if (self.checked_add(rhs)) |v| {
            return v;
        }
        @panic("TimeDelta + TimeDelta overflowed");
    }

    pub fn sub(self: Self, rhs: Self) Self {
        if (self.checked_sub(rhs)) |v| {
            return v;
        }
        @panic("TimeDelta - TimeDelta overflowed");
    }

    pub fn mul(self: Self, rhs: i32) TimeDelta {
        if (self.checked_mul(rhs)) |v| {
            return v;
        }
        @panic("TimeDelta * i32 overflowed");
    }

    pub fn div(self: Self, rhs: i32) TimeDelta {
        if (self.checked_div(rhs)) |v| {
            return v;
        }
        @panic("i32 is zero");
    }
};

/// The minimum possible `TimeDelta`: `-i64_max` milliseconds.
pub const MIN = TimeDelta{
    .secs = (-i64_max / MILLIS_PER_SEC) - 1,
    .nanos = NANOS_PER_SEC + @rem(-i64_max, MILLIS_PER_SEC) * NANOS_PER_MILLI,
};

/// The maximum possible `TimeDelta`: `i64_max` milliseconds.
pub const MAX = TimeDelta {
    .secs = i64_max / MILLIS_PER_SEC,
    .nanos = (i64_max % MILLIS_PER_SEC) * NANOS_PER_MILLI,
};

const testing = std.testing;

test "test_duration" {
    const seconds = TimeDelta.seconds;
    const days = TimeDelta.days;

    try testing.expect(!seconds(1).equal(TimeDelta.zero()));
    try testing.expect(seconds(1).add(seconds(2)).equal(seconds(3)));

    try testing.expect(seconds(86_399).add(seconds(4)).equal(days(1).add(seconds(3))));
    try testing.expect(days(10).sub(seconds(1000)).equal(seconds(863_000)));
    try testing.expect(days(10).sub(seconds(1_000_000)).equal(seconds(-136_000)));
    try testing.expect(days(2).add(seconds(86_399)).add(TimeDelta.nanoseconds(1_234_567_890)).equal(days(3).add(TimeDelta.nanoseconds(234_567_890))));
    // try testing.expect(days(-3).equal(-days(3)));
    // try testing.expect(days(-4).add(seconds(86_400 - 70)).equal(seconds(70).sub(days(3))));

    var d = TimeDelta.new(0, 0);
    d = d.add(TimeDelta.minutes(1));
    d = d.sub(seconds(30));
    try testing.expect(d.equal(seconds(30)));
}

test "test_duration_num_days" {
    try testing.expectEqual(TimeDelta.zero().num_days(), 0);
    try testing.expectEqual(TimeDelta.days(1).num_days(), 1);
    try testing.expectEqual(TimeDelta.days(-1).num_days(), -1);
    // try testing.expectEqual(TimeDelta.seconds(86_399).?.num_days(), 0);
    try testing.expectEqual(TimeDelta.seconds(86_401).num_days(), 1);
    try testing.expectEqual(TimeDelta.seconds(-86_399).num_days(), 0);
    try testing.expectEqual(TimeDelta.seconds(-86_401).num_days(), -1);
    try testing.expectEqual(TimeDelta.days(std.math.maxInt(i32)).num_days(), std.math.maxInt(i32));
    try testing.expectEqual(TimeDelta.days(std.math.minInt(i32)).num_days(), std.math.minInt(i32));
}

test "test_duration_num_seconds" {
    try testing.expectEqual(TimeDelta.zero().num_seconds(), 0);
    try testing.expectEqual(TimeDelta.seconds(1).num_seconds(), 1);
    try testing.expectEqual(TimeDelta.seconds(-1).num_seconds(), -1);
    try testing.expectEqual(TimeDelta.milliseconds(999).num_seconds(), 0);
    try testing.expectEqual(TimeDelta.milliseconds(1001).num_seconds(), 1);
    try testing.expectEqual(TimeDelta.milliseconds(-999).num_seconds(), 0);
    try testing.expectEqual(TimeDelta.milliseconds(-1001).num_seconds(), -1);
}

test "test_duration_seconds_max_allowed" {
    const duration = TimeDelta.seconds(std.math.maxInt(i64) / 1_000);
    try testing.expectEqual(duration.num_seconds(), std.math.maxInt(i64) / 1_000);
    const d: i128 = @intCast(duration.secs);
    const e: i128 = @intCast(duration.nanos);
    const lhs: i128 = d * 1_000_000_000 + e;
    try testing.expectEqual(lhs, std.math.maxInt(i64) / 1_000 * 1_000_000_000);
}

// test "test_duration_seconds_max_overflow" {
//     _ = TimeDelta.seconds(std.math.maxInt(i64) / 1_000 + 1);
// }

// TODO: this test is for checking the underflow panic so it will panic when a error occurs
// test "test_duration_seconds_max_overflow_panic" {
//     _ = TimeDelta.seconds(std.math.maxInt(i64) / 1_000 + 1);
// }

test "test_duration_seconds_min_allowed" {
    const duration = TimeDelta.seconds(std.math.minInt(i64) / 1_000); // Same as -i64_max / 1_000 due to rounding
    try testing.expectEqual(duration.num_seconds(), std.math.minInt(i64) / 1_000); // Same as -i64_max / 1_000 due to rounding

    const d: i128 = @intCast(duration.secs);
    const e: i128 = @intCast(duration.nanos);
    const lhs: i128 = d * 1_000_000_000 + e;

    try testing.expectEqual(lhs, -std.math.maxInt(i64) / 1_000 * 1_000_000_000);
}

// test "test_duration_seconds_min_underflow" {
//     _ = TimeDelta.seconds(-std.math.maxInt(i64) / 1_000 - 1);
// }

// TODO: this test is for checking the underflow panic so it will panic when a error occurs
// test "test_duration_seconds_min_underflow_panic" {
//     _ = TimeDelta.seconds(-std.math.maxInt(i64) / 1_000 - 1);
// }

test "test_duration_as_seconds_f64" {
    // try testing.expectEqual(TimeDelta.seconds(1).as_seconds_f64(), 1.0);
    // try testing.expectEqual(TimeDelta.seconds(-1).as_seconds_f64(), -1.0);
    // try testing.expectEqual(TimeDelta.seconds(100).as_seconds_f64(), 100.0);
    // try testing.expectEqual(TimeDelta.seconds(-100).as_seconds_f64(), -100.0);
    // try testing.expectEqual(TimeDelta.milliseconds(500).as_seconds_f64(), 0.5);
    // try testing.expectEqual(TimeDelta.milliseconds(-500).as_seconds_f64(), -0.5);
    // try testing.expectEqual(TimeDelta.milliseconds(1_500).as_seconds_f64(), 1.5);
    // try testing.expectEqual(TimeDelta.milliseconds(-1_500).as_seconds_f64(), -1.5);
}

test "test_duration_subsec_nanos" {
    try testing.expectEqual(TimeDelta.zero().subsec_nanos(), 0);
    try testing.expectEqual(TimeDelta.nanoseconds(1).subsec_nanos(), 1);
    try testing.expectEqual(TimeDelta.nanoseconds(-1).subsec_nanos(), -1);
    try testing.expectEqual(TimeDelta.seconds(1).subsec_nanos(), 0);
    try testing.expectEqual(TimeDelta.nanoseconds(1_000_000_001).subsec_nanos(), 1);
}

test "test_duration_subsec_micros" {
    try testing.expectEqual(TimeDelta.zero().subsec_micros(), 0);
    try testing.expectEqual(TimeDelta.microseconds(1).subsec_micros(), 1);
    try testing.expectEqual(TimeDelta.microseconds(-1).subsec_micros(), -1);
    try testing.expectEqual(TimeDelta.seconds(1).subsec_micros(), 0);
    try testing.expectEqual(TimeDelta.microseconds(1_000_001).subsec_micros(), 1);
    try testing.expectEqual(TimeDelta.nanoseconds(1_000_001_999).subsec_micros(), 1);
}

test "test_duration_subsec_millis" {
    try testing.expectEqual(TimeDelta.zero().subsec_millis(), 0);
    try testing.expectEqual(TimeDelta.milliseconds(1).subsec_millis(), 1);
    try testing.expectEqual(TimeDelta.milliseconds(-1).subsec_millis(), -1);
    try testing.expectEqual(TimeDelta.seconds(1).subsec_millis(), 0);
    try testing.expectEqual(TimeDelta.milliseconds(1_001).subsec_millis(), 1);
    try testing.expectEqual(TimeDelta.microseconds(1_001_999).subsec_millis(), 1);
}

test "test_duration_num_milliseconds" {
    try testing.expectEqual(TimeDelta.zero().num_milliseconds(), 0);
    try testing.expectEqual(TimeDelta.milliseconds(1).num_milliseconds(), 1);
    try testing.expectEqual(TimeDelta.milliseconds(-1).num_milliseconds(), -1);
    try testing.expectEqual(TimeDelta.microseconds(999).num_milliseconds(), 0);
    try testing.expectEqual(TimeDelta.microseconds(1001).num_milliseconds(), 1);
    try testing.expectEqual(TimeDelta.microseconds(-999).num_milliseconds(), 0);
    try testing.expectEqual(TimeDelta.microseconds(-1001).num_milliseconds(), -1);
}

test "test_duration_milliseconds_max_allowed" {
    // The maximum number of milliseconds acceptable through the constructor is
    // equal to the number that can be stored in a TimeDelta.
    // TODO:
    // const duration = TimeDelta.milliseconds(std.math.maxInt(i32));
    // try testing.expectEqual(duration.num_milliseconds(), i64_max);
    // try testing.expectEqual(@as(i128, @intCast(duration.secs)) * 1_000_000_000 + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)) * 1_000_000);
}

// test "test_duration_milliseconds_max_overflow" {
//     // Here we ensure that trying to add one millisecond to the maximum storable
//     // value will fail.
//     try testing.expect(TimeDelta.milliseconds(std.math.maxInt(i32))
//         .checked_add(TimeDelta.milliseconds(1)) == null);
// }

test "test_duration_milliseconds_min_allowed" {
    // The minimum number of milliseconds acceptable through the constructor is
    // not equal to the number that can be stored in a TimeDelta - there is a
    // difference of one (std.math.minInt(i64) vs -i64_max).
    // TODO:
    // var duration = TimeDelta.milliseconds(-std.math.maxInt(i32));
    // try testing.expectEqual(duration.num_milliseconds(), -i64_max);
    // try testing.expectEqual(@as(i128, @intCast(duration.secs)) * 1_000_000_000 + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(-i64_max)) * 1_000_000);
}

// TODO:
// test "test_duration_milliseconds_min_underflow" {
//     // Here we ensure that trying to subtract one millisecond from the minimum
//     // storable value will fail.
    
//     try testing.expect(TimeDelta.milliseconds(-std.math.maxInt(i32))
//         .checked_sub(TimeDelta.milliseconds(1)) == null);
// }

// #[test]
// #[should_panic(expected = "TimeDelta.milliseconds out of bounds")]
// fn test_duration_milliseconds_min_underflow_panic() {
//     // Here we ensure that trying to create a value one millisecond below the
//     // minimum storable value will fail. This test is necessary because the
//     // storable range is -i64_max, but the constructor type of i64 will allow
//     // std.math.minInt(i64), which is one value below.
//     let _ = TimeDelta.milliseconds(std.math.minInt(i64)); // Same as -i64_max - 1
// }

test "test_duration_num_microseconds" {
    try testing.expectEqual(TimeDelta.zero().num_microseconds(), 0);
    try testing.expectEqual(TimeDelta.microseconds(1).num_microseconds(), 1);
    try testing.expectEqual(TimeDelta.microseconds(-1).num_microseconds(), -1);
    try testing.expectEqual(TimeDelta.nanoseconds(999).num_microseconds(), 0);
    try testing.expectEqual(TimeDelta.nanoseconds(1001).num_microseconds(), 1);
    try testing.expectEqual(TimeDelta.nanoseconds(-999).num_microseconds(), 0);
    try testing.expectEqual(TimeDelta.nanoseconds(-1001).num_microseconds(), -1);

    // overflow checks
    const MICROS_PER_DAY: i64 = 86_400_000_000;
    try testing.expectEqual( TimeDelta.days(i64_max / MICROS_PER_DAY).num_microseconds(), i64_max / MICROS_PER_DAY * MICROS_PER_DAY);
    try testing.expectEqual(TimeDelta.days(-i64_max / MICROS_PER_DAY).num_microseconds(), (-i64_max / MICROS_PER_DAY * MICROS_PER_DAY));

    _ =  TimeDelta.days(i64_max / MICROS_PER_DAY + 1).num_microseconds();
    _ =  TimeDelta.days(-i64_max / MICROS_PER_DAY - 1).num_microseconds();
}

// TODO
// test "test_duration_microseconds_max_allowed" {
//     // The number of microseconds acceptable through the constructor is far
//     // fewer than the number that can actually be stored in a TimeDelta, so this
//     // is not a particular insightful test.
//     var duration = TimeDelta.microseconds(std.math.maxInt(i32));
//     try testing.expectEqual(try duration.num_microseconds(), std.math.maxInt(i32));
//     try testing.expectEqual(@as(i128, @intCast(duration.secs)) * 1_000_000_000 + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)) * 1_000);
//     // Here we create a TimeDelta with the maximum possible number of
//     // microseconds by creating a TimeDelta with the maximum number of
//     // milliseconds and then checking that the number of microseconds matches
//     // the storage limit.
//     duration = TimeDelta.milliseconds(std.math.maxInt(i32));
//     _ = try duration.num_microseconds();
//     try testing.expectEqual(@as(i128, @intCast(duration.secs)) * 1_000_000_000 + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)) * 1_000_000);
// }

// TODO
// test "test_duration_microseconds_max_overflow" {
//     // This test establishes that a TimeDelta can store more microseconds than
//     // are representable through the return of duration.num_microseconds().
//     var duration = TimeDelta.microseconds(std.math.maxInt(i32)).add(TimeDelta.microseconds(1));
//     _ = try duration.num_microseconds();
    
//     // try testing.expectEqual(@as(i128, @intCast(duration.secs)) * 1_000_000_000 + @as(i128, @intCast(duration.nanos)), (@as(i128, @intCast(i64_max)) + 1) * 1_000);
//     // Here we ensure that trying to add one microsecond to the maximum storable
//     // value will fail.
//     try testing.expect(TimeDelta.milliseconds(std.math.maxInt(i32))
//         .checked_add(TimeDelta.microseconds(1)) == null);
// }

test "test_duration_microseconds_min_allowed" {
    // The number of microseconds acceptable through the constructor is far
    // fewer than the number that can actually be stored in a TimeDelta, so this
    // is not a particular insightful test.
    var duration = TimeDelta.microseconds(std.math.minInt(i64));
    try testing.expectEqual(duration.num_microseconds(), (std.math.minInt(i64)));
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(std.math.minInt(i64))) * 1_000);
    // Here we create a TimeDelta with the minimum possible number of
    // microseconds by creating a TimeDelta with the minimum number of
    // milliseconds and then checking that the number of microseconds matches
    // the storage limit.
    duration = TimeDelta.milliseconds(-std.math.maxInt(i64));
    _ =  duration.num_microseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), -@as(i128, @intCast(i64_max)) * 1_000_000);
}

test "test_duration_microseconds_min_underflow" {
    // This test establishes that a TimeDelta can store more microseconds than
    // are representable through the return of duration.num_microseconds().
    const duration = TimeDelta.microseconds(std.math.minInt(i64)).sub(TimeDelta.microseconds(1));
    _ =  duration.num_microseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), (@as(i128, @intCast(std.math.minInt(i64))) - 1) * 1_000);
}

test "test_duration_num_nanoseconds" {
    try testing.expectEqual( TimeDelta.zero().num_nanoseconds(), 0);
    try testing.expectEqual( TimeDelta.nanoseconds(1).num_nanoseconds(), 1);
    try testing.expectEqual( TimeDelta.nanoseconds(-1).num_nanoseconds(), -1);

    // overflow checks
    const NANOS_PER_DAY: i64 = 86_400_000_000_000;
    try testing.expectEqual(TimeDelta.days(i64_max / NANOS_PER_DAY).num_nanoseconds(), (i64_max / NANOS_PER_DAY * NANOS_PER_DAY));
    try testing.expectEqual(TimeDelta.days(-i64_max / NANOS_PER_DAY).num_nanoseconds(), (-i64_max / NANOS_PER_DAY * NANOS_PER_DAY));
    
}

test "test_duration_nanoseconds_max_allowed" {
    // The number of nanoseconds acceptable through the constructor is far fewer
    // than the number that can actually be stored in a TimeDelta, so this is not
    // a particular insightful test.
    var duration = TimeDelta.nanoseconds(std.math.maxInt(i64));
    try testing.expectEqual(duration.num_nanoseconds(), (i64_max));
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)));
    // Here we create a TimeDelta with the maximum possible number of nanoseconds
    // by creating a TimeDelta with the maximum number of milliseconds and then
    // checking that the number of nanoseconds matches the storage limit.
    duration = TimeDelta.milliseconds(std.math.maxInt(i64));
    _ =  duration.num_nanoseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)) * 1_000_000);
}

test "test_duration_nanoseconds_max_overflow" {
    // This test establishes that a TimeDelta can store more nanoseconds than are
    // representable through the return of duration.num_nanoseconds().
    const duration = TimeDelta.nanoseconds(std.math.maxInt(i64)).add(TimeDelta.nanoseconds(1));
    _ =  duration.num_nanoseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(i64_max)) + 1);
   
}

test "test_duration_nanoseconds_min_allowed" {
    // The number of nanoseconds acceptable through the constructor is far fewer
    // than the number that can actually be stored in a TimeDelta, so this is not
    // a particular insightful test.
    var duration = TimeDelta.nanoseconds(std.math.minInt(i64));
    try testing.expectEqual( duration.num_nanoseconds(), std.math.minInt(i64));
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(std.math.minInt(i64))));
    // Here we create a TimeDelta with the minimum possible number of nanoseconds
    // by creating a TimeDelta with the minimum number of milliseconds and then
    // checking that the number of nanoseconds matches the storage limit.
    duration = TimeDelta.milliseconds(-std.math.maxInt(i64));
    _ =  duration.num_nanoseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), -@as(i128, @intCast(i64_max)) * 1_000_000);
}

test "test_duration_nanoseconds_min_underflow" {
    // This test establishes that a TimeDelta can store more nanoseconds than are
    // representable through the return of duration.num_nanoseconds().
    const duration = TimeDelta.nanoseconds(std.math.minInt(i64)).sub(TimeDelta.nanoseconds(1));
    _ =  duration.num_nanoseconds();
    try testing.expectEqual(@as(i128, @intCast(duration.secs)) * NANOS_PER_SEC + @as(i128, @intCast(duration.nanos)), @as(i128, @intCast(std.math.minInt(i64))) - 1);
}

test "test_max" {
    try testing.expectEqual(@as(i128, @intCast(MAX.secs)) * NANOS_PER_SEC + @as(i128, @intCast(MAX.nanos)), @as(i128, @intCast(i64_max)) * 1_000_000);
    try testing.expectEqual(MAX, TimeDelta.milliseconds(std.math.maxInt(i64)));
    try testing.expectEqual(MAX.num_milliseconds(), i64_max);
    _ =  MAX.num_microseconds();
    _ =  MAX.num_nanoseconds();
}


test "test_min" {
    try testing.expectEqual(@as(i128, @intCast(MIN.secs)) * NANOS_PER_SEC + @as(i128, @intCast(MIN.nanos)), -@as(i128, @intCast(i64_max)) * 1_000_000);
    try testing.expectEqual(MIN, TimeDelta.milliseconds(-std.math.maxInt(i64)));
    try testing.expectEqual(MIN.num_milliseconds(), -std.math.maxInt(i64));
    _ =  MIN.num_microseconds();
    _ =  MIN.num_nanoseconds();
}

// #[test]
// fn test_duration_ord() {
//     const milliseconds = TimeDelta.milliseconds;

//     try testing.expect(milliseconds(1) < milliseconds(2));
//     try testing.expect(milliseconds(2) > milliseconds(1));
//     try testing.expect(milliseconds(-1) > milliseconds(-2));
//     try testing.expect(milliseconds(-2) < milliseconds(-1));
//     try testing.expect(milliseconds(-1) < milliseconds(1));
//     try testing.expect(milliseconds(1) > milliseconds(-1));
//     try testing.expect(milliseconds(0) < milliseconds(1));
//     try testing.expect(milliseconds(0) > milliseconds(-1));
//     try testing.expect(milliseconds(1_001) < milliseconds(1_002));
//     try testing.expect(milliseconds(-1_001) > milliseconds(-1_002));
//     try testing.expect(TimeDelta.nanoseconds(1_234_567_890) < TimeDelta.nanoseconds(1_234_567_891));
//     try testing.expect(TimeDelta.nanoseconds(-1_234_567_890) > TimeDelta.nanoseconds(-1_234_567_891));
//     try testing.expect(milliseconds(i64_max) > milliseconds(i64_max - 1));
//     try testing.expect(milliseconds(-i64_max) < milliseconds(-i64_max + 1));
// }

// #[test]
// fn test_duration_checked_ops() {
//     let milliseconds = |ms| TimeDelta.milliseconds(ms).?;
//     let seconds = |s| TimeDelta.seconds(s).?;

//     try testing.expectEqual(
//         milliseconds(i64_max).checked_add(&milliseconds(0)),
//         Some(milliseconds(i64_max))
//     );
//     try testing.expectEqual(
//         milliseconds(i64_max - 1).checked_add(TimeDelta.microseconds(999)),
//         Some(milliseconds(i64_max - 2) + TimeDelta.microseconds(1999))
//     );
//     try testing.expect(milliseconds(i64_max).checked_add(TimeDelta.microseconds(1000)).is_none());
//     try testing.expect(milliseconds(i64_max).checked_add(TimeDelta.nanoseconds(1)).is_none());

//     try testing.expectEqual(
//         milliseconds(-i64_max).checked_sub(&milliseconds(0)),
//         Some(milliseconds(-i64_max))
//     );
//     try testing.expectEqual(
//         milliseconds(-i64_max + 1).checked_sub(TimeDelta.microseconds(999)),
//         Some(milliseconds(-i64_max + 2) - TimeDelta.microseconds(1999))
//     );
//     try testing.expect(milliseconds(-i64_max).checked_sub(&milliseconds(1)).is_none());
//     try testing.expect(milliseconds(-i64_max).checked_sub(TimeDelta.nanoseconds(1)).is_none());

//     try testing.expect(seconds(i64_max / 1000).checked_mul(2000).is_none());
//     try testing.expect(seconds(std.math.minInt(i64) / 1000).checked_mul(2000).is_none());
//     try testing.expect(seconds(1).checked_div(0).is_none());
// }

// #[test]
// fn test_duration_abs() {
//     let milliseconds = |ms| TimeDelta.milliseconds(ms).?;

//     try testing.expectEqual(milliseconds(1300).abs(), milliseconds(1300));
//     try testing.expectEqual(milliseconds(1000).abs(), milliseconds(1000));
//     try testing.expectEqual(milliseconds(300).abs(), milliseconds(300));
//     try testing.expectEqual(milliseconds(0).abs(), milliseconds(0));
//     try testing.expectEqual(milliseconds(-300).abs(), milliseconds(300));
//     try testing.expectEqual(milliseconds(-700).abs(), milliseconds(700));
//     try testing.expectEqual(milliseconds(-1000).abs(), milliseconds(1000));
//     try testing.expectEqual(milliseconds(-1300).abs(), milliseconds(1300));
//     try testing.expectEqual(milliseconds(-1700).abs(), milliseconds(1700));
//     try testing.expectEqual(milliseconds(-i64_max).abs(), milliseconds(i64_max));
// }

// #[test]
// #[allow(clippy::erasing_op)]
// fn test_duration_mul() {
//     try testing.expectEqual(TimeDelta.zero() * i32::MAX, TimeDelta.zero());
//     try testing.expectEqual(TimeDelta.zero() * i32::MIN, TimeDelta.zero());
//     try testing.expectEqual(TimeDelta.nanoseconds(1) * 0, TimeDelta.zero());
//     try testing.expectEqual(TimeDelta.nanoseconds(1) * 1, TimeDelta.nanoseconds(1));
//     try testing.expectEqual(TimeDelta.nanoseconds(1) * 1_000_000_000, TimeDelta.seconds(1).?);
//     try testing.expectEqual(TimeDelta.nanoseconds(1) * -1_000_000_000, -TimeDelta.seconds(1).?);
//     try testing.expectEqual(-TimeDelta.nanoseconds(1) * 1_000_000_000, -TimeDelta.seconds(1).?);
//     try testing.expectEqual(
//         TimeDelta.nanoseconds(30) * 333_333_333,
//         TimeDelta.seconds(10).? - TimeDelta.nanoseconds(10)
//     );
//     try testing.expectEqual(
//         (TimeDelta.nanoseconds(1)
//             + TimeDelta.seconds(1).?
//             + TimeDelta.days(1).?)
//             * 3,
//         TimeDelta.nanoseconds(3)
//             + TimeDelta.seconds(3).?
//             + TimeDelta.days(3).?
//     );
//     try testing.expectEqual(
//         TimeDelta.milliseconds(1500).? * -2,
//         TimeDelta.seconds(-3).?
//     );
//     try testing.expectEqual(
//         TimeDelta.milliseconds(-1500).? * 2,
//         TimeDelta.seconds(-3).?
//     );
// }

// #[test]
// fn test_duration_div() {
//     try testing.expectEqual(TimeDelta.zero() / i32::MAX, TimeDelta.zero());
//     try testing.expectEqual(TimeDelta.zero() / i32::MIN, TimeDelta.zero());
//     try testing.expectEqual(TimeDelta.nanoseconds(123_456_789) / 1, TimeDelta.nanoseconds(123_456_789));
//     try testing.expectEqual(TimeDelta.nanoseconds(123_456_789) / -1, -TimeDelta.nanoseconds(123_456_789));
//     try testing.expectEqual(-TimeDelta.nanoseconds(123_456_789) / -1, TimeDelta.nanoseconds(123_456_789));
//     try testing.expectEqual(-TimeDelta.nanoseconds(123_456_789) / 1, -TimeDelta.nanoseconds(123_456_789));
//     try testing.expectEqual(TimeDelta.seconds(1).? / 3, TimeDelta.nanoseconds(333_333_333));
//     try testing.expectEqual(TimeDelta.seconds(4).? / 3, TimeDelta.nanoseconds(1_333_333_333));
//     try testing.expectEqual(
//         TimeDelta.seconds(-1).? / 2,
//         TimeDelta.milliseconds(-500).?
//     );
//     try testing.expectEqual(
//         TimeDelta.seconds(1).? / -2,
//         TimeDelta.milliseconds(-500).?
//     );
//     try testing.expectEqual(
//         TimeDelta.seconds(-1).? / -2,
//         TimeDelta.milliseconds(500).?
//     );
//     try testing.expectEqual(TimeDelta.seconds(-4).? / 3, TimeDelta.nanoseconds(-1_333_333_333));
//     try testing.expectEqual(TimeDelta.seconds(-4).? / -3, TimeDelta.nanoseconds(1_333_333_333));
// }

// #[test]
// fn test_duration_sum() {
//     let duration_list_1 = [TimeDelta.zero(), TimeDelta.seconds(1).?];
//     let sum_1: TimeDelta = duration_list_1.iter().sum();
//     try testing.expectEqual(sum_1, TimeDelta.seconds(1).?);

//     let duration_list_2 = [
//         TimeDelta.zero(),
//         TimeDelta.seconds(1).?,
//         TimeDelta.seconds(6).?,
//         TimeDelta.seconds(10).?,
//     ];
//     let sum_2: TimeDelta = duration_list_2.iter().sum();
//     try testing.expectEqual(sum_2, TimeDelta.seconds(17).?);

//     let duration_arr = [
//         TimeDelta.zero(),
//         TimeDelta.seconds(1).?,
//         TimeDelta.seconds(6).?,
//         TimeDelta.seconds(10).?,
//     ];
//     let sum_3: TimeDelta = duration_arr.into_iter().sum();
//     try testing.expectEqual(sum_3, TimeDelta.seconds(17).?);
// }

// #[test]
// fn test_duration_fmt() {
//     try testing.expectEqual(TimeDelta.zero().to_string(), "P0D");
//     try testing.expectEqual(TimeDelta.days(42).?.to_string(), "PT3628800S");
//     try testing.expectEqual(TimeDelta.days(-42).?.to_string(), "-PT3628800S");
//     try testing.expectEqual(TimeDelta.seconds(42).?.to_string(), "PT42S");
//     try testing.expectEqual(TimeDelta.milliseconds(42).?.to_string(), "PT0.042S");
//     try testing.expectEqual(TimeDelta.microseconds(42).to_string(), "PT0.000042S");
//     try testing.expectEqual(TimeDelta.nanoseconds(42).to_string(), "PT0.000000042S");
//     try testing.expectEqual(
//         (TimeDelta.days(7).? + TimeDelta.milliseconds(6543).?)
//             .to_string(),
//         "PT604806.543S"
//     );
//     try testing.expectEqual(TimeDelta.seconds(-86_401).?.to_string(), "-PT86401S");
//     try testing.expectEqual(TimeDelta.nanoseconds(-1).to_string(), "-PT0.000000001S");

//     // the format specifier should have no effect on `TimeDelta`
//     try testing.expectEqual(
//         format!(
//             "{:30}",
//             TimeDelta.days(1).? + TimeDelta.milliseconds(2345).?
//         ),
//         "PT86402.345S"
//     );
// }

// #[test]
// fn test_to_std() {
//     try testing.expectEqual(TimeDelta.seconds(1).?.to_std(), Ok(Duration::new(1, 0)));
//     try testing.expectEqual(TimeDelta.seconds(86_401).?.to_std(), Ok(Duration::new(86_401, 0)));
//     try testing.expectEqual(
//         TimeDelta.milliseconds(123).?.to_std(),
//         Ok(Duration::new(0, 123_000_000))
//     );
//     try testing.expectEqual(
//         TimeDelta.milliseconds(123_765).?.to_std(),
//         Ok(Duration::new(123, 765_000_000))
//     );
//     try testing.expectEqual(TimeDelta.nanoseconds(777).to_std(), Ok(Duration::new(0, 777)));
//     try testing.expectEqual(MAX.to_std(), Ok(Duration::new(9_223_372_036_854_775, 807_000_000)));
//     try testing.expectEqual(TimeDelta.seconds(-1).?.to_std(), Err(OutOfRangeError(())));
//     try testing.expectEqual(TimeDelta.milliseconds(-1).?.to_std(), Err(OutOfRangeError(())));
// }

// #[test]
// fn test_from_std() {
//     try testing.expectEqual(
//         Ok(TimeDelta.seconds(1).?),
//         TimeDelta.from_std(Duration::new(1, 0))
//     );
//     try testing.expectEqual(
//         Ok(TimeDelta.seconds(86_401).?),
//         TimeDelta.from_std(Duration::new(86_401, 0))
//     );
//     try testing.expectEqual(
//         Ok(TimeDelta.milliseconds(123).?),
//         TimeDelta.from_std(Duration::new(0, 123_000_000))
//     );
//     try testing.expectEqual(
//         Ok(TimeDelta.milliseconds(123_765).?),
//         TimeDelta.from_std(Duration::new(123, 765_000_000))
//     );
//     try testing.expectEqual(Ok(TimeDelta.nanoseconds(777)), TimeDelta.from_std(Duration::new(0, 777)));
//     try testing.expectEqual(Ok(MAX), TimeDelta.from_std(Duration::new(9_223_372_036_854_775, 807_000_000)));
//     try testing.expectEqual(
//         TimeDelta.from_std(Duration::new(9_223_372_036_854_776, 0)),
//         Err(OutOfRangeError(()))
//     );
//     try testing.expectEqual(
//         TimeDelta.from_std(Duration::new(9_223_372_036_854_775, 807_000_001)),
//         Err(OutOfRangeError(()))
//     );
// }

// #[test]
// fn test_duration_const() {
//     const ONE_WEEK: TimeDelta = expect(TimeDelta.try_weeks(1), "");
//     const ONE_DAY: TimeDelta = expect(TimeDelta.days(1), "");
//     const ONE_HOUR: TimeDelta = expect(TimeDelta.try_hours(1), "");
//     const ONE_MINUTE: TimeDelta = expect(TimeDelta.minutes(1), "");
//     const ONE_SECOND: TimeDelta = expect(TimeDelta.seconds(1), "");
//     const ONE_MILLI: TimeDelta = expect(TimeDelta.milliseconds(1), "");
//     const ONE_MICRO: TimeDelta = TimeDelta.microseconds(1);
//     const ONE_NANO: TimeDelta = TimeDelta.nanoseconds(1);
//     let combo: TimeDelta = ONE_WEEK
//         + ONE_DAY
//         + ONE_HOUR
//         + ONE_MINUTE
//         + ONE_SECOND
//         + ONE_MILLI
//         + ONE_MICRO
//         + ONE_NANO;

//     try testing.expect(ONE_WEEK != TimeDelta.zero());
//     try testing.expect(ONE_DAY != TimeDelta.zero());
//     try testing.expect(ONE_HOUR != TimeDelta.zero());
//     try testing.expect(ONE_MINUTE != TimeDelta.zero());
//     try testing.expect(ONE_SECOND != TimeDelta.zero());
//     try testing.expect(ONE_MILLI != TimeDelta.zero());
//     try testing.expect(ONE_MICRO != TimeDelta.zero());
//     try testing.expect(ONE_NANO != TimeDelta.zero());
//     try testing.expectEqual(
//         combo,
//         TimeDelta.seconds(86400 * 7 + 86400 + 3600 + 60 + 1).?
//             + TimeDelta.nanoseconds(1 + 1_000 + 1_000_000)
//     );
// }
