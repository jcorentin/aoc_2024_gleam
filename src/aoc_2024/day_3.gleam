import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/regexp
import gleam/result

const mul_pattern = "(mul)\\((\\d+),(\\d+)\\)"

const do_pattern = "(do)\\(\\)"

const dont_pattern = "(don't)\\(\\)"

const cond_mul_pattern = mul_pattern <> "|" <> do_pattern <> "|" <> dont_pattern

fn extract_submatches(submatches: List(Option(a))) -> List(a) {
  list.filter_map(submatches, with: fn(submatch) {
    case submatch {
      Some(string) -> Ok(string)
      None -> Error(Nil)
    }
  })
}

fn regex_scan(input: String, pattern: String) -> List(List(String)) {
  let assert Ok(re) = regexp.from_string(pattern)
  regexp.scan(with: re, content: input)
  |> list.map(fn(match) { match.submatches })
  |> list.map(extract_submatches)
}

fn product(arguments: List(String)) -> Int {
  arguments
  |> list.map(int.parse)
  |> result.values()
  |> int.product()
}

pub fn pt_1(input: String) -> Int {
  regex_scan(input, mul_pattern)
  |> list.map(product)
  |> int.sum()
}

fn filter_enabled_mul(
  acc: #(Bool, Int),
  submatches: List(String),
) -> #(Bool, Int) {
  let #(enabled, sum) = acc
  let assert [operation, ..arguments] = submatches
  case operation, enabled {
    "mul", True -> #(True, product(arguments) + sum)
    "do", _ -> #(True, sum)
    "don't", _ -> #(False, sum)
    _, _ -> #(enabled, sum)
  }
}

pub fn pt_2(input: String) -> Int {
  regex_scan(input, cond_mul_pattern)
  |> list.fold(#(True, 0), filter_enabled_mul)
  |> pair.second()
}
