const std = @import("std");

pub fn Observable(comptime ValueType: type, comptime ErrorType: type) type {
  return struct {
    const Self = @This();
    const observerArrayType = std.ArrayList(*Observer(ValueType, ErrorType));

    observers: observerArrayType,

    pub fn subscribe(self: *Self, observer: *Observer(ValueType, ErrorType)) !void {
      try self.observers.append(observer); // ?? unsubscription ??
    }

    pub fn next(self: Self, value: ValueType) void {
      for (self.observers.items) |observer| {
        observer.next(value);
      }
    }

    pub fn err(self: Self, value: ErrorType) void {
      for (self.observers.items) |observer| {
        observer.err(value);
      }
    }
    
    pub fn complete(self: Self) void {
      for (self.observers.items) |observer| {
        observer.complete();
      }
    }
   
    pub fn deinit(self: Self) void {
      self.observers.deinit();
    }

    pub fn init(allocator: std.mem.Allocator) Self {
      return Self {
        .observers = observerArrayType.init(allocator),
      };
    }
  };
}

pub fn Observer(comptime ValueType: type, comptime ErrorType: type) type {
  return struct {
    const Self = @This();
    nextFn: ?*const fn (observer: *Self, value: ValueType) void,
    errorFn: ?*const fn (observer: *Self, err: ErrorType) void,
    completeFn: ?*const fn (observer: *Self) void,

    pub fn next(self: *Self, value: ValueType) void {
      if (self.nextFn != null) self.nextFn.?(self, value);
    }
    pub fn err(self: *Self, errvalue: ErrorType) void {
      if (self.errorFn != null) self.errorFn.?(self, errvalue);
    }
    pub fn complete(self: *Self) void {
      if (self.completeFn != null) self.completeFn.?(self);
    }
  };
}

test "Observer shall observe Observable" {
  var observable = Observable(u32, u32).init(std.testing.allocator);
  defer observable.deinit();
  var observer = struct {
    const Self = @This();
    observer: Observer(u32, u32),
    value: u32 = undefined,

    pub fn next(observer: *Observer(u32, u32), value: u32) void {
      var self = @fieldParentPtr(Self, "observer", observer);
      self.value = value;
    }

    pub fn init() Self {
      return Self {
        .observer = Observer(u32, u32) {
          .nextFn = next,
          .errorFn = null,
          .completeFn = null,
        },
      };
    }
  }.init();
  try observable.subscribe(&observer.observer);
  observable.next(42);
  try std.testing.expect(observer.value == 42);
}

