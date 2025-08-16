const std = @import("std");
const lib = @import("_158bit_lib");
const Layer = lib.layer.Layer;
const Network = lib.network.Network;
const DataSet = lib.dataset.Dataset;
const activation = lib.activation;
const cost = lib.cost;

const INPUT_LEN = 5;
const OUTPUT_LEN = 5;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const networkStructure = [_]u32{ INPUT_LEN, 10, OUTPUT_LEN };
    const activationFunction = activation.Sigmoid;
    const costFunction = cost.MeanSquaredError;

    var prng = std.Random.DefaultPrng.init(1);
    const rand = prng.random();

    var network = try Network.init(
        stdout,
        allocator,
        &networkStructure,
        activationFunction.function(),
        costFunction.function(),
    );
    network.initialize_random_layer_weights(rand);

    const dataset = try DataSet.init(allocator, @embedFile("training_data.txt"));
    // for (dataset.datapoints.items) |datapoint| {
    //     try stdout.print("Datapoint: Input(", .{});
    //     for (datapoint.input.items) |input_item| {
    //         try stdout.print("{d}, ", .{input_item});
    //     }
    //     try stdout.print("), Output(", .{});
    //     for (datapoint.output.items) |output_item| {
    //         try stdout.print("{d}, ", .{output_item});
    //     }
    //     try stdout.print(")\n", .{});
    // }
    _ = dataset;

    try stdout.print("\n", .{});

    try bw.flush();
}

