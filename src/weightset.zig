const std = @import("std");

const BaseData = struct {
    value: u8,
    abcde: ABCDE,
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
        const expanded_abcde = part.next() orelse continue;

        output[i] = .{
            .value = std.fmt.parseInt(u8, value, 10) catch 0,
            .abcde = expandedToABCDE(expanded_abcde)
        };
        i += 1;
    }
    return output;
}

fn expandedToABCDE(expanded: []const u8) ABCDE {
    const a = digit(expanded[0], expanded[1]);
    const b = digit(expanded[2], expanded[3]);
    const c = digit(expanded[4], expanded[5]);
    const d = digit(expanded[6], expanded[7]);
    const e = digit(expanded[8], expanded[9]);
    return .{
        .abcd = (a << 6) | (b << 4) | (c << 2) | d,
        .e = e,
    };
}

fn digit(a: u8, b: u8) u8 {
    if (a == '0' and b == '0') return 0;
    if (a == '0' and b == '1') return 1;
    if (a == '1' and b == '0') return 2;
    unreachable;
}

pub const ModifyableWeightSet = struct {
    const Self = @This();
    abcd: u8,
    e: u8,

    pub fn init(weightset_value: u8) Self {
        const abcde = weightset_value_to_abcde(weightset_value);
        return .{
            .abcd = abcde.abcd,
            .e = abcde.e
        };
    }
    pub fn set_weight(self: *Self, index: u8, weight: u8) void {
        std.debug.assert(weight <= 2);
        std.debug.assert(index < 5);
        if (index == 4) {
            self.e = weight;
            return;
        }
        self.abcd |= weight << @intCast(index * 2);
    }

    pub fn value(self: Self) u8 {
        const abcde = ABCDE{
            .abcd = self.abcd,
            .e = self.e
        };
        return abcde_to_weightset_value(abcde);
    }
};

pub const ABCDE = struct {
    abcd: u8,
    e: u8,
};
const baseData = getBaseData();
pub fn weightset_value_to_abcde(value: u8) ABCDE {
    var left: u8 = 0;
    var right: u8 = 243;
    while (left <= right) {
        const mid = @divFloor((left + right), 2);
        const val = baseData[mid];
        if (val.value == value) {
            return val.abcde;
        }
        if (val.value > value) {
            left = mid;
            continue;
        }
        right = mid;
    }
    unreachable;
}
fn abcde_to_weightset_value(abcde: ABCDE) u8 {
    //TODO: maybe convert this to binary search?
    for (0..244) |i| {
        const val = baseData[i];
        if (
            (val.abcde.abcd != abcde.abcd) and
            (val.abcde.e != abcde.e)
        ) continue;
        return val.value;
    }
    unreachable;
}
