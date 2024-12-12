import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
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

fn pt_2_region_price(region: Region) -> Int {
  todo
}

pub fn pt_2(input: PlantGrid) {
  input
  |> to_region_grid()
  |> to_regions()
  |> list.map(pt_2_region_price)
  |> int.sum()
}
