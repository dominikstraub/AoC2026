import Testing

@testable import AdventOfCode

struct Day00Tests {
  let testData = [
    (
      input: """
      1,2
      3,4
      5,6

      """,
      result1: -1,
      result2: -1
    )
  ]

  @Test func testPart1() async throws {
    for testDataEl in testData {
      if testDataEl.result1 == -1 { continue }
      let challenge = Day00(data: testDataEl.input)
      #expect(try challenge.part1() == testDataEl.result1)
    }
  }

  @Test func testPart2() async throws {
    for testDataEl in testData {
      if testDataEl.result2 == -1 { continue }
      let challenge = Day00(data: testDataEl.input)
      #expect(try challenge.part2() == testDataEl.result2)
    }
  }
}
