const std = @import("std");

const Address = std.net.Address;
const Connection = std.net.Server.Connection;
const Thread = std.Thread;
const print = std.debug.print;

var connection_id_counter: u64 = 1;

const ConnectionMap = std.AutoHashMap(u64, Connection);

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // List all the active connections
    var everyone = ConnectionMap.init(allocator);
    defer everyone.clearAndFree();

    const address = try Address.resolveIp("127.0.0.1", 1234);

    var server = try address.listen(.{});
    defer server.deinit();

    while (true) {
        const conn = try server.accept();

        const conn_id = connection_id_counter;
        try everyone.put(conn_id, conn);
        connection_id_counter += 1;

        _ = try Thread.spawn(.{}, handleClient, .{ conn_id, conn, &everyone });
    }
}

fn handleClient(conn_id: u64, conn: Connection, everyone: *ConnectionMap) !void {
    // Make sure the connection is closed when the thread finishes,
    // regardless of whether an error occurs.
    defer {
        conn.stream.close();
        _ = everyone.remove(conn_id);
    }

    var buf: [1024]u8 = undefined;

    print("Client connected: {}.\n", .{conn_id});

    while (true) {
        const len = try conn.stream.read(&buf);

        if (len == 0) {
            print("Client disconnected: {}.\n", .{conn_id});
            break;
        }

        // Send the message to everybody
        var it = everyone.valueIterator();
        while (it.next()) |c| {
            try c.stream.writeAll(buf[0..len]);
        }
    }
}
