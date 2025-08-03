const std = @import("std");
const weightset = @import("weightset.zig");
// const testing = std.testing;

// pub export fn add(a: i32, b: i32) i32 {
//     return a + b;
// }
//
// test "basic add functionality" {
//     try testing.expect(add(3, 7) == 10);
// }

pub const Layer = struct {
    const Self = @This();
    weights: std.ArrayList(u8),
    output: std.ArrayList(@Vector(5, f64)),
    number_of_rows: u32,
    number_of_columns: u32,

    // TODO: resolve anytype
    pub fn init(
        log: anytype,
        allocator: std.mem.Allocator,
        in_nodes: u32,
        out_nodes: u32
    ) anyerror!Self {
        if ((in_nodes % 5 != 0) and (out_nodes % 5 != 0)) {
            try log.print("It is recommanded to use a multiple of 5 for the number of nodes", .{});
        }
        const number_of_columns = try std.math.divCeil(u32, in_nodes, 5);
        const number_of_rows = out_nodes;
        const number_of_items = number_of_columns * number_of_rows;
        var weights = try std.ArrayList(u8).initCapacity(allocator, number_of_items);
        for (0..number_of_items) |_| {
            weights.appendAssumeCapacity(0);
        }
        var output = try std.ArrayList(@Vector(5, f64)).initCapacity(allocator, number_of_rows);
        for (0..number_of_rows) |_| {
            output.appendAssumeCapacity(@splat(0));
        }
        return .{
            .weights = weights,
            .output = output,
            .number_of_rows = number_of_rows,
            .number_of_columns = number_of_columns,
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

    pub fn apply(
        self: Self,
        prev_layer_outputs: std.ArrayList(@Vector(5, f64))
    ) void {
        std.debug.assert(prev_layer_outputs.items.len <= self.number_of_columns);
        for (0..self.number_of_rows) |i| {
            self.output.items[i] = 0;
            for (0..self.number_of_columns) |j| {
                self.output.items[i] += applyWeights(
                    prev_layer_outputs.items[i],
                    weightset.weightset_value_to_abcde(self.weights[i * self.number_of_columns + j])
                );
            }
        }
    }
};

fn applyWeights(inputs: @Vector(5, f64), abcde: weightset.ABCDE) @Vector(5, f64) {
    // TODO: do the bit manipulation technique
    const weights = @Vector(5, 64){
        ((abcde.abcd & 0b11000000) >> 6) - 1,
        ((abcde.abcd & 0b00110000) >> 4) - 1,
        ((abcde.abcd & 0b00001100) >> 2) - 1,
        ((abcde.abcd & 0b00000011)) - 1,
        (abcde.e) - 1,
    };
    return inputs * weights;
}
