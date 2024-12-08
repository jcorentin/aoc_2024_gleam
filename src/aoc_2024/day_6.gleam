import gleam/dict.{type Dict}
import gleam/list
import gleam/string

type GuardOutsideError {
  GuardOutsideError
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
  List(Position)

pub type State {
  State(guard: Guard, map: Map, trail: Trail)
}

pub fn parse(input: String) -> State {
  let input =
    input
    |> string.trim()
    |> string.split("\n")

  let default_guard = Guard(Position(0, 0), North)
  let initial_state = State(default_guard, dict.new(), [])

  use state, row, row_idx <- list.index_fold(input, initial_state)
  use state, object, col_idx <- list.index_fold(string.to_graphemes(row), state)
  let position = Position(row_idx, col_idx)
  case object {
    "#" -> State(..state, map: dict.insert(state.map, position, Obstruction))
    "." -> State(..state, map: dict.insert(state.map, position, Empty))
    "^" ->
      State(
        guard: Guard(position:, direction: North),
        map: dict.insert(state.map, position, Empty),
        trail: [Position(row_idx, col_idx), ..state.trail],
      )
    _ -> panic
  }
}

fn move_guard_forward(guard: Guard) {
  let row = guard.position.row
  let col = guard.position.col
  let new_position = case guard.direction {
    North -> Position(row: row - 1, col:)
    South -> Position(row: row + 1, col:)
    East -> Position(row:, col: col + 1)
    West -> Position(row:, col: col - 1)
  }
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

fn try_move_guard(state: State) -> Result(State, GuardOutsideError) {
  let guard_moved_forward = move_guard_forward(state.guard)
  let guard_turned_right = turn_guard_right(state.guard)
  let map_object_below_guard = dict.get(state.map, guard_moved_forward.position)
  case map_object_below_guard {
    Ok(object) ->
      case object {
        Obstruction ->
          Ok(
            State(
              ..state,
              guard: guard_turned_right,
              trail: [guard_turned_right.position, ..state.trail],
            ),
          )
        Empty ->
          Ok(
            State(
              ..state,
              guard: guard_moved_forward,
              trail: [guard_moved_forward.position, ..state.trail],
            ),
          )
      }
    Error(_) -> Error(GuardOutsideError)
  }
}

fn guard_trail(state: State) {
  case try_move_guard(state) {
    Ok(new_state) -> guard_trail(new_state)
    Error(GuardOutsideError) -> state.trail
  }
}

pub fn pt_1(input: State) {
  guard_trail(input)
  |> list.unique
  |> list.length
}

pub fn pt_2(input: State) {
  todo as "part 2 not implemented"
}
