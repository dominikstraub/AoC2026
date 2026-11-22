import Testing

@testable import AdventOfCode

struct HelpersTests {
  @Test func intPowerIsExact() {
    #expect(3 ^^ 35 == 50_031_545_098_999_707)
    #expect(2 ^^ 62 == 4_611_686_018_427_387_904)
    #expect((-2) ^^ 3 == -8)
    #expect(7 ^^ 0 == 1)
    let inferred = 2 ^^ 10
    #expect(inferred == 1024)
    #expect(2.0 ^^ -1.0 == 0.5)
    #expect(2 ^^ 3 ^^ 2 == 512)
  }

  @Test func moduloIsNonNegative() async {
    #expect(5 %% 3 == 2)
    #expect(-1 %% 3 == 2)
    #expect(-3 %% 3 == 0)
    #expect(-5 %% 3 == 1)
    #expect(-7 %% 3 == 2)
    #expect(1 + 7 %% 3 == 2)
    await #expect(processExitsWith: .failure) { _ = (1 %% -3) }
  }

  @Test func stringOffsetSubscripts() {
    #expect("abc"[1] == "b")
    #expect("abcdef"[1..<3] == "bc")
    #expect("abcdef"[1...3] == "bcd")
    #expect("abc"[2..<5] == "c")
    #expect("abc"[2...4] == "c")
    #expect("abc"[1...] == "bc")
    #expect("abc"[5...] == "")
    #expect("abc"[...1] == "ab")
    #expect("abc"[..<1] == "a")
    #expect("abc"[-1...1] == "ab")
    #expect("abc"[-3 ..< -1] == "")
    #expect("abc"[...(-1)] == "")
    #expect("abc"[..<(-2)] == "")
    #expect("abc"[(-2)...] == "abc")
  }

  @Test func binToDecRejectsSigns() {
    #expect("101".binToDec() == 5)
    #expect("-101".binToDec() == nil)
    #expect("+1".binToDec() == nil)
    #expect("".binToDec() == nil)
  }

  @Test func pointArrayInitChecksCount() async {
    #expect(Point([1, 2]) == Point(1, 2))
    await #expect(processExitsWith: .failure) { _ = Point([1, 2, 3]) }
    await #expect(processExitsWith: .failure) { _ = Point3D([1, 2]) }
  }

  @Test func partOutcomes() async throws {
    let command = try AdventOfCode.parse([])
    let solved = await command.run(part: { 42 }, named: "Part 1")
    #expect(solved != .failed && solved != .unimplemented)
    let unimplemented = await command.run(
      part: { () throws -> Int in throw PartUnimplemented(day: 0, part: 2) }, named: "Part 2")
    #expect(unimplemented == .unimplemented)
    #expect(unimplemented.timing == "n/a")
    let failed = await command.run(
      part: { () throws -> Int in throw DefaultError.message("bad") }, named: "Part 1")
    #expect(failed == .failed)
  }

  @Test func timingInMilliseconds() {
    #expect(AdventOfCode.PartOutcome.solved(.microseconds(1500)).timing == "1.500 ms")
    #expect(AdventOfCode.PartOutcome.solved(.seconds(3)).timing == "3000.000 ms")
    #expect(AdventOfCode.PartOutcome.solved(.microseconds(12)).timing == "0.012 ms")
  }

  @Test func safeSubscriptUsesOffsets() {
    let values = [10, 20, 30, 40]
    #expect(values[safe: 1] == 20)
    #expect(values[safe: 4] == nil)
    #expect(values[safe: -1] == nil)
    #expect(values.dropFirst(2)[safe: 0] == 30)
  }

  @Test func pointDimensionSubscripts() {
    var point = Point(1, 2)
    point[1] = 5
    #expect(point[0] == 1 && point.y == 5)
    var point3D = Point3D(1, 2, 3)
    point3D[2] = 9
    #expect(point3D[0] == 1 && point3D.z == 9)
    let sendable: any Sendable = point3D
    #expect(sendable is Point3D)
  }

  @Test func refPrintsItsValue() {
    #expect(String(describing: Ref(5)) == "5")
  }

  @Test func paddingToLeft() {
    #expect("101".paddingToLeft(upTo: 5, using: "0") == "00101")
    #expect("10101".paddingToLeft(upTo: 3, using: "0") == "10101")
  }

  @Test func moduloMatchesReference() {
    let edges = [Int.min, Int.min + 1, -Int.max / 2, Int.max / 2, Int.max - 1, Int.max]
    for rhs in Array(1...50) + [Int.max / 2, Int.max] {
      for lhs in Array(-1000...1000) + edges {
        let remainder = lhs % rhs
        #expect(lhs %% rhs == (remainder < 0 ? remainder + rhs : remainder), "\(lhs) %% \(rhs)")
      }
    }
  }

  @Test func intPowerMatchesRepeatedMultiplication() {
    for radix in -10...10 {
      for power in 0...15 {
        #expect(radix ^^ power == repeatElement(radix, count: power).reduce(1, *))
      }
    }
    #expect(3 ^^ 39 == repeatElement(3, count: 39).reduce(1, *))
  }

  @Test func binToDecMatchesDefinition() {
    let alphabet: [Character] = ["0", "1", "+", "-", " ", "2"]
    var strings = [""]
    for _ in 1...4 { strings += strings.flatMap { s in alphabet.map { s + String($0) } } }
    for string in Set(strings) {
      let isBinary = !string.isEmpty && string.allSatisfy { $0 == "0" || $0 == "1" }
      #expect(string.binToDec() == (isBinary ? Int(string, radix: 2) : nil), "\(string)")
    }
    #expect(String(repeating: "1", count: 63).binToDec() == Int.max)
    #expect(String(repeating: "1", count: 64).binToDec() == nil)
  }

  /// Covers both the ASCII byte path and the grapheme fallback: CR LF, combining marks right
  /// after ASCII, multi-byte characters, and substrings of a base with non-ASCII before them.
  @Test(arguments: [
    "", "abcdef", "ab\r\ncd", "\r\nab\r", "e\u{301}x\u{301}", "abc\u{301}d", "日本ab",
  ])
  func stringSubscriptsMatchClampedArraySlices(string: String) {
    checkOffsetSubscripts(string)
    let base = "é|" + string + "|x"
    checkOffsetSubscripts(base.split(separator: "|", omittingEmptySubsequences: false)[1])
  }

  private func checkOffsetSubscripts(_ string: some StringProtocol) {
    let characters = Array(string)
    let label = String(string).debugDescription
    func expected(_ lower: Int, _ upper: Int) -> String {
      let lower = min(max(0, lower), characters.count)
      return String(characters[lower..<max(lower, min(upper, characters.count))])
    }
    for offset in characters.indices {
      #expect(string[offset] == characters[offset], "\(label)[\(offset)]")
    }
    for lower in -3...characters.count + 3 {
      #expect(string[lower...] == expected(lower, .max), "\(label)")
      #expect(string[..<lower] == expected(0, lower), "\(label)")
      #expect(string[...lower] == expected(0, lower + 1), "\(label)")
      for upper in lower...characters.count + 3 {
        #expect(string[lower..<upper] == expected(lower, upper), "\(label)")
        #expect(string[lower...upper] == expected(lower, upper + 1), "\(label)")
      }
    }
  }

  @Test func pointOrderIsStrictWeakOrdering() {
    let points = (-2...2).flatMap { x in (-2...2).map { y in Point(x, y) } }
    for a in points {
      #expect(!(a < a))
      for b in points {
        #expect(!(a < b && b < a))
        #expect((a < b || b < a) == (a != b))
        for c in points where a < b && b < c { #expect(a < c) }
      }
    }
  }

  @Test func dimensionSubscriptsReadAndWrite() {
    var point = Point(3, 4)
    point[0] += 10
    point[1] -= 10
    #expect(point == Point(13, -6) && point[0] == 13 && point[1] == -6)
    var point3D = Point3D(1, 2, 3)
    for dimension in 0..<3 { point3D[dimension] *= 2 }
    #expect(point3D == Point3D(2, 4, 6))
  }

  @Test func dimensionSubscriptsTrapOutOfRange() async {
    await #expect(processExitsWith: .failure) { _ = Point3D(1, 2, 3)[3] }
    await #expect(processExitsWith: .failure) {
      var point = Point(1, 2)
      point[-1] = 0
      _ = point
    }
  }

  @Test func pointHashesAreDistinct() {
    let coordinates = Array(-50...50) + [Int(Int32.min), Int(Int32.max)]
    let points = coordinates.flatMap { x in coordinates.map { y in Point(x, y) } }
    #expect(Set(points.map(\.hashValue)).count == points.count)
  }

  @Test func point3DHashesAreDistinct() {
    let coordinates = Array(-8...8) + [-(1 << 20), (1 << 20) - 1]
    let points = coordinates.flatMap { x in
      coordinates.flatMap { y in coordinates.map { z in Point3D(x, y, z) } }
    }
    #expect(Set(points.map(\.hashValue)).count == points.count)
  }

  @Test func dayAndAllAreExclusive() {
    #expect(throws: (any Error).self) { try AdventOfCode.parse(["1", "--all"]) }
    #expect(throws: Never.self) { try AdventOfCode.parse(["--all"]) }
  }

  @Test func pointOrderIsReadingOrder() {
    let points = [Point(2, 1), Point(1, 2), Point(0, 1)]
    #expect(points.sorted() == [Point(0, 1), Point(2, 1), Point(1, 2)])
    #expect(points.min() == Point(0, 1))
    #expect(points.max() == Point(1, 2))
    #expect(!(Point(1, 2) < Point(2, 1) && Point(2, 1) < Point(1, 2)))
  }

  @Test func point3DOrderIsStrict() {
    let points = [Point3D(0, 0, 1), Point3D(1, 0, 0), Point3D(0, 1, 0)]
    #expect(points.sorted() == [Point3D(1, 0, 0), Point3D(0, 1, 0), Point3D(0, 0, 1)])
  }

  @Test func isNumberMatchesIntParsing() {
    #expect("42".isNumber)
    #expect("-5".isNumber)
    #expect(!"".isNumber)
    #expect(!"4a".isNumber)
    #expect(!"٣".isNumber)
  }

  @Test func hexToBinRejectsInvalidCharacters() {
    #expect("A1".hexToBin() == "10100001")
    #expect("1G2".hexToBin() == nil)
    #expect("A1\n".hexToBin() == nil)
  }

  static let characters =
    (UInt8(0)...127).map { Character(Unicode.Scalar($0)) } + [
      "\r\n", "1\u{303}", "٣", "５", "①", "é",
    ]

  @Test func characterHexToBinMatchesPaddedRadix() {
    for character in Self.characters {
      let expected = character.hexToDec().map {
        String(String($0, radix: 2).paddingToLeft(upTo: 4, using: "0"))
      }
      #expect(character.hexToBin() == expected, "\(character.debugDescription)")
    }
  }

  @Test func intFromCharacterMatchesStringParsing() {
    for character in Self.characters {
      #expect(Int(character) == Int(String(character)), "\(character.debugDescription)")
    }
  }

  @Test func containsAll() {
    let present: Set<Character> = ["a", "c"]
    let partlyMissing: Set<Character> = ["a", "d"]
    #expect("abc".containsAll(present))
    #expect(!"abc".containsAll(partlyMissing))
  }
}
