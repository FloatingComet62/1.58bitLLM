const std = @import("std");

pub const Dataset = struct {
    const Self = @This();
    datapoints: std.ArrayList(Datapoint),

    pub fn init(allocator: std.mem.Allocator, data: []const u8) anyerror!Self {
        var datapoints = std.ArrayList(Datapoint).init(allocator);
        var lines = std.mem.splitScalar(u8, data, '\n');
        var i: u64 = 0;

        var number_of_inputs: u32 = 0;
        var number_of_outputs: u32 = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            var line_iter = std.mem.splitScalar(u8, line, '|');
            const inputStr = line_iter.next() orelse unreachable;
            const outputStr = line_iter.next() orelse unreachable;
            if (i == 0) {
                number_of_inputs = try std.fmt.parseInt(u32, inputStr, 10);
                number_of_outputs = try std.fmt.parseInt(u32, outputStr, 10);
            }
            try datapoints.append(try Datapoint.init_from_str(
                allocator,
                inputStr,
                outputStr,
                number_of_inputs,
                number_of_outputs
            ));
            i += 1;
        }
        return .{
            .datapoints = datapoints,
        };
    }
};

pub const Datapoint = struct {
    const Self = @This();

    input: std.ArrayList(f64),
    output: std.ArrayList(f64),

    pub fn init(allocator: std.mem.Allocator, input_list: []const f64, output_list: []const f64) anyerror!Self {
        var input = try std.ArrayList(f64).initCapacity(allocator, input_list.len);
        var output = try std.ArrayList(f64).initCapacity(allocator, output_list.len);

        input.appendSliceAssumeCapacity(input_list);
        output.appendSliceAssumeCapacity(output_list);
        return .{
            .input = input,
            .output = output,
        };
    }

    pub fn init_from_str(
        allocator: std.mem.Allocator,
        inputStr: []const u8,
        outputStr: []const u8,
        inputLen: u32,
        outputLen: u32,
    ) anyerror!Self {
        var input_iter = std.mem.splitScalar(u8, inputStr, ' ');
        var inputs = try std.ArrayList(f64).initCapacity(std.heap.page_allocator, inputLen);
        defer inputs.deinit();

        while (input_iter.next()) |input_item| {
            inputs.appendAssumeCapacity(try std.fmt.parseFloat(f64, input_item));
        }

        var output_iter = std.mem.splitScalar(u8, outputStr, ' ');
        var outputs = try std.ArrayList(f64).initCapacity(std.heap.page_allocator, outputLen);
        defer outputs.deinit();

        while (output_iter.next()) |output_item| {
            outputs.appendAssumeCapacity(try std.fmt.parseFloat(f64, output_item));
        }

        return Self.init(allocator, inputs.items, outputs.items);
    }
};
