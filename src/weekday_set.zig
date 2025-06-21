// use core::{
//     fmt::{self, Debug},
//     iter::FusedIterator,
// };

// use crate::Weekday;
const root = @import("root");
const Weekday = root.Weekday;

/// A collection of [`Weekday`]s stored as a single byte.
///
/// This type is `Copy` and provides efficient set-like and slice-like operations.
/// Many operations are `const` as well.
///
/// Implemented as a bitmask where bits 1-7 correspond to Monday-Sunday.
pub const WeekdaySet = struct {
    value: u8, // Invariant: the 8-th bit is always 0.
    const Self = @This();

    pub fn init(value: u8) Self {
        return Self{
            .value = value,
        };
    }

    /// Create a `WeekdaySet` from an array of [`Weekday`]s.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::EMPTY, WeekdaySet::from_array([]));
    /// assert_eq!(WeekdaySet::single(Mon), WeekdaySet::from_array([Mon]));
    /// assert_eq!(WeekdaySet::ALL, WeekdaySet::from_array([Mon, Tue, Wed, Thu, Fri, Sat, Sun]));
    /// ```
    pub fn from_array(days: []Weekday) Self {
        var acc = Self.EMPTY;
        var idx = 0;
        while (idx < days.len()) {
            acc.value |= Self.single(days[idx]).value;
            // acc.0 |= Self::single(days[idx]).0;
            idx += 1;
        }
        return acc;
    }

    /// Create a `WeekdaySet` from a single [`Weekday`].
    pub fn single(weekday: Weekday) Self {
        return switch (weekday) {
            Weekday.Mon => Self.init(0b000_0001),
            Weekday.Tue => Self.init(0b000_0010),
            Weekday.Wed => Self.init(0b000_0100),
            Weekday.Thu => Self.init(0b000_1000),
            Weekday.Fri => Self.init(0b001_0000),
            Weekday.Sat => Self.init(0b010_0000),
            Weekday.Sun => Self.init(0b100_0000),
        };
    }

    /// Returns `Some(day)` if this collection contains exactly one day.
    ///
    /// Returns `None` otherwise.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).single_day(), Some(Mon));
    /// assert_eq!(WeekdaySet::from_array([Mon, Tue]).single_day(), None);
    /// assert_eq!(WeekdaySet::EMPTY.single_day(), None);
    /// assert_eq!(WeekdaySet::ALL.single_day(), None);
    /// ```
    pub fn single_day(self: *Self) ?Weekday {
        return switch (self) {
            Self.init(0b000_0001) => Weekday.Mon,
            Self.init(0b000_0010) => Weekday.Tue,
            Self.init(0b000_0100) => Weekday.Wed,
            Self.init(0b000_1000) => Weekday.Thu,
            Self.init(0b001_0000) => Weekday.Fri,
            Self.init(0b010_0000) => Weekday.Sat,
            Self.init(0b100_0000) => Weekday.Sun,
            else => null,
        };
    }

    /// Adds a day to the collection.
    ///
    /// Returns `true` if the day was new to the collection.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// let mut weekdays = WeekdaySet::single(Mon);
    /// assert!(weekdays.insert(Tue));
    /// assert!(!weekdays.insert(Tue));
    /// ```
    pub fn insert(self: *Self, day: Weekday) bool {
        if (self.contains(day)) {
            return false;
        }
        self.value |= Self.single(day).value;
        // self.0 |= Self::single(day).0;
        return true;
    }

    /// Removes a day from the collection.
    ///
    /// Returns `true` if the collection did contain the day.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// let mut weekdays = WeekdaySet::single(Mon);
    /// assert!(weekdays.remove(Mon));
    /// assert!(!weekdays.remove(Mon));
    /// ```
    pub fn remove(self: *Self, day: Weekday) bool {
        if (self.contains(day)) {
            self.value &= ~Self.single(day).value;
            // self.0 &= !Self::single(day).0;
            return true;
        }

        return false;
    }

    /// Returns `true` if `other` contains all days in `self`.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert!(WeekdaySet::single(Mon).is_subset(WeekdaySet::ALL));
    /// assert!(!WeekdaySet::single(Mon).is_subset(WeekdaySet::EMPTY));
    /// assert!(WeekdaySet::EMPTY.is_subset(WeekdaySet::single(Mon)));
    /// ```
    pub fn is_subset(self: *Self, other: Self) bool {
        return self.intersection(other).value == self.value;
    }

    /// Returns days that are in both `self` and `other`.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).intersection(WeekdaySet::single(Mon)), WeekdaySet::single(Mon));
    /// assert_eq!(WeekdaySet::single(Mon).intersection(WeekdaySet::single(Tue)), WeekdaySet::EMPTY);
    /// assert_eq!(WeekdaySet::ALL.intersection(WeekdaySet::single(Mon)), WeekdaySet::single(Mon));
    /// assert_eq!(WeekdaySet::ALL.intersection(WeekdaySet::EMPTY), WeekdaySet::EMPTY);
    /// ```
    pub fn intersection(self: *Self, other: Self) Self {
        return Self.init(self.value & other.value);
    }

    /// Returns days that are in either `self` or `other`.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).union(WeekdaySet::single(Mon)), WeekdaySet::single(Mon));
    /// assert_eq!(WeekdaySet::single(Mon).union(WeekdaySet::single(Tue)), WeekdaySet::from_array([Mon, Tue]));
    /// assert_eq!(WeekdaySet::ALL.union(WeekdaySet::single(Mon)), WeekdaySet::ALL);
    /// assert_eq!(WeekdaySet::ALL.union(WeekdaySet::EMPTY), WeekdaySet::ALL);
    /// ```
    pub fn union_weekdayset(self: *Self, other: Self) Self {
        return Self.init(self.value | other.value);
    }

    /// Returns days that are in `self` or `other` but not in both.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).symmetric_difference(WeekdaySet::single(Mon)), WeekdaySet::EMPTY);
    /// assert_eq!(WeekdaySet::single(Mon).symmetric_difference(WeekdaySet::single(Tue)), WeekdaySet::from_array([Mon, Tue]));
    /// assert_eq!(
    ///     WeekdaySet::ALL.symmetric_difference(WeekdaySet::single(Mon)),
    ///     WeekdaySet::from_array([Tue, Wed, Thu, Fri, Sat, Sun]),
    /// );
    /// assert_eq!(WeekdaySet::ALL.symmetric_difference(WeekdaySet::EMPTY), WeekdaySet::ALL);
    /// ```
    pub fn symmetric_difference(self: *Self, other: Self) Self {
        return Self.init(self.value ^ other.value);
    }

    /// Returns days that are in `self` but not in `other`.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).difference(WeekdaySet::single(Mon)), WeekdaySet::EMPTY);
    /// assert_eq!(WeekdaySet::single(Mon).difference(WeekdaySet::single(Tue)), WeekdaySet::single(Mon));
    /// assert_eq!(WeekdaySet::EMPTY.difference(WeekdaySet::single(Mon)), WeekdaySet::EMPTY);
    /// ```
    pub fn difference(self: *Self, other: Self) Self {
        return Self.init(self.value & !other.value);
    }

    /// Get the first day in the collection, starting from Monday.
    ///
    /// Returns `None` if the collection is empty.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).first(), Some(Mon));
    /// assert_eq!(WeekdaySet::single(Tue).first(), Some(Tue));
    /// assert_eq!(WeekdaySet::ALL.first(), Some(Mon));
    /// assert_eq!(WeekdaySet::EMPTY.first(), None);
    /// ```
    pub fn first(self: *Self) ?Weekday {
        if (self.is_empty()) {
            return null;
        }

        // Find the first non-zero bit.

        const bit = 1 << @ctz(self.value);

        return Self.init(bit).single_day();
    }

    /// Get the last day in the collection, starting from Sunday.
    ///
    /// Returns `None` if the collection is empty.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).last(), Some(Mon));
    /// assert_eq!(WeekdaySet::single(Sun).last(), Some(Sun));
    /// assert_eq!(WeekdaySet::from_array([Mon, Tue]).last(), Some(Tue));
    /// assert_eq!(WeekdaySet::EMPTY.last(), None);
    /// ```
    pub fn last(self: *Self) ?Weekday {
        if (self.is_empty()) {
            return null;
        }

        // Find the last non-zero bit.

        const bit = 1 << (7 - @clz(self.value));

        return Self.init(bit).single_day();
    }

    /// Split the collection in two at the given day.
    ///
    /// Returns a tuple `(before, after)`. `before` contains all days starting from Monday
    /// up to but __not__ including `weekday`. `after` contains all days starting from `weekday`
    /// up to and including Sunday.
    fn split_at(self: *Self, weekday: Weekday) struct { Self, Self } {
        const days_after = 0b1000_0000 - Self.single(weekday).value;
        const days_before = days_after ^ 0b0111_1111;
        return struct { Self.init(self.value & days_before), Self.init(self.value & days_after) };
    }

    // /// Iterate over the [`Weekday`]s in the collection starting from a given day.
    // ///
    // /// Wraps around from Sunday to Monday if necessary.
    // ///
    // /// # Example
    // /// ```
    // /// # use chrono::WeekdaySet;
    // /// use chrono::Weekday::*;
    // /// let weekdays = WeekdaySet::from_array([Mon, Wed, Fri]);
    // /// let mut iter = weekdays.iter(Wed);
    // /// assert_eq!(iter.next(), Some(Wed));
    // /// assert_eq!(iter.next(), Some(Fri));
    // /// assert_eq!(iter.next(), Some(Mon));
    // /// assert_eq!(iter.next(), None);
    // /// ```
    // pub const fn iter(self, start: Weekday) -> WeekdaySetIter {
    //     WeekdaySetIter { days: self, start }
    // }

    /// Returns `true` if the collection contains the given day.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert!(WeekdaySet::single(Mon).contains(Mon));
    /// assert!(WeekdaySet::from_array([Mon, Tue]).contains(Tue));
    /// assert!(!WeekdaySet::single(Mon).contains(Tue));
    /// ```
    pub fn contains(self: *Self, day: Weekday) bool {
        return self.value & Self.single(day).value != 0;
    }

    /// Returns `true` if the collection is empty.
    ///
    /// # Example
    /// ```
    /// # use chrono::{Weekday, WeekdaySet};
    /// assert!(WeekdaySet::EMPTY.is_empty());
    /// assert!(!WeekdaySet::single(Weekday::Mon).is_empty());
    /// ```
    pub fn is_empty(self: *Self) bool {
        return self.len() == 0;
    }

    /// Returns the number of days in the collection.
    ///
    /// # Example
    /// ```
    /// # use chrono::WeekdaySet;
    /// use chrono::Weekday::*;
    /// assert_eq!(WeekdaySet::single(Mon).len(), 1);
    /// assert_eq!(WeekdaySet::from_array([Mon, Wed, Fri]).len(), 3);
    /// assert_eq!(WeekdaySet::ALL.len(), 7);
    /// ```
    pub fn len(self: *Self) u8 {
        return @popCount(self.value);
        // return self.value.count_ones() as u8
    }

    /// Iterate over all 128 possible sets, from `EMPTY` to `ALL`.
    /// Returns a range tuple like .field0 = start and .field1 = end
    fn iter_all() struct { u8, u8 } {
        const start: u8 = 0b0000_0000;
        const end: u8 = 0b1000_0000;

        return .{ start, end };

        // (..).map(Self)
    }

    /// An empty `WeekdaySet`.
    pub const EMPTY: Self = Self(0b000_0000);
    /// A `WeekdaySet` containing all seven `Weekday`s.
    pub const ALL: Self = Self(0b111_1111);
};

// /// Print the underlying bitmask, padded to 7 bits.
// ///
// /// # Example
// /// ```
// /// # use chrono::WeekdaySet;
// /// use chrono::Weekday::*;
// /// assert_eq!(format!("{:?}", WeekdaySet::single(Mon)), "WeekdaySet(0000001)");
// /// assert_eq!(format!("{:?}", WeekdaySet::single(Tue)), "WeekdaySet(0000010)");
// /// assert_eq!(format!("{:?}", WeekdaySet::ALL), "WeekdaySet(1111111)");
// /// ```
// impl Debug for WeekdaySet {
//     fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
//         write!(f, "WeekdaySet({:0>7b})", self.0)
//     }
// }

// /// An iterator over a collection of weekdays, starting from a given day.
// ///
// /// See [`WeekdaySet::iter()`].
// #[derive(Debug, Clone)]
// pub struct WeekdaySetIter {
//     days: WeekdaySet,
//     start: Weekday,
// }

// impl Iterator for WeekdaySetIter {
//     type Item = Weekday;

//     fn next(&mut self) -> Option<Self::Item> {
//         if self.days.is_empty() {
//             return None;
//         }

//         // Split the collection in two at `start`.
//         // Look for the first day among the days after `start` first, including `start` itself.
//         // If there are no days after `start`, look for the first day among the days before `start`.
//         let (before, after) = self.days.split_at(self.start);
//         let days = if after.is_empty() { before } else { after };

//         let next = days.first().expect("the collection is not empty");
//         self.days.remove(next);
//         Some(next)
//     }
// }

// impl DoubleEndedIterator for WeekdaySetIter {
//     fn next_back(&mut self) -> Option<Self::Item> {
//         if self.days.is_empty() {
//             return None;
//         }

//         // Split the collection in two at `start`.
//         // Look for the last day among the days before `start` first, NOT including `start` itself.
//         // If there are no days before `start`, look for the last day among the days after `start`.
//         let (before, after) = self.days.split_at(self.start);
//         let days = if before.is_empty() { after } else { before };

//         let next_back = days.last().expect("the collection is not empty");
//         self.days.remove(next_back);
//         Some(next_back)
//     }
// }

// impl ExactSizeIterator for WeekdaySetIter {
//     fn len(&self) -> usize {
//         self.days.len().into()
//     }
// }

// impl FusedIterator for WeekdaySetIter {}

// /// Print the collection as a slice-like list of weekdays.
// ///
// /// # Example
// /// ```
// /// # use chrono::WeekdaySet;
// /// use chrono::Weekday::*;
// /// assert_eq!("[]", WeekdaySet::EMPTY.to_string());
// /// assert_eq!("[Mon]", WeekdaySet::single(Mon).to_string());
// /// assert_eq!("[Mon, Fri, Sun]", WeekdaySet::from_array([Mon, Fri, Sun]).to_string());
// /// ```
// impl fmt::Display for WeekdaySet {
//     fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
//         write!(f, "[")?;
//         let mut iter = self.iter(Weekday::Mon);
//         if let Some(first) = iter.next() {
//             write!(f, "{first}")?;
//         }
//         for weekday in iter {
//             write!(f, ", {weekday}")?;
//         }
//         write!(f, "]")
//     }
// }

// impl FromIterator<Weekday> for WeekdaySet {
//     fn from_iter<T: IntoIterator<Item = Weekday>>(iter: T) -> Self {
//         iter.into_iter().map(Self::single).fold(Self::EMPTY, Self::union)
//     }
// }

// #[cfg(test)]
// mod tests {
//     use crate::Weekday;
const std = @import("std");
const testing = std.testing;

//     use super::WeekdaySet;

//     impl WeekdaySet {
//

//     }

//     /// Panics if the 8-th bit of `self` is not 0.
fn assert_8th_bit_invariant(days: WeekdaySet) void {
    std.debug.assert(days.value & 0b1000_0000 == 0);
    // assert!(, "the 8-th bit of {days:?} is not 0");
}

// not implemented yet
// test "debug_prints_8th_bit_if_not_zero" {
//     const buffer = try std.fmt.allocPrint(std.heap.page_allocator, "{any}", WeekdaySet(0b1000_0000));
//     try testing.expect(std.mem.eql(u8, buffer, "WeekdaySet(10000000)"));
// }

test "bitwise_set_operations_preserve_8th_bit_invariant" {
    const start, const end = WeekdaySet.iter_all();
    for (start..end) |v1| {
        var set1 = WeekdaySet.init(@intCast(v1));
        for (start..end) |v2| {
            const set2 = WeekdaySet.init(@intCast(v2));
            assert_8th_bit_invariant(set1.union_weekdayset(set2));
            assert_8th_bit_invariant(set1.intersection(set2));
            assert_8th_bit_invariant(set1.symmetric_difference(set2));
        }
    }
}
