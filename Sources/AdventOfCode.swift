import ArgumentParser
import Foundation

@main
struct AdventOfCode: AsyncParsableCommand {
  @Argument(help: "The day of the challenge. For December 1st, use '1'.")
  var day: Int?

  @Flag(help: "Benchmark the time taken by the solution")
  var benchmark: Bool = false

  @Flag(help: "Run all the days available")
  var all: Bool = false

  func validate() throws {
    if all, day != nil {
      throw ValidationError("Pass either a day or --all, not both.")
    }
  }

  var selectedChallenge: any AdventDay {
    get throws {
      if let day {
        if let challenge = allChallenges.first(where: { $0.day == day }) {
          return challenge
        } else {
          throw ValidationError("No solution found for day \(day)")
        }
      } else {
        return latestChallenge
      }
    }
  }

  var latestChallenge: any AdventDay {
    allChallenges.max(by: { $0.day < $1.day })!
  }

  enum PartOutcome: Equatable {
    case solved(Duration)
    case unimplemented
    case failed

    var timing: String {
      if case .solved(let duration) = self { "\(duration)" } else { "n/a" }
    }
  }

  func run<T>(part: () async throws -> T, named: String) async -> PartOutcome {
    let clock = ContinuousClock()
    let start = clock.now
    do {
      let answer = try await part()
      let duration = start.duration(to: clock.now)
      print("\(named): \(answer)")
      return .solved(duration)
    } catch let unimplemented as PartUnimplemented {
      print("Day \(unimplemented.day) part \(unimplemented.part) unimplemented")
      return .unimplemented
    } catch {
      print("\(named): Failed with error: \(error)")
      return .failed
    }
  }

  func run() async throws {
    let challenges =
      if all {
        allChallenges
      } else {
        try [selectedChallenge]
      }

    var anyFailed = false
    for challenge in challenges {
      print("Executing Advent of Code challenge \(challenge.day)...")

      let part1 = await run(part: challenge.part1, named: "Part 1")
      let part2 = await run(part: challenge.part2, named: "Part 2")
      if [part1, part2].contains(.failed) { anyFailed = true }

      if benchmark {
        print("Part 1 took \(part1.timing), part 2 took \(part2.timing).")
        #if DEBUG
          print("Looks like you're benchmarking debug code. Try swift run -c release")
        #endif
      }
    }
    if anyFailed { throw ExitCode.failure }
  }
}

extension StringProtocol {
  public subscript(_ offset: Int) -> Element {
    self[asciiByteOffset(clampedAt: offset).map(utf8Index) ?? index(startIndex, offsetBy: offset)]
  }

  public subscript(_ range: Range<Int>) -> SubSequence {
    clamped(from: range.lowerBound, upTo: range.upperBound)
  }

  public subscript(_ range: ClosedRange<Int>) -> SubSequence {
    clamped(from: range.lowerBound, upTo: range.upperBound + 1)
  }

  public subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
    clamped(from: 0, upTo: range.upperBound + 1)
  }

  public subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
    clamped(from: 0, upTo: range.upperBound)
  }

  public subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
    let lower = Swift.max(0, range.lowerBound)
    guard let start = asciiByteOffset(clampedAt: lower) else { return dropFirst(lower) }
    return self[utf8Index(start)...]
  }

  /// Clamps to the string so window scans like `line[i - 1...i + 1]` work at both edges.
  private func clamped(from lower: Int, upTo upper: Int) -> SubSequence {
    let lower = Swift.max(0, lower)
    let upper = Swift.max(lower, upper)
    guard let end = asciiByteOffset(clampedAt: upper) else {
      return dropFirst(lower).prefix(upper - lower)
    }
    return self[utf8Index(Swift.min(lower, end))..<utf8Index(end)]
  }

  /// Byte offset of the character `offset` places in, clamped to the end; `nil` unless every
  /// character up to there is one ASCII byte. Lets the subscripts skip the grapheme walk of
  /// `index(_:offsetBy:)` (1.3× faster on 10-character lines, ~9× on 140). CR fails the check
  /// because `"\r\n"` is one character, and so does a non-ASCII byte at the offset, which could
  /// be a combining mark.
  private func asciiByteOffset(clampedAt offset: Int) -> Int? {
    guard offset >= 0 else { return nil }
    return utf8.withContiguousStorageIfAvailable { bytes -> Int? in
      let end = Swift.min(offset, bytes.count)
      // Branchless so it vectorizes; an early-exit `contains(where:)` is 4× slower.
      var flags = end < bytes.count ? bytes[end] : 0
      for byte in bytes[..<end] { flags |= byte | (byte == UInt8(ascii: "\r") ? 0x80 : 0) }
      return flags < 0x80 ? end : nil
    } ?? nil
  }

  private func utf8Index(_ offset: Int) -> Index { utf8.index(utf8.startIndex, offsetBy: offset) }

  public func containsAll(_ elements: Set<Character>) -> Bool {
    elements.isSubset(of: self)
  }

  /// `nil` if any character isn't a hex digit — trim a trailing newline first.
  public func hexToBin() -> String? {
    var bits = ""
    for char in self {
      guard let nibble = char.hexToBin() else { return nil }
      bits += nibble
    }
    return bits
  }

  /// `nil` unless every character is `0` or `1`. `Int(_:radix:)` only lets a leading sign
  /// through, so checking the first byte is enough — `allSatisfy` would cost 10×.
  public func binToDec() -> Int? {
    guard let first = utf8.first, first != UInt8(ascii: "+"), first != UInt8(ascii: "-") else {
      return nil
    }
    return Int(self, radix: 2)
  }

  public var isNumber: Bool {
    Int(self) != nil
  }
}

extension Character {
  public func hexToDec() -> Int? {
    return Int(string, radix: 16)
  }

  public func hexToBin() -> String? {
    hexToDec().map { Character.nibbles[$0] }
  }

  private static let nibbles = [
    "0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111",
    "1000", "1001", "1010", "1011", "1100", "1101", "1110", "1111",
  ]
}

extension LosslessStringConvertible {
  public var string: String { .init(self) }
}

extension BidirectionalCollection {
  /// By offset from `startIndex`, not by index: on an `ArraySlice` this differs from `self[i]`.
  public subscript(safe offset: Int) -> Element? {
    guard !isEmpty,
      offset >= 0,
      let index = index(startIndex, offsetBy: offset, limitedBy: index(before: endIndex))
    else { return nil }
    return self[index]
  }
}

infix operator %% : MultiplicationPrecedence
extension Int {
  /// Modulo in `0..<rhs`; Swift's `%` keeps the sign of `lhs`. The precondition lets the
  /// compiler drop `%`'s overflow checks, and the branches skip the division where possible.
  public static func %% (_ lhs: Int, _ rhs: Int) -> Int {
    precondition(rhs > 0, "%% needs a positive divisor, got \(rhs)")
    if lhs >= 0 { return lhs % rhs }
    if lhs >= -rhs { return lhs + rhs }
    return ((lhs % rhs) + rhs) % rhs
  }
}

precedencegroup PowerPrecedence {
  higherThan: MultiplicationPrecedence
  associativity: right
}

infix operator ^^ : PowerPrecedence
/// Traps on overflow like `*`. Not `Double` `pow`, which loses precision above 2^53.
public func ^^ (radix: Int, power: Int) -> Int {
  precondition(power >= 0, "Int ^^ needs a non-negative exponent, got \(power)")
  var result = 1
  var base = radix
  var exponent = power
  while exponent > 0 {
    if exponent & 1 == 1 { result *= base }
    exponent >>= 1
    if exponent > 0 { base *= base }
  }
  return result
}

public func ^^ (radix: Double, power: Double) -> Double {
  return pow(radix, power)
}

public enum DefaultError: Error, CustomStringConvertible {
  case message(String)

  public var description: String {
    switch self {
    case .message(let message): message
    }
  }
}

public func print(string: String) {
  Swift.print(string)
}

extension Sequence where Element: AdditiveArithmetic {
  public func sum() -> Element { reduce(.zero, +) }
}

extension Sequence where Element: Numeric {
  public func product() -> Element { reduce(1, *) }
}

extension RangeReplaceableCollection where Self: StringProtocol {
  public func paddingToLeft(upTo length: Int, using element: Element = " ") -> SubSequence {
    repeatElement(element, count: Swift.max(0, length - count)) + self[...]
  }
}

extension Array {
  public subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
    let lower = Swift.max(range.lowerBound, startIndex)
    let upper = Swift.min(range.upperBound, endIndex)
    guard lower < upper else { return nil }
    return self[lower..<upper]
  }

  public subscript(safe range: ClosedRange<Index>) -> ArraySlice<Element>? {
    guard !isEmpty else { return nil }
    let lower = Swift.max(range.lowerBound, startIndex)
    let upper = Swift.min(range.upperBound, endIndex - 1)
    guard lower <= upper else { return nil }
    return self[lower...upper]
  }
}

public final class Ref<T> {
  public var val: T

  public init(_ val: T) {
    self.val = val
  }
}

extension Ref: CustomStringConvertible where T: CustomStringConvertible {
  public var description: String { val.description }
}

public struct Point {
  public var x: Int
  public var y: Int
}

extension Point {
  public init(y: Int, x: Int) {
    self.x = x
    self.y = y
  }

  public init(coord0: Int, coord1: Int) {
    x = coord0
    y = coord1
  }

  public init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }

  public init(array: [Int]) {
    self.init(array)
  }

  public init(_ array: [Int]) {
    precondition(array.count == 2, "Point needs 2 coordinates, got \(array)")
    x = array[0]
    y = array[1]
  }
}

extension Point {
  public var array: [Int] {
    get {
      [x, y]
    }
    set(newValue) {
      self = Point(newValue)
    }
  }

  public subscript(_ dimension: Int) -> Int {
    get {
      switch dimension {
      case 0: x
      case 1: y
      default: preconditionFailure("Point has no dimension \(dimension)")
      }
    }
    set {
      switch dimension {
      case 0: x = newValue
      case 1: y = newValue
      default: preconditionFailure("Point has no dimension \(dimension)")
      }
    }
  }

  public var coord0: Int {
    return x
  }

  public var coord1: Int {
    return y
  }
}

extension Point: CustomStringConvertible {
  public var description: String {
    return "(\(x), \(y))"
  }
}

extension Point: Hashable, Sendable {
  /// One `combine` instead of the synthesized two makes `Set`/`Dictionary` ~15% faster.
  /// Collision-free while both coordinates fit in 32 bits; truncating `y` keeps its sign bits off `x`.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x &<< 32 | Int(UInt32(truncatingIfNeeded: y)))
  }
}

extension Point: Comparable {
  /// Reading order: row (`y`) first, then column (`x`).
  public static func < (lhs: Point, rhs: Point) -> Bool {
    (lhs.y, lhs.x) < (rhs.y, rhs.x)
  }
}

extension Point {
  static func + (lhs: Point, rhs: Point) -> Point {
    return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func - (lhs: Point, rhs: Point) -> Point {
    return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  static func * (lhs: Point, rhs: Point) -> Point {
    return Point(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
  }

  static func / (lhs: Point, rhs: Point) -> Point {
    return Point(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
  }

  static prefix func - (point: Point) -> Point {
    return Point(x: -point.x, y: -point.y)
  }

  static func + (lhs: Point, rhs: Int) -> Point {
    return Point(x: lhs.x + rhs, y: lhs.y + rhs)
  }

  static func - (lhs: Point, rhs: Int) -> Point {
    return Point(x: lhs.x - rhs, y: lhs.y - rhs)
  }

  static func * (lhs: Point, rhs: Int) -> Point {
    return Point(x: lhs.x * rhs, y: lhs.y * rhs)
  }

  static func / (lhs: Point, rhs: Int) -> Point {
    return Point(x: lhs.x / rhs, y: lhs.y / rhs)
  }

  static func + (lhs: Int, rhs: Point) -> Point {
    return rhs + lhs
  }

  static func * (lhs: Int, rhs: Point) -> Point {
    return rhs * lhs
  }
}

extension Point {
  var rotatedClock90: Point {
    return Point(-y, x)
  }

  var rotatedCounterClock90: Point {
    return Point(y, -x)
  }
}

public struct Point3D {
  public var x: Int
  public var y: Int
  public var z: Int
}

extension Point3D {
  public init(_ x: Int, _ y: Int, _ z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }

  public init(array: [Int]) {
    self.init(array)
  }

  public init(_ array: [Int]) {
    precondition(array.count == 3, "Point3D needs 3 coordinates, got \(array)")
    x = array[0]
    y = array[1]
    z = array[2]
  }
}

extension Point3D {
  public var array: [Int] {
    get {
      [x, y, z]
    }
    set(newValue) {
      self = Point3D(newValue)
    }
  }

  public subscript(_ dimension: Int) -> Int {
    get {
      switch dimension {
      case 0: x
      case 1: y
      case 2: z
      default: preconditionFailure("Point3D has no dimension \(dimension)")
      }
    }
    set {
      switch dimension {
      case 0: x = newValue
      case 1: y = newValue
      case 2: z = newValue
      default: preconditionFailure("Point3D has no dimension \(dimension)")
      }
    }
  }

  public var coord0: Int {
    return x
  }

  public var coord1: Int {
    return y
  }

  public var coord2: Int {
    return z
  }
}

extension Point3D: CustomStringConvertible {
  public var description: String {
    return "(\(x), \(y), \(z))"
  }
}

extension Point3D: Hashable, Sendable {
  /// One `combine` instead of the synthesized three makes `Set`/`Dictionary` ~30% faster.
  /// Collision-free while every coordinate is in `-2^20..<2^20`; masking keeps the sign bits of
  /// `y` and `z` off the fields above them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x &<< 42 | (y & 0x1F_FFFF) &<< 21 | (z & 0x1F_FFFF))
  }
}

extension Point3D: Comparable {
  public static func < (lhs: Point3D, rhs: Point3D) -> Bool {
    (lhs.z, lhs.y, lhs.x) < (rhs.z, rhs.y, rhs.x)
  }
}

extension Int {
  /// Same result as `Int(String(character))`, ~1.5–2× faster. Not `asciiValue` (3× slower)
  /// or `wholeNumberValue` (accepts non-ASCII digits).
  public init?(_ character: Character) {
    let utf8 = character.utf8
    guard utf8.count == 1, let byte = utf8.first, UInt8(ascii: "0")...UInt8(ascii: "9") ~= byte
    else { return nil }
    self = Int(byte - UInt8(ascii: "0"))
  }
}

func printArray2D<T>(_ map: [[T]]) {
  for row in map {
    print(row.map { String(describing: $0) }.joined())
  }
}

/// Starts at the origin (or the most negative coordinate), so positions line up with the puzzle's.
func printMap<T>(_ map: [Point: T], emptyValue: T) {
  guard !map.isEmpty else { return }
  let xs = map.keys.map(\.x)
  let ys = map.keys.map(\.y)
  let columns = Swift.min(0, xs.min()!)...xs.max()!
  let rows = Swift.min(0, ys.min()!)...ys.max()!
  printArray2D(rows.map { y in columns.map { x in map[Point(x, y)] ?? emptyValue } })
}

func printSet(_ points: Set<Point>, value: String, emptyValue: String = " ") {
  printMap(Dictionary(uniqueKeysWithValues: points.map { ($0, value) }), emptyValue: emptyValue)
}
