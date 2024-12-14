import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder
import party

pub type Position {
  Position(x: Int, y: Int)
}

pub type Velocity {
  Velocity(x: Int, y: Int)
}

pub type Robot {
  Robot(position: Position, velocity: Velocity)
}

fn signed_int_parser() -> party.Parser(Int, e) {
  use sign <- party.do(party.perhaps(party.char("-")))
  use number <- party.do(party.digits())
  let signed_number = result.unwrap(sign, "") <> number
  let assert Ok(signed_number) = int.parse(signed_number)
  party.return(signed_number)
}

fn number_pair_parser() -> party.Parser(#(Int, Int), e) {
  use x <- party.do(signed_int_parser())
  use <- party.drop(party.char(","))
  use y <- party.do(signed_int_parser())
  party.return(#(x, y))
}

fn position_parser() -> party.Parser(Position, e) {
  use #(x, y) <- party.do(number_pair_parser())
  party.return(Position(x, y))
}

fn velocity_parser() -> party.Parser(Velocity, e) {
  use #(x, y) <- party.do(number_pair_parser())
  party.return(Velocity(x, y))
}

fn robot_parser() -> party.Parser(Robot, e) {
  use <- party.drop(party.string("p="))
  use position <- party.do(position_parser())
  use <- party.drop(party.string(" v="))
  use velocity <- party.do(velocity_parser())
  party.return(Robot(position, velocity))
}

fn parse_robot(src: String) -> Robot {
  let assert Ok(robot) = party.go(robot_parser(), src)
  robot
}

pub fn parse(input: String) -> List(Robot) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(parse_robot)
}

const space_height = 103

const space_width = 101

// const space_height = 7
//
// const space_width = 11

fn move_robot(robot: Robot) -> Robot {
  let assert Ok(x) =
    int.modulo(robot.position.x + robot.velocity.x, space_width)
  let assert Ok(y) =
    int.modulo(robot.position.y + robot.velocity.y, space_height)
  Robot(..robot, position: Position(x, y))
}

fn time_forward(robots: List(Robot)) -> List(Robot) {
  list.map(robots, move_robot)
}

pub type Quadrant {
  TopLeft
  TopRight
  BottomLeft
  BottomRight
  None
}

fn quadrant(robot: Robot) -> Quadrant {
  let middle_height = space_height / 2
  let middle_width = space_width / 2
  case robot.position.x, robot.position.y {
    x, y if x <= middle_width - 1 && y <= middle_height - 1 -> TopLeft
    x, y if x >= middle_width + 1 && y <= middle_height - 1 -> TopRight
    x, y if x <= middle_width - 1 && y >= middle_height + 1 -> BottomLeft
    x, y if x >= middle_width + 1 && y >= middle_height + 1 -> BottomRight
    _, _ -> None
  }
}

fn quadrant_counter(robots: List(Robot)) {
  use counter, robot <- list.fold(robots, dict.new())
  dict.upsert(counter, quadrant(robot), fn(count) {
    case count {
      option.Some(count) -> count + 1
      option.None -> 1
    }
  })
}

fn safety_score(robots: List(Robot)) {
  robots
  |> quadrant_counter()
  |> dict.drop([None])
  |> dict.values()
  |> int.product()
}

pub fn pt_1(input: List(Robot)) {
  input
  |> yielder.iterate(time_forward)
  |> yielder.at(100)
  |> result.unwrap([])
  |> safety_score()
}

fn empty_grid() {
  list.repeat([], space_height)
  |> list.map(fn(_) { list.repeat(".", space_width) })
}

fn robots_grid(robots: List(Robot)) {
  let robots =
    robots
    |> list.map(fn(robot) { robot.position })
    |> set.from_list()
  use row, row_idx <- list.index_map(empty_grid())
  use _cell, col_idx <- list.index_map(row)
  case set.contains(robots, Position(col_idx, row_idx)) {
    True -> "*"
    False -> "."
  }
}

fn visualise(grid: List(List(String))) {
  grid
  |> list.map(fn(row) { string.join(row, with: "") })
  |> string.join("\n")
}

fn is_tree(robots: List(Robot)) {
  let robots =
    robots
    |> list.map(fn(robot) { robot.position })
  let distance_ratio =
    list.range(from: 0, to: space_height)
    |> list.map(fn(row) { list.filter(robots, fn(pos) { pos.y == row }) })
    |> list.map(fn(row) {
      let average =
        list.fold(row, 0, fn(sum, pos) { sum + pos.x }) / list.length(row)
      let distance_from_avg =
        list.map(row, fn(pos) { int.absolute_value(pos.x - average) })
      int.sum(distance_from_avg)
    })
    |> int.sum()
  distance_ratio < 5000
}

pub fn pt_2(input: List(Robot)) {
  io.println("\n")
  let christmas_robots =
    input
    |> yielder.iterate(time_forward)
    |> yielder.index()
    |> yielder.filter(fn(robots) {
      let #(robots, _index) = robots
      is_tree(robots)
    })
    |> yielder.first()
    |> result.unwrap(#([], 0))

  let #(robots, index) = christmas_robots
  robots
  |> robots_grid()
  |> visualise()
  |> io.println()
  index
}
