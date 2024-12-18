import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import youid/uuid.{type Uuid}

type Plant =
  String

type Region =
  List(Position)

type RegionId =
  Uuid

pub type Position {
  Position(row: Int, col: Int)
}

type Plot {
  Plot(position: Position, plant: String)
}

type PlantGrid =
  Dict(Position, Plant)

type RegionGrid =
  Dict(Position, RegionId)

type Regions =
  List(Region)

pub fn parse(input: String) -> PlantGrid {
  let rows =
    input
    |> string.trim()
    |> string.split("\n")

  use grid, row, row_idx <- list.index_fold(over: rows, from: dict.new())
  use grid, plant, col_idx <- list.index_fold(
    over: string.to_graphemes(row),
    from: grid,
  )

  dict.insert(grid, Position(row_idx, col_idx), plant)
}

fn nearby_positions(position: Position) -> List(Position) {
  let Position(row, col) = position
  [
    Position(row + 1, col),
    Position(row - 1, col),
    Position(row, col + 1),
    Position(row, col - 1),
  ]
}

fn try_nearby_plots(
  position: Position,
  plant_grid: PlantGrid,
) -> List(Result(Plot, Nil)) {
  nearby_positions(position)
  |> list.map(fn(nearby_position) {
    dict.get(plant_grid, nearby_position)
    |> result.map(Plot(nearby_position, _))
  })
}

fn complete_region(
  plot: Plot,
  region_id: Uuid,
  plant_grid: PlantGrid,
  region_grid: RegionGrid,
) -> RegionGrid {
  let region_grid =
    dict.insert(region_grid, for: plot.position, insert: region_id)
  let nearby_plots = try_nearby_plots(plot.position, plant_grid)
  use region_grid, nearby_plot <- list.fold(nearby_plots, region_grid)

  case nearby_plot {
    Ok(nearby_plot) if nearby_plot.plant == plot.plant -> {
      // Don't search again if its region is already known
      let nearby_region = dict.get(region_grid, nearby_plot.position)
      use <- bool.guard(when: result.is_ok(nearby_region), return: region_grid)
      complete_region(nearby_plot, region_id, plant_grid, region_grid)
    }
    _ -> region_grid
  }
}

fn to_region_grid(plant_grid: PlantGrid) -> RegionGrid {
  use region_grid, position, plant <- dict.fold(
    over: plant_grid,
    from: dict.new(),
  )
  let already_in_region_grid = result.is_ok(dict.get(region_grid, position))
  use <- bool.guard(when: already_in_region_grid, return: region_grid)
  complete_region(Plot(position, plant), uuid.v4(), plant_grid, region_grid)
}

fn to_regions(region_grid) -> Regions {
  {
    use regions, position, region_id <- dict.fold(
      over: region_grid,
      from: dict.new(),
    )
    use regions <- dict.upsert(in: regions, update: region_id)
    case regions {
      Some(regions) -> [position, ..regions]
      None -> [position]
    }
  }
  |> dict.values()
}

fn plot_fence_length(plot_position: Position, region: Region) -> Int {
  nearby_positions(plot_position)
  |> list.map(fn(nearby_position) {
    let is_nearby_inside_region = list.contains(region, nearby_position)
    case is_nearby_inside_region {
      True -> 0
      False -> 1
    }
  })
  |> int.sum()
}

fn region_perimeter(region: Region) -> Int {
  region
  |> list.map(plot_fence_length(_, region))
  |> int.sum()
}

fn pt_1_region_price(region: Region) -> Int {
  let area = list.length(region)
  area * region_perimeter(region)
}

pub fn pt_1(input: PlantGrid) -> Int {
  input
  |> to_region_grid()
  |> to_regions()
  |> list.map(pt_1_region_price)
  |> int.sum()
}

type FenceKind {
  Top
  Bottom
  Left
  Right
}

type Fence {
  Fence(kind: FenceKind, from: Position, to: Position)
}

fn plot_fences(pos: Position, region: Region) {
  let Position(row, col) = pos
  [
    #(Bottom, Position(row + 1, col)),
    #(Top, Position(row - 1, col)),
    #(Right, Position(row, col + 1)),
    #(Left, Position(row, col - 1)),
  ]
  |> list.fold([], fn(fences, nearby) {
    let #(side, nearby_position) = nearby
    let is_nearby_inside_region = list.contains(region, nearby_position)
    case is_nearby_inside_region {
      True -> fences
      False -> [Fence(kind: side, from: pos, to: pos), ..fences]
    }
  })
}

fn expend_fence(
  group_fence: Fence,
  fences_available: List(Fence),
  fences_not_used: List(Fence),
) -> #(Fence, List(Fence)) {
  let #(extend_from, extend_to) = besides(group_fence)
  case fences_available {
    [single_fence, ..rest_available]
      if single_fence.kind == group_fence.kind
      && single_fence.from == extend_from
    ->
      expend_fence(
        Fence(..group_fence, from: extend_from),
        list.append(fences_not_used, rest_available),
        [],
      )
    [single_fence, ..rest_available]
      if single_fence.kind == group_fence.kind && single_fence.to == extend_to
    ->
      expend_fence(
        Fence(..group_fence, to: extend_to),
        list.append(fences_not_used, rest_available),
        [],
      )
    [single_fence, ..rest_available] ->
      expend_fence(group_fence, rest_available, [
        single_fence,
        ..fences_not_used
      ])
    [] -> #(group_fence, fences_not_used)
  }
}

fn group_single_fences(
  all_single_fences: List(Fence),
  all_grouped_fences: List(Fence),
) -> List(Fence) {
  case all_single_fences {
    [first, ..rest] -> {
      let #(grouped, remaining_single) = expend_fence(first, rest, [])
      group_single_fences(remaining_single, [grouped, ..all_grouped_fences])
    }
    _ -> all_grouped_fences
  }
}

fn left(position: Position) {
  Position(row: position.row, col: position.col - 1)
}

fn right(position: Position) {
  Position(row: position.row, col: position.col + 1)
}

fn up(position: Position) {
  Position(row: position.row - 1, col: position.col)
}

fn down(position: Position) {
  Position(row: position.row + 1, col: position.col)
}

fn besides(fence: Fence) {
  case fence.kind {
    Bottom | Top -> #(left(fence.from), right(fence.to))
    Left | Right -> #(up(fence.from), down(fence.to))
  }
}

fn region_sides(region: Region) -> Int {
  region
  |> list.flat_map(plot_fences(_, region))
  |> group_single_fences([])
  |> list.length()
}

fn pt_2_region_price(region: Region) -> Int {
  let area = list.length(region)
  area * region_sides(region)
}

pub fn pt_2(input: PlantGrid) {
  input
  |> to_region_grid()
  |> to_regions()
  |> list.map(pt_2_region_price)
  |> int.sum()
}
