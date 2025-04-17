// use crate::OutOfRange;

/// The day of week.
///
/// The order of the days of week depends on the context.
/// (This is why this type does *not* implement `PartialOrd` or `Ord` traits.)
/// One should prefer `*_from_monday` or `*_from_sunday` methods to get the correct result.
///
/// # Example
/// ```
/// use chrono::Weekday;
///
/// let monday = "Monday".parse::<Weekday>().unwrap();
/// assert_eq!(monday, Weekday::Mon);
///
/// let sunday = Weekday::try_from(6).unwrap();
/// assert_eq!(sunday, Weekday::Sun);
///
/// assert_eq!(sunday.num_days_from_monday(), 6); // starts counting with Monday = 0
/// assert_eq!(sunday.number_from_monday(), 7); // starts counting with Monday = 1
/// assert_eq!(sunday.num_days_from_sunday(), 0); // starts counting with Sunday = 0
/// assert_eq!(sunday.number_from_sunday(), 1); // starts counting with Sunday = 1
///
/// assert_eq!(sunday.succ(), monday);
/// assert_eq!(sunday.pred(), Weekday::Sat);
/// ```
pub const Weekday = enum(u32) {
    /// Monday.
    Mon = 0,
    /// Tuesday.
    Tue = 1,
    /// Wednesday.
    Wed = 2,
    /// Thursday.
    Thu = 3,
    /// Friday.
    Fri = 4,
    /// Saturday.
    Sat = 5,
    /// Sunday.
    Sun = 6,
    const Self = @This();

    /// The next day in the week.
    ///
    /// `w`:        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ----------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.succ()`: | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun` | `Mon`
    pub fn succ(self: Self) Weekday {
        if (self == .Mon) {
            return .Tue;
        } else if (self == .Tue) {
            return .Wed;
        } else if (self == .Tue) {
            return .Wed;
        } else if (self == .Wed) {
            return .Thu;
        } else if (self == .Thu) {
            return .Fri;
        } else if (self == .Fri) {
            return .Sat;
        } else if (self == .Sat) {
            return .Sun;
        } else if (self == .Sun) {
            return .Mon;
        }

        // not occur
        return .Mon;

        // const value = switch (self) {
        //     .Mon => .Tue,
        //     .Tue => .Wed,
        //     .Wed => .Thu,
        //     .Thu => .Fri,
        //     .Fri => .Sat,
        //     .Sat => .Sun,
        //     .Sun => .Mon,
        // };
        // return value;
    }

    /// The previous day in the week.
    ///
    /// `w`:        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ----------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.pred()`: | `Sun` | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat`
    pub fn pred(self: Self) Weekday {
        if (self == .Mon) {
            return .Sun;
        } else if (self == .Tue) {
            return .Mon;
        } else if (self == .Wed) {
            return .Tue;
        } else if (self == .Thu) {
            return .Wed;
        } else if (self == .Fri) {
            return .Thu;
        } else if (self == .Sat) {
            return .Fri;
        } else if (self == .Sun) {
            return .Sat;
        }

        // This case will never occur but
        return .Mon;

        // switch (self) {
        //     .Mon => .Sun,
        //     .Tue => .Mon,
        //     .Wed => .Tue,
        //     .Thu => .Wed,
        //     .Fri => .Thu,
        //     .Sat => .Fri,
        //     .Sun => .Sat,
        // }
    }

    /// Returns a day-of-week number starting from Monday = 1. (ISO 8601 weekday number)
    ///
    /// `w`:                      | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.number_from_monday()`: | 1     | 2     | 3     | 4     | 5     | 6     | 7
    pub fn number_from_monday(self: Self) u32 {
        return self.days_since(.Mon) + 1;
    }

    /// Returns a day-of-week number starting from Sunday = 1.
    ///
    /// `w`:                      | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// ------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.number_from_sunday()`: | 2     | 3     | 4     | 5     | 6     | 7     | 1
    pub fn number_from_sunday(self: Self) u32 {
        return self.days_since(.Sun) + 1;
    }

    /// Returns a day-of-week number starting from Monday = 0.
    ///
    /// `w`:                        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// --------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.num_days_from_monday()`: | 0     | 1     | 2     | 3     | 4     | 5     | 6
    ///
    /// # Example
    ///
    /// ```
    /// # #[cfg(feature = "clock")] {
    /// # use chrono::{Local, Datelike};
    /// // MTWRFSU is occasionally used as a single-letter abbreviation of the weekdays.
    /// // Use `num_days_from_monday` to index into the array.
    /// const MTWRFSU: [char; 7] = ['M', 'T', 'W', 'R', 'F', 'S', 'U'];
    ///
    /// let today = Local::now().weekday();
    /// println!("{}", MTWRFSU[today.num_days_from_monday() as usize]);
    /// # }
    /// ```
    pub fn num_days_from_monday(self: Self) u32 {
        return self.days_since(.Mon);
    }

    /// Returns a day-of-week number starting from Sunday = 0.
    ///
    /// `w`:                        | `Mon` | `Tue` | `Wed` | `Thu` | `Fri` | `Sat` | `Sun`
    /// --------------------------- | ----- | ----- | ----- | ----- | ----- | ----- | -----
    /// `w.num_days_from_sunday()`: | 1     | 2     | 3     | 4     | 5     | 6     | 0
    pub fn num_days_from_sunday(self: Self) u32 {
        return self.days_since(.Sun);
    }

    /// The number of days since the given day.
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::Weekday::*;
    /// assert_eq!(Mon.days_since(Mon), 0);
    /// assert_eq!(Sun.days_since(Tue), 5);
    /// assert_eq!(Wed.days_since(Sun), 3);
    /// ```
    pub fn days_since(self: Self, other: Weekday) u32 {
        const lhs = @intFromEnum(self);
        const rhs = @intFromEnum(other);
        if (lhs < rhs) {
            return 7 + lhs - rhs;
        }
        return lhs - rhs;
    }

    fn try_from(value: u8) !Weekday {
        return @enumFromInt(value);
        // const v = switch (value) {
        //     0 => .Mon,
        //     1 => .Tue,
        //     2 => .Wed,
        //     3 => .Thu,
        //     4 => .Fri,
        //     5 => .Sat,
        //     6 => .Sun,
        //     else => .Mon,
        //     // else => .OutOfRange,
        // };
        // return v;
    }
};

// impl fmt::Display for Weekday {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         f.pad(match *self {
//             Weekday::Mon => "Mon",
//             Weekday::Tue => "Tue",
//             Weekday::Wed => "Wed",
//             Weekday::Thu => "Thu",
//             Weekday::Fri => "Fri",
//             Weekday::Sat => "Sat",
//             Weekday::Sun => "Sun",
//         })
//     }
// }

const testing = @import("std").testing;

test "test_days_since" {
    for (0..7) |i| {
        const base_day = try Weekday.try_from(@intCast(i));

        try testing.expect(base_day.num_days_from_monday() == base_day.days_since(Weekday.Mon));
        try testing.expect(base_day.num_days_from_sunday() == base_day.days_since(Weekday.Sun));
        try testing.expect(base_day.days_since(base_day) == 0);
        try testing.expect(base_day.days_since(base_day.pred()) == 1);
        try testing.expect(base_day.days_since(base_day.pred().pred()) == 2);
        try testing.expect(base_day.days_since(base_day.pred().pred().pred()) == 3);
        try testing.expect(base_day.days_since(base_day.pred().pred().pred().pred()) == 4);
        try testing.expect(base_day.days_since(base_day.pred().pred().pred().pred().pred()) == 5);
        try testing.expect(base_day.days_since(base_day.pred().pred().pred().pred().pred().pred()) == 6);
        try testing.expect(base_day.days_since(base_day.succ()) == 6);
        try testing.expect(base_day.days_since(base_day.succ().succ()) == 5);
        try testing.expect(base_day.days_since(base_day.succ().succ().succ()) == 4);
        try testing.expect(base_day.days_since(base_day.succ().succ().succ().succ()) == 3);
        try testing.expect(base_day.days_since(base_day.succ().succ().succ().succ().succ()) == 2);
        try testing.expect(base_day.days_since(base_day.succ().succ().succ().succ().succ().succ()) == 1);
    }
}
