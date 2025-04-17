// #![doc(html_root_url = "https://docs.rs/chrono/latest/", test(attr(deny(warnings))))]
// #![deny(missing_docs)]
// #![deny(missing_debug_implementations)]
// #![warn(unreachable_pub)]
// #![deny(clippy::tests_outside_test_module)]
// #![cfg_attr(not(any(feature = "std", test)), no_std)]
// #![cfg_attr(docsrs, feature(doc_auto_cfg))]

// #[cfg(feature = "alloc")]
// extern crate alloc;

pub const time_delta = @import("time_delta.zig");
pub const naive = @import("naive.zig");
pub const weekday = @import("weekday.zig");



pub const OutOfRangeError = time_delta.TimeDeltaError.OutOfRangeError;
pub const TimeDelta = time_delta.TimeDelta;


/// Alias of [`TimeDelta`].
pub const Duration = TimeDelta;


// /// A convenience module appropriate for glob imports (`use chrono::prelude::*;`).
// pub mod prelude {
//     #[allow(deprecated)]
//     pub use crate::Date;
//     #[cfg(feature = "clock")]
//     pub use crate::Local;
//     #[cfg(all(feature = "unstable-locales", feature = "alloc"))]
//     pub use crate::Locale;
//     pub use crate::SubsecRound;
//     pub use crate::{DateTime, SecondsFormat};
//     pub use crate::{Datelike, Month, Timelike, Weekday};
//     pub use crate::{FixedOffset, Utc};
//     pub use crate::{NaiveDate, NaiveDateTime, NaiveTime};
//     pub use crate::{Offset, TimeZone};
// }



// mod date;
// #[allow(deprecated)]
// pub use date::Date;
// #[doc(no_inline)]
// #[allow(deprecated)]
// pub use date::{MAX_DATE, MIN_DATE};

// mod datetime;
// pub use datetime::DateTime;
// #[allow(deprecated)]
// #[doc(no_inline)]
// pub use datetime::{MAX_DATETIME, MIN_DATETIME};

// pub mod format;
// /// L10n locales.
// #[cfg(feature = "unstable-locales")]
// pub use format::Locale;
// pub use format::{ParseError, ParseResult, SecondsFormat};

// pub mod naive;
// #[doc(inline)]
// pub use naive::{Days, NaiveDate, NaiveDateTime, NaiveTime};
// pub use naive::{IsoWeek, NaiveWeek};

// pub mod offset;
// #[cfg(feature = "clock")]
// #[doc(inline)]
// pub use offset::Local;
// #[doc(hidden)]
// pub use offset::LocalResult;
// pub use offset::MappedLocalTime;
// #[doc(inline)]
// pub use offset::{FixedOffset, Offset, TimeZone, Utc};

// pub mod round;
// pub use round::{DurationRound, RoundingError, SubsecRound};

// mod weekday;
// #[doc(no_inline)]
// pub use weekday::ParseWeekdayError;
// pub use weekday::Weekday;

// mod weekday_set;
// pub use weekday_set::WeekdaySet;

// mod month;
// #[doc(no_inline)]
// pub use month::ParseMonthError;
// pub use month::{Month, Months};

// mod traits;
// pub use traits::{Datelike, Timelike};

// #[cfg(feature = "__internal_bench")]
// #[doc(hidden)]
// pub use naive::__BenchYearFlags;

// /// Serialization/Deserialization with serde
// ///
// /// The [`DateTime`] type has default implementations for (de)serializing to/from the [RFC 3339]
// /// format. This module provides alternatives for serializing to timestamps.
// ///
// /// The alternatives are for use with serde's [`with` annotation] combined with the module name.
// /// Alternatively the individual `serialize` and `deserialize` functions in each module can be used
// /// with serde's [`serialize_with`] and [`deserialize_with`] annotations.
// ///
// /// *Available on crate feature 'serde' only.*
// ///
// /// [RFC 3339]: https://tools.ietf.org/html/rfc3339
// /// [`with` annotation]: https://serde.rs/field-attrs.html#with
// /// [`serialize_with`]: https://serde.rs/field-attrs.html#serialize_with
// /// [`deserialize_with`]: https://serde.rs/field-attrs.html#deserialize_with
// #[cfg(feature = "serde")]
// pub mod serde {
//     use core::fmt;
//     use serde::de;

//     pub use super::datetime::serde::*;

//     /// Create a custom `de::Error` with `SerdeError::InvalidTimestamp`.
//     pub(crate) fn invalid_ts<E, T>(value: T) -> E
//     where
//         E: de::Error,
//         T: fmt::Display,
//     {
//         E::custom(SerdeError::InvalidTimestamp(value))
//     }

//     enum SerdeError<T: fmt::Display> {
//         InvalidTimestamp(T),
//     }

//     impl<T: fmt::Display> fmt::Display for SerdeError<T> {
//         fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//             match self {
//                 SerdeError::InvalidTimestamp(ts) => {
//                     write!(f, "value is not a legal timestamp: {}", ts)
//                 }
//             }
//         }
//     }
// }

// /// Zero-copy serialization/deserialization with rkyv.
// ///
// /// This module re-exports the `Archived*` versions of chrono's types.
// #[cfg(any(feature = "rkyv", feature = "rkyv-16", feature = "rkyv-32", feature = "rkyv-64"))]
// pub mod rkyv {
//     pub use crate::datetime::ArchivedDateTime;
//     pub use crate::month::ArchivedMonth;
//     pub use crate::naive::date::ArchivedNaiveDate;
//     pub use crate::naive::datetime::ArchivedNaiveDateTime;
//     pub use crate::naive::isoweek::ArchivedIsoWeek;
//     pub use crate::naive::time::ArchivedNaiveTime;
//     pub use crate::offset::fixed::ArchivedFixedOffset;
//     #[cfg(feature = "clock")]
//     pub use crate::offset::local::ArchivedLocal;
//     pub use crate::offset::utc::ArchivedUtc;
//     pub use crate::time_delta::ArchivedTimeDelta;
//     pub use crate::weekday::ArchivedWeekday;

//     /// Alias of [`ArchivedTimeDelta`]
//     pub type ArchivedDuration = ArchivedTimeDelta;
// }

// /// Out of range error type used in various converting APIs
// #[derive(Clone, Copy, Hash, PartialEq, Eq)]
// pub struct OutOfRange {
//     _private: (),
// }

// impl OutOfRange {
//     const fn new() -> OutOfRange {
//         OutOfRange { _private: () }
//     }
// }

// impl fmt::Display for OutOfRange {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         write!(f, "out of range")
//     }
// }

// impl fmt::Debug for OutOfRange {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         write!(f, "out of range")
//     }
// }

// #[cfg(feature = "std")]
// impl std::error::Error for OutOfRange {}

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

// /// Workaround because `.expect()` is not (yet) available in const context.
// pub(crate) const fn expect<T: Copy>(opt: Option<T>, msg: &str) -> T {
//     match opt {
//         Some(val) => val,
//         None => panic!("{}", msg),
//     }
// }

// #[cfg(test)]
// mod tests {
//     #[cfg(feature = "clock")]
//     use crate::{DateTime, FixedOffset, Local, NaiveDate, NaiveDateTime, NaiveTime, Utc};

//     #[test]
//     #[allow(deprecated)]
//     #[cfg(feature = "clock")]
//     fn test_type_sizes() {
//         use core::mem::size_of;
//         assert_eq!(size_of::<NaiveDate>(), 4);
//         assert_eq!(size_of::<Option<NaiveDate>>(), 4);
//         assert_eq!(size_of::<NaiveTime>(), 8);
//         assert_eq!(size_of::<Option<NaiveTime>>(), 12);
//         assert_eq!(size_of::<NaiveDateTime>(), 12);
//         assert_eq!(size_of::<Option<NaiveDateTime>>(), 12);

//         assert_eq!(size_of::<DateTime<Utc>>(), 12);
//         assert_eq!(size_of::<DateTime<FixedOffset>>(), 16);
//         assert_eq!(size_of::<DateTime<Local>>(), 16);
//         assert_eq!(size_of::<Option<DateTime<FixedOffset>>>(), 16);
//     }
// }
