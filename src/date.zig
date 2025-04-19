// this module is deprecated so no point in converting it still I will get the needed functions

// #[cfg(feature = "rkyv")]
// use rkyv::{Archive, Deserialize, Serialize};

// #[cfg(all(feature = "unstable-locales", feature = "alloc"))]
// use crate::format::Locale;
// #[cfg(feature = "alloc")]
// use crate::format::{DelayedFormat, Item, StrftimeItems};
// use crate::naive::{, NaiveDate, };
// use crate::offset::{TimeZone, Utc};
// use crate::{DateTime, Datelike, TimeDelta, Weekday};

const naive = @import("naive/root.zig");

const IsoWeek = naive.IsoWeek;
const NaiveTime = naive.NaiveTime;
const NaiveDate = naive.NaiveDate;

// The date is a simple alias for NaiveDate and also this date is deprecated so
// this is the Date for zig. No need to implement it another time.
pub const Date = NaiveDate;


// #[deprecated(since = "0.4.23", note = "Use `NaiveDate` or `DateTime<Tz>` instead")]
// pub struct Date<Tz: TimeZone> {
//     date: NaiveDate,
//     offset: Tz::Offset,
// }

const std = @import("std");
const testing = std.testing;
const TimeDelta = @import("root").TimeDelta;

//     use super::Date;

//     use crate::{FixedOffset, NaiveDate, TimeDelta, Utc};

//     #[cfg(feature = "clock")]
//     use crate::offset::{Local, TimeZone};


    // test "test_years_elapsed" {
    //     const WEEKS_PER_YEAR: f32 = 52.1775;

    //     // This is always at least one year because 1 year = 52.1775 weeks.
    //     const one_year_ago = Utc.today() - TimeDelta.weeks(std.math.ceil(@as(i64, (WEEKS_PER_YEAR * 1.5))));
    //     // A bit more than 2 years.
    //     const two_year_ago = Utc::today() - TimeDelta::weeks((WEEKS_PER_YEAR * 2.5).ceil() as i64);

    //     assert_eq!(Utc::today().years_since(one_year_ago), Some(1));
    //     assert_eq!(Utc::today().years_since(two_year_ago), Some(2));

    //     // If the given DateTime is later than now, the function will always return 0.
    //     let future = Utc::today() + TimeDelta::weeks(12);
    //     assert_eq!(Utc::today().years_since(future), None);
    // }

//     #[test]
//     fn test_date_add_assign() {
//         let naivedate = NaiveDate::from_ymd_opt(2000, 1, 1).unwrap();
//         let date = Date::<Utc>::from_utc(naivedate, Utc);
//         let mut date_add = date;

//         date_add += TimeDelta::days(5);
//         assert_eq!(date_add, date + TimeDelta::days(5));

//         let timezone = FixedOffset::east_opt(60 * 60).unwrap();
//         let date = date.with_timezone(&timezone);
//         let date_add = date_add.with_timezone(&timezone);

//         assert_eq!(date_add, date + TimeDelta::days(5));

//         let timezone = FixedOffset::west_opt(2 * 60 * 60).unwrap();
//         let date = date.with_timezone(&timezone);
//         let date_add = date_add.with_timezone(&timezone);

//         assert_eq!(date_add, date + TimeDelta::days(5));
//     }

//     #[test]
//     #[cfg(feature = "clock")]
//     fn test_date_add_assign_local() {
//         let naivedate = NaiveDate::from_ymd_opt(2000, 1, 1).unwrap();

//         let date = Local.from_utc_date(&naivedate);
//         let mut date_add = date;

//         date_add += TimeDelta::days(5);
//         assert_eq!(date_add, date + TimeDelta::days(5));
//     }

//     #[test]
//     fn test_date_sub_assign() {
//         let naivedate = NaiveDate::from_ymd_opt(2000, 1, 1).unwrap();
//         let date = Date::<Utc>::from_utc(naivedate, Utc);
//         let mut date_sub = date;

//         date_sub -= TimeDelta::days(5);
//         assert_eq!(date_sub, date - TimeDelta::days(5));

//         let timezone = FixedOffset::east_opt(60 * 60).unwrap();
//         let date = date.with_timezone(&timezone);
//         let date_sub = date_sub.with_timezone(&timezone);

//         assert_eq!(date_sub, date - TimeDelta::days(5));

//         let timezone = FixedOffset::west_opt(2 * 60 * 60).unwrap();
//         let date = date.with_timezone(&timezone);
//         let date_sub = date_sub.with_timezone(&timezone);

//         assert_eq!(date_sub, date - TimeDelta::days(5));
//     }

//     #[test]
//     #[cfg(feature = "clock")]
//     fn test_date_sub_assign_local() {
//         let naivedate = NaiveDate::from_ymd_opt(2000, 1, 1).unwrap();

//         let date = Local.from_utc_date(&naivedate);
//         let mut date_sub = date;

//         date_sub -= TimeDelta::days(5);
//         assert_eq!(date_sub, date - TimeDelta::days(5));
//     }
// }
