const std = @import("std");
const lib = @import("_158bit_lib");
const Layer = lib.layer.Layer;
const Network = lib.network.Network;
const activation = lib.activation;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const inputSlice = [_]f64{ 1, 2, 3, 4, 5 };
    const networkStructureSlice = [_]u32{ inputSlice.len, 10, 5 };
    const activationFunction = activation.Sigmoid;

    var networkStructure = try std.ArrayList(u32).initCapacity(
        std.heap.page_allocator,
        networkStructureSlice.len
    );
    defer networkStructure.deinit();
    for (networkStructureSlice) |item| {
        networkStructure.appendAssumeCapacity(item);
    }
    var input = try std.ArrayList(f64).initCapacity(std.heap.page_allocator, inputSlice.len);
    defer input.deinit();
    for (inputSlice) |item| {
        input.appendAssumeCapacity(item);
    }

    var network = try Network.init(
        stdout,
        allocator,
        networkStructure,
        activationFunction.function()
    );

    const output = network.apply(input);
    for (output.items) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});

    try bw.flush();
}

