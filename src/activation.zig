const std = @import("std");
const math = std.math;

pub const Function = struct {
    const Self = @This();
    solveFn: *const fn (x: f64) f64,
    derivativeFn: *const fn(x: f64) f64,

    pub fn solve(self: *const Self, x: f64) f64 {
        return self.solveFn(x);
    }
    pub fn derivative(self: *const Self, x: f64) f64 {
        return self.derivativeFn(x);
    }
};

pub const Sigmoid = struct {
    pub fn solve(x: f64) f64 {
        return 1.0 / (1 + math.exp(-x));
    }
    pub fn derivative(x: f64) f64 {
        return Sigmoid.solve(x) * (1 - Sigmoid.solve(x));
    }
    pub fn function() Function {
        return .{
            .solveFn = solve,
            .derivativeFn = derivative,
        };
    }
};
