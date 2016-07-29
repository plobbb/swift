//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Accesses the memory layout of `T` through its
/// `size`, `stride`, and `alignment` properties
public struct MemoryLayout<T> {

  /// Returns the contiguous memory footprint of `T`.
  ///
  /// Does not include any dynamically-allocated or "remote" 
  /// storage. In particular, `MemoryLayout<T>.size`, when 
  /// `T` is a class type, is the same regardless of how many 
  /// stored properties `T` has.
  @_transparent
  public static var size: Int { return _sizeof(T.self) }

  /// For instances of `T` in an `Array<T>`, returns the number of
  /// bytes from the start of one instance to the start of the
  /// next. This is the same as the number of bytes moved when an
  /// `UnsafePointer<T>` is incremented. `T` may have a lower minimal
  /// alignment that trades runtime performance for space
  /// efficiency. The result is always positive.
  @_transparent
  public static var stride: Int { return _strideof(T.self) }

  /// Returns the default memory alignment of `T`.
  @_transparent
  public static var alignment: Int { return _alignof(T.self) }
}

extension MemoryLayout {
  @_transparent
  init(_: @autoclosure () -> T) {}

  @_transparent
  public static func of(_ candidate: @autoclosure () -> T) -> MemoryLayout<T>.Type {
    return MemoryLayout.init(candidate).dynamicType
  }
}

//===----------------------------------------------------------------------===//
// Unavailables
//===----------------------------------------------------------------------===//

@available(*, unavailable, message: "use MemoryLayout<T>.size instead.")
public func sizeof<T>(_:T.Type) -> Int {
  return _sizeof(T.self);
}

@available(*, unavailable, message: "use MemoryLayout.of(value).size instead.")
public func sizeofValue<T>(_:T) -> Int {
  return _sizeof(T.self);
}

@available(*, unavailable, message: "use MemoryLayout<T>.alignment instead.")
public func alignof<T>(_:T.Type) -> Int {
  return _alignof(T.self);
}

@available(*, unavailable, message: "use MemoryLayout.of(value).alignment instead.")
public func alignofValue<T>(_:T) -> Int {
  return _alignof(T.self);
}

@available(*, unavailable, message: "use MemoryLayout<T>.stride instead.")
public func strideof<T>(_:T.Type) -> Int {
  return _strideof(T.self);
}

@available(*, unavailable, message: "use MemoryLayout.of(value).stride instead.")
public func strideofValue<T>(_:T) -> Int {
  return _strideof(T.self);
}
