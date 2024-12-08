import gleam/bool
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

type MoveError {
  OutsideMapError
  GuardInLoopError
}

pub type MapObject {
  Obstruction
  Empty
}

pub type Position {
  Position(row: Int, col: Int)
}

pub type Direction {
  North
  South
  East
  West
}

type Map =
  Dict(Position, MapObject)

pub type Guard {
  Guard(position: Position, direction: Direction)
}

type Trail =
  Set(Guard)

pub type State {
  State(guard: Guard, map: Map, trail: Trail)
}

pub fn parse(input: String) -> State {
  let input =
    input
    |> string.trim()
    |> string.split("\n")

  let default_guard = Guard(Position(0, 0), North)
  let initial_state = State(default_guard, dict.new(), set.new())

  use state, row, row_idx <- list.index_fold(input, initial_state)
  use state, object, col_idx <- list.index_fold(string.to_graphemes(row), state)

  let position = Position(row_idx, col_idx)
  let update_map = fn(object) { dict.insert(state.map, position, object) }

  case object {
    "#" -> State(..state, map: update_map(Obstruction))
    "." -> State(..state, map: update_map(Empty))
    "^" ->
      State(
        guard: Guard(position:, direction: North),
        map: update_map(Empty),
        trail: set.insert(state.trail, Guard(position:, direction: North)),
      )
    _ -> panic as "Unknown input map character"
  }
}

fn ahead_position(position: Position, direction: Direction) -> Position {
  let row = position.row
  let col = position.col
  case direction {
    North -> Position(row: row - 1, col:)
    South -> Position(row: row + 1, col:)
    East -> Position(row:, col: col + 1)
    West -> Position(row:, col: col - 1)
  }
}

fn try_look_ahead(state: State) -> Result(MapObject, MoveError) {
  let look_ahead_position =
    ahead_position(state.guard.position, state.guard.direction)

  dict.get(state.map, look_ahead_position)
  |> result.replace_error(OutsideMapError)
}

fn move_guard_forward(guard: Guard) {
  let new_position = ahead_position(guard.position, guard.direction)
  Guard(..guard, position: new_position)
}

fn turn_guard_right(guard: Guard) {
  let new_direction = case guard.direction {
    North -> East
    South -> West
    East -> South
    West -> North
  }
  move_guard_forward(Guard(..guard, direction: new_direction))
}

fn try_move_guard(state: State) -> Result(State, MoveError) {
  use object <- result.try(try_look_ahead(state))

  let new_guard = case object {
    Obstruction -> turn_guard_right(state.guard)
    Empty -> move_guard_forward(state.guard)
  }

  use <- bool.guard(
    set.contains(state.trail, new_guard),
    Error(GuardInLoopError),
  )

  Ok(
    State(..state, guard: new_guard, trail: set.insert(state.trail, new_guard)),
  )
}

fn guard_trail(state: State) {
  case try_move_guard(state) {
    Ok(new_state) -> guard_trail(new_state)
    Error(OutsideMapError) -> state.trail
    Error(GuardInLoopError) -> panic as "Guard is stuck in a loop !"
  }
}

pub fn pt_1(input: State) {
  guard_trail(input)
  // Remove duplicate positions
  |> set.map(fn(guard) { guard.position })
  |> set.size()
}

fn is_guard_in_loop(state: State) {
  case try_move_guard(state) {
    Ok(new_state) -> is_guard_in_loop(new_state)
    Error(OutsideMapError) -> False
    Error(GuardInLoopError) -> True
  }
}

pub fn pt_2(input: State) {
  use count, position, _object <- dict.fold(input.map, 0)

  // Do not place an obstruction where the guard is initially
  use <- bool.guard(position == input.guard.position, count)

  // Add an obstruction otherwise
  let map_with_obstruction = dict.insert(input.map, position, Obstruction)
  let state = State(..input, map: map_with_obstruction)

  case is_guard_in_loop(state) {
    True -> count + 1
    False -> count
  }
}
