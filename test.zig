const std = @import("std");


pub fn main() !void {
    const v = 0b0000_0100_0000_0110;

    std.debug.print("{d}\n", .{v});

}

