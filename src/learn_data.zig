const std = @import("std");
const Layer = @import("layer.zig").Layer;

pub const LayerLearnData = struct {
    const Self = @This();

    inputs: std.ArrayList(f64),
    weighted_inputs: std.ArrayList(f64),
    activations: std.ArrayList(f64),
    node_values: std.ArrayList(f64),

    fn init(allocator: std.mem.Allocator, layer: Layer) anyerror!Self {
        return .{
            .inputs = try std.ArrayList(f64).initCapacity(allocator, layer.number_of_rows),
            .activations = try std.ArrayList(f64).initCapacity(allocator, layer.number_of_rows),
            .node_values = try std.ArrayList(f64).initCapacity(allocator, layer.number_of_rows),
        };
    }
};

pub const NetworkLearnData = struct {
    const Self = @This();
    layer_data: std.ArrayList(LayerLearnData),

    fn init(allocator: std.mem.Allocator, layers: std.ArrayList(Layer)) anyerror!Self {
        var layer_data = try std.ArrayList(f64).initCapacity(allocator, layers.items.len);
        for (layers.items) |layer| {
            layer_data.appendAssumeCapacity(try LayerLearnData.init(allocator, layer));
        }
        return .{
            .layer_data = layer_data
        };
    }
};
