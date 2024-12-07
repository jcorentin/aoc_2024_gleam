import gleam/int
import gleam/list
import gleam/result
import gleam/string

const max_levels_diff = 3

type Level =
  Int

type Report =
  List(Level)

fn parse_report(report: String) -> Report {
  let assert Ok(report) =
    report
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all()

  report
}

pub fn parse(input: String) -> List(Report) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(parse_report)
}

fn is_safe(report: Report) -> Bool {
  report
  |> list.window_by_2()
  |> list.map(fn(levels) { levels.0 - levels.1 })
  |> fn(report_diff) {
    list.all(report_diff, fn(diff) { diff > 0 && diff <= max_levels_diff })
    || list.all(report_diff, fn(diff) { diff < 0 && diff >= -max_levels_diff })
  }
}

pub fn pt_1(input: List(Report)) -> Int {
  input |> list.count(is_safe)
}

// [], [1,3,2,4,5], [] -> [[1,3,2,4], [1,3,2,5], [1,3,4,5], [1,2,4,5], [3,2,4,5]]
// TODO as "Check list.combinations source code"
fn do_dampener_options(
  acc: List(List(Int)),
  pre: List(Int),
  post: List(Int),
) -> List(List(Int)) {
  case pre {
    [_] -> [post, ..acc]
    [head, ..rest] ->
      do_dampener_options(
        [list.append(post, rest), ..acc],
        rest,
        list.append(post, [head]),
      )
    [] -> acc
  }
}

// [1,3,2,4,5] -> [[1,3,2,4], [1,3,2,5], [1,3,4,5], [1,2,4,5], [3,2,4,5]]
fn dampener_options(report: List(Int)) {
  do_dampener_options([], report, [])
}

fn is_safe_with_dampener(report: Report) -> Bool {
  case is_safe(report) {
    True -> True
    False -> {
      dampener_options(report)
      |> list.any(satisfying: is_safe)
    }
  }
}

pub fn pt_2(input: List(Report)) {
  input |> list.count(is_safe_with_dampener)
}
