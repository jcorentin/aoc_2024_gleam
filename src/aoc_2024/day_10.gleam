import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

type Height =
  Int

const ground: Height = 0

const summit: Height = 9

pub type Position {
  Position(row: Int, col: Int)
}

type Point {
  Point(position: Position, height: Height)
}

type Map =
  Dict(Position, Height)

type Direction {
  North
  East
  South
  West
}

pub fn parse(input: String) -> Map {
  let input =
    input
    |> string.trim()
    |> string.split("\n")

  use map, row, row_idx <- list.index_fold(over: input, from: dict.new())
  use map, height, col_idx <- list.index_fold(
    over: string.to_graphemes(row),
    from: map,
  )

  let position = Position(row: row_idx, col: col_idx)
  let assert Ok(height) = int.parse(height)
  dict.insert(map, position, height)
}

fn adjacent_point(
  point: Point,
  direction: Direction,
  map: Map,
) -> Result(Point, Nil) {
  let Position(row: row, col: col) = point.position
  let adjacent_position = case direction {
    North -> Position(row - 1, col)
    East -> Position(row, col + 1)
    South -> Position(row + 1, col)
    West -> Position(row, col - 1)
  }
  dict.get(map, adjacent_position)
  |> result.map(fn(adjacent_height) {
    Point(position: adjacent_position, height: adjacent_height)
  })
}

const all_directions = [North, East, South, West]

fn do_accessible_summits(
  summits_reached: List(Point),
  point: Point,
  map: Map,
) -> List(Point) {
  list.map(all_directions, fn(direction) {
    adjacent_point(point, direction, map)
    |> result.map(fn(adjacent_point) {
      case adjacent_point {
        // Found an accessible summit
        Point(_, height) if height == summit && height - point.height == 1 -> [
          adjacent_point,
          ..summits_reached
        ]
        // Found an accessible higher point
        Point(_, height) if height - point.height == 1 ->
          do_accessible_summits(summits_reached, adjacent_point, map)
        // This point is either too high to be accessible or it's not higher than here
        _ -> []
      }
    })
    // In case we're searching outside the map
    |> result.unwrap([])
  })
  |> list.flatten()
}

fn accessible_summits(from point: Point, on map: Map) -> List(Point) {
  do_accessible_summits([], point, map)
}

fn all_trails_from_trailheads(map: Map) {
  dict.filter(map, fn(_, height) { height == ground })
  |> dict.fold([], fn(summits_reached, trailhead_position, _trailhead_height) {
    let trailhead = Point(trailhead_position, ground)
    [accessible_summits(from: trailhead, on: map), ..summits_reached]
  })
}

pub fn pt_1(input: Map) -> Int {
  all_trails_from_trailheads(input)
  |> list.map(list.unique)
  |> list.map(list.length)
  |> int.sum()
}

pub fn pt_2(input: Map) {
  all_trails_from_trailheads(input)
  |> list.map(list.length)
  |> int.sum()
}
