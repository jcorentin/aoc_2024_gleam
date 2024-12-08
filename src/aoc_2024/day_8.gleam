import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/yielder

type Antenna =
  String

pub type Position {
  Position(x: Int, y: Int)
}

type Antennas =
  Dict(Antenna, List(Position))

pub type Grid {
  Grid(max_x: Int, max_y: Int, antennas: Antennas)
}

pub fn parse(input: String) -> Grid {
  let input =
    string.trim(input)
    |> string.split("\n")

  use grid, row, row_idx <- list.index_fold(input, Grid(0, 0, dict.new()))
  use grid, char, col_idx <- list.index_fold(string.to_graphemes(row), grid)

  let position = Position(col_idx, row_idx)
  let antennas = case char {
    "." -> grid.antennas
    antenna ->
      dict.upsert(grid.antennas, antenna, fn(positions) {
        case positions {
          Some(positions) -> [position, ..positions]
          None -> [position]
        }
      })
  }
  Grid(max_x: col_idx, max_y: row_idx, antennas:)
}

fn pt_1_pair_antinodes(pair: #(Position, Position)) -> List(Position) {
  let #(first_antenna, second_antenna) = pair
  let vec_x = first_antenna.x - second_antenna.x
  let vec_y = first_antenna.y - second_antenna.y
  let first_antinode =
    Position(x: first_antenna.x + vec_x, y: first_antenna.y + vec_y)
  let second_antinode =
    Position(x: second_antenna.x - vec_x, y: second_antenna.y - vec_y)
  [first_antinode, second_antinode]
}

fn pt_1_all_antinodes(positions: List(Position)) {
  positions
  |> list.combination_pairs()
  |> list.flat_map(pt_1_pair_antinodes)
}

fn is_in_grid(position: Position, max_x: Int, max_y: Int) -> Bool {
  position.x >= 0
  && position.y >= 0
  && position.x <= max_x
  && position.y <= max_y
}

pub fn pt_1(input: Grid) {
  input.antennas
  |> dict.values()
  |> list.flat_map(pt_1_all_antinodes)
  |> list.filter(is_in_grid(_, input.max_x, input.max_y))
  |> list.unique()
  |> list.length()
}

fn pt_2_pair_antinodes(pair: #(Position, Position), max_x, max_y) {
  let #(first_antenna, second_antenna) = pair
  let vec_x = first_antenna.x - second_antenna.x
  let vec_y = first_antenna.y - second_antenna.y
  let first_antinodes =
    yielder.iterate(first_antenna, fn(position) {
      Position(x: position.x + vec_x, y: position.y + vec_y)
    })
    |> yielder.take_while(is_in_grid(_, max_x, max_y))
    |> yielder.to_list()
  let second_antinodes =
    yielder.iterate(second_antenna, fn(position) {
      Position(x: position.x - vec_x, y: position.y - vec_y)
    })
    |> yielder.take_while(is_in_grid(_, max_x, max_y))
    |> yielder.to_list()
  list.append(first_antinodes, second_antinodes)
}

fn pt_2_all_antinodes(positions: List(Position), max_x, max_y) {
  positions
  |> list.combination_pairs()
  |> list.flat_map(pt_2_pair_antinodes(_, max_x, max_y))
}

pub fn pt_2(input: Grid) {
  let all_antinodes = pt_2_all_antinodes(_, input.max_y, input.max_y)
  input.antennas
  |> dict.values()
  |> list.flat_map(all_antinodes)
  |> list.unique()
  |> list.length()
}
