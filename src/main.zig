const std = @import("std");
const print = std.debug.print;
const Address = std.net.Address;
const Connection = std.net.Server.Connection;
const Thread = std.Thread;

pub fn main() !void {
    const address = try Address.resolveIp("127.0.0.1", 1234);

    var server = try address.listen(.{});
    defer server.deinit();

    while (true) {
        const conn = try server.accept();
        _ = try Thread.spawn(.{}, handleClient, .{conn});
    }
}

fn handleClient(conn: Connection) !void {
    // Make sure the connection is closed when the thread finishes,
    // regardless of whether an error occurs.
    defer conn.stream.close();

    var buf: [1024]u8 = undefined;

    while (true) {
        const len = try conn.stream.read(&buf);

        if (len == 0) {
            print("Client disconnected.\n", .{});
            break;
        }

        // TODO: Send to other clients
        try conn.stream.writeAll(buf[0..len]);
    }
}
