const std = @import("std");
const weightset = @import("weightset.zig");
const activation = @import("activation.zig");

pub const Layer = struct {
    const Self = @This();
    weights: std.ArrayList(u8),
    output: std.ArrayList(f64),
    number_of_rows: u32,
    number_of_columns: u32,
    activationFunction: activation.Function,

    // TODO: resolve anytype
    pub fn init(
        log: anytype,
        allocator: std.mem.Allocator,
        in_nodes: u32,
        out_nodes: u32,
        activationFunction: activation.Function,
    ) anyerror!Self {
        if ((in_nodes % 5 != 0) or (out_nodes % 5 != 0)) {
            try log.print("It is recommanded to use a multiple of 5 for the number of nodes\n", .{});
        }
        const number_of_columns = try std.math.divCeil(u32, in_nodes, 5);
        const number_of_rows = out_nodes;
        const number_of_items = number_of_columns * number_of_rows;
        var weights = try std.ArrayList(u8).initCapacity(allocator, number_of_items);
        for (0..number_of_items) |_| {
            weights.appendAssumeCapacity(0);
        }
        var biases = try std.ArrayList(f64).initCapacity(allocator, number_of_rows);
        var output = try std.ArrayList(f64).initCapacity(allocator, number_of_rows);
        for (0..number_of_rows) |_| {
            biases.appendAssumeCapacity(0.0);
            output.appendAssumeCapacity(0.0);
        }
        return .{
            .weights = weights,
            .output = output,
            .number_of_rows = number_of_rows,
            .number_of_columns = number_of_columns,
            .activationFunction = activationFunction,
        };
    }

    pub fn set_weight(self: *Self, weight_index: u32, weight: u8) void {
        const quotient = @divTrunc(weight_index, 5);
        const remainder = @as(u8, @intCast(@mod(weight_index, 5)));
        var modifyableWeightSet = weightset.ModifyableWeightSet.init(self.weights.items[quotient]);
        modifyableWeightSet.set_weight(remainder, weight);
        self.weights.items[quotient] = modifyableWeightSet.value();
    }
    pub fn set_weightset(self: *Self, weightset_index: u32, weight_set: u8) void {
        self.weights[weightset_index] = weight_set;
    }

    pub fn set_bias(self: *Self, bias_index: u32, bias: f64) void {
        self.biases.items[bias_index] = bias;
    }

    pub fn apply(
        self: Self,
        prev_layer_outputs: std.ArrayList(f64)
    ) void {
        std.debug.assert(prev_layer_outputs.items.len <= (self.number_of_columns * 5));
        for (0..self.number_of_rows) |i| {
            self.output.items[i] = self.biases.items[i];
            for (0..self.number_of_columns) |j| {
                self.output.items[i] += applyWeights(
                    @Vector(5, f64){
                        safe_index(prev_layer_outputs, 5 * j + 0),
                        safe_index(prev_layer_outputs, 5 * j + 1),
                        safe_index(prev_layer_outputs, 5 * j + 2),
                        safe_index(prev_layer_outputs, 5 * j + 3),
                        safe_index(prev_layer_outputs, 5 * j + 4),
                    },
                    weightset.weightset_value_to_abcde(self.weights.items[i * self.number_of_columns + j])
                );
            }
            self.output.items[i] = self.activationFunction.solve(self.output.items[i]);
        }
    }
};

fn safe_index(arr: std.ArrayList(f64), i: usize) f64 {
    if (i >= arr.items.len) {
        return 0.0;
    }
    return arr.items[i];
}

fn applyWeights(inputs: @Vector(5, f64), abcde: weightset.ABCDE) f64 {
    // TODO: do the bit manipulation technique
    const weights = @Vector(5, f64){
        @floatFromInt(((abcde.abcd & 0b11000000) >> 6) - 1),
        @floatFromInt(((abcde.abcd & 0b00110000) >> 4) - 1),
        @floatFromInt(((abcde.abcd & 0b00001100) >> 2) - 1),
        @floatFromInt(((abcde.abcd & 0b00000011)) - 1),
        @floatFromInt((abcde.e) - 1),
    };
    const vec = inputs * weights;
    return vec[0] + vec[1] + vec[2] + vec[3] + vec[4];
}
