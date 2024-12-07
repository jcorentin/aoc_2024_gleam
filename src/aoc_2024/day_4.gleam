import gleam/dict.{type Dict}
import gleam/function
import gleam/list
import gleam/result
import gleam/string

pub type Position {
  Position(row: Int, col: Int)
}

type Letter =
  String

type Grid =
  Dict(Position, Letter)

type Direction {
  N
  NE
  E
  SE
  S
  SW
  W
  NW
}

// Input parsing into a Grid

fn create_grid(input: List(List(Letter))) -> Grid {
  use grid, row, row_idx <- list.index_fold(over: input, from: dict.new())
  use grid, letter, col_idx <- list.index_fold(over: row, from: grid)
  dict.insert(grid, Position(row_idx, col_idx), letter)
}

pub fn parse(input: String) -> Grid {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> create_grid()
}

fn next_search_position(position: Position, direction: Direction) -> Position {
  case direction {
    N -> Position(position.row - 1, position.col)
    NE -> Position(position.row - 1, position.col + 1)
    E -> Position(position.row, position.col + 1)
    SE -> Position(position.row + 1, position.col + 1)
    S -> Position(position.row + 1, position.col)
    SW -> Position(position.row + 1, position.col - 1)
    W -> Position(position.row, position.col - 1)
    NW -> Position(position.row - 1, position.col - 1)
  }
}

fn is_search_word_found(
  current_position: Position,
  search_word: List(Letter),
  direction: Direction,
  grid: Grid,
) -> Bool {
  case dict.get(grid, current_position), search_word {
    Ok(current_letter), [last_search_letter] ->
      current_letter == last_search_letter
    Ok(current_letter), [first_search_letter, ..rest_search_word]
      if current_letter == first_search_letter
    ->
      is_search_word_found(
        next_search_position(current_position, direction),
        rest_search_word,
        direction,
        grid,
      )
    _, _ -> False
  }
}

const all_directions = [N, NE, E, SE, S, SW, W, NW]

fn count_matches_in_all_directions(
  current_position: Position,
  current_letter: Letter,
  search_word: List(Letter),
  grid: Grid,
) -> Int {
  let assert [initial_search_letter, ..rest_search_word] = search_word
  case current_letter == initial_search_letter {
    True -> {
      all_directions
      |> list.map(fn(direction) {
        is_search_word_found(
          next_search_position(current_position, direction),
          rest_search_word,
          direction,
          grid,
        )
      })
      |> list.count(function.identity)
    }
    False -> 0
  }
}

pub fn pt_1(grid: Grid) -> Int {
  let pt_1_search_word = ["X", "M", "A", "S"]
  dict.fold(grid, 0, fn(acc, position, letter) {
    count_matches_in_all_directions(position, letter, pt_1_search_word, grid)
    + acc
  })
}

const diagonal_directions = [NE, SE, SW, NW]

fn letters_around(current_position, grid) {
  diagonal_directions
  |> list.map(next_search_position(current_position, _))
  |> list.map(dict.get(grid, _))
  |> result.all()
}

const pt_2_valid_letters_around_a = [
  ["M", "M", "S", "S"], ["M", "S", "S", "M"], ["S", "M", "M", "S"],
  ["S", "S", "M", "M"],
]

fn has_correct_letters_around(current_position: Position, grid: Grid) -> Bool {
  case letters_around(current_position, grid) {
    Ok(letters_around) ->
      list.contains(pt_2_valid_letters_around_a, letters_around)
    Error(_) -> False
  }
}

fn is_xmas_center(
  current_position: Position,
  current_letter: Letter,
  grid: Grid,
) -> Bool {
  case current_letter == "A" {
    True -> has_correct_letters_around(current_position, grid)
    False -> False
  }
}

pub fn pt_2(grid: Grid) -> Int {
  dict.fold(grid, 0, fn(acc, position, letter) {
    case is_xmas_center(position, letter, grid) {
      True -> acc + 1
      False -> acc
    }
  })
}
