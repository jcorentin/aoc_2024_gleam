import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string

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

pub fn parse(input: String) {
  let input =
    string.trim(input)
    |> string.split("\n")

  use grid, row, row_idx <- list.index_fold(input, Grid(0, 0, dict.new()))
  use grid, object, col_idx <- list.index_fold(string.to_graphemes(row), grid)
  let position = Position(col_idx, row_idx)
  let antennas = case object {
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

fn pair_antinodes(pair: #(Position, Position)) {
  let #(first_antenna, second_antenna) = pair
  let vec_x = first_antenna.x - second_antenna.x
  let vec_y = first_antenna.y - second_antenna.y
  let first_antinode =
    Position(x: first_antenna.x + vec_x, y: first_antenna.y + vec_y)
  let second_antinode =
    Position(x: second_antenna.x - vec_x, y: second_antenna.y - vec_y)
  [first_antinode, second_antinode]
}

fn all_antinodes(positions: List(Position)) {
  positions
  |> list.combination_pairs()
  |> list.flat_map(pair_antinodes)
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
  |> list.flat_map(all_antinodes)
  |> list.filter(is_in_grid(_, input.max_x, input.max_y))
  |> list.unique()
  |> list.length()
}

pub fn pt_2(input: Grid) {
  todo as "part 2 not implemented"
}
