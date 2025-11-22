const std = @import("std");
const zimg = @import("zigimg");

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

    framebuffer.pixels.bgra32[atPixel(width, ax, ay)] = white;
    framebuffer.pixels.bgra32[atPixel(width, bx, by)] = white;
    framebuffer.pixels.bgra32[atPixel(width, cx, cy)] = white;

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
    from: struct { x: usize, y: usize },
    to: struct { x: usize, y: usize },
    framebuffer: *zimg.Image,
    color: zimg.color.Bgra32,
) void {
    const delta_y = @as(i32, @intCast(to.y)) - @as(i32, @intCast(from.y));
    var x = from.x;
    while (x < to.x) {
        defer x += 1;
        const t = @as(f32, @floatFromInt((x - from.x))) / @as(f32, @floatFromInt(to.x - from.x));
        const y: usize = @intFromFloat(@round(@as(f32, @floatFromInt(from.y)) + t * @as(f32, @floatFromInt(delta_y))));

        framebuffer.pixels.bgra32[atPixel(framebuffer.width, x, y)] = color;
    }
}

fn atPixel(framebuffer_width: usize, x: usize, y: usize) usize {
    return ((y * framebuffer_width) + x);
}
