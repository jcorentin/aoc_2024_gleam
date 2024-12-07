import counter
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn parse_locations(locations: List(String)) -> Result(List(Int), Nil) {
  locations
  |> list.map(int.parse)
  |> result.all()
}

pub fn parse(input: String) -> #(List(Int), List(Int)) {
  let #(left, right) =
    input
    |> string.split(on: "\n")
    |> list.map(with: string.split_once(_, on: "   "))
    |> result.values()
    |> list.unzip()

  let assert Ok(left) = parse_locations(left)
  let left = list.sort(left, int.compare)

  let assert Ok(right) = parse_locations(right)
  let right = list.sort(right, int.compare)

  #(left, right)
}

pub fn pt_1(input: #(List(Int), List(Int))) -> Int {
  let #(left, right) = input
  list.map2(left, right, fn(a, b) { int.absolute_value(a - b) })
  |> int.sum()
}

pub fn pt_2(input: #(List(Int), List(Int))) -> Int {
  let #(left, right) = input
  let loc_counter = counter.from_list(right)
  list.fold(over: left, from: 0, with: fn(score, loc) {
    score + loc * counter.get(loc_counter, loc)
  })
}
