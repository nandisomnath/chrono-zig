Chrono: Timezone-aware date and time handling
========================================



Chrono aims to provide all functionality needed to do correct operations on dates and times in the
[proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar):

* The `DateTime` type is timezone-aware
  by default, with separate timezone-naive types.
* Operations that may produce an invalid or ambiguous date and time return `Option` or `MappedLocalTime`
* Configurable parsing and formatting with an `strftime` inspired date and time formatting syntax.
* The `Local` timezone works with the current timezone of the OS.
* Types and operations are implemented to be reasonably efficient.

Timezone data is not shipped with chrono by default to limit binary sizes. Use the companion crate
[Chrono-TZ](https://crates.io/crates/chrono-tz) or [`tzfile`](https://crates.io/crates/tzfile) for
full timezone support.

## Documentation

Not available for now

<!-- See [docs.rs](https://docs.rs/chrono/latest/chrono/) for the API reference. -->

## Limitations

* Only the proleptic Gregorian calendar (i.e. extended to support older dates) is supported.
* Date types are limited to about +/- 262,000 years from the common epoch.
* Time types are limited to nanosecond accuracy.
* Leap seconds can be represented, but Chrono does not fully support them.

## Module features



## Rust version requirements

The Minimum Supported Zig Version is currently **Rust 0.14.0**.


## License

This project is licensed under 
* [MIT License](https://opensource.org/licenses/MIT)


