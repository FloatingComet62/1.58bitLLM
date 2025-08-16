const std = @import("std");
const math = std.math;

pub const Function = struct {
    const Self = @This();
    solveFn: *const fn (items: []f64, index: usize) f64,
    derivativeFn: *const fn(items: []f64, index: usize) f64,

    pub fn solve(self: *const Self, items: []f64, index: usize) f64 {
        return self.solveFn(items, index);
    }
    pub fn derivative(self: *const Self, items: []f64, index: usize) f64 {
        return self.derivativeFn(items, index);
    }
};

pub const Sigmoid = struct {
    pub fn solve(items: []f64, index: usize) f64 {
        return 1.0 / (1 + math.exp(-items[index]));
    }
    pub fn derivative(items: []f64, index: usize) f64 {
        return Sigmoid.solve(items, index) * (1 - Sigmoid.solve(items, index));
    }
    pub fn function() Function {
        return .{
            .solveFn = solve,
            .derivativeFn = derivative,
        };
    }
};
