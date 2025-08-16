const std = @import("std");

const BaseData = struct {
    value: u8,
    abcde: u16,
};

fn getBaseData() [243]BaseData {
    @setEvalBranchQuota(38558); // MAYBE, this value will change with compiler versions :)
    var output: [243]BaseData = undefined;
    const file_contents = @embedFile("base_expanded.txt");
    var lines = std.mem.splitScalar(u8, file_contents, '\n');
    var i = 0;
    while (lines.next()) |line| {
        var part = std.mem.splitScalar(u8, line, ' ');
        const value = part.next() orelse continue;
        const expanded_u16 = part.next() orelse continue;

        output[i] = .{
            .value = std.fmt.parseInt(u8, value, 10) catch 0,
            .abcde = expandedTou16(expanded_u16)
        };
        i += 1;
    }
    return output;
}

fn expandedTou16(expanded: []const u8) u16 {
    const a = digit(expanded[0], expanded[1]);
    const b = digit(expanded[2], expanded[3]);
    const c = digit(expanded[4], expanded[5]);
    const d = digit(expanded[6], expanded[7]);
    const e = digit(expanded[8], expanded[9]);
    return (@as(u16, @intCast(e)) << 8) | (a << 6) | (b << 4) | (c << 2) | d;
}

fn digit(a: u8, b: u8) u8 {
    if (a == '0' and b == '0') return 0;
    if (a == '0' and b == '1') return 1;
    if (a == '1' and b == '0') return 2;
    unreachable;
}

const baseData = getBaseData();
pub const ModifyableWeightSet = struct {
    const Self = @This();
    data: u16,

    pub fn init(weightset_value: u8) Self {
        var left: u8 = 0;
        var right: u8 = 243;
        while (left <= right) {
            const mid = @divFloor((left + right), 2);
            const val = baseData[mid];
            if (val.value == weightset_value) {
                return . { .data = val.abcde };
            }
            if (val.value > weightset_value) {
                left = mid;
                continue;
            }
            right = mid;
        }
        unreachable;
    }
    pub fn set_weight(self: *Self, index: u8, weight: u8) void {
        std.debug.assert(weight <= 2);
        std.debug.assert(index < 5);
        self.data &= 0b1111111111 & (0b00 << @intCast(index * 2));
        self.data |= ((weight & 0b11) << @intCast(index * 2));
    }

    pub fn value(self: Self) u8 {
        //TODO: maybe convert this to binary search?
        for (0..244) |i| {
            const val = baseData[i];
            if (val.abcde != self.data) continue;
            return val.value;
        }
        unreachable;
    }
};
