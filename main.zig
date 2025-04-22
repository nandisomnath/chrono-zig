const std = @import("std");


pub fn main() void {
    const flags: u8 = 6;
    const v: u32 = @as(u32, 0b0000010000000110) >> @intCast(flags);
    std.debug.print("{any}", .{v});
    _ = &v;

}
