@_exported import Algorithms
@_exported import Collections
import Foundation

protocol AdventDay: Sendable {
  associatedtype Answer = String

  /// Derived from the type name's number suffix (`Day01` → 1) unless implemented.
  static var day: Int { get }

  init(data: String)

  func part1() async throws -> Answer

  func part2() async throws -> Answer
}

struct PartUnimplemented: Error {
  let day: Int
  let part: Int
}

extension AdventDay {
  static var day: Int {
    let typeName = String(reflecting: Self.self)
    guard let i = typeName.lastIndex(where: { !$0.isNumber }),
      let day = Int(typeName[i...].dropFirst())
    else {
      fatalError(
        """
        Day number not found in type name: \
        implement the static `day` property \
        or use the day number as your type's suffix (like `Day3`).
        """)
    }
    return day
  }

  var day: Int {
    Self.day
  }

  // Lets a day compile and run before part 2 is written.
  func part2() throws -> Answer {
    throw PartUnimplemented(day: day, part: 2)
  }

  /// Creates the challenge from its `Data/DayNN.txt` puzzle input.
  init() {
    self.init(data: Self.loadData(challengeDay: Self.day))
  }

  static func loadData(challengeDay: Int) -> String {
    let dayString = String(format: "%02d", challengeDay)
    let dataFilename = "Day\(dayString)"
    guard
      let dataURL = Bundle.module.url(
        forResource: dataFilename,
        withExtension: "txt",
        subdirectory: "Data")
    else {
      fatalError("Couldn't find file '\(dataFilename).txt' in the 'Data' directory.")
    }
    let data: String
    do {
      data = try String(contentsOf: dataURL, encoding: .utf8)
    } catch {
      fatalError("Couldn't read '\(dataFilename).txt': \(error)")
    }

    // CRLF files (e.g. saved on Windows) would break splitting on "\n".
    return data.replacingOccurrences(of: "\r", with: "")
  }
}
