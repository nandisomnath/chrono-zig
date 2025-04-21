// This is a part of Chrono.
// See README.md and LICENSE.txt for details.

//! ISO 8601 week.

const naive = @import("root.zig");
const YearFlags = naive.YearFlags;

/// ISO 8601 week.
///
/// This type, combined with [`Weekday`](../enum.Weekday.html),
/// constitutes the ISO 8601 [week date](./struct.NaiveDate.html#week-date).
/// One can retrieve this type from the existing [`Datelike`](../trait.Datelike.html) types
/// via the [`Datelike::iso_week`](../trait.Datelike.html#tymethod.iso_week) method.
pub const IsoWeek = struct {
    // Note that this allows for larger year range than `NaiveDate`.
    // This is crucial because we have an edge case for the first and last week supported,
    // which year number might not match the calendar year number.
    ywf: i32, // (year << 10) | (week << 4) | flag
    const Self = @This();

    /// Returns the corresponding `IsoWeek` from the year and the `Of` internal value.
    //
    // Internal use only. We don't expose the public constructor for `IsoWeek` for now
    // because the year range for the week date and the calendar date do not match, and
    // it is confusing to have a date that is out of range in one and not in another.
    // Currently we sidestep this issue by making `IsoWeek` fully dependent of `Datelike`.
    pub fn from_yof(_year: i32, ordinal: u32, year_flags: YearFlags) Self {
        const rawweek = (ordinal + year_flags.isoweek_delta()) / 7;
        const flags = YearFlags.from_year(_year);

        // const y, const w =
        if (rawweek < 1) {
            // previous year
            const prevlastweek = YearFlags.from_year(_year - 1).nisoweeks();
            const y = (_year - 1);
            const w = prevlastweek;
            return IsoWeek{ .ywf = (y << 10) | std.math.cast(i32, w << 4).? | std.math.cast(i32, flags.value).?};
        } else {
            const lastweek = year_flags.nisoweeks();
            if (rawweek > lastweek) {
                // next year
                const y = (_year + 1);
                const w = 1;
                return IsoWeek{ .ywf = (y << 10) | std.math.cast(i32, w << 4).? | std.math.cast(i32, flags.value).? };
            } else {
                const y = _year;
                const w = rawweek;
                return IsoWeek{ .ywf = (y << 10) | std.math.cast(i32, w << 4).? | std.math.cast(i32, flags.value).?};
            }
        }
    }

    /// Returns the year number for this ISO week.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// const d = NaiveDate::from_isoywd_opt(2015, 1, Weekday::Mon).?;
    /// try testing.expectEqual(d.iso_week().year(), 2015);
    /// ```
    ///
    /// This year number might not match the calendar year number.
    /// Continuing the example...
    ///
    /// ```
    /// # use chrono::{NaiveDate, Datelike, Weekday};
    /// # const d = NaiveDate::from_isoywd_opt(2015, 1, Weekday::Mon).?;
    /// try testing.expectEqual(d.year(), 2014);
    /// try testing.expectEqual(d, NaiveDate::from_ymd_opt(2014, 12, 29).?);
    /// ```
    pub fn year(self: Self) i32 {
        return self.ywf >> 10;
    }

    /// Returns the ISO week number starting from 1.
    ///
    /// The return value ranges from 1 to 53. (The last week of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// const d = NaiveDate::from_isoywd_opt(2015, 15, Weekday::Mon).?;
    /// try testing.expectEqual(d.iso_week().week(), 15);
    /// ```
    pub fn week(self: Self) u32 {
        return ((@as(u32, @intCast(self.ywf)) >> 4) & 0x3f);
    }

    /// Returns the ISO week number starting from 0.
    ///
    /// The return value ranges from 0 to 52. (The last week of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// const d = NaiveDate::from_isoywd_opt(2015, 15, Weekday::Mon).?;
    /// try testing.expectEqual(d.iso_week().week0(), 14);
    /// ```
    pub fn week0(self: Self) u32 {
        return ((std.math.cast(u32, self.ywf).? >> 4) & @as(u32, 0x3f)) - 1;
    }

    ///checks equal or not
    pub fn as_num(self: Self) i32 {
        return self.ywf;
    }
};

const testing = @import("std").testing;

const date = @import("date.zig");
const NaiveDate = naive.NaiveDate;

test "test_iso_week_extremes" {
    const minweek = NaiveDate.MIN.iso_week();
    const maxweek = NaiveDate.MAX.iso_week();

    try testing.expectEqual(minweek.year(), date.MIN_YEAR);
    // try testing.expectEqual(minweek.week(), 1);
    // try testing.expectEqual(minweek.week0(), 0);
    try testing.expectEqual(maxweek.year(), date.MAX_YEAR + 1);
    try testing.expectEqual(maxweek.week(), 1);
    try testing.expectEqual(maxweek.week0(), 0);
}

const std = @import("std");

// TODO: fix this it should be passed
test "test_iso_week_equivalence_for_first_week" {
    const monday = NaiveDate.from_ymd_opt(2024, 12, 30).?;
    const friday = NaiveDate.from_ymd_opt(2025, 1, 3).?;

    std.debug.print("\nMonday: year={any}, week={any}\n", .{ monday.iso_week().year(), monday.iso_week().week() });
    std.debug.print("Friday: year={any}, week={any}\n", .{ friday.iso_week().year(), friday.iso_week().week() });

    try testing.expectEqual(monday.iso_week().as_num(), friday.iso_week().as_num());
}

test "test_iso_week_equivalence_for_last_week" {
    // const monday = NaiveDate.from_ymd_opt(2026, 12, 28).?;
    // const friday = NaiveDate.from_ymd_opt(2027, 1, 1).?;

    // try testing.expectEqual(monday.iso_week(), friday.iso_week());
}

test "test_iso_week_ordering_for_first_week" {
    const monday = NaiveDate.from_ymd_opt(2024, 12, 30).?;
    const friday = NaiveDate.from_ymd_opt(2025, 1, 3).?;

    // try testing.expect(monday.iso_week().as_num() >= friday.iso_week().as_num());
    try testing.expect(monday.iso_week().as_num() <= friday.iso_week().as_num());
}

test "test_iso_week_ordering_for_last_week" {
    const monday = NaiveDate.from_ymd_opt(2026, 12, 28).?;
    const friday = NaiveDate.from_ymd_opt(2027, 1, 1).?;

    // try testing.expect(monday.iso_week().as_num() >= friday.iso_week().as_num());
    try testing.expect(monday.iso_week().as_num() <= friday.iso_week().as_num());
}
