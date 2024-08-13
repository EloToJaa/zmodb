const std = @import("std");
const mb = @import("modbus");

pub fn main() !void {
    const ctx = mb.modbus_new_tcp("127.0.0.1", 502);
    const res = mb.modbus_connect(ctx);
    defer mb.modbus_free(ctx);

    if (res == -1) {
        std.debug.print("Connection failed\n", .{});
        return;
    }

    defer mb.modbus_close(ctx);

    std.debug.print("Hello, world!\n", .{});
}
