const std = @import("std");
const zimg = @import("zigimg");

const PixelCoord = struct { x: usize, y: usize };

const white = zimg.Colors(zimg.color.Bgra32).White;
const green = zimg.Colors(zimg.color.Bgra32).Green;
const red = zimg.Colors(zimg.color.Bgra32).Red;
const blue = zimg.Colors(zimg.color.Bgra32).Blue;
const yellow = zimg.Colors(zimg.color.Bgra32).Yellow;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) {
            std.debug.print("leaked memory\n", .{});
        }
    }
    const allocator = gpa.allocator();

    const width: usize = 64;
    const height: usize = 64;

    var framebuffer = try zimg.Image.create(allocator, width, height, .bgra32);
    defer framebuffer.deinit(allocator);

    const ax = 7;
    const ay = 3;
    const bx = 12;
    const by = 37;
    const cx = 62;
    const cy = 53;

    line(.{ .x = ax, .y = ay }, .{ .x = bx, .y = by }, &framebuffer, blue);
    line(.{ .x = cx, .y = cy }, .{ .x = bx, .y = by }, &framebuffer, green);
    line(.{ .x = cx, .y = cy }, .{ .x = ax, .y = ay }, &framebuffer, yellow);
    line(.{ .x = ax, .y = ay }, .{ .x = cx, .y = cy }, &framebuffer, red);

    drawPixel(&framebuffer, ax, ay, white);
    drawPixel(&framebuffer, bx, by, white);
    drawPixel(&framebuffer, cx, cy, white);

    var write_buffer: [zimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;

    // OUTPUT TGA FILE
    // try framebuffer.writeToFilePath(
    //     allocator,
    //     "framebuffer.tga",
    //     write_buffer[0..],
    //     .{ .tga = .{ .author_name = "yo-reign" } },
    // );

    // OUTPUT AS PNG INSTEAD
    try framebuffer.convert(allocator, .rgba32);
    try framebuffer.writeToFilePath(
        allocator,
        "framebuffer.png",
        write_buffer[0..],
        .{ .png = .{ .filter_choice = .{ .specified = .none } } },
    );
}

fn line(
    from: PixelCoord,
    to: PixelCoord,
    framebuffer: *zimg.Image,
    color: zimg.color.Bgra32,
) void {
    var a = from;
    var b = to;

    const is_steep = @abs(@as(i32, @intCast(a.x)) - @as(i32, @intCast(b.x))) < @abs(@as(i32, @intCast(a.y)) - @as(i32, @intCast(b.y)));
    if (is_steep) {
        std.mem.swap(usize, &a.x, &a.y);
        std.mem.swap(usize, &b.x, &b.y);
    }

    // Ensure left to right
    if (a.x > b.x) {
        std.mem.swap(PixelCoord, &a, &b);
    }

    const delta_y = @as(i32, @intCast(b.y)) - @as(i32, @intCast(a.y));

    var x = a.x;
    while (x <= b.x) {
        defer x += 1;
        const t = @as(f32, @floatFromInt((x - a.x))) / @as(f32, @floatFromInt(b.x - a.x));
        const y: usize = @intFromFloat(@round(@as(f32, @floatFromInt(a.y)) + t * @as(f32, @floatFromInt(delta_y))));

        if (is_steep) {
            drawPixel(framebuffer, y, x, color);
        } else {
            drawPixel(framebuffer, x, y, color);
        }
    }
}

fn findPixelIndex(framebuffer_width: usize, x: usize, y: usize) usize {
    return ((y * framebuffer_width) + x);
}

fn drawPixel(framebuffer: *zimg.Image, x: usize, y: usize, brga_color: zimg.color.Bgra32) void {
    framebuffer.pixels.bgra32[findPixelIndex(framebuffer.width, x, y)] = brga_color;
}
