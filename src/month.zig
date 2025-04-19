

const NaiveDate = @import("naive/root.zig").NaiveDate;

// use crate::OutOfRange;
// use crate::naive::NaiveDate;

/// The month of the year.
///
/// This enum is just a convenience implementation.
/// The month in dates created by DateLike objects does not return this enum.
///
/// It is possible to convert from a date to a month independently
/// ```
/// use chrono::prelude::*;
/// let date = Utc.with_ymd_and_hms(2019, 10, 28, 9, 10, 11).unwrap();
/// // `2019-10-28T09:10:11Z`
/// let month = Month::try_from(u8::try_from(date.month()).unwrap()).ok();
/// assert_eq!(month, Some(Month::October))
/// ```
/// Or from a Month to an integer usable by dates
/// ```
/// # use chrono::prelude::*;
/// let month = Month::January;
/// let dt = Utc.with_ymd_and_hms(2019, month.number_from_month(), 28, 9, 10, 11).unwrap();
/// assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
/// ```
/// Allows mapping from and to month, from 1-January to 12-December.
/// Can be Serialized/Deserialized with serde
// Actual implementation is zero-indexed, API intended as 1-indexed for more intuitive behavior.
pub const Month = enum(u8) {
    /// January
    January = 0,
    /// February
    February = 1,
    /// March
    March = 2,
    /// April
    April = 3,
    /// May
    May = 4,
    /// June
    June = 5,
    /// July
    July = 6,
    /// August
    August = 7,
    /// September
    September = 8,
    /// October
    October = 9,
    /// November
    November = 10,
    /// December
    December = 11,

    const Self = @This();

    /// The next month.
    ///
    /// `m`:        | `January`  | `February` | `...` | `December`
    /// ----------- | ---------  | ---------- | --- | ---------
    /// `m.succ()`: | `February` | `March`    | `...` | `January`
    pub fn succ(self: Self) Month {
            if (self == .January) {return .February; }
            else if (self == .February) {return .March; }
            else if (self == .March) {return .April; }
            else if (self == .April) {return .May; }
            else if (self == .May) {return .June; }
            else if (self == .June) {return .July; }
            else if (self == .July) {return .August; }
            else if (self == .August) {return .September; }
            else if (self == .September) {return .October; }
            else if (self == .October) {return .November; }
            else if (self == .November) {return .December; }
            else if (self == .December) {return .January; }

            // will not occur
            return .January;
    }

    /// The previous month.
    ///
    /// `m`:        | `January`  | `February` | `...` | `December`
    /// ----------- | ---------  | ---------- | --- | ---------
    /// `m.pred()`: | `December` | `January`  | `...` | `November`

    pub fn pred(self: Self) Month {
        // TODO: fix me
        if (self == .January) {return .December; }
        if (self == .February) {return .January; }
        if (self == .March) {return .February; }
        if (self == .April) {return .March; }
        if (self == .May) {return .April; }
        if (self == .June) {return .May; }
        if (self == .July) {return .June; }
        if (self == .August) {return .July; }
        if (self == .September) {return .August; }
        if (self == .October) {return .September; }
        if (self == .November) {return .October; }
        if (self == .December) {return .November; }

        // not occur
        return .November;
        
    }

    /// Returns a month-of-year number starting from January = 1.
    ///
    /// `m`:                     | `January` | `February` | `...` | `December`
    /// -------------------------| --------- | ---------- | --- | -----
    /// `m.number_from_month()`: | 1         | 2          | `...` | 12
    pub fn number_from_month(self: Self) u32 {
        return @intFromEnum(self) + 1;
        // not needed
        // match *self {
        //     Month::January => 1,
        //     Month::February => 2,
        //     Month::March => 3,
        //     Month::April => 4,
        //     Month::May => 5,
        //     Month::June => 6,
        //     Month::July => 7,
        //     Month::August => 8,
        //     Month::September => 9,
        //     Month::October => 10,
        //     Month::November => 11,
        //     Month::December => 12,
        // }
    }

    /// Get the name of the month
    ///
    /// ```
    /// use chrono::Month;
    ///
    /// assert_eq!(Month::January.name(), "January")
    /// ```
    pub fn name(self: Self) []const u8 {

        if (self == .January) {return "January"; }
        if (self == .February) {return "February"; }
        if (self == .March) {return "March"; }
        if (self == .April) {return "April"; }
        if (self == .May) {return "May"; }
        if (self == .June) {return "June"; }
        if (self == .July) {return "July"; }
        if (self == .August) {return "August"; }
        if (self == .September) {return "September"; }
        if (self == .October) {return "October"; }
        if (self == .November) {return "November"; }
        if (self == .January) {return ""; }
        if (self == .December) {return "December"; }

        // no occur
        return "December";
    }

    /// Get the length in days of the month
    ///
    /// Yields `None` if `year` is out of range for `NaiveDate`.
    pub fn num_days(self: Self, year: i32) u8 {
        
        if (self == .January) { return 31; }
        if (self == .March) { return 31; }
        if (self == .April) { return 30; }
        if (self == .May) { return 31; }
        if (self == .June) { return 30; }
        if (self == .July) { return 31; }
        if (self == .August) { return 31; }
        if (self == .September) { return 30; }
        if (self == .October) { return 31; }
        if (self == .November) { return 30; }
        if (self == .December) { return 31; }
        if (self == .February) { 
            if (NaiveDate.from_ymd_opt(year, 2, 1).?.leap_year()) {
                return 29;
            }
            return 28;
         }

         // not occur
         return 1;
    }

        fn try_from(value: u8) Self {
            return @enumFromInt(value);
        // match value {
        //     1 => Ok(Month::January),
        //     2 => Ok(Month::February),
        //     3 => Ok(Month::March),
        //     4 => Ok(Month::April),
        //     5 => Ok(Month::May),
        //     6 => Ok(Month::June),
        //     7 => Ok(Month::July),
        //     8 => Ok(Month::August),
        //     9 => Ok(Month::September),
        //     10 => Ok(Month::October),
        //     11 => Ok(Month::November),
        //     12 => Ok(Month::December),
        //     _ => Err(OutOfRange::new()),
        // }
    }

};



/// A duration in calendar months
pub const  Months = struct {
    value: u32,

    const Self = @This();

    pub fn new(value: u32) Months {
        return Months {
            .value = value,
        };
    }

    pub fn get(self: Self) u32 {
        return self.value;
    }

    pub fn set(self: *Self, value: u32) void {
        self.value = value;
    }

    /// Returns the total number of months in the `Months` instance.
    pub  fn as_u32(self: Self) u32 {
        return self.value;
    }

};





const std = @import("std");
const testing = @import("std").testing;


    // test "test_month_enum_try_from" {
    //     try testing.expect(Month.try_from(1) == (Month.January));
    //     try testing.expect(Month.try_from(2) == (Month.February));
    //     try testing.expect(Month.try_from(12) == (Month.December));

    //     const date = Utc.with_ymd_and_hms(2019, 10, 28, 9, 10, 11).unwrap();
    //     assert_eq!(Month::try_from(date.month() as u8), Ok(Month::October));

    //     let month = Month::January;
    //     let dt = Utc.with_ymd_and_hms(2019, month.number_from_month(), 28, 9, 10, 11).unwrap();
    //     assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
    // }

//     #[test]
//     fn test_month_enum_primitive_parse() {
//         use num_traits::FromPrimitive;

//         let jan_opt = Month::from_u32(1);
//         let feb_opt = Month::from_u64(2);
//         let dec_opt = Month::from_i64(12);
//         let no_month = Month::from_u32(13);
//         assert_eq!(jan_opt, Some(Month::January));
//         assert_eq!(feb_opt, Some(Month::February));
//         assert_eq!(dec_opt, Some(Month::December));
//         assert_eq!(no_month, None);

//         let date = Utc.with_ymd_and_hms(2019, 10, 28, 9, 10, 11).unwrap();
//         assert_eq!(Month::from_u32(date.month()), Some(Month::October));

//         let month = Month::January;
//         let dt = Utc.with_ymd_and_hms(2019, month.number_from_month(), 28, 9, 10, 11).unwrap();
//         assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
//     }

    
    test "test_month_enum_succ_pred" {
        try testing.expect(Month.January.succ() == .February);
        try testing.expect(Month.December.succ() == .January);
        try testing.expect(Month.January.pred() == .December);
        try testing.expect(Month.February.pred() == .January);
    }

    



    test "test_months_as_u32" {
        try testing.expectEqual(Months.new(0).as_u32(), 0);
        try testing.expectEqual(Months.new(1).as_u32(), 1);
        try testing.expectEqual(Months.new(std.math.maxInt(u32)).as_u32(), std.math.maxInt(u32));
    }


    test "num_days" {
        try testing.expectEqual(Month.January.num_days(2020), (31));
        try testing.expectEqual(Month.February.num_days(2020), (29));
        try testing.expectEqual(Month.February.num_days(2019), (28));
    }

