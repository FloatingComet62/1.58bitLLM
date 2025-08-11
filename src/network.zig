const std = @import("std");
const layer = @import("layer.zig");
const activation = @import("activation.zig");
const NetworkLearnData = @import("learn_data.zig").NetworkLearnData;

pub const Network = struct {
    const Self = @This();
    layers: std.ArrayList(layer.Layer),

    pub fn init(
        log: anytype,
        allocator: std.mem.Allocator,
        layer_nodes: std.ArrayList(u32),
        activationFunction: activation.Function,
    ) anyerror!Self {
        std.debug.assert(layer_nodes.items.len > 1);
        var layers = try std.ArrayList(layer.Layer).initCapacity(allocator, layer_nodes.items.len - 1);
        var i: u32 = 1;
        while (i < layer_nodes.items.len) {
            const in_nodes = layer_nodes.items[i - 1];
            const out_nodes = layer_nodes.items[i];
            layers.appendAssumeCapacity(try layer.Layer.init(
                log,
                allocator,
                in_nodes,
                out_nodes,
                activationFunction
            ));
            i += 1;
        }
        return .{
            .layers = layers,
        };
    }

    pub fn apply(self: Self, input: std.ArrayList(f64)) std.ArrayList(f64) {
        var layer_input = input;
        for (self.layers.items) |network_layer| {
            network_layer.apply(layer_input);
            layer_input = network_layer.output;
        }
        return layer_input;
    }

    pub fn applyGradients(self: *Self, input: std.ArrayList(f64), expected_output: std.ArrayList(f64), network_learn: NetworkLearnData) void {
        //TODO
    }
};
