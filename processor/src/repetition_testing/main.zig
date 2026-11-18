const std = @import("std");
const c = @import("c");

const read = @import("read.zig");
const write = @import("write.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    // try read.readFileAlloc(io, init.gpa, stdout_writer);
    // try read.readSliceShortAlloc(io, init.gpa, stdout_writer);
    // try read.readSliceShort(io, init.gpa, stdout_writer);

    // try write.mmapWriteForward(stdout_writer);
    // try write.mmapWriteForwardAlloc(stdout_writer);
    // try write.mmapWriteBackward(stdout_writer);
    // try write.mmapWriteBackwardAlloc(stdout_writer);
    // try write.mmapWriteConverge(stdout_writer);
    // try write.mmapWriteConvergeAlloc(stdout_writer);

    try read.mmap(io, stdout_writer);
    try read.mmapAlloc(io, stdout_writer);
    try read.mmapAllocPopulate(io, stdout_writer);
}
