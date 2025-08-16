const std = @import("std");
const layer = @import("layer.zig");
const activation = @import("activation.zig");
const cost = @import("cost.zig");
const NetworkLearnData = @import("learn_data.zig").NetworkLearnData;

pub const Network = struct {
    const Self = @This();
    layers: std.ArrayList(layer.Layer),

    pub fn init(
        log: anytype,
        allocator: std.mem.Allocator,
        layer_nodes: []const u32,
        activationFunction: activation.Function,
        costFunction: cost.CostFunction,
    ) anyerror!Self {
        std.debug.assert(layer_nodes.len > 1);
        var layers = try std.ArrayList(layer.Layer).initCapacity(allocator, layer_nodes.len - 1);
        var i: u32 = 1;
        while (i < layer_nodes.len) {
            const in_nodes = layer_nodes[i - 1];
            const out_nodes = layer_nodes[i];
            layers.appendAssumeCapacity(try layer.Layer.init(
                log,
                allocator,
                in_nodes,
                out_nodes,
                activationFunction,
                costFunction
            ));
            i += 1;
        }
        return .{
            .layers = layers,
        };
    }

    pub fn initialize_random_layer_weights(self: *Self, rand: std.Random) void {
        for (0..self.layers.items.len) |i| {
            self.layers.items[i].initialize_random_weights(rand);
        }
    }

    pub fn apply(self: Self, input: []const f64) []const f64 {
        var layer_input = input;
        for (self.layers.items) |network_layer| {
            network_layer.apply(layer_input);
            layer_input = network_layer.output.items;
        }
        return layer_input;
    }
    //
    // pub fn applyGradients(self: *Self, input: std.ArrayList(f64), expected_output: std.ArrayList(f64), network_learn: NetworkLearnData) void {
    //     //TODO
    // }
};
