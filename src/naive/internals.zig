const std = @import("std");

/// Year flags (aka the dominical letter).
///
/// `YearFlags` are used as the last four bits of `NaiveDate`, `Mdf` and `IsoWeek`.
///
/// There are 14 possible classes of year in the Gregorian calendar:
/// common and leap years starting with Monday through Sunday.
///
/// The `YearFlags` stores this information into 4 bits `LWWW`. `L` is the leap year flag, with `1`
/// for the common year (this simplifies validating an ordinal in `NaiveDate`). `WWW` is a non-zero
/// `Weekday` of the last day in the preceding year.

// pub struct YearFlags(pub(super) u8);
pub const YearFlags = struct {
    value: u32,
    const Self = @This();
    pub fn new(value: u32) YearFlags {
        return YearFlags {
            .value = value,
        };
    }

    pub fn set(self: *Self, value: u32) void {
        self.value = value;
    }

    pub fn get(self: Self) u32 {
        return self.value;
    }



    pub fn from_year(_year: i32) YearFlags {
        const year = rem_euclid(_year, 400);
        return YearFlags.from_year_mod_400(year);
    }


    pub  fn from_year_mod_400(year: i32) YearFlags {
        return YEAR_TO_FLAGS[@intCast(year)];
    }


    pub fn ndays(self: Self) u32 {
        return 366 - (self.value >> 3);
    }

 
    pub fn isoweek_delta(self: Self) u32 {
        // let YearFlags(flags) = *self;
        var delta = self.value & 0b0111;
        if (delta < 3) {
            delta += 7;
        }
        return delta;
    }

    // TODO: find a left shift and right shift alternative 
    // pub fn nisoweeks(self: Self) u32 {
    //     // let YearFlags(flags) = *self;
    //     const value: u32 = (0b0000_0100_0000_0110 >> self.value);
    //     return 52 + (value & 1);
    // }

};

// Weekday of the last day in the preceding year.
// Allows for quick day of week calculation from the 1-based ordinal.
const YEAR_STARTS_AFTER_MONDAY: u8 = 7; // non-zero to allow use with `NonZero*`.
const YEAR_STARTS_AFTER_THUESDAY: u8 = 1;
const YEAR_STARTS_AFTER_WEDNESDAY: u8 = 2;
const YEAR_STARTS_AFTER_THURSDAY: u8 = 3;
const YEAR_STARTS_AFTER_FRIDAY: u8 = 4;
const YEAR_STARTS_AFTER_SATURDAY: u8 = 5;
const YEAR_STARTS_AFTER_SUNDAY: u8 = 6;

const COMMON_YEAR: u8 = 1 << 3;
const LEAP_YEAR: u8 = 0 << 3;

pub const A = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_SATURDAY);
pub const AG = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_SATURDAY);
pub const B = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_FRIDAY);
pub const BA = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_FRIDAY);
pub const C = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_THURSDAY);
pub const CB = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_THURSDAY);
pub const D = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_WEDNESDAY);
pub const DC = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_WEDNESDAY);
pub const E = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_THUESDAY);
pub const ED = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_THUESDAY);
pub const F = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_MONDAY);
pub const FE = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_MONDAY);
pub const G = YearFlags.new(COMMON_YEAR | YEAR_STARTS_AFTER_SUNDAY);
pub const GF = YearFlags.new(LEAP_YEAR | YEAR_STARTS_AFTER_SUNDAY);

const YEAR_TO_FLAGS = [_]YearFlags{
    BA, G, F, E, DC, B, A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA,
    G, F, E, DC, B, A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G,
    F, E, DC, B, A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F,
    E, DC, B, A, G, FE, D, C, B, AG, F, E, D, // 100
    C, B, A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC,
    B, A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B,
    A, G, FE, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A,
    G, FE, D, C, B, AG, F, E, D, CB, A, G, F, // 200
    E, D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE,
    D, C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE, D,
    C, B, AG, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE, D, C,
    B, AG, F, E, D, CB, A, G, F, ED, C, B, A, // 300
    G, F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE, D, C, B, AG,
    F, E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE, D, C, B, AG, F,
    E, D, CB, A, G, F, ED, C, B, A, GF, E, D, C, BA, G, F, E, DC, B, A, G, FE, D, C, B, AG, F, E,
    D, CB, A, G, F, ED, C, B, A, GF, E, D, C, // 400
};

fn rem_euclid(this: i32, other: i32) i32 {
    return @mod(this, other);
}


// impl fmt::Debug for YearFlags {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         let YearFlags(flags) = *self;
//         match flags {
//             0o15 => "A".fmt(f),
//             0o05 => "AG".fmt(f),
//             0o14 => "B".fmt(f),
//             0o04 => "BA".fmt(f),
//             0o13 => "C".fmt(f),
//             0o03 => "CB".fmt(f),
//             0o12 => "D".fmt(f),
//             0o02 => "DC".fmt(f),
//             0o11 => "E".fmt(f),
//             0o01 => "ED".fmt(f),
//             0o10 => "F?".fmt(f),
//             0o00 => "FE?".fmt(f), // non-canonical
//             0o17 => "F".fmt(f),
//             0o07 => "FE".fmt(f),
//             0o16 => "G".fmt(f),
//             0o06 => "GF".fmt(f),
//             _ => write!(f, "YearFlags({})", flags),
//         }
//     }
// }

// OL: (ordinal << 1) | leap year flag
const MAX_OL: u32 = 366 << 1; // `(366 << 1) | 1` would be day 366 in a non-leap year
const MAX_MDL: u32 = (12 << 6) | (31 << 1) | 1;

// The next table are adjustment values to convert a date encoded as month-day-leapyear to
// ordinal-leapyear. OL = MDL - adjustment.
// Dates that do not exist are encoded as `XX`.
const XX: i8 = 0;
const MDL_TO_OL = [_]u32{
    XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX,
    XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX,
    XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, XX, // 0
    XX, XX, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, // 1
    XX, XX, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, XX, XX, XX, XX, XX, // 2
    XX, XX, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, // 3
    XX, XX, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76,
    74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76,
    74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, XX, XX, // 4
    XX, XX, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80,
    78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80,
    78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, // 5
    XX, XX, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82,
    80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82,
    80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, XX, XX, // 6
    XX, XX, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86,
    84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86,
    84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, // 7
    XX, XX, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88,
    86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88,
    86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, // 8
    XX, XX, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90,
    88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90,
    88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, XX, XX, // 9
    XX, XX, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94,
    92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94,
    92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, // 10
    XX, XX, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96,
    94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96,
    94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, XX, XX, // 11
    XX, XX, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, // 12
};

const OL_TO_MDL= [_]u8{
    0, 0, // 0
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, // 1
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, // 2
    74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72,
    74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72,
    74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, // 3
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, // 4
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, // 5
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, // 6
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, // 7
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, // 8
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, // 9
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, // 10
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94,
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94,
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, // 11
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, // 12
};

/// Month, day of month and year flags: `(month << 9) | (day << 4) | flags`
/// `M_MMMD_DDDD_LFFF`
///
/// The whole bits except for the least 3 bits are referred as `Mdl` (month, day of month, and leap
/// year flag), which is an index to the `MDL_TO_OL` lookup table.
///
/// The conversion between the packed calendar date (`Mdf`) and the ordinal date (`NaiveDate`) is
/// based on the moderately-sized lookup table (~1.5KB) and the packed representation is chosen for
/// efficient lookup.
///
/// The methods of `Mdf` validate their inputs as late as possible. Dates that can't exist, like
/// February 30, can still be represented. This allows the validation to be combined with the final
/// table lookup, which is good for performance.
pub const Mdf = struct {
    value: u32,

    const Self = @This();
    pub fn new_value(value: u32) Mdf {
        return Self {
            .value = value,
        };
    }

    pub fn set(self: *Self, value: u32) void {
        self.value = value;
    }

    pub fn get(self: Self) u32 {
        return self.value;
    }


    /// Makes a new `Mdf` value from month, day and `YearFlags`.
    ///
    /// This method doesn't fully validate the range of the `month` and `day` parameters, only as
    /// much as what can't be deferred until later. The year `flags` are trusted to be correct.
    ///
    /// # Errors
    ///
    /// Returns `None` if `month > 12` or `day > 31`.
    pub fn new(_month: u32, _day: u32, yearFlags: YearFlags) ?Mdf {
        if (_month <= 12 and _day <= 31) {
            return Mdf.new_value((_month << 9) | (_day << 4) | yearFlags.get());
        }
        return null;
    }

    /// Makes a new `Mdf` value from an `i32` with an ordinal and a leap year flag, and year
    /// `flags`.
    ///
    /// The `ol` is trusted to be valid, and the `flags` are trusted to match it.
    pub fn from_ol(ol: i32, yearFlags: YearFlags) Mdf {
        std.debug.assert(ol > 1 and ol <= MAX_OL);
        // Array is indexed from `[2..=MAX_OL]`, with a `0` index having a meaningless value.
        return Mdf.new_value(((ol + OL_TO_MDL[ol]) << 3) |  yearFlags.get());
    }

    /// Returns the month of this `Mdf`.
    pub fn month(self: Self) u32 {
        return self.value >> 9;
    }

    /// Replaces the month of this `Mdf`, keeping the day and flags.
    ///
    /// # Errors
    ///
    /// Returns `None` if `month > 12`.
    pub fn with_month(self: Self, _month: u32) ?Mdf {
        if (_month > 12) {
            return null;
        }
        return Mdf.new_value((self.value & 0b1_1111_1111) | (_month << 9));
    }

    /// Returns the day of this `Mdf`.
    pub fn day(self: Self) u32 {
        return (self.value >> 4) & 0b1_1111;
    }

    /// Replaces the day of this `Mdf`, keeping the month and flags.
    ///
    /// # Errors
    ///
    /// Returns `None` if `day > 31`.
    pub fn with_day(self: Self, _day: u32) Mdf {
        if (_day > 31) {
            return null;
        }
        return Mdf.new_value((self.value & !0b1_1111_0000) | (_day << 4));
    }

    /// Replaces the flags of this `Mdf`, keeping the month and day.
    pub fn with_flags(self: Self, yearFlags: YearFlags) Mdf {
        return Mdf.new_value((self.value & !0b1111) | yearFlags.value);
    }


    // /// Returns the ordinal that corresponds to this `Mdf`.
    // ///
    // /// This does a table lookup to calculate the corresponding ordinal. It will return an error if
    // /// the `Mdl` turns out not to be a valid date.
    // ///
    // /// # Errors
    // ///
    // /// Returns `None` if `month == 0` or `day == 0`, or if a the given day does not exist in the
    // /// given month.
    // pub fn ordinal(self: Self) ?u32 {
    //     const mdl = self.value >> 3;
    //     const value = switch (MDL_TO_OL[mdl]) {
    //         XX => null,
    //         v => (mdl - v) >> 1,
    //     };
    //     return value;
    // }

    // /// Returns the year flags of this `Mdf`.
    // pub fn year_flags(self: Self) YearFlags {
    //     return YearFlags.new(self.value & 0b1111);
    // }

    /// Returns the ordinal that corresponds to this `Mdf`, encoded as a value including year flags.
    ///
    /// This does a table lookup to calculate the corresponding ordinal. It will return an error if
    /// the `Mdl` turns out not to be a valid date.
    ///
    /// # Errors
    ///
    /// Returns `None` if `month == 0` or `day == 0`, or if a the given day does not exist in the
    /// given month.
    pub fn ordinal_and_flags(self: Self) u32 {
        const mdl = self.value >> 3;
        if (MDL_TO_OL[mdl] == XX) {
            @panic("ordinal_and_flags() function is failed");
        }
        return self.value - (MDL_TO_OL[mdl] << 3);
    }

    fn valid(self: Self) bool {
        const mdl = self.value >> 3;
        return MDL_TO_OL[mdl] > 0;
    }

};



// impl fmt::Debug for Mdf {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         let Mdf(mdf) = *self;
//         write!(
//             f,
//             "Mdf(({} << 9) | ({} << 4) | {:#04o} /*{:?}*/)",
//             mdf >> 9,
//             (mdf >> 4) & 0b1_1111,
//             mdf & 0b1111,
//             YearFlags((mdf & 0b1111) as u8)
//         )
//     }
// }


    // use super::Mdf;
    // use super::{A, AG, B, BA, C, CB, D, DC, E, ED, F, FE, G, GF, YearFlags};

const NONLEAP_FLAGS = [_]YearFlags{A, B, C, D, E, F, G};
const LEAP_FLAGS = [_]YearFlags{AG, BA, CB, DC, ED, FE, GF};
const FLAGS = [_]YearFlags{A, B, C, D, E, F, G, AG, BA, CB, DC, ED, FE, GF};

const testing = @import("std").testing;


test "test_year_flags_ndays_from_year" {
    try testing.expect(YearFlags.from_year(2014).ndays() == 365);
    try testing.expect(YearFlags.from_year(2012).ndays() == 366);
    try testing.expect(YearFlags.from_year(2000).ndays() == 366);
    try testing.expect(YearFlags.from_year(1900).ndays() == 365);
    try testing.expect(YearFlags.from_year(1600).ndays() == 366);
    try testing.expect(YearFlags.from_year(1).ndays() == 365);
    try testing.expect(YearFlags.from_year(0).ndays() == 366); // 1 BCE (proleptic Gregorian)
    try testing.expect(YearFlags.from_year(-1).ndays() == 365); // 2 BCE
    try testing.expect(YearFlags.from_year(-4).ndays() == 366); // 5 BCE
    try testing.expect(YearFlags.from_year(-99).ndays() == 365); // 100 BCE
    try testing.expect(YearFlags.from_year(-100).ndays() == 365); // 101 BCE
    try testing.expect(YearFlags.from_year(-399).ndays() == 365); // 400 BCE
    try testing.expect(YearFlags.from_year(-400).ndays() == 366); // 401 BCE
}

 
// test "test_year_flags_nisoweeks" {
//     try testing.expect(A.nisoweeks() == 52);
//     try testing.expect(B.nisoweeks() == 52);
//     try testing.expect(C.nisoweeks() == 52);
//     try testing.expect(D.nisoweeks() == 53);
//     try testing.expect(E.nisoweeks() == 52);
//     try testing.expect(F.nisoweeks() == 52);
//     try testing.expect(G.nisoweeks() == 52);
//     try testing.expect(AG.nisoweeks() == 52);
//     try testing.expect(BA.nisoweeks() == 52);
//     try testing.expect(CB.nisoweeks() == 52);
//     try testing.expect(DC.nisoweeks() == 53);
//     try testing.expect(ED.nisoweeks() == 53);
//     try testing.expect(FE.nisoweeks() == 52);
//     try testing.expect(GF.nisoweeks() == 52);
// }

    
    // test "test_mdf_valid" {
    //     fn check(expected: bool, flags: YearFlags, month1: u32, day1: u32, month2: u32, day2: u32) {
    //         for month in month1..=month2 {
    //             for day in day1..=day2 {
    //                 let mdf = match Mdf::new(month, day, flags) {
    //                     Some(mdf) => mdf,
    //                     None if !expected => continue,
    //                     None => panic!("Mdf::new({}, {}, {:?}) returned None", month, day, flags),
    //                 };

    //                 assert!(
    //                     mdf.valid() == expected,
    //                     "month {} day {} = {:?} should be {} for dominical year {:?}",
    //                     month,
    //                     day,
    //                     mdf,
    //                     if expected { "valid" } else { "invalid" },
    //                     flags
    //                 );
    //             }
    //         }
    //     }

    //     for &flags in NONLEAP_FLAGS.iter() {
    //         check(false, flags, 0, 0, 0, 1024);
    //         check(false, flags, 0, 0, 16, 0);
    //         check(true, flags, 1, 1, 1, 31);
    //         check(false, flags, 1, 32, 1, 1024);
    //         check(true, flags, 2, 1, 2, 28);
    //         check(false, flags, 2, 29, 2, 1024);
    //         check(true, flags, 3, 1, 3, 31);
    //         check(false, flags, 3, 32, 3, 1024);
    //         check(true, flags, 4, 1, 4, 30);
    //         check(false, flags, 4, 31, 4, 1024);
    //         check(true, flags, 5, 1, 5, 31);
    //         check(false, flags, 5, 32, 5, 1024);
    //         check(true, flags, 6, 1, 6, 30);
    //         check(false, flags, 6, 31, 6, 1024);
    //         check(true, flags, 7, 1, 7, 31);
    //         check(false, flags, 7, 32, 7, 1024);
    //         check(true, flags, 8, 1, 8, 31);
    //         check(false, flags, 8, 32, 8, 1024);
    //         check(true, flags, 9, 1, 9, 30);
    //         check(false, flags, 9, 31, 9, 1024);
    //         check(true, flags, 10, 1, 10, 31);
    //         check(false, flags, 10, 32, 10, 1024);
    //         check(true, flags, 11, 1, 11, 30);
    //         check(false, flags, 11, 31, 11, 1024);
    //         check(true, flags, 12, 1, 12, 31);
    //         check(false, flags, 12, 32, 12, 1024);
    //         check(false, flags, 13, 0, 16, 1024);
    //         check(false, flags, u32::MAX, 0, u32::MAX, 1024);
    //         check(false, flags, 0, u32::MAX, 16, u32::MAX);
    //         check(false, flags, u32::MAX, u32::MAX, u32::MAX, u32::MAX);
    //     }

    //     for &flags in LEAP_FLAGS.iter() {
    //         check(false, flags, 0, 0, 0, 1024);
    //         check(false, flags, 0, 0, 16, 0);
    //         check(true, flags, 1, 1, 1, 31);
    //         check(false, flags, 1, 32, 1, 1024);
    //         check(true, flags, 2, 1, 2, 29);
    //         check(false, flags, 2, 30, 2, 1024);
    //         check(true, flags, 3, 1, 3, 31);
    //         check(false, flags, 3, 32, 3, 1024);
    //         check(true, flags, 4, 1, 4, 30);
    //         check(false, flags, 4, 31, 4, 1024);
    //         check(true, flags, 5, 1, 5, 31);
    //         check(false, flags, 5, 32, 5, 1024);
    //         check(true, flags, 6, 1, 6, 30);
    //         check(false, flags, 6, 31, 6, 1024);
    //         check(true, flags, 7, 1, 7, 31);
    //         check(false, flags, 7, 32, 7, 1024);
    //         check(true, flags, 8, 1, 8, 31);
    //         check(false, flags, 8, 32, 8, 1024);
    //         check(true, flags, 9, 1, 9, 30);
    //         check(false, flags, 9, 31, 9, 1024);
    //         check(true, flags, 10, 1, 10, 31);
    //         check(false, flags, 10, 32, 10, 1024);
    //         check(true, flags, 11, 1, 11, 30);
    //         check(false, flags, 11, 31, 11, 1024);
    //         check(true, flags, 12, 1, 12, 31);
    //         check(false, flags, 12, 32, 12, 1024);
    //         check(false, flags, 13, 0, 16, 1024);
    //         check(false, flags, u32::MAX, 0, u32::MAX, 1024);
    //         check(false, flags, 0, u32::MAX, 16, u32::MAX);
    //         check(false, flags, u32::MAX, u32::MAX, u32::MAX, u32::MAX);
    //     }
    // }

    // #[test]
    // fn test_mdf_fields() {
    //     for &flags in FLAGS.iter() {
    //         for month in 1u32..=12 {
    //             for day in 1u32..31 {
    //                 let mdf = match Mdf::new(month, day, flags) {
    //                     Some(mdf) => mdf,
    //                     None => continue,
    //                 };

    //                 if mdf.valid() {
    //                     assert_eq!(mdf.month(), month);
    //                     assert_eq!(mdf.day(), day);
    //                 }
    //             }
    //         }
    //     }
    // }

    // #[test]
    // fn test_mdf_with_fields() {
    //     fn check(flags: YearFlags, month: u32, day: u32) {
    //         let mdf = Mdf::new(month, day, flags).unwrap();

    //         for month in 0u32..=16 {
    //             let mdf = match mdf.with_month(month) {
    //                 Some(mdf) => mdf,
    //                 None if month > 12 => continue,
    //                 None => panic!("failed to create Mdf with month {}", month),
    //             };

    //             if mdf.valid() {
    //                 assert_eq!(mdf.month(), month);
    //                 assert_eq!(mdf.day(), day);
    //             }
    //         }

    //         for day in 0u32..=1024 {
    //             let mdf = match mdf.with_day(day) {
    //                 Some(mdf) => mdf,
    //                 None if day > 31 => continue,
    //                 None => panic!("failed to create Mdf with month {}", month),
    //             };

    //             if mdf.valid() {
    //                 assert_eq!(mdf.month(), month);
    //                 assert_eq!(mdf.day(), day);
    //             }
    //         }
    //     }

    //     for &flags in NONLEAP_FLAGS.iter() {
    //         check(flags, 1, 1);
    //         check(flags, 1, 31);
    //         check(flags, 2, 1);
    //         check(flags, 2, 28);
    //         check(flags, 2, 29);
    //         check(flags, 12, 31);
    //     }
    //     for &flags in LEAP_FLAGS.iter() {
    //         check(flags, 1, 1);
    //         check(flags, 1, 31);
    //         check(flags, 2, 1);
    //         check(flags, 2, 29);
    //         check(flags, 2, 30);
    //         check(flags, 12, 31);
    //     }
    // }

    // #[test]
    // fn test_mdf_new_range() {
    //     let flags = YearFlags::from_year(2023);
    //     assert!(Mdf::new(13, 1, flags).is_none());
    //     assert!(Mdf::new(1, 32, flags).is_none());
    // }

