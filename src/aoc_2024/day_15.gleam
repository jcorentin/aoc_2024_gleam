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

pub fn parse(input: String) -> #(State, Pt2State, List(Move)) {
  let assert Ok(#(map, moves)) =
    input
    |> string.trim()
    |> string.split_once(on: "\n\n")

  let pt1_state_map = parse_map(map)
  let pt2_state_map = pt_2_parse_map(map)
  let all_moves = parse_moves(moves)
  #(pt1_state_map, pt2_state_map, all_moves)
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

pub fn pt_1(input: #(State, Pt2State, List(Move))) -> Int {
  let #(state, _, moves) = input
  let final_state = list.fold(over: moves, from: state, with: move_robot)
  final_state.map
  |> dict.filter(keeping: fn(_pos, obj) { obj == Box })
  |> dict.keys()
  |> list.map(gps_coordinate)
  |> int.sum()
}

pub type Pt2MapObject {
  BigWall
  LeftBox
  RightBox
  BigEmpty
}

pub type Pt2Map =
  Dict(Position, Pt2MapObject)

pub type Pt2State {
  Pt2State(robot: Robot, map: Pt2Map)
}

fn pt_2_parse_map(map: String) -> Pt2State {
  let rows = string.split(map, "\n")
  use state, row, row_idx <- list.index_fold(
    over: rows,
    from: Pt2State(robot: Robot(Position(0, 0)), map: dict.new()),
  )
  use state, cell, col_idx <- list.index_fold(
    over: string.to_graphemes(row),
    from: state,
  )
  let robot = case cell {
    "@" -> Robot(Position(row_idx, col_idx * 2))
    _ -> state.robot
  }
  let left_object = case cell {
    "#" -> BigWall
    "." -> BigEmpty
    "@" -> BigEmpty
    "O" -> LeftBox
    _ -> panic as "Unexpected object in map input"
  }
  let right_object = case left_object {
    LeftBox -> RightBox
    object -> object
  }
  let new_map =
    dict.insert(state.map, Position(row_idx, col_idx * 2), left_object)
  let new_extended_map =
    dict.insert(new_map, Position(row_idx, col_idx * 2 + 1), right_object)
  Pt2State(robot:, map: new_extended_map)
}

fn next_big_box_position(box_type, box_position, move) {
  let left = case box_type {
    LeftBox -> move_object(box_position, move)
    RightBox -> move_object(box_position, move) |> move_object(Left)
    _ -> panic as "Not a box !"
  }
  let right = move_object(left, Right)
  #(left, right)
}

fn move_big_box(
  box_position,
  box_type,
  next_position_left,
  next_position_right,
  map,
) {
  let #(left, right) = case box_type {
    LeftBox -> #(box_position, move_object(box_position, Right))
    RightBox -> #(move_object(box_position, Left), box_position)
    _ -> panic as "Not a box !"
  }
  let cut =
    dict.insert(map, left, BigEmpty)
    |> dict.insert(right, BigEmpty)
  let paste =
    dict.insert(cut, next_position_left, LeftBox)
    |> dict.insert(next_position_right, RightBox)
  paste
}

fn pt2_try_move_box(
  box_type: Pt2MapObject,
  box_position: Position,
  move: Move,
  map: Pt2Map,
) {
  let #(next_position_left, next_position_right) =
    next_big_box_position(box_type, box_position, move)
  let with_box_moved = move_big_box(
    box_position,
    box_type,
    next_position_left,
    next_position_right,
    _,
  )
  case dict.get(map, next_position_left), dict.get(map, next_position_right) {
    Ok(BigEmpty), Ok(BigEmpty) -> Ok(with_box_moved(map))
    Ok(BigEmpty), Ok(LeftBox) if move == Left -> Ok(with_box_moved(map))
    Ok(RightBox), Ok(BigEmpty) if move == Right -> Ok(with_box_moved(map))
    Ok(BigWall), _ -> Error(Nil)
    _, Ok(BigWall) -> Error(Nil)
    Ok(LeftBox), Ok(RightBox) ->
      // Push aligned up or down
      case pt2_try_move_box(LeftBox, next_position_left, move, map) {
        Ok(new_map) -> Ok(with_box_moved(new_map))
        Error(Nil) -> Error(Nil)
      }
    Ok(RightBox), Ok(BigEmpty) ->
      // Push disaligned up or down
      case pt2_try_move_box(RightBox, next_position_left, move, map) {
        Ok(new_map) -> Ok(with_box_moved(new_map))
        Error(Nil) -> Error(Nil)
      }
    Ok(BigEmpty), Ok(LeftBox) ->
      // Push disaligned up or down
      case pt2_try_move_box(LeftBox, next_position_right, move, map) {
        Ok(new_map) -> Ok(with_box_moved(new_map))
        Error(Nil) -> Error(Nil)
      }
    Ok(RightBox), Ok(LeftBox) if move == Left ->
      // Push left box 
      case pt2_try_move_box(RightBox, next_position_left, move, map) {
        Ok(new_map) -> Ok(with_box_moved(new_map))
        Error(Nil) -> Error(Nil)
      }
    Ok(RightBox), Ok(LeftBox) if move == Right ->
      // Push right box 
      case pt2_try_move_box(LeftBox, next_position_right, move, map) {
        Ok(new_map) -> Ok(with_box_moved(new_map))
        Error(Nil) -> Error(Nil)
      }
    Ok(RightBox), Ok(LeftBox) ->
      // Push two boxes side by side at a time up or down 
      case pt2_try_move_box(RightBox, next_position_left, move, map) {
        Ok(new_map) -> {
          case pt2_try_move_box(LeftBox, next_position_right, move, new_map) {
            Ok(again_new_map) -> Ok(with_box_moved(again_new_map))
            Error(Nil) -> Error(Nil)
          }
        }
        Error(Nil) -> Error(Nil)
      }
    _, _ -> panic as "Box is outside the map !"
  }
}

fn pt2_move_robot(state: Pt2State, move: Move) -> Pt2State {
  let Robot(robot_position) = state.robot
  let next_position = move_object(robot_position, move)
  case dict.get(state.map, next_position) {
    Ok(BigEmpty) -> Pt2State(robot: Robot(next_position), map: state.map)
    Ok(BigWall) -> state
    Ok(LeftBox) ->
      case pt2_try_move_box(LeftBox, next_position, move, state.map) {
        Ok(new_map) -> Pt2State(robot: Robot(next_position), map: new_map)
        Error(_) -> state
      }
    Ok(RightBox) ->
      case pt2_try_move_box(RightBox, next_position, move, state.map) {
        Ok(new_map) -> Pt2State(robot: Robot(next_position), map: new_map)
        Error(_) -> state
      }
    Error(_) -> panic as "Robot is outside the map !"
  }
}

pub fn pt_2(input: #(State, Pt2State, List(Move))) {
  let #(_, state, moves) = input
  let final_state = list.fold(over: moves, from: state, with: pt2_move_robot)
  final_state.map
  |> dict.filter(keeping: fn(_pos, obj) { obj == LeftBox })
  |> dict.keys()
  |> list.map(gps_coordinate)
  |> int.sum()
}
