//===--- StringUTF16.swift ------------------------------------------------===//
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

extension String {
  /// A collection of UTF-16 code units that encodes a `String` value.
  public struct UTF16View
    : BidirectionalCollection,
    CustomStringConvertible,
    CustomDebugStringConvertible {

    /// A position in a string's collection of UTF-16 code units.
    public struct Index : Comparable {
      // Foundation needs access to these fields so it can expose
      // random access
      public // SPI(Foundation)
      init(_offset: Int) { self._offset = _offset }

      public let _offset: Int
    }

    public typealias IndexDistance = Int

    /// The position of the first code unit if the `String` is
    /// non-empty; identical to `endIndex` otherwise.
    public var startIndex: Index {
      return Index(_offset: 0)
    }

    /// The "past the end" position.
    ///
    /// `endIndex` is not a valid argument to `subscript`, and is always
    /// reachable from `startIndex` by zero or more applications of
    /// `successor()`.
    public var endIndex: Index {
      return Index(_offset: _length)
    }

    // TODO: swift-3-indexing-model - add docs
    @warn_unused_result
    public func next(i: Index) -> Index {
      // FIXME: swift-3-indexing-model: range check i?
      return Index(_offset: _unsafePlus(i._offset, 1))
    }

    // TODO: swift-3-indexing-model - add docs
    @warn_unused_result
    public func previous(i: Index) -> Index {
      // FIXME: swift-3-indexing-model: range check i?
      return Index(_offset: _unsafeMinus(i._offset, 1))
    }

    // TODO: swift-3-indexing-model - add docs
    @warn_unused_result
    public func advance(i: Index, by n: IndexDistance) -> Index {
      // FIXME: swift-3-indexing-model: range check i?
      return Index(_offset: i._offset.advanced(by: n))
    }

    // TODO: swift-3-indexing-model - add docs
    @warn_unused_result
    public func advance(i: Index, by n: IndexDistance, limit: Index) -> Index {
      // FIXME: swift-3-indexing-model: range check i?
      let d = i._offset.distance(to: limit._offset)
      if d == 0 || (d > 0 ? d <= n : d >= n) {
        return limit
      }
      return Index(_offset: i._offset.advanced(by: n))
    }

    // TODO: swift-3-indexing-model - add docs
    @warn_unused_result
    public func distance(from start: Index, to end: Index) -> IndexDistance {
      // FIXME: swift-3-indexing-model: range check start and end?
      return start._offset.distance(to: end._offset)
    }

    @warn_unused_result
    func _internalIndex(at i: Int) -> Int {
      return _core.startIndex + _offset + i
    }

    /// Access the element at `position`.
    ///
    /// - Precondition: `position` is a valid position in `self` and
    ///   `position != endIndex`.
    public subscript(i: Index) -> UTF16.CodeUnit {
      let position = i._offset
      _precondition(position >= 0 && position < _length,
          "out-of-range access on a UTF16View")

      let index = _internalIndex(at: position)
      let u = _core[index]
      if _fastPath((u >> 11) != 0b1101_1) {
        // Neither high-surrogate, nor low-surrogate -- well-formed sequence
        // of 1 code unit.
        return u
      }

      if (u >> 10) == 0b1101_10 {
        // `u` is a high-surrogate.  Sequence is well-formed if it
        // is followed by a low-surrogate.
        if _fastPath(
               index + 1 < _core.count &&
               (_core[index + 1] >> 10) == 0b1101_11) {
          return u
        }
        return 0xfffd
      }

      // `u` is a low-surrogate.  Sequence is well-formed if
      // previous code unit is a high-surrogate.
      if _fastPath(index != 0 && (_core[index - 1] >> 10) == 0b1101_10) {
        return u
      }
      return 0xfffd
    }

#if _runtime(_ObjC)
    // These may become less important once <rdar://problem/19255291> is addressed.

    @available(
      *, unavailable,
      message: "Indexing a String's UTF16View requires a String.UTF16View.Index, which can be constructed from Int when Foundation is imported")
    public subscript(i: Int) -> UTF16.CodeUnit {
      fatalError("unavailable function can't be called")
    }

    @available(
      *, unavailable,
      message: "Slicing a String's UTF16View requires a Range<String.UTF16View.Index>, String.UTF16View.Index can be constructed from Int when Foundation is imported")
    public subscript(bounds: Range<Int>) -> UTF16View {
      fatalError("unavailable function can't be called")
    }
#endif

    /// Get the contiguous subrange of elements enclosed by `bounds`.
    ///
    /// - Complexity: O(1) unless bridging from Objective-C requires an
    ///   O(N) conversion.
    public subscript(bounds: Range<Index>) -> UTF16View {
      return UTF16View(
        _core,
        offset: _internalIndex(at: bounds.startIndex._offset),
        length: bounds.endIndex._offset - bounds.startIndex._offset)
    }

    internal init(_ _core: _StringCore) {
      self._offset = 0
      self._length = _core.count
      self._core = _core
    }

    internal init(_ _core: _StringCore, offset: Int, length: Int) {
      self._offset = offset
      self._length = length
      self._core = _core
    }

    public var description: String {
      let start = _internalIndex(at: 0)
      let end = _internalIndex(at: _length)
      return String(_core[start..<end])
    }

    public var debugDescription: String {
      return "StringUTF16(\(self.description.debugDescription))"
    }

    internal var _offset: Int
    internal var _length: Int
    internal let _core: _StringCore
  }

  /// A UTF-16 encoding of `self`.
  public var utf16: UTF16View {
    get {
      return UTF16View(_core)
    }
    set {
      self = String(newValue)
    }
  }

  /// Construct the `String` corresponding to the given sequence of
  /// UTF-16 code units.  If `utf16` contains unpaired surrogates, the
  /// result is `nil`.
  public init?(_ utf16: UTF16View) {
    let wholeString = String(utf16._core)

    if let start = UTF16Index(
      _offset: utf16._offset
    ).samePosition(in: wholeString) {
      if let end = UTF16Index(
        _offset: utf16._offset + utf16._length
      ).samePosition(in: wholeString) {
        self = wholeString[start..<end]
        return
      }
    }
    return nil
  }

  /// The index type for subscripting a `String`'s `utf16` view.
  public typealias UTF16Index = UTF16View.Index
}

// FIXME: swift-3-indexing-model: add complete set of forwards for Comparable 
//        assuming String.UTF8View.Index continues to exist
@warn_unused_result
public func == (
  lhs: String.UTF16View.Index, rhs: String.UTF16View.Index
) -> Bool {
  return lhs._offset == rhs._offset
}

@warn_unused_result
public func < (
  lhs: String.UTF16View.Index, rhs: String.UTF16View.Index
) -> Bool {
  return lhs._offset < rhs._offset
}

// Index conversions
extension String.UTF16View.Index {
  /// Construct the position in `utf16` that corresponds exactly to
  /// `utf8Index`. If no such position exists, the result is `nil`.
  ///
  /// - Precondition: `utf8Index` is an element of
  ///   `String(utf16)!.utf8.indices`.
  public init?(
    _ utf8Index: String.UTF8Index, within utf16: String.UTF16View
  ) {
    let core = utf16._core

    _precondition(
      utf8Index._coreIndex >= 0 && utf8Index._coreIndex <= core.endIndex,
      "Invalid String.UTF8Index for this UTF-16 view")

    // Detect positions that have no corresponding index.
    if !String.UTF8View(core)._indexIsOnUnicodeScalarBoundary(utf8Index) {
      return nil
    }
    _offset = utf8Index._coreIndex
  }

  /// Construct the position in `utf16` that corresponds exactly to
  /// `unicodeScalarIndex`.
  ///
  /// - Precondition: `unicodeScalarIndex` is an element of
  ///   `String(utf16)!.unicodeScalars.indices`.
  public init(
    _ unicodeScalarIndex: String.UnicodeScalarIndex,
    within utf16: String.UTF16View) {
    _offset = unicodeScalarIndex._position
  }

  /// Construct the position in `utf16` that corresponds exactly to
  /// `characterIndex`.
  ///
  /// - Precondition: `characterIndex` is an element of
  ///   `String(utf16)!.indices`.
  public init(_ characterIndex: String.Index, within utf16: String.UTF16View) {
    _offset = characterIndex._utf16Index
  }

  /// Returns the position in `utf8` that corresponds exactly
  /// to `self`, or if no such position exists, `nil`.
  ///
  /// - Precondition: `self` is an element of
  ///   `String(utf8)!.utf16.indices`.
  @warn_unused_result
  public func samePosition(
    in utf8: String.UTF8View
  ) -> String.UTF8View.Index? {
    return String.UTF8View.Index(self, within: utf8)
  }

  /// Returns the position in `unicodeScalars` that corresponds exactly
  /// to `self`, or if no such position exists, `nil`.
  ///
  /// - Precondition: `self` is an element of
  ///   `String(unicodeScalars).utf16.indices`.
  @warn_unused_result
  public func samePosition(
    in unicodeScalars: String.UnicodeScalarView
  ) -> String.UnicodeScalarIndex? {
    return String.UnicodeScalarIndex(self, within: unicodeScalars)
  }

  /// Returns the position in `characters` that corresponds exactly
  /// to `self`, or if no such position exists, `nil`.
  ///
  /// - Precondition: `self` is an element of `characters.utf16.indices`.
  @warn_unused_result
  public func samePosition(
    in characters: String
  ) -> String.Index? {
    return String.Index(self, within: characters)
  }
}

// Reflection
extension String.UTF16View : CustomReflectable {
  /// Returns a mirror that reflects `self`.
  public var customMirror: Mirror {
    return Mirror(self, unlabeledChildren: self)
  }
}

extension String.UTF16View : CustomPlaygroundQuickLookable {
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(description)
  }
}
