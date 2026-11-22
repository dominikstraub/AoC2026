import Foundation

struct Day00: AdventDay {
  var data: String

  func getValues() throws -> [Point] {
    try data.split(separator: "\n").map { line in
      let parts = line.split(separator: ",")
      guard parts.count == 2, let x = Int(parts[0]), let y = Int(parts[1]) else {
        throw DefaultError.message("Can't parse line: \(line)")
      }
      return Point(x, y)
    }
  }

  func part1() throws -> Int {
    let values = try getValues()
    print(values)
    return -1
  }
}
