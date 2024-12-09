import gleam/function
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn to_file_blocks(disk_map_part: List(String), file_id: Int) -> List(String) {
  let file_id = int.to_string(file_id)

  case disk_map_part {
    [file_length, free_space_length] -> {
      let assert Ok(file_length) = int.parse(file_length)
      let file_blocks = list.repeat(file_id, file_length)

      let assert Ok(free_space_length) = int.parse(free_space_length)
      let free_blocks = list.repeat(".", free_space_length)

      list.append(file_blocks, free_blocks)
    }

    [file_length] -> {
      let assert Ok(file_length) = int.parse(file_length)
      list.repeat(file_id, file_length)
    }

    _ -> panic as "Incorrect extract of disk map as input"
  }
}

pub fn parse(input: String) -> List(String) {
  input
  |> string.trim()
  |> string.to_graphemes()
  |> list.sized_chunk(into: 2)
  |> list.index_map(to_file_blocks)
  |> list.flatten()
}

fn do_reclaim_free_space(
  acc: List(String),
  compacted: List(String),
  free_blocks: List(String),
) -> List(String) {
  case compacted, free_blocks {
    [], _ -> acc

    [_, ..rest_compacted], [free_block, ..rest_free_blocks] ->
      do_reclaim_free_space(
        [free_block, ..acc],
        rest_compacted,
        rest_free_blocks,
      )

    [any_block, ..rest_compacted], [] ->
      do_reclaim_free_space([any_block, ..acc], rest_compacted, [])
  }
}

fn reclaim_free_space(
  compacted: List(String),
  free_blocks: List(String),
) -> List(String) {
  do_reclaim_free_space([], compacted, free_blocks)
}

fn do_pt1_compact(
  compacted: List(String),
  free_blocks: List(String),
  remaining_blocks: List(String),
  reversed_blocks: List(String),
) -> List(String) {
  case remaining_blocks, reversed_blocks {
    [".", ..], [".", ..rest_reverse_blocks] ->
      do_pt1_compact(
        compacted,
        free_blocks,
        remaining_blocks,
        rest_reverse_blocks,
      )

    [".", ..rest_remaining_blocks], [file_block, ..rest_reverse_blocks] ->
      do_pt1_compact(
        [file_block, ..compacted],
        [".", ..free_blocks],
        rest_remaining_blocks,
        rest_reverse_blocks,
      )

    [file_block, ..rest_remaining_blocks], _ ->
      do_pt1_compact(
        [file_block, ..compacted],
        free_blocks,
        rest_remaining_blocks,
        reversed_blocks,
      )

    [], _ -> reclaim_free_space(compacted, free_blocks)
  }
}

fn pt1_compact(blocks) {
  do_pt1_compact([], [], blocks, list.reverse(blocks))
}

fn checksum(checksum: Int, block: String, position: Int) -> Int {
  let block = result.unwrap(int.parse(block), 0)
  checksum + block * position
}

pub fn pt_1(input: List(String)) {
  input
  |> pt1_compact()
  |> list.index_fold(0, checksum)
}

fn do_delete_file(
  file: List(String),
  disk_part_to_search: List(List(String)),
  disk_part_searched: List(List(String)),
) -> List(List(String)) {
  case disk_part_to_search {
    [blocks, ..rest_of_disk] if blocks == file ->
      list.append(
        list.reverse(disk_part_searched),
        // Actual deletion, replacing file by free blocks
        [list.map(file, fn(_) { "." }), ..rest_of_disk],
      )
    [blocks, ..rest_of_disk] ->
      do_delete_file(file, rest_of_disk, [blocks, ..disk_part_searched])
    [] -> panic as "File is not on disk"
  }
}

fn delete_file(file: List(String), disk: List(List(String))) {
  do_delete_file(file, disk, [])
}

fn do_try_move_file(
  file: List(String),
  disk_part_to_search: List(List(String)),
  disk_part_searched: List(List(String)),
) -> Result(List(List(String)), String) {
  let file_length = list.length(file)
  case disk_part_to_search {
    [] -> panic as "File is not on disk"
    [blocks, ..] if blocks == file -> Error("File cannot be moved left")
    [[".", ..] as free_blocks, ..rest_of_disk] ->
      case list.length(free_blocks) {
        n if n > file_length ->
          // Found a big free slot file, inserting file and deleting original
          Ok(
            list.append(list.reverse(disk_part_searched), [
              file,
              list.repeat(".", n - file_length),
              ..delete_file(file, rest_of_disk)
            ]),
          )
        n if n == file_length ->
          // Found a slot with exactly the good size, inserting file and deleting original
          Ok(
            list.append(list.reverse(disk_part_searched), [
              file,
              ..delete_file(file, rest_of_disk)
            ]),
          )
        _ ->
          // Free slot is not big enough, search continues
          do_try_move_file(file, rest_of_disk, [
            free_blocks,
            ..disk_part_searched
          ])
      }
    [other_file, ..rest_of_disk] ->
      do_try_move_file(file, rest_of_disk, [other_file, ..disk_part_searched])
  }
}

fn try_move_file(file, disk) {
  do_try_move_file(file, disk, [])
}

fn pt2_compact(disk: List(List(String))) {
  disk
  |> list.reverse()
  |> list.fold(disk, fn(compacted_disk, block) {
    case block {
      [] -> compacted_disk
      [".", ..] -> compacted_disk
      [_, ..] as file ->
        try_move_file(file, compacted_disk)
        |> result.unwrap(compacted_disk)
    }
  })
}

pub fn pt_2(input: List(String)) {
  input
  |> list.chunk(function.identity)
  |> pt2_compact()
  |> list.flatten()
  |> list.index_fold(0, checksum)
}
