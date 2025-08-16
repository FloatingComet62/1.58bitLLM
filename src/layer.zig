const std = @import("std");
const weightset = @import("weightset.zig");
const activation = @import("activation.zig");
const cost = @import("cost.zig");
const LayerLearnData = @import("learn_data.zig").LayerLearnData;

pub const Layer = struct {
    const Self = @This();

    weights: std.ArrayList(u8),
    biases: std.ArrayList(f64),
    output: std.ArrayList(f64),

    number_of_rows: u32,
    number_of_columns: u32,

    activationFunction: activation.Function,
    costFunction: cost.CostFunction,

    costGradientWeights: std.ArrayList(u8),
    costGradientBiases: std.ArrayList(f64),
    learnStep: f64,

    // TODO: resolve anytype
    pub fn init(
        log: anytype,
        allocator: std.mem.Allocator,
        in_nodes: u32,
        out_nodes: u32,
        activationFunction: activation.Function,
        costFunction: cost.CostFunction,
    ) anyerror!Self {
        if ((in_nodes % 5 != 0) or (out_nodes % 5 != 0)) {
            try log.print("It is recommanded to use a multiple of 5 for the number of nodes\n", .{});
        }
        const number_of_columns = try std.math.divCeil(u32, in_nodes, 5);
        const number_of_rows = out_nodes;
        const number_of_items = number_of_columns * number_of_rows;
        var weights = try std.ArrayList(u8).initCapacity(allocator, number_of_items);
        var costGradientWeights = try std.ArrayList(u8).initCapacity(allocator, number_of_items);
        for (0..number_of_items) |_| {
            weights.appendAssumeCapacity(0);
            costGradientWeights.appendAssumeCapacity(0);
        }
        var biases = try std.ArrayList(f64).initCapacity(allocator, number_of_rows);
        var costGradientBiases = try std.ArrayList(f64).initCapacity(allocator, number_of_rows);
        var output = try std.ArrayList(f64).initCapacity(allocator, number_of_rows);
        for (0..number_of_rows) |_| {
            biases.appendAssumeCapacity(0.0);
            costGradientBiases.appendAssumeCapacity(0.0);
            output.appendAssumeCapacity(0.0);
        }
        return .{
            .weights = weights,
            .biases = biases,
            .output = output,
            .number_of_rows = number_of_rows,
            .number_of_columns = number_of_columns,
            .activationFunction = activationFunction,
            .costFunction = costFunction,
            .costGradientWeights = costGradientWeights,
            .costGradientBiases = costGradientBiases,
            .learnStep = 0.5,
        };
    }

    pub fn initialize_random_weights(self: *Self, rand: std.Random) void {
        for (0..self.weights.items.len) |i| {
            self.weights.items[i] = rand.intRangeAtMost(u8, 0, 0b11110010);
        }
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
    pub fn get_weight(self: Self, weight_index: u32) u8 {
        const quotient = @divTrunc(weight_index, 5);
        const remainder = @as(u8, @intCast(@mod(weight_index, 5)));
        const modifyableWeightSet = weightset.ModifyableWeightSet.init(self.weights.items[quotient]);
        return (modifyableWeightSet.data << @intCast(remainder * 2)) & 0b11;
    }
    pub fn get_weight2d(self: Self, node_in: usize, node_out: usize) u8 {
        return self.get_weight(node_in * self.number_of_columns + node_out);
    }

    pub fn apply(
        self: Self,
        prev_layer_outputs: []const f64
    ) void {
        std.debug.assert(prev_layer_outputs.len <= (self.number_of_columns * 5));
        for (0..self.number_of_rows) |i| {
            self.output.items[i] = self.biases.items[i];
            for (0..self.number_of_columns) |j| {
                const weightsetObject = weightset.ModifyableWeightSet.init((
                    self.weights.items[i * self.number_of_columns + j]
                ));
                self.output.items[i] += applyWeights(
                    @Vector(5, f64){
                        safe_index(prev_layer_outputs, 5 * j + 0),
                        safe_index(prev_layer_outputs, 5 * j + 1),
                        safe_index(prev_layer_outputs, 5 * j + 2),
                        safe_index(prev_layer_outputs, 5 * j + 3),
                        safe_index(prev_layer_outputs, 5 * j + 4),
                    },
                    weightsetObject.data
                );
            }
            self.output.items[i] = self.activationFunction.solve(self.output.items, i);
        }
    }

    pub fn applyGradients(self: *Self, learnRate: f64) void {
        //TODO: weights
        for (0..self.biases.items.len) |i| {
            self.biases.items[i] += self.costGradientBiases[i] * learnRate;
            self.costGradientBiases[i] = 0;
        }
    }

    pub fn calculateOutputLayerNodeValues(self: *Self, layer_learn_data: *LayerLearnData, expected_output: std.ArrayList(f64)) void {
        std.debug.assert(layer_learn_data.inputs.items.len == expected_output.items.len);
        for (0..layer_learn_data.node_values.items.len) |i| {
            const cost_derivative = self.costFunction.derivative(layer_learn_data.activations.items[i], expected_output.items[i]);
            const activation_derivative = self.activationFunction.derivative(layer_learn_data.weighted_inputs, i);
            layer_learn_data.node_values.items[i] = cost_derivative * activation_derivative;
        }
    }

    pub fn calculateHiddenLayerNodeValues(self: *Self, layer_learn_data: *LayerLearnData, old_layer: *Layer, old_node_values: std.ArrayList(64)) void {
        for (0..self.number_of_rows) |new_node_index| {
            var new_node_value: f64 = 0.0;
            for (0..old_node_values.items.len) |old_node_index| {
                const weighted_input_derivative = old_layer.get_weight2d(new_node_index, old_node_index);
                new_node_value += (weighted_input_derivative - 1) * old_node_values.items[old_node_index];
            }
            new_node_value *= self.activationFunction.derivative(layer_learn_data, new_node_index);
            layer_learn_data.node_values[new_node_index] = new_node_value;
        }
    }
};

fn safe_index(arr: []const f64, i: usize) f64 {
    if (i >= arr.len) {
        return 0.0;
    }
    return arr[i];
}

fn applyWeights(inputs: @Vector(5, f64), abcde: u16) f64 {
    // TODO: do the bit manipulation technique
    const weights = @Vector(5, f64){
        @floatFromInt(((abcde & 0b0011000000) >> 6) - 1),
        @floatFromInt(((abcde & 0b0000110000) >> 4) - 1),
        @floatFromInt(((abcde & 0b0000001100) >> 2) - 1),
        @floatFromInt(((abcde & 0b0000000011)     ) - 1),
        @floatFromInt(((abcde & 0b1100000000) >> 8) - 1),
    };
    const vec = inputs * weights;
    return vec[0] + vec[1] + vec[2] + vec[3] + vec[4];
}
