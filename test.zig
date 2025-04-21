const std = @import("std");


pub fn main() !void {
    const v = ~ 0b1_1111_0000;

    std.debug.print("{b}\n", .{v});

}

