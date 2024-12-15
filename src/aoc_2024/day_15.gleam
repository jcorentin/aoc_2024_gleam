import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string

pub type Position {
  Position(row: Int, col: Int)
}

pub type MapObject {
  Wall
  Box
  Empty
}

pub type Map =
  Dict(Position, MapObject)

pub type Robot {
  Robot(Position)
}

pub type Move {
  Up
  Down
  Left
  Right
}

pub type State {
  State(robot: Robot, map: Map)
}

fn parse_map(map: String) -> State {
  let rows = string.split(map, "\n")
  use state, row, row_idx <- list.index_fold(
    over: rows,
    from: State(robot: Robot(Position(0, 0)), map: dict.new()),
  )
  use state, cell, col_idx <- list.index_fold(
    over: string.to_graphemes(row),
    from: state,
  )
  let robot = case cell {
    "@" -> Robot(Position(row_idx, col_idx))
    _ -> state.robot
  }
  let map_object = case cell {
    "#" -> Wall
    "." -> Empty
    "@" -> Empty
    "O" -> Box
    _ -> panic as "Unexpected object in map input"
  }
  State(
    robot:,
    map: dict.insert(state.map, Position(row_idx, col_idx), map_object),
  )
}

fn parse_moves(moves: String) -> List(Move) {
  string.to_graphemes(moves)
  |> list.fold(from: [], with: fn(moves, move) {
    case move {
      "^" -> [Up, ..moves]
      ">" -> [Right, ..moves]
      "v" -> [Down, ..moves]
      "<" -> [Left, ..moves]
      _ -> moves
    }
  })
  |> list.reverse()
}

pub fn parse(input: String) -> #(State, List(Move)) {
  let assert Ok(#(map, moves)) =
    input
    |> string.trim()
    |> string.split_once(on: "\n\n")

  let initial_state_map = parse_map(map)
  let all_moves = parse_moves(moves)
  #(initial_state_map, all_moves)
}

fn move_object(pos: Position, move: Move) -> Position {
  case move {
    Up -> Position(pos.row - 1, pos.col)
    Down -> Position(pos.row + 1, pos.col)
    Left -> Position(pos.row, pos.col - 1)
    Right -> Position(pos.row, pos.col + 1)
  }
}

fn move_box(from: Position, to: Position, on map: Map) -> Map {
  let cut = dict.insert(map, from, Empty)
  let paste = dict.insert(cut, to, Box)
  paste
}

fn try_move_box(
  box_position: Position,
  move: Move,
  map: Map,
) -> Result(Map, Nil) {
  let next_position = move_object(box_position, move)
  case dict.get(map, next_position) {
    Ok(Empty) -> Ok(move_box(box_position, next_position, map))
    Ok(Wall) -> Error(Nil)
    Ok(Box) ->
      case try_move_box(next_position, move, map) {
        Ok(new_map) -> Ok(move_box(box_position, next_position, new_map))
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> panic as "Box is outside the map !"
  }
}

fn move_robot(state: State, move: Move) -> State {
  let Robot(robot_position) = state.robot
  let next_position = move_object(robot_position, move)
  case dict.get(state.map, next_position) {
    Ok(Empty) -> State(robot: Robot(next_position), map: state.map)
    Ok(Wall) -> state
    Ok(Box) ->
      case try_move_box(next_position, move, state.map) {
        Ok(new_map) -> State(robot: Robot(next_position), map: new_map)
        Error(_) -> state
      }
    Error(_) -> panic as "Robot is outside the map !"
  }
}

fn gps_coordinate(position: Position) -> Int {
  position.row * 100 + position.col
}

pub fn pt_1(input: #(State, List(Move))) -> Int {
  let #(state, moves) = input
  let final_state = list.fold(over: moves, from: state, with: move_robot)
  final_state.map
  |> dict.filter(keeping: fn(_pos, obj) { obj == Box })
  |> dict.keys()
  |> list.map(gps_coordinate)
  |> int.sum()
}

pub fn pt_2(input: #(State, List(Move))) {
  todo as "part 2 not implemented"
}
