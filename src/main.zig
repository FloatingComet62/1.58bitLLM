const std = @import("std");
const lib = @import("_158bit_lib");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var layer = try lib.Layer.init(stdout, allocator, 5, 5);
    layer.set_weight(7, 2);

    try bw.flush();
}

