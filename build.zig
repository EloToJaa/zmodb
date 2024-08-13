const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zmodb",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();

    const libmodbus = try buildLibmodbus("libmodbus", b, target, optimize);

    const modbusModule = b.addModule("modbus", .{
        .root_source_file = b.path("src/modbus/modbus.zig"),
        .target = target,
        .optimize = optimize,
    });
    modbusModule.linkLibrary(libmodbus);

    exe.root_module.addImport("modbus", modbusModule);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const runStep = b.step("run", "Run the app");
    runStep.dependOn(&run_cmd.step);
}

pub fn buildLibmodbus(
    comptime subdir: []const u8,
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "modbus",
        .target = target,
        .optimize = optimize,
    });

    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (optimize != .Debug) try flags.append("-Os");
    try flags.append("-Wno-return-type-c-linkage");
    try flags.append("-fno-sanitize=undefined");
    try flags.append("-std=gnu23");
    try flags.append("-D_GNU_SOURCE");

    lib.addIncludePath(b.path(subdir ++ "/src"));
    lib.addIncludePath(b.path("src/modbus/"));

    lib.addCSourceFiles(.{
        .files = &.{
            subdir ++ "/src/modbus-data.c",
            subdir ++ "/src/modbus-rtu.c",
            subdir ++ "/src/modbus-tcp.c",
            subdir ++ "/src/modbus.c",
        },
        .flags = flags.items,
    });

    lib.linkLibC();

    b.installArtifact(lib);

    return lib;
}
