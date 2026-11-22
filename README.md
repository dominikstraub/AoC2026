# Advent of Code 2026 — Swift

[![Language](https://img.shields.io/badge/language-Swift-red.svg)](https://swift.org)

Solutions for the daily programming puzzles at
[Advent of Code 2026](<https://adventofcode.com/2026>), by
[Eric Wastl](<http://was.tl/>). Built on Apple's
[Advent of Code starter project](https://github.com/swiftlang/swift-aoc-starter-example).

## Usage

Swift comes with Xcode, or you can [install it](https://www.swift.org/install/)
on a supported macOS, Linux, or Windows platform.

If you're using Xcode, you can open this project by choosing File / Open and
select the parent directory.

If you prefer the command line, you can run the test suite with `swift test`,
and run the output with `swift run`.

If you're using Visual Studio Code to edit, you might find these Swift
extensions useful:

- [Swift](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode)
  (provides core language edit / debug / test / format features)

## Challenges

The challenges assume three files (replace 00 with the day of the challenge).

- `Sources/Data/Day00.txt`: the input data provided for the challenge (gitignored
  for every day except `Day00`, since Advent of Code asks not to publish inputs)
- `Sources/Day00.swift`: the code to solve the challenge
- `Tests/Day00.swift`: any unit tests that you want to include

To start a new day's challenge, make a copy of these files, updating 00 to the
day number.

```diff
// Add each new day implementation to this array:
let allChallenges: [any AdventDay] = [
-  Day00()
+  Day00(),
+  Day01(),
]
```

Then implement part 1 and 2. The `AdventOfCode.swift` file controls which challenge
is run with `swift run`. By default it runs the most recent challenge.

To supply command line arguments use `swift run AdventOfCode`. For example,
`swift run -c release AdventOfCode --benchmark 3` builds the binary with full
optimizations, and benchmarks the challenge for day 3.

## Linting and Formatting

swift-format ships with the Swift toolchain. Lint and format the sources with:

```shell
$ swift format lint -r Package.swift Sources Tests
$ swift format -i -r Package.swift Sources Tests
```

swift-format uses its built-in default style. A `.swift-format` configuration
file can be used to customize the style, see
[Configuration](https://github.com/swiftlang/swift-format/blob/main/Documentation/Configuration.md)
for more details.
