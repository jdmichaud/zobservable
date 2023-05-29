const std = @import("std");
const observable = @import("observable.zig");

const Observable = observable.Observable;
const Observer = observable.Observer;

// This file demonstrate the use of the Observable pattern

const Bar = struct {
  const Self = @This();

  observable: Observable(u32, u32),
  value: u32,

  pub fn init(allocator: std.mem.Allocator) Self {
    return Self {
      .value = 0,
      .observable = Observable(u32, u32).init(allocator),
    };
  }

  pub fn deinit(self: Self) void {
    self.observable.deinit();
  }
};

pub fn Foo(comptime ValueType: type) type {
  return struct {
    const Self = @This();
    observer: Observer(ValueType, u32),

    pub fn next(observer: *Observer(ValueType, u32), value: ValueType) void {
      _ = observer;
      std.debug.print("Foo: {}\n", .{ value });
    }

    pub fn init() Self {
      return Self {
        .observer = Observer(ValueType, u32) {
          .nextFn = next,
          .errorFn = null,
          .completeFn = null,
        },
      };
    }
  };
}

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  var gpa = general_purpose_allocator.allocator();
  var bar = Bar.init(gpa);
  defer bar.deinit();
  var foo = Foo(u32).init();
  try bar.observable.subscribe(&foo.observer);
  bar.observable.next(12);
  bar.observable.err(0);
  bar.observable.complete();
}

