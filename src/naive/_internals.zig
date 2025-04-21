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
    value: u8,
    const Self = @This();

    pub fn new(value: u8) YearFlags {
        return YearFlags{
            .value = value,
        };
    }

    pub fn set(self: *Self, value: u8) void {
        self.value = value;
    }

    pub fn get(self: Self) u8 {
        return self.value;
    }

    pub fn from_year(_year: i32) YearFlags {
        const year = @mod(_year, 400); 
        return YearFlags.from_year_mod_400(year);
    }

    pub fn from_year_mod_400(year: i32) YearFlags {
        return YEAR_TO_FLAGS[@intCast(year)];
    }

    pub fn ndays(self: Self) u32 {
        return std.math.sub(u32, 366, (self.value >> 3)) catch @panic("ndays(): unable to subtract.");
    }

    pub fn isoweek_delta(self: Self) u32 {
        var delta = self.value & 0b0111;
        if (delta < 3) {
            delta += 7;
        }
        return delta;
    }

    // TODO: find a left shift and right shift alternative
    pub fn nisoweeks(self: Self) u32 {
        const v: u32 = 1030;
        const value = v >> std.math.cast(u5, self.value).?; //>> self.value);
        return 52 + (value & 1);
    }
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
    BA, G, F,  E,  DC, B, A,  G,  FE, D, C,  B,  AG, F, E,  D,  CB, A, G,  F,  ED, C, B,  A,  GF, E, D,  C,  BA,
    G,  F, E,  DC, B,  A, G,  FE, D,  C, B,  AG, F,  E, D,  CB, A,  G, F,  ED, C,  B, A,  GF, E,  D, C,  BA, G,
    F,  E, DC, B,  A,  G, FE, D,  C,  B, AG, F,  E,  D, CB, A,  G,  F, ED, C,  B,  A, GF, E,  D,  C, BA, G,  F,
    E,  DC, B,  A,  G,  FE, D,  C,  B,  AG, F,  E,  D, // 100
    C,  B,  A,  G,  FE, D,  C,  B,  AG, F,  E,  D,  CB,
    A,  G,  F,  ED, C,  B,  A,  GF, E,  D,  C,  BA, G,
    F,  E,  DC, B,  A,  G,  FE, D,  C,  B,  AG, F,  E,
    D,  CB, A,  G,  F,  ED, C,  B,  A,  GF, E,  D,  C,
    BA, G,  F,  E,  DC, B,  A,  G,  FE, D,  C,  B,  AG,
    F,  E,  D,  CB, A,  G,  F,  ED, C,  B,  A,  GF, E,
    D,  C,  BA, G,  F,  E,  DC, B,  A,
    G,  FE, D,  C,  B,  AG, F,  E,  D,  CB, A,  G,  F, // 200
    E,  D,  C,  B,  AG, F,  E,  D,  CB, A,  G,  F,  ED,
    C,  B,  A,  GF, E,  D,  C,  BA, G,  F,  E,  DC, B,
    A,  G,  FE, D,  C,  B,  AG, F,  E,  D,  CB, A,  G,
    F,  ED, C,  B,  A,  GF, E,  D,  C,  BA, G,  F,  E,
    DC, B,  A,  G,  FE, D,  C,  B,  AG, F,  E,  D,  CB,
    A,  G,  F,  ED, C,  B,  A,  GF, E,  D,  C,  BA, G,
    F,  E,  DC, B,  A,  G,  FE, D,  C,
    B,  AG, F,  E,  D,  CB, A,  G,  F,  ED, C,  B,  A, // 300
    G,  F,  E,  D,  CB, A,  G,  F,  ED, C,  B,  A,  GF,
    E,  D,  C,  BA, G,  F,  E,  DC, B,  A,  G,  FE, D,
    C,  B,  AG, F,  E,  D,  CB, A,  G,  F,  ED, C,  B,
    A,  GF, E,  D,  C,  BA, G,  F,  E,  DC, B,  A,  G,
    FE, D,  C,  B,  AG, F,  E,  D,  CB, A,  G,  F,  ED,
    C,  B,  A,  GF, E,  D,  C,  BA, G,  F,  E,  DC, B,
    A,  G,  FE, D,  C,  B,  AG, F,  E,
    D, CB, A, G, F, ED, C, B, A, GF, E, D, C, // 400
};


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
    XX, XX, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, // 1
    XX, XX, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, XX, XX, XX, XX, XX, // 2
    XX, XX, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, // 3
    XX, XX, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76,
    74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76,
    74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76,
    74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, XX, XX, // 4
    XX, XX, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80,
    78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80,
    78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80,
    78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, // 5
    XX, XX, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82,
    80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82,
    80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82,
    80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, XX, XX, // 6
    XX, XX, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86,
    84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86,
    84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86,
    84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, // 7
    XX, XX, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88,
    86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88,
    86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88,
    86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, // 8
    XX, XX, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90,
    88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90,
    88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90,
    88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, XX, XX, // 9
    XX, XX, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94,
    92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94,
    92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94,
    92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, // 10
    XX, XX, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96,
    94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96,
    94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96,
    94, 96,  94, 96,  94, 96,  94, 96,  94, 96,  94, 96,  94, 96,  XX, XX, // 11
    XX, XX,  98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100,
    98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, // 12
};

const OL_TO_MDL = [_]u8{
    0,  0, // 0
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, // 1
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66,
    66, 66, 66, 66, 66, 66, 66, 66, 66, // 2
    74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72,
    74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72, 74, 72, 74, 72, 74, 72,
    74, 72, 74, 72, 74, 72, 74, 72, 74,
    72, 74, 72,
    74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, 74, 72, // 3
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74,
    76, 74, 76, 74, 76, 74, 76, 74, 76, 74, 76, 74, // 4
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78,
    80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, 80, 78, // 5
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80,
    82, 80, 82, 80, 82, 80, 82, 80, 82, 80, 82, 80, // 6
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84,
    86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, 86, 84, // 7
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86,
    88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, 88, 86, // 8
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88,
    90, 88, 90, 88, 90, 88, 90, 88, 90, 88, 90, 88, // 9
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92,
    94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, 94, 92, // 10
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94,
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94,
    96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94, 96, 94,
    96, 94, 96, 94, 96, 94,
    96,  94, 96,  94, 96,  94, 96,  94, 96,  94, 96,  94, // 11
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100, 98, 100, 98, 100, 98, 100, 98, 100, 98, 100, 98,
    100,
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
        return Self{
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
        if (_month > 12 or _day > 31) {
            return null;
        }
        return Mdf.new_value((_month << 9) | (_day << 4) | yearFlags.get());
    }

    /// Makes a new `Mdf` value from an `i32` with an ordinal and a leap year flag, and year
    /// `flags`.
    ///
    /// The `ol` is trusted to be valid, and the `flags` are trusted to match it.
    pub fn from_ol(ol: i32, yearFlags: YearFlags) Mdf {
        std.debug.assert(ol > 1 and ol <= MAX_OL);
        // Array is indexed from `[2..=MAX_OL]`, with a `0` index having a meaningless value.
        return Mdf.new_value(((ol + OL_TO_MDL[ol]) << 3) | yearFlags.get());
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
    pub fn with_day(self: Self, _day: u32) ?Mdf {
        if (_day > 31) {
            return null;
        }
        // ~ @as(u32, 0b1_1111_0000))  = 4294966799
        return Mdf.new_value((self.value & 4294966799 | (_day << 4)));
    }

    /// Replaces the flags of this `Mdf`, keeping the month and day.
    pub fn with_flags(self: Self, yearFlags: YearFlags) Mdf {
        return Mdf.new_value((self.value & ~0b1111) | yearFlags.value);
    }

    /// Returns the ordinal that corresponds to this `Mdf`.
    ///
    /// This does a table lookup to calculate the corresponding ordinal. It will return an error if
    /// the `Mdl` turns out not to be a valid date.
    ///
    /// # Errors
    ///
    /// Returns `None` if `month == 0` or `day == 0`, or if a the given day does not exist in the
    /// given month.
    pub fn ordinal(self: Self) ?u32 {
        const mdl = self.value >> 3; //>> 3;

        if (XX == self) {
            return XX;
        }
        return (mdl - MDL_TO_OL[mdl]) >> 1;
    }

    /// Returns the year flags of this `Mdf`.
    pub fn year_flags(self: Self) YearFlags {
        return YearFlags.new(self.value & 0b1111);
    }

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





