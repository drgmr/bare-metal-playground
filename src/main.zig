const StackTrace = @import("std").builtin.StackTrace;

const MultiBoot = packed struct {
    const MAGIC = 0x1BADB002;

    const ALIGN = 1 << 0;
    const MEMINFO = 1 << 1;
    const FLAGS = ALIGN | MEMINFO;

    magic: i32,
    flags: i32,
    checksum: i32,

    fn init() @This() {
        return .{
            .magic = 0x1BADB002,
            .flags = FLAGS,
            .checksum = -(MAGIC + FLAGS),
        };
    }
};

export var multiboot align(4) linksection(".multiboot") = MultiBoot.init();

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, kmain, .{});

    while (true) {}
}

pub fn panic(msg: []const u8, error_return_trace: ?*StackTrace) noreturn {
    _ = error_return_trace;

    @setCold(true);

    Terminal.write("KERNEL PANIC: ");
    Terminal.write(msg);

    while (true) {}
}

fn kmain() void {
    Terminal.initialize();
    Terminal.writeLine("Hello, Kernel World from Zig!");

    Terminal.setColor(ColorSet.init(.red, .white));
    Terminal.writeLine("Hello!");
    Terminal.setColor(ColorSet.init(.green, .white));
    Terminal.writeLine("Hello!");
    Terminal.setColor(ColorSet.init(.blue, .white));
    Terminal.writeLine("Hello!");

    Terminal.setColor(ColorSet.init(.white, .black));
    Terminal.write("And done!");
}

const ColorSet = struct {
    color: u16,

    fn init(fg: VgaColor, bg: VgaColor) @This() {
        return .{ .color = @as(u16, VgaColor.combine(fg, bg)) << 8 };
    }

    fn apply(self: @This(), char: u8) u16 {
        return char | self.color;
    }
};

const VgaColor = enum(u8) {
    black = 0,
    blue,
    green,
    cyan,
    red,
    magenta,
    brown,
    light_gray,
    dark_gray,
    light_blue,
    light_green,
    light_cyan,
    light_red,
    light_magenta,
    light_brown,
    white,

    fn combine(fg: @This(), bg: @This()) u8 {
        return @enumToInt(fg) | (@enumToInt(bg) << 4);
    }
};

const Terminal = struct {
    const WIDTH = 80;
    const HEIGHT = 25;

    var buffer: [*]volatile u16 = @intToPtr([*]volatile u16, 0xB8000);

    var row: usize = 0;
    var column: usize = 0;

    var current_color: ColorSet = ColorSet.init(.white, .black);

    fn initialize() void {
        var y: usize = 0;
        while (y < HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < WIDTH) : (x += 1) {
                putCharAt(' ', current_color, x, y);
            }
        }
    }

    fn setColor(new_color: ColorSet) void {
        current_color = new_color;
    }

    fn putCharAt(c: u8, new_color: ColorSet, x: usize, y: usize) void {
        const index = y * WIDTH + x;
        buffer[index] = new_color.apply(c);
    }

    fn putChar(c: u8) void {
        putCharAt(c, current_color, column, row);
        column += 1;
        if (column == WIDTH) {
            column = 0;
            row += 1;
            if (row == HEIGHT) {
                row = 0;
            }
        }
    }

    fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }

    fn writeLine(data: []const u8) void {
        write(data);

        column = 0;
        row += 1;
        if (row == HEIGHT) {
            row = 0;
        }
    }
};
