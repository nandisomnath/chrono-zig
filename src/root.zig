pub const time_delta = @import("time_delta.zig");
pub const OutOfRangeError = time_delta.TimeDeltaError.OutOfRangeError;
pub const TimeDelta = time_delta.TimeDelta;
/// Alias of [`TimeDelta`].
pub const Duration = TimeDelta;


// mod date;
// const date = @import("date.zig");
// pub const Date = date.Date;
// pub const MAX_DATE = date.MAX_DATE;
// pub const MIN_DATE = date.MIN_DATE;


// // mod datetime;
// const datetime = @import("datetime/root.zig");
// pub const DateTime = datetime.DateTime;
// pub const MAX_DATETIME = date.MAX_DATETIME;
// pub const MIN_DATETIME = date.MIN_DATETIME;


// // pub mod format;
// pub const format = @import("format/root.zig");
// pub const Locale = format.Locale;
// pub const ParseError = format.ParseError;
// pub const ParseResult = format.ParseResult;
// pub const SecondsFormat = format.SecondsFormat;


// // pub mod naive;
// pub const naive = @import("naive/root.zig");
// pub const Days = naive.Days ;
// pub const NaiveDate = naive.NaiveDate ;
// pub const NaiveDateTime= naive.NaiveDateTime ;
// pub const NaiveTime = naive.NaiveTime ;
// pub const IsoWeek = naive.IsoWeek ;
// pub const NaiveWeek = naive.NaiveWeek ;

// // pub mod offset;
// pub const offset = @import("offset/root.zig");
// pub const Local = offset.Local;
// pub const LocalResult = offset.LocalResult;
// pub const MappedLocalTime = offset.MappedLocalTime;
// pub const FixedOffset = offset.FixedOffset;
// pub const Offset = offset.Offset;
// pub const TimeZone = offset.TimeZone;
// pub const Utc = offset.Utc;


// // pub mod round;
// pub const round = @import("round.zig");
// pub const DurationRound = round.DurationRound;
// pub const RoundingError = round.RoundingError;
// pub const SubsecRound = round.SubsecRound;


// // mod weekday;
// const weekday = @import("weekday.zig");
// pub const Weekday = weekday.Weekday;
// pub const ParseWeekdayError = weekday.ParseWeekdayError;


// // mod weekday_set;
// const weekday_set = @import("weekday_set.zig");
// pub const WeekdaySet = weekday_set.WeekdaySet;


// // mod month;
// const month = @import("month.zig");
// pub const ParseMonthError = month.ParseMonthError;
// pub const Month = month.Month;
// pub const Months = month.Month;


// mod traits;
// pub use traits::{Datelike, Timelike};

// #[cfg(feature = "__internal_bench")]
// #[doc(hidden)]
// pub use naive::__BenchYearFlags;



pub const ChronoError = error {
    OutOfRange,
};




// TODO: this is a macro used in most of the code 
// /// Workaround because `?` is not (yet) available in const context.
// #[macro_export]
// #[doc(hidden)]
// macro_rules! try_opt {
//     ($e:expr) => {
//         match $e {
//             Some(v) => v,
//             None => return None,
//         }
//     };
// }

const std = @import("std");
const testing = std.testing;





// test "test_type_sizes" {
        
//         testing.expectEqual(@sizeof(NaiveDate), 4);
//         testing.expectEqual(@sizeof(NaiveTime), 8);
//         testing.expectEqual(@sizeof(NaiveDateTime), 12);
//         testing.expectEqual(@sizeof(DateTime<Utc>), 12);
//         testing.expectEqual(@sizeof(DateTime<FixedOffset>), 16);
//         testing.expectEqual(@sizeof(DateTime<Local>), 16);
// }

test {
    _ = time_delta;
    // _ = naive;
    // _ = weekday;
    // _ = month;
}
