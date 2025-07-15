// #[cfg(feature = "alloc")]
// use core::borrow::Borrow;
// use core::iter::FusedIterator;
// use core::num::NonZeroI32;
// use core::ops::{Add, AddAssign, Sub, SubAssign};
// use core::{fmt, str};

// #[cfg(any(feature = "rkyv", feature = "rkyv-16", feature = "rkyv-32", feature = "rkyv-64"))]
// use rkyv::{Archive, Deserialize, Serialize};

// /// L10n locales.
// #[cfg(all(feature = "unstable-locales", feature = "alloc"))]
// use pure_rust_locales::Locale;

// #[cfg(feature = "alloc")]
// use crate::format::DelayedFormat;
// use crate::format::{
//     Item, Numeric, Pad, ParseError, ParseResult, Parsed, StrftimeItems, parse, parse_and_remainder,
//     write_hundreds,
// };
// use crate::month::Months;
// use crate::naive::{Days, IsoWeek, NaiveDateTime, NaiveTime, NaiveWeek};
const NaiveTime = @import("time.zig").NaiveTime;
// const NaiveDateTime = @import("datetime.zig").NaiveDateTime;


// use crate::{Datelike, TimeDelta, Weekday};
// use crate::{expect, try_opt};

// use super::internals::{Mdf, YearFlags};

// #[cfg(test)]
// mod tests;


//a >> b == a / 2.pow(b)


// the zig support for max 
const std = @import("std");
const internals = @import("internals.zig");
const weekday = @import("../weekday.zig");
const month = @import("../month.zig");
const naive = @import("../naive/root.zig");
const isoweek = @import("isoweek.zig");


const Days = naive.Days;
const Months = month.Months;
const IsoWeek = isoweek.IsoWeek;
const Weekday = weekday.Weekday;
const YearFlags = internals.YearFlags;
const Mdf = internals.Mdf;
const NaiveDateTime = @import("datetime.zig").NaiveDateTime;
const TimeDelta = @import("../time_delta.zig").TimeDelta;

const i32_max = std.math.maxInt(i32);
const i32_min = std.math.minInt(i32);

fn div_euclid(comptime T: type, this: T, other: T) !T {
    const value = try std.math.divFloor(T, this, other);
    return value;
}

fn rem_euclid(comptime T: type, this: T, other: T) !T {
    return @mod(this, other);
}


/// ISO 8601 calendar date without timezone.
/// Allows for every [proleptic Gregorian date] from Jan 1, 262145 BCE to Dec 31, 262143 CE.
/// Also supports the conversion from ISO 8601 ordinal and week date.
///
/// # Calendar Date
///
/// The ISO 8601 **calendar date** follows the proleptic Gregorian calendar.
/// It is like a normal civil calendar but note some slight differences:
///
/// * Dates before the Gregorian calendar's inception in 1582 are defined via the extrapolation.
///   Be careful, as historical dates are often noted in the Julian calendar and others
///   and the transition to Gregorian may differ across countries (as late as early 20C).
///
///   (Some example: Both Shakespeare from Britain and Cervantes from Spain seemingly died
///   on the same calendar date---April 23, 1616---but in the different calendar.
///   Britain used the Julian calendar at that time, so Shakespeare's death is later.)
///
/// * ISO 8601 calendars have the year 0, which is 1 BCE (a year before 1 CE).
///   If you need a typical BCE/BC and CE/AD notation for year numbers,
///   use the [`Datelike::year_ce`] method.
///
/// # Week Date
///
/// The ISO 8601 **week date** is a triple of year number, week number
/// and [day of the week](Weekday) with the following rules:
///
/// * A week consists of Monday through Sunday, and is always numbered within some year.
///   The week number ranges from 1 to 52 or 53 depending on the year.
///
/// * The week 1 of given year is defined as the first week containing January 4 of that year,
///   or equivalently, the first week containing four or more days in that year.
///
/// * The year number in the week date may *not* correspond to the actual Gregorian year.
///   For example, January 3, 2016 (Sunday) was on the last (53rd) week of 2015.
///
/// Chrono's date types default to the ISO 8601 [calendar date](#calendar-date), but
/// [`Datelike::iso_week`] and [`Datelike::weekday`] methods can be used to get the corresponding
/// week date.
///
/// # Ordinal Date
///
/// The ISO 8601 **ordinal date** is a pair of year number and day of the year ("ordinal").
/// The ordinal number ranges from 1 to 365 or 366 depending on the year.
/// The year number is the same as that of the [calendar date](#calendar-date).
///
/// This is currently the internal format of Chrono's date types.
///
/// [proleptic Gregorian date]: crate::NaiveDate#calendar-date
pub const NaiveDate = struct {

    // NonZeroI32
    pyof: i32, // (year << 13) | of
    const Self = @This();


    /// The minimum possible `NaiveDate` (January 1, 262144 BCE).
    pub const MIN: NaiveDate = NaiveDate.from_yof((MIN_YEAR << 13) | (1 << 4) | 0o12 );
    /// The maximum possible `NaiveDate` (December 31, 262142 CE).
    pub const MAX: NaiveDate = NaiveDate.from_yof((MAX_YEAR << 13) | (365 << 4) | 0o16);

    pub fn weeks_from(self: Self, _day: Weekday) i32 {
        return self.ordinal() - self.weekday().days_since(_day) + 6 / 7;
    }


    /// Create a new `NaiveDate` from a raw year-ordinal-flags `i32`.
    ///
    /// In a valid value an ordinal is never `0`, and neither are the year flags. This method
    /// doesn't do any validation in release builds.
    fn from_yof(_yof: i32) NaiveDate {
        // The following are the invariants our ordinal and flags should uphold for a valid
        // `NaiveDate`.
        std.debug.assert(((_yof & OL_MASK) >> 3) > 1);
        std.debug.assert(((_yof & OL_MASK) >> 3) <= MAX_OL);
        std.debug.assert((_yof & 0b111) != 0);
        return NaiveDate {
            .pyof = _yof,
        };
    }

    /// Get the raw year-ordinal-flags `i32`.
    fn yof(self: Self) i32 {
        return self.pyof;
    }

    fn from_ordinal_and_flags(
        _year: i32,
        _ordinal: u32,
        flags: YearFlags,
    ) ?NaiveDate {
        if (_year < MIN_YEAR or _year > MAX_YEAR) {
            return null; // Out-of-range
        }
        if (_ordinal == 0 or _ordinal > 366) {
            return null; // Invalid
        }
        std.debug.assert(YearFlags.from_year(_year).value == flags.value);
        const _yof = (_year << 13) | (_ordinal << 4) | flags.value;
        if (_yof & OL_MASK <= MAX_OL) {
            return NaiveDate.from_yof(_yof);
        } else {
            return null;
        }
             
    }



    /// Makes a new `NaiveDate` from year, ordinal and flags.
    /// Does not check whether the flags are correct for the provided year.
    /// Makes a new `NaiveDate` from year and packed month-day-flags.
    /// Does not check whether the flags are correct for the provided year.
    fn from_mdf(_year: i32, _mdf: Mdf) ?NaiveDate {
        if (_year < MIN_YEAR or _year > MAX_YEAR) {
            return null; // Out-of-range
        }
        return NaiveDate.from_yof((_year << 13) | std.math.cast(i32, _mdf.ordinal_and_flags().?).?);
    }

  

    /// Makes a new `NaiveDate` from the [calendar date](#calendar-date)
    /// (year, month and day).
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified calendar day does not exist (for example 2023-04-31).
    /// - The value for `month` or `day` is invalid.
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_ymd_opt = NaiveDate::from_ymd_opt;
    ///
    /// assert!(from_ymd_opt(2015, 3, 14).is_some());
    /// assert!(from_ymd_opt(2015, 0, 14).is_none());
    /// assert!(from_ymd_opt(2015, 2, 29).is_none());
    /// assert!(from_ymd_opt(-4, 2, 29).is_some()); // 5 BCE is a leap year
    /// assert!(from_ymd_opt(400000, 1, 1).is_none());
    /// assert!(from_ymd_opt(-400000, 1, 1).is_none());
    /// ```
    pub fn from_ymd_opt(_year: i32, _month: u32, _day: u32) ?NaiveDate {
        const flags = YearFlags.from_year(_year);
        // std.debug.print("{s} from_ymd_opt() flag: {any}\n", .{name, flags.value});
        if (Mdf.new(_month, _day, flags)) |_mdf| {
            return NaiveDate.from_mdf(_year, _mdf);
        } else {
            return null;
        }
    }

    

    /// Makes a new `NaiveDate` from the [ordinal date](#ordinal-date)
    /// (year and day of the year).
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified ordinal day does not exist (for example 2023-366).
    /// - The value for `ordinal` is invalid (for example: `0`, `400`).
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_yo_opt = NaiveDate::from_yo_opt;
    ///
    /// assert!(from_yo_opt(2015, 100).is_some());
    /// assert!(from_yo_opt(2015, 0).is_none());
    /// assert!(from_yo_opt(2015, 365).is_some());
    /// assert!(from_yo_opt(2015, 366).is_none());
    /// assert!(from_yo_opt(-4, 366).is_some()); // 5 BCE is a leap year
    /// assert!(from_yo_opt(400000, 1).is_none());
    /// assert!(from_yo_opt(-400000, 1).is_none());
    /// ```
    pub fn from_yo_opt(_year: i32, _ordinal: u32) ?NaiveDate {
        const flags = YearFlags.from_year(_year);
        return NaiveDate.from_ordinal_and_flags(_year, _ordinal, flags);
    }


    /// Makes a new `NaiveDate` from the [ISO week date](#week-date)
    /// (year, week number and day of the week).
    /// The resulting `NaiveDate` may have a different year from the input year.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified week does not exist in that year (for example 2023 week 53).
    /// - The value for `week` is invalid (for example: `0`, `60`).
    /// - If the resulting date is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// let from_isoywd_opt = NaiveDate::from_isoywd_opt;
    ///
    /// assert_eq!(from_isoywd_opt(2015, 0, Weekday::Sun), None);
    /// assert_eq!(from_isoywd_opt(2015, 10, Weekday::Sun), Some(from_ymd(2015, 3, 8)));
    /// assert_eq!(from_isoywd_opt(2015, 30, Weekday::Mon), Some(from_ymd(2015, 7, 20)));
    /// assert_eq!(from_isoywd_opt(2015, 60, Weekday::Mon), None);
    ///
    /// assert_eq!(from_isoywd_opt(400000, 10, Weekday::Fri), None);
    /// assert_eq!(from_isoywd_opt(-400000, 10, Weekday::Sat), None);
    /// ```
    ///
    /// The year number of ISO week date may differ from that of the calendar date.
    ///
    /// ```
    /// # use chrono::{NaiveDate, Weekday};
    /// # let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// # let from_isoywd_opt = NaiveDate::from_isoywd_opt;
    /// //           Mo Tu We Th Fr Sa Su
    /// // 2014-W52  22 23 24 25 26 27 28    has 4+ days of new year,
    /// // 2015-W01  29 30 31  1  2  3  4 <- so this is the first week
    /// assert_eq!(from_isoywd_opt(2014, 52, Weekday::Sun), Some(from_ymd(2014, 12, 28)));
    /// assert_eq!(from_isoywd_opt(2014, 53, Weekday::Mon), None);
    /// assert_eq!(from_isoywd_opt(2015, 1, Weekday::Mon), Some(from_ymd(2014, 12, 29)));
    ///
    /// // 2015-W52  21 22 23 24 25 26 27    has 4+ days of old year,
    /// // 2015-W53  28 29 30 31  1  2  3 <- so this is the last week
    /// // 2016-W01   4  5  6  7  8  9 10
    /// assert_eq!(from_isoywd_opt(2015, 52, Weekday::Sun), Some(from_ymd(2015, 12, 27)));
    /// assert_eq!(from_isoywd_opt(2015, 53, Weekday::Sun), Some(from_ymd(2016, 1, 3)));
    /// assert_eq!(from_isoywd_opt(2015, 54, Weekday::Mon), None);
    /// assert_eq!(from_isoywd_opt(2016, 1, Weekday::Mon), Some(from_ymd(2016, 1, 4)));
    /// ```
    pub fn from_isoywd_opt(_year: i32, _week: u32, _weekday: Weekday) ?NaiveDate {
        const flags = YearFlags.from_year(_year);
        const nweeks = flags.nisoweeks();
        if (_week == 0 or _week > nweeks) {
            return null;
        }
        // ordinal = week ordinal - delta
        const weekord = _week * 7 + _weekday;
        const delta = flags.isoweek_delta();
        
        // const (year, ordinal, flags) = 
        if (weekord <= delta) {
            // ordinal < 1, previous year
            const prevflags = YearFlags.from_year(_year - 1);
            // (year - 1, weekord + prevflags.ndays() - delta, prevflags)
            return NaiveDate.from_ordinal_and_flags(_year-1, weekord + prevflags.ndays() - delta, prevflags);
        }

        const _ordinal = weekord - delta;
        const ndays = flags.ndays();
        if (_ordinal <= ndays) {
            // this year
            // (year, ordinal, flags)
            return NaiveDate.from_ordinal_and_flags(_year, _ordinal, flags);
        } 

        // ordinal > ndays, next year
        const nextflags = YearFlags.from_year(_year + 1);
        // (year + 1, ordinal - ndays, nextflags)
        return NaiveDate.from_ordinal_and_flags(_year+1, _ordinal-ndays, nextflags);
    
    }

    

    /// Makes a new `NaiveDate` from a day's number in the proleptic Gregorian calendar, with
    /// January 1, 1 being day 1.
    ///
    /// # Errors
    ///
    /// Returns `None` if the date is out of range.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_ndays_opt = NaiveDate::from_num_days_from_ce_opt;
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    ///
    /// assert_eq!(from_ndays_opt(730_000), Some(from_ymd(1999, 9, 3)));
    /// assert_eq!(from_ndays_opt(1), Some(from_ymd(1, 1, 1)));
    /// assert_eq!(from_ndays_opt(0), Some(from_ymd(0, 12, 31)));
    /// assert_eq!(from_ndays_opt(-1), Some(from_ymd(0, 12, 30)));
    /// assert_eq!(from_ndays_opt(100_000_000), None);
    /// assert_eq!(from_ndays_opt(-100_000_000), None);
    /// ```
    pub  fn from_num_days_from_ce_opt(_days: i32)  !?NaiveDate {
        const days = try std.math.add(i32, _days, 365); // make December 31, 1 BCE equal to day 0
        const year_div_400 =  try div_euclid(i32, days, 146_097);// days.div_euclid(146_097);
        const cycle =  try rem_euclid(i32, days, 146_097);//days.rem_euclid(146_097);
        const year_mod_400, const _ordinal = cycle_to_yo(cycle);
        const flags = YearFlags.from_year_mod_400(year_mod_400);
        return NaiveDate.from_ordinal_and_flags(year_div_400 * 400 + year_mod_400, _ordinal, flags);
    }

    /// Returns the day of week.
    // This duplicates `Datelike::weekday()`, because trait methods can't be const yet.
    pub fn weekday(self: Self) Weekday {
        const v = (((self.yof() & ORDINAL_MASK) >> 4) + (self.yof() & WEEKDAY_FLAGS_MASK)) % 7;
        if (v == 0) { return .Mon; }
        if (v == 1) { return .Tue; }
        if (v == 2) { return .Wed; }
        if (v == 3) { return .Thu; }
        if (v == 4) { return .Fri; }
        if (v == 5) { return .Sat; }
        return .Sun;
    }


    /// Makes a new `NaiveDate` by counting the number of occurrences of a particular day-of-week
    /// since the beginning of the given month. For instance, if you want the 2nd Friday of March
    /// 2017, you would use `NaiveDate::from_weekday_of_month(2017, 3, Weekday::Fri, 2)`.
    ///
    /// `n` is 1-indexed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified day does not exist in that month (for example the 5th Monday of Apr. 2023).
    /// - The value for `month` or `n` is invalid.
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    /// assert_eq!(
    ///     NaiveDate::from_weekday_of_month_opt(2017, 3, Weekday::Fri, 2),
    ///     NaiveDate::from_ymd_opt(2017, 3, 10)
    /// )
    /// ```
    pub  fn from_weekday_of_month_opt(
        _year: i32,
        _month: u32,
        _weekday: Weekday,
        n: u8,
    ) ?NaiveDate {
        if (n == 0) {
            return null;
        }
        
        var first = NaiveDate.from_ymd_opt(_year, _month, 1).?.weekday();
        const first_to_dow = (7 + _weekday.number_from_monday() - first.number_from_monday()) % 7;
        const _day = (n - 1) * 7 + first_to_dow + 1;
        return NaiveDate.from_ymd_opt(_year, _month, _day);
    }


    /// Add a duration in [`Months`] to the date
    ///
    /// Uses the last day of the month if the day does not exist in the resulting month.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Months};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_add_months(Months::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 8, 20).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7, 31).unwrap().checked_add_months(Months::new(2)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 9, 30).unwrap())
    /// );
    /// ```
    pub fn checked_add_months(self: Self, months: Months) ?NaiveDate {
        if (months.value == 0) {
            return self;
        }

        if (months.value <= i32_max) {
            return self.diff_months(months.value);
        }
        return null;
    }


    /// Subtract a duration in [`Months`] from the date
    ///
    /// Uses the last day of the month if the day does not exist in the resulting month.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Months};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_sub_months(Months::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2021, 8, 20).unwrap())
    /// );
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2014, 1, 1)
    ///         .unwrap()
    ///         .checked_sub_months(Months::new(core::i32::MAX as u32 + 1)),
    ///     None
    /// );
    /// ```
    pub fn checked_sub_months(self: Self, months: Months)  ?NaiveDate {
        if (months.value == 0) {
            return self;
        }

        if (months.value <= i32_max) {
            return self.diff_months(-(months.value));
        }

        return null;
    }

    fn diff_months(self: Self, _months: i32)  !NaiveDate {
        const months = try std.math.add(i32, (self.year() * 12 + self.month() - 1), _months);
        
        const _year =  try div_euclid(i32, months, 12); //months.div_euclid(12);
        const _month = try rem_euclid(i32, months, 12); //months.rem_euclid(12) as u32 + 1;

        // Clamp original day in case new month is shorter
        var flags = YearFlags.from_year(_year);
        const feb_days = switch (flags.ndays()) {
            366 => 29,
            else => 28
        };
        const days = [_]i32{31, feb_days, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
        const day_max = days[(_month - 1)];
        var _day = self.day();
        if (_day > day_max) {
            _day = day_max;
        }

        return NaiveDate.from_ymd_opt(_year, _month, _day);
    }

    /// Add a duration in [`Days`] to the date
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Days};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_add_days(Days::new(9)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 3, 1).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7, 31).unwrap().checked_add_days(Days::new(2)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 8, 2).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7, 31).unwrap().checked_add_days(Days::new(1000000000000)),
    ///     None
    /// );
    /// ```
    pub fn checked_add_days(self: Self, days: Days) ?NaiveDate {
        if (days.value <= i32_max) {
            return self.add_days(days.value);
        }
        return null;
    }

    /// Subtract a duration in [`Days`] from the date
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Days};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_sub_days(Days::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 2, 14).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_sub_days(Days::new(1000000000000)),
    ///     None
    /// );
    /// ```
    pub fn checked_sub_days(self: Self, days: Days) ?NaiveDate {
        if (days.value <= i32_max) {
            return self.add_days(-days.value);
        }
        return null;
    }

    /// Returns `true` if this is a leap year.
    ///
    /// ```
    /// # use chrono::NaiveDate;
    /// assert_eq!(NaiveDate::from_ymd_opt(2000, 1, 1).unwrap().leap_year(), true);
    /// assert_eq!(NaiveDate::from_ymd_opt(2001, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2002, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2003, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2004, 1, 1).unwrap().leap_year(), true);
    /// assert_eq!(NaiveDate::from_ymd_opt(2100, 1, 1).unwrap().leap_year(), false);
    /// ```
    pub fn leap_year(self: Self) bool {
        
        return self.yof() & (0b1000) == 0;
    }

    pub fn iso_week(self: Self) IsoWeek {
        return IsoWeek.from_yof(self.year(), self.ordinal(), self.year_flags());
    }


    // This duplicates `Datelike::year()`, because trait methods can't be const yet.

    fn year(self: Self)  i32 {
        return self.yof() >> 13;
    }

    /// Returns the day of year starting from 1.
    // This duplicates `Datelike::ordinal()`, because trait methods can't be const yet.
    fn ordinal(self: Self) u32 {
        return (std.math.cast(u32, (self.yof() & ORDINAL_MASK)).? >> 4); //as u32
    }

    // This duplicates `Datelike::month()`, because trait methods can't be const yet.

    fn month(self: Self) u32 {
        return self.mdf().month();
    }

    // This duplicates `Datelike::day()`, because trait methods can't be const yet.
    fn day(self: Self) u32 {
        return self.mdf().day();
    }

    
    /// Returns the packed month-day-flags.
    fn mdf(self: Self) Mdf {
        Mdf.from_ol((self.yof() & OL_MASK) >> 3, self.year_flags());
    }


    fn year_flags(self: Self) YearFlags {
        return YearFlags.new(@intCast((self.yof() & YEAR_FLAGS_MASK)));
    }

    /// Add a duration of `i32` days to the date.
    pub fn add_days(self: *Self, days: i32) ?Self {
        // Fast path if the result is within the same year.
        // Also `DateTime::checked_(add|sub)_days` relies on this path, because if the value remains
        // within the year it doesn't do a check if the year is in range.
        // This way `DateTime:checked_(add|sub)_days(Days::new(0))` can be a no-op on dates were the
        // local datetime is beyond `NaiveDate::{MIN, MAX}.
        const _ordinal = try std.math.add(i32,  ((self.yof() & ORDINAL_MASK) >> 4) , days);
        
        
        if (_ordinal > 0 and _ordinal <= (365 + @as(i32, self.leap_year()))) {
            const year_and_flags = self.yof() & !ORDINAL_MASK;
            return NaiveDate.from_yof(year_and_flags | (_ordinal << 4));
        }
        
        // do the full check
        const _year = self.year();
        var year_div_400, const year_mod_400 = div_mod_floor(_year, 400);
        const cycle = yo_to_cycle(@intCast(year_mod_400), self.ordinal());
        // const  cycle = try_opt!((@as(i32, cycle)).checked_add(days));
        const _cycle = try std.math.add(i32, cycle, days);
        const  cycle_div_400y, const __cycle = div_mod_floor(_cycle, 146_097);
        year_div_400 += cycle_div_400y;

        const _year_mod_400, const __ordinal = cycle_to_yo(__cycle);
        
        const _flags = YearFlags.from_year_mod_400(_year_mod_400);
        return NaiveDate.from_ordinal_and_flags(year_div_400 * 400 + @as(i32, _year_mod_400), __ordinal, _flags);
    }


    /// Makes a new `NaiveDateTime` from the current date and given `NaiveTime`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, NaiveTime};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// let t = NaiveTime::from_hms_milli_opt(12, 34, 56, 789).unwrap();
    ///
    /// let dt: NaiveDateTime = d.and_time(t);
    /// assert_eq!(dt.date(), d);
    /// assert_eq!(dt.time(), t);
    /// ```
    pub fn and_time(self: *Self, time: NaiveTime)  NaiveDateTime {
        return NaiveDateTime.new(*self, time);
    }


    /// Makes a new `NaiveDateTime` from the current date, hour, minute and second.
    ///
    /// No [leap second](./struct.NaiveTime.html#leap-second-handling) is allowed here;
    /// use `NaiveDate::and_hms_*_opt` methods with a subsecond parameter instead.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute and/or second.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// assert!(d.and_hms_opt(12, 34, 56).is_some());
    /// assert!(d.and_hms_opt(12, 34, 60).is_none()); // use `and_hms_milli_opt` instead
    /// assert!(d.and_hms_opt(12, 60, 56).is_none());
    /// assert!(d.and_hms_opt(24, 34, 56).is_none());
    /// ```
    pub fn and_hms_opt(self: *Self, _hour: u32, _min: u32, _sec: u32) ?NaiveDateTime {
        const _time = NaiveTime.from_hms_opt(_hour, _min, _sec) catch return null;
        return self.and_time(_time);
    }


    /// Makes a new `NaiveDateTime` from the current date, hour, minute, second and millisecond.
    ///
    /// The millisecond part is allowed to exceed 1,000,000,000 in order to represent a [leap second](
    /// ./struct.NaiveTime.html#leap-second-handling), but only when `sec == 59`.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute, second and/or millisecond.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// assert!(d.and_hms_milli_opt(12, 34, 56, 789).is_some());
    /// assert!(d.and_hms_milli_opt(12, 34, 59, 1_789).is_some()); // leap second
    /// assert!(d.and_hms_milli_opt(12, 34, 59, 2_789).is_none());
    /// assert!(d.and_hms_milli_opt(12, 34, 60, 789).is_none());
    /// assert!(d.and_hms_milli_opt(12, 60, 56, 789).is_none());
    /// assert!(d.and_hms_milli_opt(24, 34, 56, 789).is_none());
    /// ```
    pub fn and_hms_milli_opt(
        self: *Self,
        _hour: u32,
        _min: u32,
        _sec: u32,
        _milli: u32,
    ) ?NaiveDateTime {
        const _time = NaiveTime.from_hms_milli_opt(_hour, _min, _sec, _milli) catch return null;
        return self.and_time(_time);
    }


    /// Makes a new `NaiveDateTime` from the current date, hour, minute, second and microsecond.
    ///
    /// The microsecond part is allowed to exceed 1,000,000 in order to represent a [leap second](
    /// ./struct.NaiveTime.html#leap-second-handling), but only when `sec == 59`.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute, second and/or microsecond.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// assert!(d.and_hms_micro_opt(12, 34, 56, 789_012).is_some());
    /// assert!(d.and_hms_micro_opt(12, 34, 59, 1_789_012).is_some()); // leap second
    /// assert!(d.and_hms_micro_opt(12, 34, 59, 2_789_012).is_none());
    /// assert!(d.and_hms_micro_opt(12, 34, 60, 789_012).is_none());
    /// assert!(d.and_hms_micro_opt(12, 60, 56, 789_012).is_none());
    /// assert!(d.and_hms_micro_opt(24, 34, 56, 789_012).is_none());
    /// ```
    pub fn and_hms_micro_opt(
        self: *Self,
        _hour: u32,
        _min: u32,
        _sec: u32,
        _micro: u32,
    ) ?NaiveDateTime {
        const time = NaiveTime.from_hms_micro_opt(_hour, _min, _sec, _micro) catch return null;
        return self.and_time(time);
    }

    /// Makes a new `NaiveDateTime` from the current date, hour, minute, second and nanosecond.
    ///
    /// The nanosecond part is allowed to exceed 1,000,000,000 in order to represent a [leap second](
    /// ./struct.NaiveTime.html#leap-second-handling), but only when `sec == 59`.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute, second and/or nanosecond.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// assert!(d.and_hms_nano_opt(12, 34, 56, 789_012_345).is_some());
    /// assert!(d.and_hms_nano_opt(12, 34, 59, 1_789_012_345).is_some()); // leap second
    /// assert!(d.and_hms_nano_opt(12, 34, 59, 2_789_012_345).is_none());
    /// assert!(d.and_hms_nano_opt(12, 34, 60, 789_012_345).is_none());
    /// assert!(d.and_hms_nano_opt(12, 60, 56, 789_012_345).is_none());
    /// assert!(d.and_hms_nano_opt(24, 34, 56, 789_012_345).is_none());
    /// ```
    pub  fn and_hms_nano_opt(
        self: *Self,
        _hour: u32,
        _min: u32,
        _sec: u32,
        _nano: u32,
    ) ?NaiveDateTime {
        const _time = NaiveTime.from_hms_nano_opt(_hour, _min, _sec, _nano) catch return null;
        return self.and_time(_time);
    }


    /// Makes a new `NaiveDate` with the packed month-day-flags changed.
    ///
    /// Returns `None` when the resulting `NaiveDate` would be invalid.
    fn with_mdf(self: *Self, _mdf: Mdf) ?NaiveDate {
        std.debug.assert(self.year_flags().value == _mdf.year_flags().value);


        if (_mdf.ordinal()) |_ordinal| {
            return NaiveDate.from_yof(
                    (self.yof() & !ORDINAL_MASK) |
                     @as(i32, (_ordinal << 4))
                    );
        } else {
            return null;
        }

    }

    /// Makes a new `NaiveDate` for the next calendar date.
    ///
    /// # Errors
    ///
    /// Returns `None` when `self` is the last representable date.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 6, 3).unwrap().succ_opt(),
    ///     Some(NaiveDate::from_ymd_opt(2015, 6, 4).unwrap())
    /// );
    /// assert_eq!(NaiveDate::MAX.succ_opt(), None);
    /// ```

    pub fn succ_opt(self: *Self) ?NaiveDate {
        const new_ol = (self.yof() & OL_MASK) + (1 << 4);
        switch (new_ol <= MAX_OL) {
            true => return NaiveDate.from_yof(self.yof() & !OL_MASK | new_ol),
            false => return NaiveDate.from_yo_opt(self.year() + 1, 1),
        }
    }


    /// Makes a new `NaiveDate` for the previous calendar date.
    ///
    /// # Errors
    ///
    /// Returns `None` when `self` is the first representable date.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 6, 3).unwrap().pred_opt(),
    ///     Some(NaiveDate::from_ymd_opt(2015, 6, 2).unwrap())
    /// );
    /// assert_eq!(NaiveDate::MIN.pred_opt(), None);
    /// ```
    pub fn pred_opt(self: *Self) ?NaiveDate {
        const new_shifted_ordinal = (self.yof() & ORDINAL_MASK) - (1 << 4);
        switch (new_shifted_ordinal > 0) {
            true => return NaiveDate.from_yof(self.yof() & !ORDINAL_MASK | new_shifted_ordinal),
            false => return NaiveDate.from_ymd_opt(self.year() - 1, 12, 31),
        }
    }



    /// Adds the number of whole days in the given `TimeDelta` to the current date.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, TimeDelta};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
    /// assert_eq!(
    ///     d.checked_add_signed(TimeDelta::try_days(40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 15).unwrap())
    /// );
    /// assert_eq!(
    ///     d.checked_add_signed(TimeDelta::try_days(-40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 7, 27).unwrap())
    /// );
    /// assert_eq!(d.checked_add_signed(TimeDelta::try_days(1_000_000_000).unwrap()), None);
    /// assert_eq!(d.checked_add_signed(TimeDelta::try_days(-1_000_000_000).unwrap()), None);
    /// assert_eq!(NaiveDate::MAX.checked_add_signed(TimeDelta::try_days(1).unwrap()), None);
    /// ```
    pub fn checked_add_signed(self: *Self, rhs: TimeDelta) ?NaiveDate {
        const _days = rhs.num_days();
        if (_days < @as(i64, std.math.minInt(i32)) or _days > @as(i64, std.math.maxInt(i32))) {
            return null;
        }
        return self.add_days(_days);
    }


};



// impl NaiveDate {





//     /// Subtracts the number of whole days in the given `TimeDelta` from the current date.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if the resulting date would be out of range.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{NaiveDate, TimeDelta};
//     ///
//     /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
//     /// assert_eq!(
//     ///     d.checked_sub_signed(TimeDelta::try_days(40).unwrap()),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 7, 27).unwrap())
//     /// );
//     /// assert_eq!(
//     ///     d.checked_sub_signed(TimeDelta::try_days(-40).unwrap()),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 10, 15).unwrap())
//     /// );
//     /// assert_eq!(d.checked_sub_signed(TimeDelta::try_days(1_000_000_000).unwrap()), None);
//     /// assert_eq!(d.checked_sub_signed(TimeDelta::try_days(-1_000_000_000).unwrap()), None);
//     /// assert_eq!(NaiveDate::MIN.checked_sub_signed(TimeDelta::try_days(1).unwrap()), None);
//     /// ```
//     #[must_use]
//     pub const fn checked_sub_signed(self, rhs: TimeDelta) -> Option<NaiveDate> {
//         let days = -rhs.num_days();
//         if days < i32::MIN as i64 || days > i32::MAX as i64 {
//             return None;
//         }
//         self.add_days(days as i32)
//     }

//     /// Subtracts another `NaiveDate` from the current date.
//     /// Returns a `TimeDelta` of integral numbers.
//     ///
//     /// This does not overflow or underflow at all,
//     /// as all possible output fits in the range of `TimeDelta`.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{NaiveDate, TimeDelta};
//     ///
//     /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     /// let since = NaiveDate::signed_duration_since;
//     ///
//     /// assert_eq!(since(from_ymd(2014, 1, 1), from_ymd(2014, 1, 1)), TimeDelta::zero());
//     /// assert_eq!(
//     ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 12, 31)),
//     ///     TimeDelta::try_days(1).unwrap()
//     /// );
//     /// assert_eq!(since(from_ymd(2014, 1, 1), from_ymd(2014, 1, 2)), TimeDelta::try_days(-1).unwrap());
//     /// assert_eq!(
//     ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 9, 23)),
//     ///     TimeDelta::try_days(100).unwrap()
//     /// );
//     /// assert_eq!(
//     ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 1, 1)),
//     ///     TimeDelta::try_days(365).unwrap()
//     /// );
//     /// assert_eq!(
//     ///     since(from_ymd(2014, 1, 1), from_ymd(2010, 1, 1)),
//     ///     TimeDelta::try_days(365 * 4 + 1).unwrap()
//     /// );
//     /// assert_eq!(
//     ///     since(from_ymd(2014, 1, 1), from_ymd(1614, 1, 1)),
//     ///     TimeDelta::try_days(365 * 400 + 97).unwrap()
//     /// );
//     /// ```
//     #[must_use]
//     pub const fn signed_duration_since(self, rhs: NaiveDate) -> TimeDelta {
//         let year1 = self.year();
//         let year2 = rhs.year();
//         let (year1_div_400, year1_mod_400) = div_mod_floor(year1, 400);
//         let (year2_div_400, year2_mod_400) = div_mod_floor(year2, 400);
//         let cycle1 = yo_to_cycle(year1_mod_400 as u32, self.ordinal()) as i64;
//         let cycle2 = yo_to_cycle(year2_mod_400 as u32, rhs.ordinal()) as i64;
//         let days = (year1_div_400 as i64 - year2_div_400 as i64) * 146_097 + (cycle1 - cycle2);
//         // The range of `TimeDelta` is ca. 585 million years, the range of `NaiveDate` ca. 525.000
//         // years.
//         expect(TimeDelta::try_days(days), "always in range")
//     }

//     /// Returns the number of whole years from the given `base` until `self`.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if `base > self`.
//     #[must_use]
//     pub const fn years_since(&self, base: Self) -> Option<u32> {
//         let mut years = self.year() - base.year();
//         // Comparing tuples is not (yet) possible in const context. Instead we combine month and
//         // day into one `u32` for easy comparison.
//         if ((self.month() << 5) | self.day()) < ((base.month() << 5) | base.day()) {
//             years -= 1;
//         }

//         match years >= 0 {
//             true => Some(years as u32),
//             false => None,
//         }
//     }

//     /// Formats the date with the specified formatting items.
//     /// Otherwise it is the same as the ordinary `format` method.
//     ///
//     /// The `Iterator` of items should be `Clone`able,
//     /// since the resulting `DelayedFormat` value may be formatted multiple times.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::format::strftime::StrftimeItems;
//     /// use chrono::NaiveDate;
//     ///
//     /// let fmt = StrftimeItems::new("%Y-%m-%d");
//     /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
//     /// assert_eq!(d.format_with_items(fmt.clone()).to_string(), "2015-09-05");
//     /// assert_eq!(d.format("%Y-%m-%d").to_string(), "2015-09-05");
//     /// ```
//     ///
//     /// The resulting `DelayedFormat` can be formatted directly via the `Display` trait.
//     ///
//     /// ```
//     /// # use chrono::NaiveDate;
//     /// # use chrono::format::strftime::StrftimeItems;
//     /// # let fmt = StrftimeItems::new("%Y-%m-%d").clone();
//     /// # let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
//     /// assert_eq!(format!("{}", d.format_with_items(fmt)), "2015-09-05");
//     /// ```
//     #[cfg(feature = "alloc")]
//     #[inline]
//     #[must_use]
//     pub fn format_with_items<'a, I, B>(&self, items: I) -> DelayedFormat<I>
//     where
//         I: Iterator<Item = B> + Clone,
//         B: Borrow<Item<'a>>,
//     {
//         DelayedFormat::new(Some(*self), None, items)
//     }

//     /// Formats the date with the specified format string.
//     /// See the [`format::strftime` module](crate::format::strftime)
//     /// on the supported escape sequences.
//     ///
//     /// This returns a `DelayedFormat`,
//     /// which gets converted to a string only when actual formatting happens.
//     /// You may use the `to_string` method to get a `String`,
//     /// or just feed it into `print!` and other formatting macros.
//     /// (In this way it avoids the redundant memory allocation.)
//     ///
//     /// # Panics
//     ///
//     /// Converting or formatting the returned `DelayedFormat` panics if the format string is wrong.
//     /// Because of this delayed failure, you are recommended to immediately use the `DelayedFormat`
//     /// value.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::NaiveDate;
//     ///
//     /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
//     /// assert_eq!(d.format("%Y-%m-%d").to_string(), "2015-09-05");
//     /// assert_eq!(d.format("%A, %-d %B, %C%y").to_string(), "Saturday, 5 September, 2015");
//     /// ```
//     ///
//     /// The resulting `DelayedFormat` can be formatted directly via the `Display` trait.
//     ///
//     /// ```
//     /// # use chrono::NaiveDate;
//     /// # let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
//     /// assert_eq!(format!("{}", d.format("%Y-%m-%d")), "2015-09-05");
//     /// assert_eq!(format!("{}", d.format("%A, %-d %B, %C%y")), "Saturday, 5 September, 2015");
//     /// ```
//     #[cfg(feature = "alloc")]
//     #[inline]
//     #[must_use]
//     pub fn format<'a>(&self, fmt: &'a str) -> DelayedFormat<StrftimeItems<'a>> {
//         self.format_with_items(StrftimeItems::new(fmt))
//     }

//     /// Formats the date with the specified formatting items and locale.
//     #[cfg(all(feature = "unstable-locales", feature = "alloc"))]
//     #[inline]
//     #[must_use]
//     pub fn format_localized_with_items<'a, I, B>(
//         &self,
//         items: I,
//         locale: Locale,
//     ) -> DelayedFormat<I>
//     where
//         I: Iterator<Item = B> + Clone,
//         B: Borrow<Item<'a>>,
//     {
//         DelayedFormat::new_with_locale(Some(*self), None, items, locale)
//     }

//     /// Formats the date with the specified format string and locale.
//     ///
//     /// See the [`crate::format::strftime`] module on the supported escape
//     /// sequences.
//     #[cfg(all(feature = "unstable-locales", feature = "alloc"))]
//     #[inline]
//     #[must_use]
//     pub fn format_localized<'a>(
//         &self,
//         fmt: &'a str,
//         locale: Locale,
//     ) -> DelayedFormat<StrftimeItems<'a>> {
//         self.format_localized_with_items(StrftimeItems::new_with_locale(fmt, locale), locale)
//     }

//     /// Returns an iterator that steps by days across all representable dates.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// # use chrono::NaiveDate;
//     ///
//     /// let expected = [
//     ///     NaiveDate::from_ymd_opt(2016, 2, 27).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 2, 28).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 2, 29).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 3, 1).unwrap(),
//     /// ];
//     ///
//     /// let mut count = 0;
//     /// for (idx, d) in NaiveDate::from_ymd_opt(2016, 2, 27).unwrap().iter_days().take(4).enumerate() {
//     ///     assert_eq!(d, expected[idx]);
//     ///     count += 1;
//     /// }
//     /// assert_eq!(count, 4);
//     ///
//     /// for d in NaiveDate::from_ymd_opt(2016, 3, 1).unwrap().iter_days().rev().take(4) {
//     ///     count -= 1;
//     ///     assert_eq!(d, expected[count]);
//     /// }
//     /// ```
//     #[inline]
//     pub const fn iter_days(&self) -> NaiveDateDaysIterator {
//         NaiveDateDaysIterator { value: *self }
//     }

//     /// Returns an iterator that steps by weeks across all representable dates.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// # use chrono::NaiveDate;
//     ///
//     /// let expected = [
//     ///     NaiveDate::from_ymd_opt(2016, 2, 27).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 3, 5).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 3, 12).unwrap(),
//     ///     NaiveDate::from_ymd_opt(2016, 3, 19).unwrap(),
//     /// ];
//     ///
//     /// let mut count = 0;
//     /// for (idx, d) in NaiveDate::from_ymd_opt(2016, 2, 27).unwrap().iter_weeks().take(4).enumerate() {
//     ///     assert_eq!(d, expected[idx]);
//     ///     count += 1;
//     /// }
//     /// assert_eq!(count, 4);
//     ///
//     /// for d in NaiveDate::from_ymd_opt(2016, 3, 19).unwrap().iter_weeks().rev().take(4) {
//     ///     count -= 1;
//     ///     assert_eq!(d, expected[count]);
//     /// }
//     /// ```
//     #[inline]
//     pub const fn iter_weeks(&self) -> NaiveDateWeeksIterator {
//         NaiveDateWeeksIterator { value: *self }
//     }

//     /// Returns the [`NaiveWeek`] that the date belongs to, starting with the [`Weekday`]
//     /// specified.
//     #[inline]
//     pub const fn week(&self, start: Weekday) -> NaiveWeek {
//         NaiveWeek::new(*self, start)
//     }

   



//     /// Counts the days in the proleptic Gregorian calendar, with January 1, Year 1 (CE) as day 1.
//     // This duplicates `Datelike::num_days_from_ce()`, because trait methods can't be const yet.
//     pub(crate) const fn num_days_from_ce(&self) -> i32 {
//         // we know this wouldn't overflow since year is limited to 1/2^13 of i32's full range.
//         let mut year = self.year() - 1;
//         let mut ndays = 0;
//         if year < 0 {
//             let excess = 1 + (-year) / 400;
//             year += excess * 400;
//             ndays -= excess * 146_097;
//         }
//         let div_100 = year / 100;
//         ndays += ((year * 1461) >> 2) - div_100 + (div_100 >> 2);
//         ndays + self.ordinal() as i32
//     }




//     /// One day before the minimum possible `NaiveDate` (December 31, 262145 BCE).
//     pub(crate) const BEFORE_MIN: NaiveDate =
//         NaiveDate::from_yof(((MIN_YEAR - 1) << 13) | (366 << 4) | 0o07 /* FE */);
//     /// One day after the maximum possible `NaiveDate` (January 1, 262143 CE).
//     pub(crate) const AFTER_MAX: NaiveDate =
//         NaiveDate::from_yof(((MAX_YEAR + 1) << 13) | (1 << 4) | 0o17 /* F */);
// }

// impl Datelike for NaiveDate {
//     /// Returns the year number in the [calendar date](#calendar-date).
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().year(), 2015);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().year(), -308); // 309 BCE
//     /// ```
//     #[inline]
//     fn year(&self) -> i32 {
//         self.year()
//     }

//     /// Returns the month number starting from 1.
//     ///
//     /// The return value ranges from 1 to 12.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().month(), 9);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().month(), 3);
//     /// ```
//     #[inline]
//     fn month(&self) -> u32 {
//         self.month()
//     }

//     /// Returns the month number starting from 0.
//     ///
//     /// The return value ranges from 0 to 11.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().month0(), 8);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().month0(), 2);
//     /// ```
//     #[inline]
//     fn month0(&self) -> u32 {
//         self.month() - 1
//     }

//     /// Returns the day of month starting from 1.
//     ///
//     /// The return value ranges from 1 to 31. (The last day of month differs by months.)
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().day(), 8);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().day(), 14);
//     /// ```
//     ///
//     /// Combined with [`NaiveDate::pred_opt`](#method.pred_opt),
//     /// one can determine the number of days in a particular month.
//     /// (Note that this panics when `year` is out of range.)
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// fn ndays_in_month(year: i32, month: u32) -> u32 {
//     ///     // the first day of the next month...
//     ///     let (y, m) = if month == 12 { (year + 1, 1) } else { (year, month + 1) };
//     ///     let d = NaiveDate::from_ymd_opt(y, m, 1).unwrap();
//     ///
//     ///     // ...is preceded by the last day of the original month
//     ///     d.pred_opt().unwrap().day()
//     /// }
//     ///
//     /// assert_eq!(ndays_in_month(2015, 8), 31);
//     /// assert_eq!(ndays_in_month(2015, 9), 30);
//     /// assert_eq!(ndays_in_month(2015, 12), 31);
//     /// assert_eq!(ndays_in_month(2016, 2), 29);
//     /// assert_eq!(ndays_in_month(2017, 2), 28);
//     /// ```
//     #[inline]
//     fn day(&self) -> u32 {
//         self.day()
//     }

//     /// Returns the day of month starting from 0.
//     ///
//     /// The return value ranges from 0 to 30. (The last day of month differs by months.)
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().day0(), 7);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().day0(), 13);
//     /// ```
//     #[inline]
//     fn day0(&self) -> u32 {
//         self.mdf().day() - 1
//     }

//     /// Returns the day of year starting from 1.
//     ///
//     /// The return value ranges from 1 to 366. (The last day of year differs by years.)
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().ordinal(), 251);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().ordinal(), 74);
//     /// ```
//     ///
//     /// Combined with [`NaiveDate::pred_opt`](#method.pred_opt),
//     /// one can determine the number of days in a particular year.
//     /// (Note that this panics when `year` is out of range.)
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// fn ndays_in_year(year: i32) -> u32 {
//     ///     // the first day of the next year...
//     ///     let d = NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap();
//     ///
//     ///     // ...is preceded by the last day of the original year
//     ///     d.pred_opt().unwrap().ordinal()
//     /// }
//     ///
//     /// assert_eq!(ndays_in_year(2015), 365);
//     /// assert_eq!(ndays_in_year(2016), 366);
//     /// assert_eq!(ndays_in_year(2017), 365);
//     /// assert_eq!(ndays_in_year(2000), 366);
//     /// assert_eq!(ndays_in_year(2100), 365);
//     /// ```
//     #[inline]
//     fn ordinal(&self) -> u32 {
//         ((self.yof() & ORDINAL_MASK) >> 4) as u32
//     }

//     /// Returns the day of year starting from 0.
//     ///
//     /// The return value ranges from 0 to 365. (The last day of year differs by years.)
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().ordinal0(), 250);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().ordinal0(), 73);
//     /// ```
//     #[inline]
//     fn ordinal0(&self) -> u32 {
//         self.ordinal() - 1
//     }

//     /// Returns the day of week.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate, Weekday};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().weekday(), Weekday::Tue);
//     /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().weekday(), Weekday::Fri);
//     /// ```
//     #[inline]
//     fn weekday(&self) -> Weekday {
//         self.weekday()
//     }



//     /// Makes a new `NaiveDate` with the year number changed, while keeping the same month and day.
//     ///
//     /// This method assumes you want to work on the date as a year-month-day value. Don't use it if
//     /// you want the ordinal to stay the same after changing the year, of if you want the week and
//     /// weekday values to stay the same.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (February 29 in a non-leap year).
//     /// - The year is out of range for a `NaiveDate`.
//     ///
//     /// # Examples
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_year(2016),
//     ///     Some(NaiveDate::from_ymd_opt(2016, 9, 8).unwrap())
//     /// );
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_year(-308),
//     ///     Some(NaiveDate::from_ymd_opt(-308, 9, 8).unwrap())
//     /// );
//     /// ```
//     ///
//     /// A leap day (February 29) is a case where this method can return `None`.
//     ///
//     /// ```
//     /// # use chrono::{NaiveDate, Datelike};
//     /// assert!(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap().with_year(2015).is_none());
//     /// assert!(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap().with_year(2020).is_some());
//     /// ```
//     ///
//     /// Don't use `with_year` if you want the ordinal date to stay the same:
//     ///
//     /// ```
//     /// # use chrono::{Datelike, NaiveDate};
//     /// assert_ne!(
//     ///     NaiveDate::from_yo_opt(2020, 100).unwrap().with_year(2023).unwrap(),
//     ///     NaiveDate::from_yo_opt(2023, 100).unwrap() // result is 2023-101
//     /// );
//     /// ```
//     #[inline]
//     fn with_year(&self, year: i32) -> Option<NaiveDate> {
//         // we need to operate with `mdf` since we should keep the month and day number as is
//         let mdf = self.mdf();

//         // adjust the flags as needed
//         let flags = YearFlags::from_year(year);
//         let mdf = mdf.with_flags(flags);

//         NaiveDate::from_mdf(year, mdf)
//     }

//     /// Makes a new `NaiveDate` with the month number (starting from 1) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (for example `month(4)` when day of the month is 31).
//     /// - The value for `month` is invalid.
//     ///
//     /// # Examples
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month(10),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 10, 8).unwrap())
//     /// );
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month(13), None); // No month 13
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().with_month(2), None); // No Feb 30
//     /// ```
//     ///
//     /// Don't combine multiple `Datelike::with_*` methods. The intermediate value may not exist.
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// fn with_year_month(date: NaiveDate, year: i32, month: u32) -> Option<NaiveDate> {
//     ///     date.with_year(year)?.with_month(month)
//     /// }
//     /// let d = NaiveDate::from_ymd_opt(2020, 2, 29).unwrap();
//     /// assert!(with_year_month(d, 2019, 1).is_none()); // fails because of invalid intermediate value
//     ///
//     /// // Correct version:
//     /// fn with_year_month_fixed(date: NaiveDate, year: i32, month: u32) -> Option<NaiveDate> {
//     ///     NaiveDate::from_ymd_opt(year, month, date.day())
//     /// }
//     /// let d = NaiveDate::from_ymd_opt(2020, 2, 29).unwrap();
//     /// assert_eq!(with_year_month_fixed(d, 2019, 1), NaiveDate::from_ymd_opt(2019, 1, 29));
//     /// ```
//     #[inline]
//     fn with_month(&self, month: u32) -> Option<NaiveDate> {
//         self.with_mdf(self.mdf().with_month(month)?)
//     }

//     /// Makes a new `NaiveDate` with the month number (starting from 0) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (for example `month0(3)` when day of the month is 31).
//     /// - The value for `month0` is invalid.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month0(9),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 10, 8).unwrap())
//     /// );
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month0(12), None); // No month 12
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().with_month0(1), None); // No Feb 30
//     /// ```
//     #[inline]
//     fn with_month0(&self, month0: u32) -> Option<NaiveDate> {
//         let month = month0.checked_add(1)?;
//         self.with_mdf(self.mdf().with_month(month)?)
//     }

//     /// Makes a new `NaiveDate` with the day of month (starting from 1) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (for example `day(31)` in April).
//     /// - The value for `day` is invalid.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day(30),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap())
//     /// );
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day(31), None);
//     /// // no September 31
//     /// ```
//     #[inline]
//     fn with_day(&self, day: u32) -> Option<NaiveDate> {
//         self.with_mdf(self.mdf().with_day(day)?)
//     }

//     /// Makes a new `NaiveDate` with the day of month (starting from 0) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (for example `day(30)` in April).
//     /// - The value for `day0` is invalid.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{Datelike, NaiveDate};
//     ///
//     /// assert_eq!(
//     ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day0(29),
//     ///     Some(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap())
//     /// );
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day0(30), None);
//     /// // no September 31
//     /// ```
//     #[inline]
//     fn with_day0(&self, day0: u32) -> Option<NaiveDate> {
//         let day = day0.checked_add(1)?;
//         self.with_mdf(self.mdf().with_day(day)?)
//     }

//     /// Makes a new `NaiveDate` with the day of year (starting from 1) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (`with_ordinal(366)` in a non-leap year).
//     /// - The value for `ordinal` is invalid.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{NaiveDate, Datelike};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal(60),
//     ///            Some(NaiveDate::from_ymd_opt(2015, 3, 1).unwrap()));
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal(366),
//     ///            None); // 2015 had only 365 days
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal(60),
//     ///            Some(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap()));
//     /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal(366),
//     ///            Some(NaiveDate::from_ymd_opt(2016, 12, 31).unwrap()));
//     /// ```
//     #[inline]
//     fn with_ordinal(&self, ordinal: u32) -> Option<NaiveDate> {
//         if ordinal == 0 || ordinal > 366 {
//             return None;
//         }
//         let yof = (self.yof() & !ORDINAL_MASK) | (ordinal << 4) as i32;
//         match yof & OL_MASK <= MAX_OL {
//             true => Some(NaiveDate::from_yof(yof)),
//             false => None, // Does not exist: Ordinal 366 in a common year.
//         }
//     }

//     /// Makes a new `NaiveDate` with the day of year (starting from 0) changed.
//     ///
//     /// # Errors
//     ///
//     /// Returns `None` if:
//     /// - The resulting date does not exist (`with_ordinal0(365)` in a non-leap year).
//     /// - The value for `ordinal0` is invalid.
//     ///
//     /// # Example
//     ///
//     /// ```
//     /// use chrono::{NaiveDate, Datelike};
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal0(59),
//     ///            Some(NaiveDate::from_ymd_opt(2015, 3, 1).unwrap()));
//     /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal0(365),
//     ///            None); // 2015 had only 365 days
//     ///
//     /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal0(59),
//     ///            Some(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap()));
//     /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal0(365),
//     ///            Some(NaiveDate::from_ymd_opt(2016, 12, 31).unwrap()));
//     /// ```
//     #[inline]
//     fn with_ordinal0(&self, ordinal0: u32) -> Option<NaiveDate> {
//         let ordinal = ordinal0.checked_add(1)?;
//         self.with_ordinal(ordinal)
//     }
// }

// /// Add `TimeDelta` to `NaiveDate`.
// ///
// /// This discards the fractional days in `TimeDelta`, rounding to the closest integral number of
// /// days towards `TimeDelta::zero()`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using [`NaiveDate::checked_add_signed`] to get an `Option` instead.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::{NaiveDate, TimeDelta};
// ///
// /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
// ///
// /// assert_eq!(from_ymd(2014, 1, 1) + TimeDelta::zero(), from_ymd(2014, 1, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) + TimeDelta::try_seconds(86399).unwrap(), from_ymd(2014, 1, 1));
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) + TimeDelta::try_seconds(-86399).unwrap(),
// ///     from_ymd(2014, 1, 1)
// /// );
// /// assert_eq!(from_ymd(2014, 1, 1) + TimeDelta::try_days(1).unwrap(), from_ymd(2014, 1, 2));
// /// assert_eq!(from_ymd(2014, 1, 1) + TimeDelta::try_days(-1).unwrap(), from_ymd(2013, 12, 31));
// /// assert_eq!(from_ymd(2014, 1, 1) + TimeDelta::try_days(364).unwrap(), from_ymd(2014, 12, 31));
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) + TimeDelta::try_days(365 * 4 + 1).unwrap(),
// ///     from_ymd(2018, 1, 1)
// /// );
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) + TimeDelta::try_days(365 * 400 + 97).unwrap(),
// ///     from_ymd(2414, 1, 1)
// /// );
// /// ```
// ///
// /// [`NaiveDate::checked_add_signed`]: crate::NaiveDate::checked_add_signed
// impl Add<TimeDelta> for NaiveDate {
//     type Output = NaiveDate;

//     #[inline]
//     fn add(self, rhs: TimeDelta) -> NaiveDate {
//         self.checked_add_signed(rhs).expect("`NaiveDate + TimeDelta` overflowed")
//     }
// }

// /// Add-assign of `TimeDelta` to `NaiveDate`.
// ///
// /// This discards the fractional days in `TimeDelta`, rounding to the closest integral number of days
// /// towards `TimeDelta::zero()`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using [`NaiveDate::checked_add_signed`] to get an `Option` instead.
// impl AddAssign<TimeDelta> for NaiveDate {
//     #[inline]
//     fn add_assign(&mut self, rhs: TimeDelta) {
//         *self = self.add(rhs);
//     }
// }

// /// Add `Months` to `NaiveDate`.
// ///
// /// The result will be clamped to valid days in the resulting month, see `checked_add_months` for
// /// details.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using `NaiveDate::checked_add_months` to get an `Option` instead.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::{Months, NaiveDate};
// ///
// /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
// ///
// /// assert_eq!(from_ymd(2014, 1, 1) + Months::new(1), from_ymd(2014, 2, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) + Months::new(11), from_ymd(2014, 12, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) + Months::new(12), from_ymd(2015, 1, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) + Months::new(13), from_ymd(2015, 2, 1));
// /// assert_eq!(from_ymd(2014, 1, 31) + Months::new(1), from_ymd(2014, 2, 28));
// /// assert_eq!(from_ymd(2020, 1, 31) + Months::new(1), from_ymd(2020, 2, 29));
// /// ```
// impl Add<Months> for NaiveDate {
//     type Output = NaiveDate;

//     fn add(self, months: Months) -> Self::Output {
//         self.checked_add_months(months).expect("`NaiveDate + Months` out of range")
//     }
// }

// /// Subtract `Months` from `NaiveDate`.
// ///
// /// The result will be clamped to valid days in the resulting month, see `checked_sub_months` for
// /// details.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using `NaiveDate::checked_sub_months` to get an `Option` instead.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::{Months, NaiveDate};
// ///
// /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
// ///
// /// assert_eq!(from_ymd(2014, 1, 1) - Months::new(11), from_ymd(2013, 2, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) - Months::new(12), from_ymd(2013, 1, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) - Months::new(13), from_ymd(2012, 12, 1));
// /// ```
// impl Sub<Months> for NaiveDate {
//     type Output = NaiveDate;

//     fn sub(self, months: Months) -> Self::Output {
//         self.checked_sub_months(months).expect("`NaiveDate - Months` out of range")
//     }
// }

// /// Add `Days` to `NaiveDate`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using `NaiveDate::checked_add_days` to get an `Option` instead.
// impl Add<Days> for NaiveDate {
//     type Output = NaiveDate;

//     fn add(self, days: Days) -> Self::Output {
//         self.checked_add_days(days).expect("`NaiveDate + Days` out of range")
//     }
// }

// /// Subtract `Days` from `NaiveDate`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using `NaiveDate::checked_sub_days` to get an `Option` instead.
// impl Sub<Days> for NaiveDate {
//     type Output = NaiveDate;

//     fn sub(self, days: Days) -> Self::Output {
//         self.checked_sub_days(days).expect("`NaiveDate - Days` out of range")
//     }
// }

// /// Subtract `TimeDelta` from `NaiveDate`.
// ///
// /// This discards the fractional days in `TimeDelta`, rounding to the closest integral number of
// /// days towards `TimeDelta::zero()`.
// /// It is the same as the addition with a negated `TimeDelta`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using [`NaiveDate::checked_sub_signed`] to get an `Option` instead.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::{NaiveDate, TimeDelta};
// ///
// /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
// ///
// /// assert_eq!(from_ymd(2014, 1, 1) - TimeDelta::zero(), from_ymd(2014, 1, 1));
// /// assert_eq!(from_ymd(2014, 1, 1) - TimeDelta::try_seconds(86399).unwrap(), from_ymd(2014, 1, 1));
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) - TimeDelta::try_seconds(-86399).unwrap(),
// ///     from_ymd(2014, 1, 1)
// /// );
// /// assert_eq!(from_ymd(2014, 1, 1) - TimeDelta::try_days(1).unwrap(), from_ymd(2013, 12, 31));
// /// assert_eq!(from_ymd(2014, 1, 1) - TimeDelta::try_days(-1).unwrap(), from_ymd(2014, 1, 2));
// /// assert_eq!(from_ymd(2014, 1, 1) - TimeDelta::try_days(364).unwrap(), from_ymd(2013, 1, 2));
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) - TimeDelta::try_days(365 * 4 + 1).unwrap(),
// ///     from_ymd(2010, 1, 1)
// /// );
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) - TimeDelta::try_days(365 * 400 + 97).unwrap(),
// ///     from_ymd(1614, 1, 1)
// /// );
// /// ```
// ///
// /// [`NaiveDate::checked_sub_signed`]: crate::NaiveDate::checked_sub_signed
// impl Sub<TimeDelta> for NaiveDate {
//     type Output = NaiveDate;

//     #[inline]
//     fn sub(self, rhs: TimeDelta) -> NaiveDate {
//         self.checked_sub_signed(rhs).expect("`NaiveDate - TimeDelta` overflowed")
//     }
// }

// /// Subtract-assign `TimeDelta` from `NaiveDate`.
// ///
// /// This discards the fractional days in `TimeDelta`, rounding to the closest integral number of
// /// days towards `TimeDelta::zero()`.
// /// It is the same as the addition with a negated `TimeDelta`.
// ///
// /// # Panics
// ///
// /// Panics if the resulting date would be out of range.
// /// Consider using [`NaiveDate::checked_sub_signed`] to get an `Option` instead.
// impl SubAssign<TimeDelta> for NaiveDate {
//     #[inline]
//     fn sub_assign(&mut self, rhs: TimeDelta) {
//         *self = self.sub(rhs);
//     }
// }

// /// Subtracts another `NaiveDate` from the current date.
// /// Returns a `TimeDelta` of integral numbers.
// ///
// /// This does not overflow or underflow at all,
// /// as all possible output fits in the range of `TimeDelta`.
// ///
// /// The implementation is a wrapper around
// /// [`NaiveDate::signed_duration_since`](#method.signed_duration_since).
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::{NaiveDate, TimeDelta};
// ///
// /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
// ///
// /// assert_eq!(from_ymd(2014, 1, 1) - from_ymd(2014, 1, 1), TimeDelta::zero());
// /// assert_eq!(from_ymd(2014, 1, 1) - from_ymd(2013, 12, 31), TimeDelta::try_days(1).unwrap());
// /// assert_eq!(from_ymd(2014, 1, 1) - from_ymd(2014, 1, 2), TimeDelta::try_days(-1).unwrap());
// /// assert_eq!(from_ymd(2014, 1, 1) - from_ymd(2013, 9, 23), TimeDelta::try_days(100).unwrap());
// /// assert_eq!(from_ymd(2014, 1, 1) - from_ymd(2013, 1, 1), TimeDelta::try_days(365).unwrap());
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) - from_ymd(2010, 1, 1),
// ///     TimeDelta::try_days(365 * 4 + 1).unwrap()
// /// );
// /// assert_eq!(
// ///     from_ymd(2014, 1, 1) - from_ymd(1614, 1, 1),
// ///     TimeDelta::try_days(365 * 400 + 97).unwrap()
// /// );
// /// ```
// impl Sub<NaiveDate> for NaiveDate {
//     type Output = TimeDelta;

//     #[inline]
//     fn sub(self, rhs: NaiveDate) -> TimeDelta {
//         self.signed_duration_since(rhs)
//     }
// }

// impl From<NaiveDateTime> for NaiveDate {
//     fn from(naive_datetime: NaiveDateTime) -> Self {
//         naive_datetime.date()
//     }
// }

// /// Iterator over `NaiveDate` with a step size of one day.
// #[derive(Debug, Copy, Clone, Hash, PartialEq, PartialOrd, Eq, Ord)]
// pub struct NaiveDateDaysIterator {
//     value: NaiveDate,
// }

// impl Iterator for NaiveDateDaysIterator {
//     type Item = NaiveDate;

//     fn next(&mut self) -> Option<Self::Item> {
//         // We return the current value, and have no way to return `NaiveDate::MAX`.
//         let current = self.value;
//         // This can't panic because current is < NaiveDate::MAX:
//         self.value = current.succ_opt()?;
//         Some(current)
//     }

//     fn size_hint(&self) -> (usize, Option<usize>) {
//         let exact_size = NaiveDate::MAX.signed_duration_since(self.value).num_days();
//         (exact_size as usize, Some(exact_size as usize))
//     }
// }

// impl ExactSizeIterator for NaiveDateDaysIterator {}

// impl DoubleEndedIterator for NaiveDateDaysIterator {
//     fn next_back(&mut self) -> Option<Self::Item> {
//         // We return the current value, and have no way to return `NaiveDate::MIN`.
//         let current = self.value;
//         self.value = current.pred_opt()?;
//         Some(current)
//     }
// }

// impl FusedIterator for NaiveDateDaysIterator {}

// /// Iterator over `NaiveDate` with a step size of one week.
// #[derive(Debug, Copy, Clone, Hash, PartialEq, PartialOrd, Eq, Ord)]
// pub struct NaiveDateWeeksIterator {
//     value: NaiveDate,
// }

// impl Iterator for NaiveDateWeeksIterator {
//     type Item = NaiveDate;

//     fn next(&mut self) -> Option<Self::Item> {
//         let current = self.value;
//         self.value = current.checked_add_days(Days::new(7))?;
//         Some(current)
//     }

//     fn size_hint(&self) -> (usize, Option<usize>) {
//         let exact_size = NaiveDate::MAX.signed_duration_since(self.value).num_weeks();
//         (exact_size as usize, Some(exact_size as usize))
//     }
// }

// impl ExactSizeIterator for NaiveDateWeeksIterator {}

// impl DoubleEndedIterator for NaiveDateWeeksIterator {
//     fn next_back(&mut self) -> Option<Self::Item> {
//         let current = self.value;
//         self.value = current.checked_sub_days(Days::new(7))?;
//         Some(current)
//     }
// }

// impl FusedIterator for NaiveDateWeeksIterator {}

// /// The `Debug` output of the naive date `d` is the same as
// /// [`d.format("%Y-%m-%d")`](crate::format::strftime).
// ///
// /// The string printed can be readily parsed via the `parse` method on `str`.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::NaiveDate;
// ///
// /// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(2015, 9, 5).unwrap()), "2015-09-05");
// /// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(0, 1, 1).unwrap()), "0000-01-01");
// /// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(9999, 12, 31).unwrap()), "9999-12-31");
// /// ```
// ///
// /// ISO 8601 requires an explicit sign for years before 1 BCE or after 9999 CE.
// ///
// /// ```
// /// # use chrono::NaiveDate;
// /// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(-1, 1, 1).unwrap()), "-0001-01-01");
// /// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(10000, 12, 31).unwrap()), "+10000-12-31");
// /// ```
// impl fmt::Debug for NaiveDate {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         use core::fmt::Write;

//         let year = self.year();
//         let mdf = self.mdf();
//         if (0..=9999).contains(&year) {
//             write_hundreds(f, (year / 100) as u8)?;
//             write_hundreds(f, (year % 100) as u8)?;
//         } else {
//             // ISO 8601 requires the explicit sign for out-of-range years
//             write!(f, "{:+05}", year)?;
//         }

//         f.write_char('-')?;
//         write_hundreds(f, mdf.month() as u8)?;
//         f.write_char('-')?;
//         write_hundreds(f, mdf.day() as u8)
//     }
// }

// /// The `Display` output of the naive date `d` is the same as
// /// [`d.format("%Y-%m-%d")`](crate::format::strftime).
// ///
// /// The string printed can be readily parsed via the `parse` method on `str`.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::NaiveDate;
// ///
// /// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(2015, 9, 5).unwrap()), "2015-09-05");
// /// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(0, 1, 1).unwrap()), "0000-01-01");
// /// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(9999, 12, 31).unwrap()), "9999-12-31");
// /// ```
// ///
// /// ISO 8601 requires an explicit sign for years before 1 BCE or after 9999 CE.
// ///
// /// ```
// /// # use chrono::NaiveDate;
// /// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(-1, 1, 1).unwrap()), "-0001-01-01");
// /// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(10000, 12, 31).unwrap()), "+10000-12-31");
// /// ```
// impl fmt::Display for NaiveDate {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         fmt::Debug::fmt(self, f)
//     }
// }

// /// Parsing a `str` into a `NaiveDate` uses the same format,
// /// [`%Y-%m-%d`](crate::format::strftime), as in `Debug` and `Display`.
// ///
// /// # Example
// ///
// /// ```
// /// use chrono::NaiveDate;
// ///
// /// let d = NaiveDate::from_ymd_opt(2015, 9, 18).unwrap();
// /// assert_eq!("2015-09-18".parse::<NaiveDate>(), Ok(d));
// ///
// /// let d = NaiveDate::from_ymd_opt(12345, 6, 7).unwrap();
// /// assert_eq!("+12345-6-7".parse::<NaiveDate>(), Ok(d));
// ///
// /// assert!("foo".parse::<NaiveDate>().is_err());
// /// ```
// impl str::FromStr for NaiveDate {
//     type Err = ParseError;

//     fn from_str(s: &str) -> ParseResult<NaiveDate> {
//         const ITEMS: &[Item<'static>] = &[
//             Item::Numeric(Numeric::Year, Pad::Zero),
//             Item::Space(""),
//             Item::Literal("-"),
//             Item::Numeric(Numeric::Month, Pad::Zero),
//             Item::Space(""),
//             Item::Literal("-"),
//             Item::Numeric(Numeric::Day, Pad::Zero),
//             Item::Space(""),
//         ];

//         let mut parsed = Parsed::new();
//         parse(&mut parsed, s, ITEMS.iter())?;
//         parsed.to_naive_date()
//     }
// }

/// The default value for a NaiveDate is 1st of January 1970.
///
/// # Example
///
/// ```rust
/// use chrono::NaiveDate;
///
/// let default_date = NaiveDate::default();
/// assert_eq!(default_date, NaiveDate::from_ymd_opt(1970, 1, 1).unwrap());
/// ```
// impl Default for NaiveDate {
//     fn default() -> Self {
//         NaiveDate::from_ymd_opt(1970, 1, 1).unwrap()
//     }
// }

fn cycle_to_yo(cycle: u32) struct {u32, u32} {
    var year_mod_400 = cycle / 365;
    var ordinal0 = cycle % 365;
    const delta = YEAR_DELTAS[year_mod_400];
    if (ordinal0 < delta) {
        year_mod_400 -= 1;
        ordinal0 += 365 - YEAR_DELTAS[year_mod_400];
    } else {
        ordinal0 -= delta;
    }
    return .{(year_mod_400), (ordinal0 + 1)};
}

fn yo_to_cycle(year_mod_400: u32, ordinal: u32) u32 {
    return year_mod_400 * 365 + YEAR_DELTAS[year_mod_400] + ordinal - 1;
}


fn div_mod_floor(this: i32, other: i32) struct {i32, i32} {
    const _div_euclid = div_euclid(i32, this, other) catch unreachable;
    const _rem_euclid = rem_euclid(i32,  this, other) catch unreachable;

    return .{_div_euclid, _rem_euclid};
}

/// MAX_YEAR is one year less than the type is capable of representing. Internally we may sometimes
/// use the headroom, notably to handle cases where the offset of a `DateTime` constructed with
/// `NaiveDate::MAX` pushes it beyond the valid, representable range.
pub const MAX_YEAR: i32 = (std.math.maxInt(i32) >> 13) - 1;

/// MIN_YEAR is one year more than the type is capable of representing. Internally we may sometimes
/// use the headroom, notably to handle cases where the offset of a `DateTime` constructed with
/// `NaiveDate::MIN` pushes it beyond the valid, representable range.
pub const MIN_YEAR: i32 = (std.math.minInt(i32) >> 13) + 1;

const ORDINAL_MASK: i32 = 0b1_1111_1111_0000;

const LEAP_YEAR_MASK: i32 = 0b1000;

// OL: ordinal and leap year flag.
// With only these parts of the date an ordinal 366 in a common year would be encoded as
// `((366 << 1) | 1) << 3`, and in a leap year as `((366 << 1) | 0) << 3`, which is less.
// This allows for efficiently checking the ordinal exists depending on whether this is a leap year.
const OL_MASK: i32 = ORDINAL_MASK | LEAP_YEAR_MASK;
const MAX_OL: i32 = 366 << 4;

// Weekday of the last day in the preceding year.
// Allows for quick day of week calculation from the 1-based ordinal.
const WEEKDAY_FLAGS_MASK: i32 = 0b111;

const YEAR_FLAGS_MASK: i32 = LEAP_YEAR_MASK | WEEKDAY_FLAGS_MASK;

const YEAR_DELTAS = [_]i32{
    0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8,
    8, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14,
    15, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20,
    21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 25, 25, 25, // 100
    25, 25, 25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29, 29, 30, 30, 30,
    30, 31, 31, 31, 31, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34, 34, 35, 35, 35, 35, 36, 36, 36,
    36, 37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39, 39, 40, 40, 40, 40, 41, 41, 41, 41, 42, 42, 42,
    42, 43, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48,
    48, 49, 49, 49, // 200
    49, 49, 49, 49, 49, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53, 53, 54, 54, 54,
    54, 55, 55, 55, 55, 56, 56, 56, 56, 57, 57, 57, 57, 58, 58, 58, 58, 59, 59, 59, 59, 60, 60, 60,
    60, 61, 61, 61, 61, 62, 62, 62, 62, 63, 63, 63, 63, 64, 64, 64, 64, 65, 65, 65, 65, 66, 66, 66,
    66, 67, 67, 67, 67, 68, 68, 68, 68, 69, 69, 69, 69, 70, 70, 70, 70, 71, 71, 71, 71, 72, 72, 72,
    72, 73, 73, 73, // 300
    73, 73, 73, 73, 73, 74, 74, 74, 74, 75, 75, 75, 75, 76, 76, 76, 76, 77, 77, 77, 77, 78, 78, 78,
    78, 79, 79, 79, 79, 80, 80, 80, 80, 81, 81, 81, 81, 82, 82, 82, 82, 83, 83, 83, 83, 84, 84, 84,
    84, 85, 85, 85, 85, 86, 86, 86, 86, 87, 87, 87, 87, 88, 88, 88, 88, 89, 89, 89, 89, 90, 90, 90,
    90, 91, 91, 91, 91, 92, 92, 92, 92, 93, 93, 93, 93, 94, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96,
    96, 97, 97, 97, 97, // 400+1
};


// extra test
// use super::{Days, MAX_YEAR, MIN_YEAR, Months, NaiveDate};
// use crate::naive::internals::{A, AG, B, BA, C, CB, D, DC, E, ED, F, FE, G, GF, YearFlags};
// use crate::{Datelike, TimeDelta, Weekday};

// // as it is hard to verify year flags in `NaiveDate::MIN` and `NaiveDate::MAX`,
// // we use a separate run-time test.
// #[test]
// fn test_date_bounds() {
//     let calculated_min = NaiveDate::from_ymd_opt(MIN_YEAR, 1, 1).unwrap();
//     let calculated_max = NaiveDate::from_ymd_opt(MAX_YEAR, 12, 31).unwrap();
//     assert!(
//         NaiveDate::MIN == calculated_min,
//         "`NaiveDate::MIN` should have year flag {:?}",
//         calculated_min.year_flags()
//     );
//     assert!(
//         NaiveDate::MAX == calculated_max,
//         "`NaiveDate::MAX` should have year flag {:?} and ordinal {}",
//         calculated_max.year_flags(),
//         calculated_max.ordinal()
//     );

//     // let's also check that the entire range do not exceed 2^44 seconds
//     // (sometimes used for bounding `TimeDelta` against overflow)
//     let maxsecs = NaiveDate::MAX.signed_duration_since(NaiveDate::MIN).num_seconds();
//     let maxsecs = maxsecs + 86401; // also take care of DateTime
//     assert!(
//         maxsecs < (1 << MAX_BITS),
//         "The entire `NaiveDate` range somehow exceeds 2^{} seconds",
//         MAX_BITS
//     );

//     const BEFORE_MIN: NaiveDate = NaiveDate::BEFORE_MIN;
//     assert_eq!(BEFORE_MIN.year_flags(), YearFlags::from_year(BEFORE_MIN.year()));
//     assert_eq!((BEFORE_MIN.month(), BEFORE_MIN.day()), (12, 31));

//     const AFTER_MAX: NaiveDate = NaiveDate::AFTER_MAX;
//     assert_eq!(AFTER_MAX.year_flags(), YearFlags::from_year(AFTER_MAX.year()));
//     assert_eq!((AFTER_MAX.month(), AFTER_MAX.day()), (1, 1));
// }

// #[test]
// fn diff_months() {
//     // identity
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(Months::new(0)),
//         Some(NaiveDate::from_ymd_opt(2022, 8, 3).unwrap())
//     );

//     // add with months exceeding `i32::MAX`
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3)
//             .unwrap()
//             .checked_add_months(Months::new(i32::MAX as u32 + 1)),
//         None
//     );

//     // sub with months exceeding `i32::MIN`
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3)
//             .unwrap()
//             .checked_sub_months(Months::new(i32::MIN.unsigned_abs() + 1)),
//         None
//     );

//     // add overflowing year
//     assert_eq!(NaiveDate::MAX.checked_add_months(Months::new(1)), None);

//     // add underflowing year
//     assert_eq!(NaiveDate::MIN.checked_sub_months(Months::new(1)), None);

//     // sub crossing year 0 boundary
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(Months::new(2050 * 12)),
//         Some(NaiveDate::from_ymd_opt(-28, 8, 3).unwrap())
//     );

//     // add crossing year boundary
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(Months::new(6)),
//         Some(NaiveDate::from_ymd_opt(2023, 2, 3).unwrap())
//     );

//     // sub crossing year boundary
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(Months::new(10)),
//         Some(NaiveDate::from_ymd_opt(2021, 10, 3).unwrap())
//     );

//     // add clamping day, non-leap year
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 1, 29).unwrap().checked_add_months(Months::new(1)),
//         Some(NaiveDate::from_ymd_opt(2022, 2, 28).unwrap())
//     );

//     // add to leap day
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 10, 29).unwrap().checked_add_months(Months::new(16)),
//         Some(NaiveDate::from_ymd_opt(2024, 2, 29).unwrap())
//     );

//     // add into december
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 10, 31).unwrap().checked_add_months(Months::new(2)),
//         Some(NaiveDate::from_ymd_opt(2022, 12, 31).unwrap())
//     );

//     // sub into december
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 10, 31).unwrap().checked_sub_months(Months::new(10)),
//         Some(NaiveDate::from_ymd_opt(2021, 12, 31).unwrap())
//     );

//     // add into january
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(Months::new(5)),
//         Some(NaiveDate::from_ymd_opt(2023, 1, 3).unwrap())
//     );

//     // sub into january
//     assert_eq!(
//         NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(Months::new(7)),
//         Some(NaiveDate::from_ymd_opt(2022, 1, 3).unwrap())
//     );
// }

// #[test]
// fn test_readme_doomsday() {
//     for y in NaiveDate::MIN.year()..=NaiveDate::MAX.year() {
//         // even months
//         let d4 = NaiveDate::from_ymd_opt(y, 4, 4).unwrap();
//         let d6 = NaiveDate::from_ymd_opt(y, 6, 6).unwrap();
//         let d8 = NaiveDate::from_ymd_opt(y, 8, 8).unwrap();
//         let d10 = NaiveDate::from_ymd_opt(y, 10, 10).unwrap();
//         let d12 = NaiveDate::from_ymd_opt(y, 12, 12).unwrap();

//         // nine to five, seven-eleven
//         let d59 = NaiveDate::from_ymd_opt(y, 5, 9).unwrap();
//         let d95 = NaiveDate::from_ymd_opt(y, 9, 5).unwrap();
//         let d711 = NaiveDate::from_ymd_opt(y, 7, 11).unwrap();
//         let d117 = NaiveDate::from_ymd_opt(y, 11, 7).unwrap();

//         // "March 0"
//         let d30 = NaiveDate::from_ymd_opt(y, 3, 1).unwrap().pred_opt().unwrap();

//         let weekday = d30.weekday();
//         let other_dates = [d4, d6, d8, d10, d12, d59, d95, d711, d117];
//         assert!(other_dates.iter().all(|d| d.weekday() == weekday));
//     }
// }

// #[test]
// fn test_date_from_ymd() {
//     let from_ymd = NaiveDate::from_ymd_opt;

//     assert!(from_ymd(2012, 0, 1).is_none());
//     assert!(from_ymd(2012, 1, 1).is_some());
//     assert!(from_ymd(2012, 2, 29).is_some());
//     assert!(from_ymd(2014, 2, 29).is_none());
//     assert!(from_ymd(2014, 3, 0).is_none());
//     assert!(from_ymd(2014, 3, 1).is_some());
//     assert!(from_ymd(2014, 3, 31).is_some());
//     assert!(from_ymd(2014, 3, 32).is_none());
//     assert!(from_ymd(2014, 12, 31).is_some());
//     assert!(from_ymd(2014, 13, 1).is_none());
// }

// #[test]
// fn test_date_from_yo() {
//     let from_yo = NaiveDate::from_yo_opt;
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();

//     assert_eq!(from_yo(2012, 0), None);
//     assert_eq!(from_yo(2012, 1), Some(ymd(2012, 1, 1)));
//     assert_eq!(from_yo(2012, 2), Some(ymd(2012, 1, 2)));
//     assert_eq!(from_yo(2012, 32), Some(ymd(2012, 2, 1)));
//     assert_eq!(from_yo(2012, 60), Some(ymd(2012, 2, 29)));
//     assert_eq!(from_yo(2012, 61), Some(ymd(2012, 3, 1)));
//     assert_eq!(from_yo(2012, 100), Some(ymd(2012, 4, 9)));
//     assert_eq!(from_yo(2012, 200), Some(ymd(2012, 7, 18)));
//     assert_eq!(from_yo(2012, 300), Some(ymd(2012, 10, 26)));
//     assert_eq!(from_yo(2012, 366), Some(ymd(2012, 12, 31)));
//     assert_eq!(from_yo(2012, 367), None);
//     assert_eq!(from_yo(2012, (1 << 28) | 60), None);

//     assert_eq!(from_yo(2014, 0), None);
//     assert_eq!(from_yo(2014, 1), Some(ymd(2014, 1, 1)));
//     assert_eq!(from_yo(2014, 2), Some(ymd(2014, 1, 2)));
//     assert_eq!(from_yo(2014, 32), Some(ymd(2014, 2, 1)));
//     assert_eq!(from_yo(2014, 59), Some(ymd(2014, 2, 28)));
//     assert_eq!(from_yo(2014, 60), Some(ymd(2014, 3, 1)));
//     assert_eq!(from_yo(2014, 100), Some(ymd(2014, 4, 10)));
//     assert_eq!(from_yo(2014, 200), Some(ymd(2014, 7, 19)));
//     assert_eq!(from_yo(2014, 300), Some(ymd(2014, 10, 27)));
//     assert_eq!(from_yo(2014, 365), Some(ymd(2014, 12, 31)));
//     assert_eq!(from_yo(2014, 366), None);
// }

// #[test]
// fn test_date_from_isoywd() {
//     let from_isoywd = NaiveDate::from_isoywd_opt;
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();

//     assert_eq!(from_isoywd(2004, 0, Weekday::Sun), None);
//     assert_eq!(from_isoywd(2004, 1, Weekday::Mon), Some(ymd(2003, 12, 29)));
//     assert_eq!(from_isoywd(2004, 1, Weekday::Sun), Some(ymd(2004, 1, 4)));
//     assert_eq!(from_isoywd(2004, 2, Weekday::Mon), Some(ymd(2004, 1, 5)));
//     assert_eq!(from_isoywd(2004, 2, Weekday::Sun), Some(ymd(2004, 1, 11)));
//     assert_eq!(from_isoywd(2004, 52, Weekday::Mon), Some(ymd(2004, 12, 20)));
//     assert_eq!(from_isoywd(2004, 52, Weekday::Sun), Some(ymd(2004, 12, 26)));
//     assert_eq!(from_isoywd(2004, 53, Weekday::Mon), Some(ymd(2004, 12, 27)));
//     assert_eq!(from_isoywd(2004, 53, Weekday::Sun), Some(ymd(2005, 1, 2)));
//     assert_eq!(from_isoywd(2004, 54, Weekday::Mon), None);

//     assert_eq!(from_isoywd(2011, 0, Weekday::Sun), None);
//     assert_eq!(from_isoywd(2011, 1, Weekday::Mon), Some(ymd(2011, 1, 3)));
//     assert_eq!(from_isoywd(2011, 1, Weekday::Sun), Some(ymd(2011, 1, 9)));
//     assert_eq!(from_isoywd(2011, 2, Weekday::Mon), Some(ymd(2011, 1, 10)));
//     assert_eq!(from_isoywd(2011, 2, Weekday::Sun), Some(ymd(2011, 1, 16)));

//     assert_eq!(from_isoywd(2018, 51, Weekday::Mon), Some(ymd(2018, 12, 17)));
//     assert_eq!(from_isoywd(2018, 51, Weekday::Sun), Some(ymd(2018, 12, 23)));
//     assert_eq!(from_isoywd(2018, 52, Weekday::Mon), Some(ymd(2018, 12, 24)));
//     assert_eq!(from_isoywd(2018, 52, Weekday::Sun), Some(ymd(2018, 12, 30)));
//     assert_eq!(from_isoywd(2018, 53, Weekday::Mon), None);
// }

// #[test]
// fn test_date_from_isoywd_and_iso_week() {
//     for year in 2000..2401 {
//         for week in 1..54 {
//             for &weekday in [
//                 Weekday::Mon,
//                 Weekday::Tue,
//                 Weekday::Wed,
//                 Weekday::Thu,
//                 Weekday::Fri,
//                 Weekday::Sat,
//                 Weekday::Sun,
//             ]
//             .iter()
//             {
//                 let d = NaiveDate::from_isoywd_opt(year, week, weekday);
//                 if let Some(d) = d {
//                     assert_eq!(d.weekday(), weekday);
//                     let w = d.iso_week();
//                     assert_eq!(w.year(), year);
//                     assert_eq!(w.week(), week);
//                 }
//             }
//         }
//     }

//     for year in 2000..2401 {
//         for month in 1..13 {
//             for day in 1..32 {
//                 let d = NaiveDate::from_ymd_opt(year, month, day);
//                 if let Some(d) = d {
//                     let w = d.iso_week();
//                     let d_ = NaiveDate::from_isoywd_opt(w.year(), w.week(), d.weekday());
//                     assert_eq!(d, d_.unwrap());
//                 }
//             }
//         }
//     }
// }

// #[test]
// fn test_date_from_num_days_from_ce() {
//     let from_ndays_from_ce = NaiveDate::from_num_days_from_ce_opt;
//     assert_eq!(from_ndays_from_ce(1), Some(NaiveDate::from_ymd_opt(1, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(2), Some(NaiveDate::from_ymd_opt(1, 1, 2).unwrap()));
//     assert_eq!(from_ndays_from_ce(31), Some(NaiveDate::from_ymd_opt(1, 1, 31).unwrap()));
//     assert_eq!(from_ndays_from_ce(32), Some(NaiveDate::from_ymd_opt(1, 2, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(59), Some(NaiveDate::from_ymd_opt(1, 2, 28).unwrap()));
//     assert_eq!(from_ndays_from_ce(60), Some(NaiveDate::from_ymd_opt(1, 3, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(365), Some(NaiveDate::from_ymd_opt(1, 12, 31).unwrap()));
//     assert_eq!(from_ndays_from_ce(365 + 1), Some(NaiveDate::from_ymd_opt(2, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(365 * 2 + 1), Some(NaiveDate::from_ymd_opt(3, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(365 * 3 + 1), Some(NaiveDate::from_ymd_opt(4, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(365 * 4 + 2), Some(NaiveDate::from_ymd_opt(5, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(146097 + 1), Some(NaiveDate::from_ymd_opt(401, 1, 1).unwrap()));
//     assert_eq!(
//         from_ndays_from_ce(146097 * 5 + 1),
//         Some(NaiveDate::from_ymd_opt(2001, 1, 1).unwrap())
//     );
//     assert_eq!(from_ndays_from_ce(719163), Some(NaiveDate::from_ymd_opt(1970, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(0), Some(NaiveDate::from_ymd_opt(0, 12, 31).unwrap())); // 1 BCE
//     assert_eq!(from_ndays_from_ce(-365), Some(NaiveDate::from_ymd_opt(0, 1, 1).unwrap()));
//     assert_eq!(from_ndays_from_ce(-366), Some(NaiveDate::from_ymd_opt(-1, 12, 31).unwrap())); // 2 BCE

//     for days in (-9999..10001).map(|x| x * 100) {
//         assert_eq!(from_ndays_from_ce(days).map(|d| d.num_days_from_ce()), Some(days));
//     }

//     assert_eq!(from_ndays_from_ce(NaiveDate::MIN.num_days_from_ce()), Some(NaiveDate::MIN));
//     assert_eq!(from_ndays_from_ce(NaiveDate::MIN.num_days_from_ce() - 1), None);
//     assert_eq!(from_ndays_from_ce(NaiveDate::MAX.num_days_from_ce()), Some(NaiveDate::MAX));
//     assert_eq!(from_ndays_from_ce(NaiveDate::MAX.num_days_from_ce() + 1), None);

//     assert_eq!(from_ndays_from_ce(i32::MIN), None);
//     assert_eq!(from_ndays_from_ce(i32::MAX), None);
// }

// #[test]
// fn test_date_from_weekday_of_month_opt() {
//     let ymwd = NaiveDate::from_weekday_of_month_opt;
//     assert_eq!(ymwd(2018, 8, Weekday::Tue, 0), None);
//     assert_eq!(ymwd(2018, 8, Weekday::Wed, 1), Some(NaiveDate::from_ymd_opt(2018, 8, 1).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Thu, 1), Some(NaiveDate::from_ymd_opt(2018, 8, 2).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Sun, 1), Some(NaiveDate::from_ymd_opt(2018, 8, 5).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Mon, 1), Some(NaiveDate::from_ymd_opt(2018, 8, 6).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Tue, 1), Some(NaiveDate::from_ymd_opt(2018, 8, 7).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Wed, 2), Some(NaiveDate::from_ymd_opt(2018, 8, 8).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Sun, 2), Some(NaiveDate::from_ymd_opt(2018, 8, 12).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Thu, 3), Some(NaiveDate::from_ymd_opt(2018, 8, 16).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Thu, 4), Some(NaiveDate::from_ymd_opt(2018, 8, 23).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Thu, 5), Some(NaiveDate::from_ymd_opt(2018, 8, 30).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Fri, 5), Some(NaiveDate::from_ymd_opt(2018, 8, 31).unwrap()));
//     assert_eq!(ymwd(2018, 8, Weekday::Sat, 5), None);
// }

// #[test]
// fn test_date_fields() {
//     fn check(year: i32, month: u32, day: u32, ordinal: u32) {
//         let d1 = NaiveDate::from_ymd_opt(year, month, day).unwrap();
//         assert_eq!(d1.year(), year);
//         assert_eq!(d1.month(), month);
//         assert_eq!(d1.day(), day);
//         assert_eq!(d1.ordinal(), ordinal);

//         let d2 = NaiveDate::from_yo_opt(year, ordinal).unwrap();
//         assert_eq!(d2.year(), year);
//         assert_eq!(d2.month(), month);
//         assert_eq!(d2.day(), day);
//         assert_eq!(d2.ordinal(), ordinal);

//         assert_eq!(d1, d2);
//     }

//     check(2012, 1, 1, 1);
//     check(2012, 1, 2, 2);
//     check(2012, 2, 1, 32);
//     check(2012, 2, 29, 60);
//     check(2012, 3, 1, 61);
//     check(2012, 4, 9, 100);
//     check(2012, 7, 18, 200);
//     check(2012, 10, 26, 300);
//     check(2012, 12, 31, 366);

//     check(2014, 1, 1, 1);
//     check(2014, 1, 2, 2);
//     check(2014, 2, 1, 32);
//     check(2014, 2, 28, 59);
//     check(2014, 3, 1, 60);
//     check(2014, 4, 10, 100);
//     check(2014, 7, 19, 200);
//     check(2014, 10, 27, 300);
//     check(2014, 12, 31, 365);
// }

// #[test]
// fn test_date_weekday() {
//     assert_eq!(NaiveDate::from_ymd_opt(1582, 10, 15).unwrap().weekday(), Weekday::Fri);
//     // May 20, 1875 = ISO 8601 reference date
//     assert_eq!(NaiveDate::from_ymd_opt(1875, 5, 20).unwrap().weekday(), Weekday::Thu);
//     assert_eq!(NaiveDate::from_ymd_opt(2000, 1, 1).unwrap().weekday(), Weekday::Sat);
// }

// #[test]
// fn test_date_with_fields() {
//     let d = NaiveDate::from_ymd_opt(2000, 2, 29).unwrap();
//     assert_eq!(d.with_year(-400), Some(NaiveDate::from_ymd_opt(-400, 2, 29).unwrap()));
//     assert_eq!(d.with_year(-100), None);
//     assert_eq!(d.with_year(1600), Some(NaiveDate::from_ymd_opt(1600, 2, 29).unwrap()));
//     assert_eq!(d.with_year(1900), None);
//     assert_eq!(d.with_year(2000), Some(NaiveDate::from_ymd_opt(2000, 2, 29).unwrap()));
//     assert_eq!(d.with_year(2001), None);
//     assert_eq!(d.with_year(2004), Some(NaiveDate::from_ymd_opt(2004, 2, 29).unwrap()));
//     assert_eq!(d.with_year(i32::MAX), None);

//     let d = NaiveDate::from_ymd_opt(2000, 4, 30).unwrap();
//     assert_eq!(d.with_month(0), None);
//     assert_eq!(d.with_month(1), Some(NaiveDate::from_ymd_opt(2000, 1, 30).unwrap()));
//     assert_eq!(d.with_month(2), None);
//     assert_eq!(d.with_month(3), Some(NaiveDate::from_ymd_opt(2000, 3, 30).unwrap()));
//     assert_eq!(d.with_month(4), Some(NaiveDate::from_ymd_opt(2000, 4, 30).unwrap()));
//     assert_eq!(d.with_month(12), Some(NaiveDate::from_ymd_opt(2000, 12, 30).unwrap()));
//     assert_eq!(d.with_month(13), None);
//     assert_eq!(d.with_month(u32::MAX), None);

//     let d = NaiveDate::from_ymd_opt(2000, 2, 8).unwrap();
//     assert_eq!(d.with_day(0), None);
//     assert_eq!(d.with_day(1), Some(NaiveDate::from_ymd_opt(2000, 2, 1).unwrap()));
//     assert_eq!(d.with_day(29), Some(NaiveDate::from_ymd_opt(2000, 2, 29).unwrap()));
//     assert_eq!(d.with_day(30), None);
//     assert_eq!(d.with_day(u32::MAX), None);
// }

// #[test]
// fn test_date_with_ordinal() {
//     let d = NaiveDate::from_ymd_opt(2000, 5, 5).unwrap();
//     assert_eq!(d.with_ordinal(0), None);
//     assert_eq!(d.with_ordinal(1), Some(NaiveDate::from_ymd_opt(2000, 1, 1).unwrap()));
//     assert_eq!(d.with_ordinal(60), Some(NaiveDate::from_ymd_opt(2000, 2, 29).unwrap()));
//     assert_eq!(d.with_ordinal(61), Some(NaiveDate::from_ymd_opt(2000, 3, 1).unwrap()));
//     assert_eq!(d.with_ordinal(366), Some(NaiveDate::from_ymd_opt(2000, 12, 31).unwrap()));
//     assert_eq!(d.with_ordinal(367), None);
//     assert_eq!(d.with_ordinal((1 << 28) | 60), None);
//     let d = NaiveDate::from_ymd_opt(1999, 5, 5).unwrap();
//     assert_eq!(d.with_ordinal(366), None);
//     assert_eq!(d.with_ordinal(u32::MAX), None);
// }

// #[test]
// fn test_date_num_days_from_ce() {
//     assert_eq!(NaiveDate::from_ymd_opt(1, 1, 1).unwrap().num_days_from_ce(), 1);

//     for year in -9999..10001 {
//         assert_eq!(
//             NaiveDate::from_ymd_opt(year, 1, 1).unwrap().num_days_from_ce(),
//             NaiveDate::from_ymd_opt(year - 1, 12, 31).unwrap().num_days_from_ce() + 1
//         );
//     }
// }

// #[test]
// fn test_date_succ() {
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     assert_eq!(ymd(2014, 5, 6).succ_opt(), Some(ymd(2014, 5, 7)));
//     assert_eq!(ymd(2014, 5, 31).succ_opt(), Some(ymd(2014, 6, 1)));
//     assert_eq!(ymd(2014, 12, 31).succ_opt(), Some(ymd(2015, 1, 1)));
//     assert_eq!(ymd(2016, 2, 28).succ_opt(), Some(ymd(2016, 2, 29)));
//     assert_eq!(ymd(NaiveDate::MAX.year(), 12, 31).succ_opt(), None);
// }

// #[test]
// fn test_date_pred() {
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     assert_eq!(ymd(2016, 3, 1).pred_opt(), Some(ymd(2016, 2, 29)));
//     assert_eq!(ymd(2015, 1, 1).pred_opt(), Some(ymd(2014, 12, 31)));
//     assert_eq!(ymd(2014, 6, 1).pred_opt(), Some(ymd(2014, 5, 31)));
//     assert_eq!(ymd(2014, 5, 7).pred_opt(), Some(ymd(2014, 5, 6)));
//     assert_eq!(ymd(NaiveDate::MIN.year(), 1, 1).pred_opt(), None);
// }

// #[test]
// fn test_date_checked_add_signed() {
//     fn check(lhs: Option<NaiveDate>, delta: TimeDelta, rhs: Option<NaiveDate>) {
//         assert_eq!(lhs.unwrap().checked_add_signed(delta), rhs);
//         assert_eq!(lhs.unwrap().checked_sub_signed(-delta), rhs);
//     }
//     let ymd = NaiveDate::from_ymd_opt;

//     check(ymd(2014, 1, 1), TimeDelta::zero(), ymd(2014, 1, 1));
//     check(ymd(2014, 1, 1), TimeDelta::try_seconds(86399).unwrap(), ymd(2014, 1, 1));
//     // always round towards zero
//     check(ymd(2014, 1, 1), TimeDelta::try_seconds(-86399).unwrap(), ymd(2014, 1, 1));
//     check(ymd(2014, 1, 1), TimeDelta::try_days(1).unwrap(), ymd(2014, 1, 2));
//     check(ymd(2014, 1, 1), TimeDelta::try_days(-1).unwrap(), ymd(2013, 12, 31));
//     check(ymd(2014, 1, 1), TimeDelta::try_days(364).unwrap(), ymd(2014, 12, 31));
//     check(ymd(2014, 1, 1), TimeDelta::try_days(365 * 4 + 1).unwrap(), ymd(2018, 1, 1));
//     check(ymd(2014, 1, 1), TimeDelta::try_days(365 * 400 + 97).unwrap(), ymd(2414, 1, 1));

//     check(ymd(-7, 1, 1), TimeDelta::try_days(365 * 12 + 3).unwrap(), ymd(5, 1, 1));

//     // overflow check
//     check(
//         ymd(0, 1, 1),
//         TimeDelta::try_days(MAX_DAYS_FROM_YEAR_0 as i64).unwrap(),
//         ymd(MAX_YEAR, 12, 31),
//     );
//     check(ymd(0, 1, 1), TimeDelta::try_days(MAX_DAYS_FROM_YEAR_0 as i64 + 1).unwrap(), None);
//     check(ymd(0, 1, 1), TimeDelta::MAX, None);
//     check(
//         ymd(0, 1, 1),
//         TimeDelta::try_days(MIN_DAYS_FROM_YEAR_0 as i64).unwrap(),
//         ymd(MIN_YEAR, 1, 1),
//     );
//     check(ymd(0, 1, 1), TimeDelta::try_days(MIN_DAYS_FROM_YEAR_0 as i64 - 1).unwrap(), None);
//     check(ymd(0, 1, 1), TimeDelta::MIN, None);
// }

// #[test]
// fn test_date_signed_duration_since() {
//     fn check(lhs: Option<NaiveDate>, rhs: Option<NaiveDate>, delta: TimeDelta) {
//         assert_eq!(lhs.unwrap().signed_duration_since(rhs.unwrap()), delta);
//         assert_eq!(rhs.unwrap().signed_duration_since(lhs.unwrap()), -delta);
//     }
//     let ymd = NaiveDate::from_ymd_opt;

//     check(ymd(2014, 1, 1), ymd(2014, 1, 1), TimeDelta::zero());
//     check(ymd(2014, 1, 2), ymd(2014, 1, 1), TimeDelta::try_days(1).unwrap());
//     check(ymd(2014, 12, 31), ymd(2014, 1, 1), TimeDelta::try_days(364).unwrap());
//     check(ymd(2015, 1, 3), ymd(2014, 1, 1), TimeDelta::try_days(365 + 2).unwrap());
//     check(ymd(2018, 1, 1), ymd(2014, 1, 1), TimeDelta::try_days(365 * 4 + 1).unwrap());
//     check(ymd(2414, 1, 1), ymd(2014, 1, 1), TimeDelta::try_days(365 * 400 + 97).unwrap());

//     check(
//         ymd(MAX_YEAR, 12, 31),
//         ymd(0, 1, 1),
//         TimeDelta::try_days(MAX_DAYS_FROM_YEAR_0 as i64).unwrap(),
//     );
//     check(
//         ymd(MIN_YEAR, 1, 1),
//         ymd(0, 1, 1),
//         TimeDelta::try_days(MIN_DAYS_FROM_YEAR_0 as i64).unwrap(),
//     );
// }

// #[test]
// fn test_date_add_days() {
//     fn check(lhs: Option<NaiveDate>, days: Days, rhs: Option<NaiveDate>) {
//         assert_eq!(lhs.unwrap().checked_add_days(days), rhs);
//     }
//     let ymd = NaiveDate::from_ymd_opt;

//     check(ymd(2014, 1, 1), Days::new(0), ymd(2014, 1, 1));
//     // always round towards zero
//     check(ymd(2014, 1, 1), Days::new(1), ymd(2014, 1, 2));
//     check(ymd(2014, 1, 1), Days::new(364), ymd(2014, 12, 31));
//     check(ymd(2014, 1, 1), Days::new(365 * 4 + 1), ymd(2018, 1, 1));
//     check(ymd(2014, 1, 1), Days::new(365 * 400 + 97), ymd(2414, 1, 1));

//     check(ymd(-7, 1, 1), Days::new(365 * 12 + 3), ymd(5, 1, 1));

//     // overflow check
//     check(ymd(0, 1, 1), Days::new(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()), ymd(MAX_YEAR, 12, 31));
//     check(ymd(0, 1, 1), Days::new(u64::try_from(MAX_DAYS_FROM_YEAR_0).unwrap() + 1), None);
// }

// #[test]
// fn test_date_sub_days() {
//     fn check(lhs: Option<NaiveDate>, days: Days, rhs: Option<NaiveDate>) {
//         assert_eq!(lhs.unwrap().checked_sub_days(days), rhs);
//     }
//     let ymd = NaiveDate::from_ymd_opt;

//     check(ymd(2014, 1, 1), Days::new(0), ymd(2014, 1, 1));
//     check(ymd(2014, 1, 2), Days::new(1), ymd(2014, 1, 1));
//     check(ymd(2014, 12, 31), Days::new(364), ymd(2014, 1, 1));
//     check(ymd(2015, 1, 3), Days::new(365 + 2), ymd(2014, 1, 1));
//     check(ymd(2018, 1, 1), Days::new(365 * 4 + 1), ymd(2014, 1, 1));
//     check(ymd(2414, 1, 1), Days::new(365 * 400 + 97), ymd(2014, 1, 1));

//     check(ymd(MAX_YEAR, 12, 31), Days::new(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()), ymd(0, 1, 1));
//     check(
//         ymd(0, 1, 1),
//         Days::new((-MIN_DAYS_FROM_YEAR_0).try_into().unwrap()),
//         ymd(MIN_YEAR, 1, 1),
//     );
// }

// #[test]
// fn test_date_addassignment() {
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     let mut date = ymd(2016, 10, 1);
//     date += TimeDelta::try_days(10).unwrap();
//     assert_eq!(date, ymd(2016, 10, 11));
//     date += TimeDelta::try_days(30).unwrap();
//     assert_eq!(date, ymd(2016, 11, 10));
// }

// #[test]
// fn test_date_subassignment() {
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     let mut date = ymd(2016, 10, 11);
//     date -= TimeDelta::try_days(10).unwrap();
//     assert_eq!(date, ymd(2016, 10, 1));
//     date -= TimeDelta::try_days(2).unwrap();
//     assert_eq!(date, ymd(2016, 9, 29));
// }

// #[test]
// fn test_date_fmt() {
//     assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(2012, 3, 4).unwrap()), "2012-03-04");
//     assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(0, 3, 4).unwrap()), "0000-03-04");
//     assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(-307, 3, 4).unwrap()), "-0307-03-04");
//     assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(12345, 3, 4).unwrap()), "+12345-03-04");

//     assert_eq!(NaiveDate::from_ymd_opt(2012, 3, 4).unwrap().to_string(), "2012-03-04");
//     assert_eq!(NaiveDate::from_ymd_opt(0, 3, 4).unwrap().to_string(), "0000-03-04");
//     assert_eq!(NaiveDate::from_ymd_opt(-307, 3, 4).unwrap().to_string(), "-0307-03-04");
//     assert_eq!(NaiveDate::from_ymd_opt(12345, 3, 4).unwrap().to_string(), "+12345-03-04");

//     // the format specifier should have no effect on `NaiveTime`
//     assert_eq!(format!("{:+30?}", NaiveDate::from_ymd_opt(1234, 5, 6).unwrap()), "1234-05-06");
//     assert_eq!(format!("{:30?}", NaiveDate::from_ymd_opt(12345, 6, 7).unwrap()), "+12345-06-07");
// }

// #[test]
// fn test_date_from_str() {
//     // valid cases
//     let valid = [
//         "-0000000123456-1-2",
//         "    -123456 - 1 - 2    ",
//         "-12345-1-2",
//         "-1234-12-31",
//         "-7-6-5",
//         "350-2-28",
//         "360-02-29",
//         "0360-02-29",
//         "2015-2 -18",
//         "2015-02-18",
//         "+70-2-18",
//         "+70000-2-18",
//         "+00007-2-18",
//     ];
//     for &s in &valid {
//         eprintln!("test_date_from_str valid {:?}", s);
//         let d = match s.parse::<NaiveDate>() {
//             Ok(d) => d,
//             Err(e) => panic!("parsing `{}` has failed: {}", s, e),
//         };
//         eprintln!("d {:?} (NaiveDate)", d);
//         let s_ = format!("{:?}", d);
//         eprintln!("s_ {:?}", s_);
//         // `s` and `s_` may differ, but `s.parse()` and `s_.parse()` must be same
//         let d_ = match s_.parse::<NaiveDate>() {
//             Ok(d) => d,
//             Err(e) => {
//                 panic!("`{}` is parsed into `{:?}`, but reparsing that has failed: {}", s, d, e)
//             }
//         };
//         eprintln!("d_ {:?} (NaiveDate)", d_);
//         assert!(
//             d == d_,
//             "`{}` is parsed into `{:?}`, but reparsed result \
//                             `{:?}` does not match",
//             s,
//             d,
//             d_
//         );
//     }

//     // some invalid cases
//     // since `ParseErrorKind` is private, all we can do is to check if there was an error
//     let invalid = [
//         "",                     // empty
//         "x",                    // invalid
//         "Fri, 09 Aug 2013 GMT", // valid date, wrong format
//         "Sat Jun 30 2012",      // valid date, wrong format
//         "1441497364.649",       // valid datetime, wrong format
//         "+1441497364.649",      // valid datetime, wrong format
//         "+1441497364",          // valid datetime, wrong format
//         "2014/02/03",           // valid date, wrong format
//         "2014",                 // datetime missing data
//         "2014-01",              // datetime missing data
//         "2014-01-00",           // invalid day
//         "2014-11-32",           // invalid day
//         "2014-13-01",           // invalid month
//         "2014-13-57",           // invalid month, day
//         "9999999-9-9",          // invalid year (out of bounds)
//     ];
//     for &s in &invalid {
//         eprintln!("test_date_from_str invalid {:?}", s);
//         assert!(s.parse::<NaiveDate>().is_err());
//     }
// }

// #[test]
// fn test_date_parse_from_str() {
//     let ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
//     assert_eq!(
//         NaiveDate::parse_from_str("2014-5-7T12:34:56+09:30", "%Y-%m-%dT%H:%M:%S%z"),
//         Ok(ymd(2014, 5, 7))
//     ); // ignore time and offset
//     assert_eq!(
//         NaiveDate::parse_from_str("2015-W06-1=2015-033 Q1", "%G-W%V-%u = %Y-%j Q%q"),
//         Ok(ymd(2015, 2, 2))
//     );
//     assert_eq!(NaiveDate::parse_from_str("Fri, 09 Aug 13", "%a, %d %b %y"), Ok(ymd(2013, 8, 9)));
//     assert!(NaiveDate::parse_from_str("Sat, 09 Aug 2013", "%a, %d %b %Y").is_err());
//     assert!(NaiveDate::parse_from_str("2014-57", "%Y-%m-%d").is_err());
//     assert!(NaiveDate::parse_from_str("2014", "%Y").is_err()); // insufficient

//     assert!(NaiveDate::parse_from_str("2014-5-7 Q3", "%Y-%m-%d Q%q").is_err()); // mismatched quarter

//     assert_eq!(
//         NaiveDate::parse_from_str("2020-01-0", "%Y-%W-%w").ok(),
//         NaiveDate::from_ymd_opt(2020, 1, 12),
//     );

//     assert_eq!(
//         NaiveDate::parse_from_str("2019-01-0", "%Y-%W-%w").ok(),
//         NaiveDate::from_ymd_opt(2019, 1, 13),
//     );
// }

// #[test]
// fn test_day_iterator_limit() {
//     assert_eq!(NaiveDate::from_ymd_opt(MAX_YEAR, 12, 29).unwrap().iter_days().take(4).count(), 2);
//     assert_eq!(
//         NaiveDate::from_ymd_opt(MIN_YEAR, 1, 3).unwrap().iter_days().rev().take(4).count(),
//         2
//     );
// }

// #[test]
// fn test_week_iterator_limit() {
//     assert_eq!(NaiveDate::from_ymd_opt(MAX_YEAR, 12, 12).unwrap().iter_weeks().take(4).count(), 2);
//     assert_eq!(
//         NaiveDate::from_ymd_opt(MIN_YEAR, 1, 15).unwrap().iter_weeks().rev().take(4).count(),
//         2
//     );
// }

// #[test]
// fn test_weeks_from() {
//     // tests per: https://github.com/chronotope/chrono/issues/961
//     // these internally use `weeks_from` via the parsing infrastructure
//     assert_eq!(
//         NaiveDate::parse_from_str("2020-01-0", "%Y-%W-%w").ok(),
//         NaiveDate::from_ymd_opt(2020, 1, 12),
//     );
//     assert_eq!(
//         NaiveDate::parse_from_str("2019-01-0", "%Y-%W-%w").ok(),
//         NaiveDate::from_ymd_opt(2019, 1, 13),
//     );

//     // direct tests
//     for (y, starts_on) in &[
//         (2019, Weekday::Tue),
//         (2020, Weekday::Wed),
//         (2021, Weekday::Fri),
//         (2022, Weekday::Sat),
//         (2023, Weekday::Sun),
//         (2024, Weekday::Mon),
//         (2025, Weekday::Wed),
//         (2026, Weekday::Thu),
//     ] {
//         for day in &[
//             Weekday::Mon,
//             Weekday::Tue,
//             Weekday::Wed,
//             Weekday::Thu,
//             Weekday::Fri,
//             Weekday::Sat,
//             Weekday::Sun,
//         ] {
//             assert_eq!(
//                 NaiveDate::from_ymd_opt(*y, 1, 1).map(|d| d.weeks_from(*day)),
//                 Some(if day == starts_on { 1 } else { 0 })
//             );

//             // last day must always be in week 52 or 53
//             assert!(
//                 [52, 53].contains(&NaiveDate::from_ymd_opt(*y, 12, 31).unwrap().weeks_from(*day)),
//             );
//         }
//     }

//     let base = NaiveDate::from_ymd_opt(2019, 1, 1).unwrap();

//     // 400 years covers all year types
//     for day in &[
//         Weekday::Mon,
//         Weekday::Tue,
//         Weekday::Wed,
//         Weekday::Thu,
//         Weekday::Fri,
//         Weekday::Sat,
//         Weekday::Sun,
//     ] {
//         // must always be below 54
//         for dplus in 1..(400 * 366) {
//             assert!((base + Days::new(dplus)).weeks_from(*day) < 54)
//         }
//     }
// }

// #[test]
// fn test_with_0_overflow() {
//     let dt = NaiveDate::from_ymd_opt(2023, 4, 18).unwrap();
//     assert!(dt.with_month0(4294967295).is_none());
//     assert!(dt.with_day0(4294967295).is_none());
//     assert!(dt.with_ordinal0(4294967295).is_none());
// }

// #[test]
// fn test_leap_year() {
//     for year in 0..=MAX_YEAR {
//         let date = NaiveDate::from_ymd_opt(year, 1, 1).unwrap();
//         let is_leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
//         assert_eq!(date.leap_year(), is_leap);
//         assert_eq!(date.leap_year(), date.with_ordinal(366).is_some());
//     }
// }

// #[test]
// fn test_date_yearflags() {
//     for (year, year_flags, _) in YEAR_FLAGS {
//         assert_eq!(NaiveDate::from_yo_opt(year, 1).unwrap().year_flags(), year_flags);
//     }
// }

// #[test]
// fn test_weekday_with_yearflags() {
//     for (year, year_flags, first_weekday) in YEAR_FLAGS {
//         let first_day_of_year = NaiveDate::from_yo_opt(year, 1).unwrap();
//         dbg!(year);
//         assert_eq!(first_day_of_year.year_flags(), year_flags);
//         assert_eq!(first_day_of_year.weekday(), first_weekday);

//         let mut prev = first_day_of_year.weekday();
//         for ordinal in 2u32..=year_flags.ndays() {
//             let date = NaiveDate::from_yo_opt(year, ordinal).unwrap();
//             let expected = prev.succ();
//             assert_eq!(date.weekday(), expected);
//             prev = expected;
//         }
//     }
// }

// #[test]
// fn test_isoweekdate_with_yearflags() {
//     for (year, year_flags, _) in YEAR_FLAGS {
//         // January 4 should be in the first week
//         let jan4 = NaiveDate::from_ymd_opt(year, 1, 4).unwrap();
//         let iso_week = jan4.iso_week();
//         assert_eq!(jan4.year_flags(), year_flags);
//         assert_eq!(iso_week.week(), 1);
//     }
// }

// #[test]
// fn test_date_to_mdf_to_date() {
//     for (year, year_flags, _) in YEAR_FLAGS {
//         for ordinal in 1..=year_flags.ndays() {
//             let date = NaiveDate::from_yo_opt(year, ordinal).unwrap();
//             assert_eq!(date, NaiveDate::from_mdf(date.year(), date.mdf()).unwrap());
//         }
//     }
// }

// // Used for testing some methods with all combinations of `YearFlags`.
// // (year, flags, first weekday of year)
// const YEAR_FLAGS: [(i32, YearFlags, Weekday); 14] = [
//     (2006, A, Weekday::Sun),
//     (2005, B, Weekday::Sat),
//     (2010, C, Weekday::Fri),
//     (2009, D, Weekday::Thu),
//     (2003, E, Weekday::Wed),
//     (2002, F, Weekday::Tue),
//     (2001, G, Weekday::Mon),
//     (2012, AG, Weekday::Sun),
//     (2000, BA, Weekday::Sat),
//     (2016, CB, Weekday::Fri),
//     (2004, DC, Weekday::Thu),
//     (2020, ED, Weekday::Wed),
//     (2008, FE, Weekday::Tue),
//     (2024, GF, Weekday::Mon),
// ];

// #[test]
// #[cfg(feature = "rkyv-validation")]
// fn test_rkyv_validation() {
//     let date_min = NaiveDate::MIN;
//     let bytes = rkyv::to_bytes::<_, 4>(&date_min).unwrap();
//     assert_eq!(rkyv::from_bytes::<NaiveDate>(&bytes).unwrap(), date_min);

//     let date_max = NaiveDate::MAX;
//     let bytes = rkyv::to_bytes::<_, 4>(&date_max).unwrap();
//     assert_eq!(rkyv::from_bytes::<NaiveDate>(&bytes).unwrap(), date_max);
// }

// //   MAX_YEAR-12-31 minus 0000-01-01
// // = (MAX_YEAR-12-31 minus 0000-12-31) + (0000-12-31 - 0000-01-01)
// // = MAX_YEAR * 365 + (# of leap years from 0001 to MAX_YEAR) + 365
// // = (MAX_YEAR + 1) * 365 + (# of leap years from 0001 to MAX_YEAR)
// const MAX_DAYS_FROM_YEAR_0: i32 =
//     (MAX_YEAR + 1) * 365 + MAX_YEAR / 4 - MAX_YEAR / 100 + MAX_YEAR / 400;

// //   MIN_YEAR-01-01 minus 0000-01-01
// // = MIN_YEAR * 365 + (# of leap years from MIN_YEAR to 0000)
// const MIN_DAYS_FROM_YEAR_0: i32 = MIN_YEAR * 365 + MIN_YEAR / 4 - MIN_YEAR / 100 + MIN_YEAR / 400;

// // only used for testing, but duplicated in naive::datetime
// const MAX_BITS: usize = 44;

