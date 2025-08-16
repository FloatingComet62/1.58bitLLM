const std = @import("std");
const math = std.math;

pub const CostFunction = struct {
    const Self = @This();
    solveFn: *const fn (prediction: []f64, expected: []f64) f64,
    derivativeFn: *const fn (prediction: f64, expected: f64) f64,

    pub fn solve(self: *const Self, prediction: []f64, expected: []f64) f64 {
        return self.solveFn(prediction, expected);
    }
    pub fn derivative(self: *const Self, prediction: f64, expected: f64) f64 {
        return self.derivativeFn(prediction, expected);
    }
};

pub const MeanSquaredError = struct {
    pub fn solve(prediction: []f64, expected: []f64) f64 {
        std.debug.assert(prediction.len == expected.len);
        var output: f64 = 0;
        for (0..prediction.len) |i| {
            const cost = prediction[i] - expected[i];
            output += cost * cost;
        }
        return 0.5 * output;
    }
    pub fn derivative(prediction: f64, expected: f64) f64 {
        return prediction - expected;
    }
    pub fn function() CostFunction {
        return .{
            .solveFn = solve,
            .derivativeFn = derivative,
        };
    }
};
