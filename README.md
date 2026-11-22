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

To start a new day's challenge, run:

```shell
$ scripts/new-day 7    # or without a day on puzzle day, in AoC's time zone
```

It downloads the input to `Sources/Data/Day07.txt` and creates the source and
test files from the `Day00` ones. Then it regenerates `Sources/AllChallenges.swift`,
the list of days `swift run` knows about. Files that already exist are skipped, so in
a fresh clone the same command just fetches the missing input. If the puzzle hasn't
unlocked yet, or the download fails, the script stops before creating anything.
After deleting or renaming a day, run `scripts/new-day --register` to update the
list.

The download needs your adventofcode.com `session` cookie (from the browser's
developer tools), stored once in the macOS Keychain. Run the same command again
when the cookie expires:

```shell
$ security add-generic-password -U -s adventofcode-session -a "$USER" -w
```

AoC asks automated tools to include contact details. The User-Agent names this repo;
`export AOC_CONTACT=you@example.com` in your shell profile appends your contact.

Then implement part 1 and 2. `swift run` runs the most recent challenge by default.

To supply command line arguments use `swift run AdventOfCode`. For example,
`swift run -c release AdventOfCode --benchmark 3` builds the binary with full
optimizations, and benchmarks the challenge for day 3. `scripts/benchmark 3` runs it
several times and records the best time per part in [BENCHMARKS.md](BENCHMARKS.md).

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
